// The game engine's public API. The UI only calls these four functions:
//   execute(state, input)       a typed command
//   tick(state)                 once per second, drives the trace timer
//   completeCrack(state, won)   when the crack minigame ends
//   prompt(state)               the text before the cursor

import 'game_state.dart';
import 'models.dart';
import 'parser.dart';
import 'paths.dart';

const _traceWarningAt = 10; // seconds left when the warning prints

String prompt(GameState s) {
  final user = s.data.playerUser;
  final node = s.node;
  if (node == null) return '$user@${s.data.playerHostname}:~\$';
  return '$user@${node.hostname}:${s.cwd}\$';
}

CommandResult execute(GameState s, String input) {
  final cmd = parseCommand(input);
  if (cmd == null) return CommandResult(s, const []);

  final result = switch (cmd.name) {
    'help' => _help(s),
    'mail' => _mail(s),
    'hint' => _hint(s),
    'scan' => _scan(s),
    'connect' => _connect(s, cmd.args),
    'disconnect' => _disconnect(s),
    'probe' => _probe(s),
    'crack' => _crack(s, cmd.args),
    'login' => _login(s, cmd.args),
    'ls' => _ls(s),
    'cd' => _cd(s, cmd.args),
    'cat' => _cat(s, cmd.args),
    'grep' => _grep(s, cmd.args),
    'download' => _download(s, cmd.args),
    'report' => _report(s, cmd.args),
    'learn' => _learn(s, cmd.args),
    'clear' => CommandResult(s, const [], Effect.clearScreen),
    _ => _error(s, "command not found: ${cmd.name}. Type 'help' for a list."),
  };

  if (result.effect == Effect.clearScreen) return result;
  final echo = OutputLine('${prompt(s)} ${input.trim()}', LineStyle.input);
  return CommandResult(result.state, [echo, ...result.lines], result.effect, result.downloaded);
}

CommandResult tick(GameState s) {
  final remaining = s.traceRemaining;
  if (remaining == null) return CommandResult(s, const []);

  final next = remaining - 1;
  if (next > 0) {
    final lines = next == _traceWarningAt
        ? const [OutputLine('WARNING: $_traceWarningAt seconds until the trace completes!', LineStyle.warning)]
        : const <OutputLine>[];
    return CommandResult(s.copyWith(traceRemaining: next), lines);
  }

  return CommandResult(s.resetSession(), const [
    OutputLine('TRACE COMPLETE. Connection terminated.', LineStyle.error),
    OutputLine('You were caught, and your progress on this job was reset. Try again, faster.', LineStyle.dim),
  ]);
}

CommandResult completeCrack(GameState s, {required bool success}) {
  final port = s.crackPort;
  final ip = s.connectedIp;
  if (port == null || ip == null) return CommandResult(s, const []);

  if (!success) {
    return CommandResult(s.copyWith(crackPort: null), [
      OutputLine("Crack failed. Run 'crack $port' to try again.", LineStyle.error),
    ]);
  }
  return CommandResult(s.copyWith(crackPort: null, unlocked: {...s.unlocked, ip}), [
    OutputLine('Port $port cracked. Access granted.', LineStyle.success),
  ]);
}

// ---------------------------------------------------------------- helpers

CommandResult _ok(GameState s, List<OutputLine> lines) => CommandResult(s, lines);

CommandResult _error(GameState s, String message) => CommandResult(s, [OutputLine(message, LineStyle.error)]);

CommandResult _usage(GameState s, String name) {
  final usage = s.data.commands.firstWhere((c) => c.name == name).usage;
  return _error(s, 'usage: $usage');
}

const _notConnected = "You're on your own machine. 'connect' to a remote one first.";
const _locked = "Permission denied: this machine is locked. Try 'probe'.";

/// Ends the current job and moves on to the next one.
CommandResult _completeMission(GameState s, List<OutputLine> lines, {DownloadedFile? downloaded}) {
  final done = s.mission!;
  final next = s.resetSession().copyWith(
    missionIndex: s.missionIndex + 1,
    completed: {...s.completed, done.id},
  );
  final upcoming = next.mission;
  return CommandResult(next, [
    ...lines,
    const OutputLine(''),
    OutputLine('*** JOB COMPLETE: ${done.title} ***', LineStyle.success),
    const OutputLine('Connection closed.', LineStyle.dim),
    if (upcoming != null)
      OutputLine("New mail from ${upcoming.sender}. Type 'mail' to read it.")
    else
      const OutputLine('That was the last job. You beat ROOT_ACCESS!', LineStyle.success),
  ], Effect.none, downloaded);
}

// --------------------------------------------------------------- commands

CommandResult _help(GameState s) => _ok(s, [
      for (final c in s.data.commands) ...[
        OutputLine(c.usage),
        OutputLine('    ${c.description}', LineStyle.dim),
      ],
    ]);

CommandResult _mail(GameState s) {
  final m = s.mission;
  if (m == null) return _ok(s, const [OutputLine('No new mail.', LineStyle.dim)]);
  return _ok(s, [
    OutputLine('From: ${m.sender}', LineStyle.dim),
    OutputLine('Subject: ${m.subject}', LineStyle.dim),
    const OutputLine(''),
    for (final line in m.body) OutputLine(line),
  ]);
}

CommandResult _hint(GameState s) {
  final m = s.mission;
  if (m == null) return _ok(s, const [OutputLine('No job right now.', LineStyle.dim)]);
  return _ok(s, [OutputLine('Hint: ${m.hint}', LineStyle.dim)]);
}

CommandResult _scan(GameState s) {
  final nodes = s.mission?.nodes ?? const <NetworkNode>[];
  return _ok(s, [
    const OutputLine('Scanning local network...', LineStyle.dim),
    for (final n in nodes) OutputLine('  ${n.ip.padRight(14)} ${n.hostname}'),
    OutputLine('${nodes.length} host${nodes.length == 1 ? '' : 's'} found.', LineStyle.dim),
  ]);
}

CommandResult _connect(GameState s, List<String> args) {
  if (args.isEmpty) return _usage(s, 'connect');
  final node = s.nodeAt(args.first);
  if (node == null) return _error(s, 'connect: no route to host ${args.first}');

  final traced = node.traceSeconds > 0;
  final next = s.copyWith(
    connectedIp: node.ip,
    cwd: '/',
    traceRemaining: traced ? node.traceSeconds : null,
    crackPort: null,
  );
  return _ok(next, [
    OutputLine('Connected to ${node.hostname} (${node.ip}).', LineStyle.success),
    if (!next.hasAccess) const OutputLine("Access is restricted. Use 'probe' to inspect its ports.", LineStyle.dim),
    if (traced)
      OutputLine('Trace detected! You have ${node.traceSeconds} seconds before you are locked out.', LineStyle.warning),
  ]);
}

CommandResult _disconnect(GameState s) {
  final node = s.node;
  if (node == null) return _error(s, 'disconnect: not connected to anything');
  return _ok(s.copyWith(connectedIp: null, cwd: '/', traceRemaining: null, crackPort: null), [
    OutputLine('Disconnected from ${node.hostname}.', LineStyle.dim),
  ]);
}

CommandResult _probe(GameState s) {
  final node = s.node;
  if (node == null) return _error(s, _notConnected);
  final lock = s.hasAccess ? null : node.lock;

  return _ok(s, [
    OutputLine('Probing ${node.hostname} (${node.ip})...', LineStyle.dim),
    const OutputLine('  PORT   SERVICE   STATE'),
    for (final p in node.ports)
      OutputLine(
        '  ${'${p.number}'.padRight(6)} ${p.service.padRight(9)} ${p.number == lock?.port ? 'LOCKED' : 'open'}',
        p.number == lock?.port ? LineStyle.warning : LineStyle.normal,
      ),
    if (lock != null && lock.crackable)
      OutputLine("Port ${lock.port} is crackable. Try 'crack ${lock.port}'.", LineStyle.dim),
    if (lock != null && !lock.crackable)
      OutputLine('Port ${lock.port} is hardened: cracking will not work here.', LineStyle.dim),
  ]);
}

CommandResult _crack(GameState s, List<String> args) {
  final node = s.node;
  if (node == null) return _error(s, _notConnected);
  final port = args.isEmpty ? null : int.tryParse(args.first);
  if (port == null) return _usage(s, 'crack');
  if (!node.ports.any((p) => p.number == port)) return _error(s, 'crack: port $port is not open on ${node.hostname}');

  final lock = node.lock;
  if (s.hasAccess) return _ok(s, const [OutputLine('You already have access to this machine.', LineStyle.dim)]);
  if (lock!.port != port) return _error(s, "crack: port $port isn't the lock. Use 'probe' to find it.");
  if (!lock.crackable) {
    return _error(s, 'crack: port $port is hardened against cracking. You will need real credentials.');
  }
  return CommandResult(s.copyWith(crackPort: port), [
    OutputLine('Starting crack on port $port...', LineStyle.dim),
  ], Effect.startCrack);
}

CommandResult _login(GameState s, List<String> args) {
  final node = s.node;
  if (node == null) return _error(s, _notConnected);
  if (args.length < 2) return _usage(s, 'login');
  if (s.hasAccess) return _ok(s, const [OutputLine('You already have access to this machine.', LineStyle.dim)]);

  final lock = node.lock!;
  final valid = lock.user != null && args[0] == lock.user && args[1] == lock.password;
  if (!valid) return _error(s, 'Access denied.');
  return _ok(s.copyWith(unlocked: {...s.unlocked, node.ip}), [
    OutputLine('Logged in as ${args[0]}. Access granted.', LineStyle.success),
  ]);
}

CommandResult _ls(GameState s) {
  final node = s.node;
  if (node == null) {
    final names = [for (final key in s.downloads) basename(key)]..sort();
    return _ok(s, [
      const OutputLine('~/downloads:', LineStyle.dim),
      if (names.isEmpty) const OutputLine('  (empty)', LineStyle.dim),
      for (final name in names) OutputLine('  $name'),
    ]);
  }
  if (!s.hasAccess) return _error(s, _locked);
  final entries = listDirectory(node.files, s.cwd);
  if (entries.isEmpty) return _ok(s, const [OutputLine('(empty)', LineStyle.dim)]);
  return _ok(s, [for (final e in entries) OutputLine(e, e.endsWith('/') ? LineStyle.dim : LineStyle.normal)]);
}

CommandResult _cd(GameState s, List<String> args) {
  final node = s.node;
  if (node == null) return _error(s, _notConnected);
  if (!s.hasAccess) return _error(s, _locked);
  final target = resolvePath(s.cwd, args.isEmpty ? '/' : args.first);
  if (!isDirectory(node.files, target)) return _error(s, 'cd: no such folder: ${args.first}');
  return _ok(s.copyWith(cwd: target), const []);
}

/// Finds a file for cat/grep/download, or returns the error to show.
({List<String>? lines, String? path, String? error}) _readFile(GameState s, String name) {
  final node = s.node;
  if (node == null) {
    // On your own machine you can read what you downloaded.
    for (final key in s.downloads) {
      if (basename(key) == name) {
        final sep = key.indexOf(':');
        final file = findFile(s.nodeAt(key.substring(0, sep))!.files, key.substring(sep + 1));
        return (lines: file!.lines, path: file.path, error: null);
      }
    }
    return (lines: null, path: null, error: 'no such file in ~/downloads: $name');
  }
  if (!s.hasAccess) return (lines: null, path: null, error: _locked);
  final path = resolvePath(s.cwd, name);
  final file = findFile(node.files, path);
  if (file == null) return (lines: null, path: null, error: 'no such file: $name');
  return (lines: file.lines, path: file.path, error: null);
}

CommandResult _cat(GameState s, List<String> args) {
  if (args.isEmpty) return _usage(s, 'cat');
  final file = _readFile(s, args.first);
  if (file.error != null) return _error(s, 'cat: ${file.error}');
  return _ok(s, [for (final line in file.lines!) OutputLine(line)]);
}

CommandResult _grep(GameState s, List<String> args) {
  if (args.length < 2) return _usage(s, 'grep');
  final word = args[0].toLowerCase();
  final file = _readFile(s, args[1]);
  if (file.error != null) return _error(s, 'grep: ${file.error}');

  // Case-insensitive, like `grep -i`, so beginners aren't tripped up by capitals.
  final matches = file.lines!.where((l) => l.toLowerCase().contains(word)).toList();
  return _ok(s, [
    for (final line in matches) OutputLine(line),
    OutputLine('-- ${matches.length} matching line${matches.length == 1 ? '' : 's'}', LineStyle.dim),
  ]);
}

CommandResult _download(GameState s, List<String> args) {
  final node = s.node;
  if (node == null) return _error(s, 'download: $_notConnected');
  if (args.isEmpty) return _usage(s, 'download');
  final file = _readFile(s, args.first);
  if (file.error != null) return _error(s, 'download: ${file.error}');

  final key = '${node.ip}:${file.path}';
  if (s.downloads.contains(key)) {
    return _ok(s, [OutputLine('${basename(file.path!)} is already in ~/downloads.', LineStyle.dim)]);
  }
  final next = s.copyWith(downloads: {...s.downloads, key});
  final lines = [OutputLine('Downloaded ${basename(file.path!)} to ~/downloads.', LineStyle.success)];
  final downloaded = DownloadedFile(host: node.hostname, file: VirtualFile(path: file.path!, lines: file.lines!));

  final goal = s.mission?.objective;
  if (goal is DownloadObjective && goal.ip == node.ip && goal.path == file.path) {
    return _completeMission(next, lines, downloaded: downloaded);
  }
  return CommandResult(next, lines, Effect.none, downloaded);
}

CommandResult _report(GameState s, List<String> args) {
  if (args.isEmpty) return _usage(s, 'report');
  final goal = s.mission?.objective;
  if (goal is! ReportObjective) return _error(s, 'report: this job has nothing to report.');

  final answer = args.join(' ').trim();
  if (answer.toLowerCase() != goal.answer.toLowerCase()) {
    return _error(s, "Report rejected: that doesn't match the evidence.");
  }
  return _completeMission(s, [OutputLine('Report accepted: $answer', LineStyle.success)]);
}

CommandResult _learn(GameState s, List<String> args) {
  final topics = s.data.topics;
  if (args.isEmpty) {
    return _ok(s, [
      const OutputLine('Topics:', LineStyle.dim),
      OutputLine('  ${topics.keys.join(', ')}'),
      const OutputLine("Type 'learn <topic>', for example 'learn ports'.", LineStyle.dim),
    ]);
  }
  final topic = topics[args.first.toLowerCase()];
  if (topic == null) return _error(s, "learn: no topic '${args.first}'. Type 'learn' for the list.");
  return _ok(s, [for (final line in topic) OutputLine(line)]);
}
