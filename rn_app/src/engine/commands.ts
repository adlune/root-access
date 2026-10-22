// Port of flutter_app/lib/engine/commands.dart
// The game engine's public API. The UI only calls these four functions:
//   execute(state, input)       a typed command
//   tick(state)                 once per second, drives the trace timer
//   completeCrack(state, won)   when the crack minigame ends
//   prompt(state)               the text before the cursor

import {
  type CommandResult,
  type DownloadedFile,
  type Effect,
  type GameState,
  type OutputLine,
  connectedNode,
  currentMission,
  hasAccess,
  line,
  nodeAt,
  resetSession,
} from './gameState';
import { parseCommand } from './parser';
import { basename, findFile, isDirectory, listDirectory, resolvePath } from './paths';

const TRACE_WARNING_AT = 10; // seconds left when the warning prints

export function prompt(s: GameState): string {
  const user = s.data.player.user;
  const node = connectedNode(s);
  if (node === null) return `${user}@${s.data.player.hostname}:~$`;
  return `${user}@${node.hostname}:${s.cwd}$`;
}

export function execute(s: GameState, input: string): CommandResult {
  const cmd = parseCommand(input);
  if (cmd === null) return ok(s, []);
  const { args } = cmd;

  let result: CommandResult;
  switch (cmd.name) {
    case 'help': result = help(s); break;
    case 'mail': result = mail(s); break;
    case 'hint': result = hint(s); break;
    case 'scan': result = scan(s); break;
    case 'connect': result = connect(s, args); break;
    case 'disconnect': result = disconnect(s); break;
    case 'probe': result = probe(s); break;
    case 'crack': result = crack(s, args); break;
    case 'login': result = login(s, args); break;
    case 'ls': result = ls(s); break;
    case 'cd': result = cd(s, args); break;
    case 'cat': result = cat(s, args); break;
    case 'grep': result = grep(s, args); break;
    case 'download': result = download(s, args); break;
    case 'report': result = report(s, args); break;
    case 'learn': result = learn(s, args); break;
    case 'clear': result = ok(s, [], 'clearScreen'); break;
    default: result = error(s, `command not found: ${cmd.name}. Type 'help' for a list.`);
  }

  if (result.effect === 'clearScreen') return result;
  const echo = line(`${prompt(s)} ${input.trim()}`, 'input');
  return { ...result, lines: [echo, ...result.lines] };
}

export function tick(s: GameState): CommandResult {
  const remaining = s.traceRemaining;
  if (remaining === null) return ok(s, []);

  const next = remaining - 1;
  if (next > 0) {
    const lines = next === TRACE_WARNING_AT
      ? [line(`WARNING: ${TRACE_WARNING_AT} seconds until the trace completes!`, 'warning')]
      : [];
    return ok({ ...s, traceRemaining: next }, lines);
  }

  return ok(resetSession(s), [
    line('TRACE COMPLETE. Connection terminated.', 'error'),
    line('You were caught, and your progress on this job was reset. Try again, faster.', 'dim'),
  ]);
}

export function completeCrack(s: GameState, success: boolean): CommandResult {
  const port = s.crackPort;
  const ip = s.connectedIp;
  if (port === null || ip === null) return ok(s, []);

  if (!success) {
    return ok({ ...s, crackPort: null }, [line(`Crack failed. Run 'crack ${port}' to try again.`, 'error')]);
  }
  return ok({ ...s, crackPort: null, unlocked: [...s.unlocked, ip] }, [
    line(`Port ${port} cracked. Access granted.`, 'success'),
  ]);
}

// ---------------------------------------------------------------- helpers

function ok(s: GameState, lines: OutputLine[], effect: Effect = 'none'): CommandResult {
  return { state: s, lines, effect };
}

function error(s: GameState, message: string): CommandResult {
  return ok(s, [line(message, 'error')]);
}

function usage(s: GameState, name: string): CommandResult {
  const { usage } = s.data.commands.find((c) => c.name === name)!;
  return error(s, `usage: ${usage}`);
}

const NOT_CONNECTED = "You're on your own machine. 'connect' to a remote one first.";
const LOCKED = "Permission denied: this machine is locked. Try 'probe'.";

const plural = (n: number, word: string) => `${n} ${word}${n === 1 ? '' : 's'}`;

/** Ends the current job and moves on to the next one. */
function completeMission(s: GameState, lines: OutputLine[], downloaded?: DownloadedFile): CommandResult {
  const done = currentMission(s)!;
  const next: GameState = {
    ...resetSession(s),
    missionIndex: s.missionIndex + 1,
    completed: [...s.completed, done.id],
  };
  const upcoming = currentMission(next);
  const result = ok(next, [
    ...lines,
    line(''),
    line(`*** JOB COMPLETE: ${done.title} ***`, 'success'),
    line('Connection closed.', 'dim'),
    upcoming !== null
      ? line(`New mail from ${upcoming.sender}. Type 'mail' to read it.`)
      : line('That was the last job. You beat ROOT_ACCESS!', 'success'),
  ]);
  return { ...result, downloaded };
}

// --------------------------------------------------------------- commands

function help(s: GameState): CommandResult {
  return ok(s, s.data.commands.flatMap((c) => [line(c.usage), line(`    ${c.description}`, 'dim')]));
}

function mail(s: GameState): CommandResult {
  const m = currentMission(s);
  if (m === null) return ok(s, [line('No new mail.', 'dim')]);
  return ok(s, [
    line(`From: ${m.sender}`, 'dim'),
    line(`Subject: ${m.subject}`, 'dim'),
    line(''),
    ...m.body.map((text) => line(text)),
  ]);
}

function hint(s: GameState): CommandResult {
  const m = currentMission(s);
  if (m === null) return ok(s, [line('No job right now.', 'dim')]);
  return ok(s, [line(`Hint: ${m.hint}`, 'dim')]);
}

function scan(s: GameState): CommandResult {
  const nodes = currentMission(s)?.nodes ?? [];
  return ok(s, [
    line('Scanning local network...', 'dim'),
    ...nodes.map((n) => line(`  ${n.ip.padEnd(14)} ${n.hostname}`)),
    line(`${plural(nodes.length, 'host')} found.`, 'dim'),
  ]);
}

function connect(s: GameState, args: string[]): CommandResult {
  if (args.length === 0) return usage(s, 'connect');
  const node = nodeAt(s, args[0]);
  if (node === null) return error(s, `connect: no route to host ${args[0]}`);

  const traced = node.traceSeconds > 0;
  const next: GameState = {
    ...s,
    connectedIp: node.ip,
    cwd: '/',
    traceRemaining: traced ? node.traceSeconds : null,
    crackPort: null,
  };
  return ok(next, [
    line(`Connected to ${node.hostname} (${node.ip}).`, 'success'),
    ...(hasAccess(next) ? [] : [line("Access is restricted. Use 'probe' to inspect its ports.", 'dim')]),
    ...(traced
      ? [line(`Trace detected! You have ${node.traceSeconds} seconds before you are locked out.`, 'warning')]
      : []),
  ]);
}

function disconnect(s: GameState): CommandResult {
  const node = connectedNode(s);
  if (node === null) return error(s, 'disconnect: not connected to anything');
  return ok({ ...s, connectedIp: null, cwd: '/', traceRemaining: null, crackPort: null }, [
    line(`Disconnected from ${node.hostname}.`, 'dim'),
  ]);
}

function probe(s: GameState): CommandResult {
  const node = connectedNode(s);
  if (node === null) return error(s, NOT_CONNECTED);
  const lock = hasAccess(s) ? null : node.lock;

  return ok(s, [
    line(`Probing ${node.hostname} (${node.ip})...`, 'dim'),
    line('  PORT   SERVICE   STATE'),
    ...node.ports.map((p) => {
      const locked = p.number === lock?.port;
      return line(
        `  ${String(p.number).padEnd(6)} ${p.service.padEnd(9)} ${locked ? 'LOCKED' : 'open'}`,
        locked ? 'warning' : 'normal',
      );
    }),
    ...(lock?.crackable ? [line(`Port ${lock.port} is crackable. Try 'crack ${lock.port}'.`, 'dim')] : []),
    ...(lock && !lock.crackable ? [line(`Port ${lock.port} is hardened: cracking will not work here.`, 'dim')] : []),
  ]);
}

function crack(s: GameState, args: string[]): CommandResult {
  const node = connectedNode(s);
  if (node === null) return error(s, NOT_CONNECTED);
  // Strict like Dart's int.tryParse: "21abc" is not a port (parseInt would say 21).
  if (args.length === 0 || !/^\d+$/.test(args[0])) return usage(s, 'crack');
  const port = Number(args[0]);
  if (!node.ports.some((p) => p.number === port)) return error(s, `crack: port ${port} is not open on ${node.hostname}`);

  if (hasAccess(s)) return ok(s, [line('You already have access to this machine.', 'dim')]);
  const lock = node.lock!;
  if (lock.port !== port) return error(s, `crack: port ${port} isn't the lock. Use 'probe' to find it.`);
  if (!lock.crackable) {
    return error(s, `crack: port ${port} is hardened against cracking. You will need real credentials.`);
  }
  return ok({ ...s, crackPort: port }, [line(`Starting crack on port ${port}...`, 'dim')], 'startCrack');
}

function login(s: GameState, args: string[]): CommandResult {
  const node = connectedNode(s);
  if (node === null) return error(s, NOT_CONNECTED);
  if (args.length < 2) return usage(s, 'login');
  if (hasAccess(s)) return ok(s, [line('You already have access to this machine.', 'dim')]);

  const lock = node.lock!;
  const valid = lock.user !== null && args[0] === lock.user && args[1] === lock.password;
  if (!valid) return error(s, 'Access denied.');
  return ok({ ...s, unlocked: [...s.unlocked, node.ip] }, [line(`Logged in as ${args[0]}. Access granted.`, 'success')]);
}

function ls(s: GameState): CommandResult {
  const node = connectedNode(s);
  if (node === null) {
    const names = s.downloads.map(basename).sort();
    return ok(s, [
      line('~/downloads:', 'dim'),
      ...(names.length === 0 ? [line('  (empty)', 'dim')] : []),
      ...names.map((name) => line(`  ${name}`)),
    ]);
  }
  if (!hasAccess(s)) return error(s, LOCKED);
  const entries = listDirectory(node.files, s.cwd);
  if (entries.length === 0) return ok(s, [line('(empty)', 'dim')]);
  return ok(s, entries.map((e) => line(e, e.endsWith('/') ? 'dim' : 'normal')));
}

function cd(s: GameState, args: string[]): CommandResult {
  const node = connectedNode(s);
  if (node === null) return error(s, NOT_CONNECTED);
  if (!hasAccess(s)) return error(s, LOCKED);
  const target = resolvePath(s.cwd, args[0] ?? '/');
  if (!isDirectory(node.files, target)) return error(s, `cd: no such folder: ${args[0]}`);
  return ok({ ...s, cwd: target }, []);
}

type FileLookup = { lines: string[]; path: string } | { error: string };

/** Finds a file for cat/grep/download, or returns the error to show. */
function readFile(s: GameState, name: string): FileLookup {
  const node = connectedNode(s);
  if (node === null) {
    // On your own machine you can read what you downloaded.
    const key = s.downloads.find((k) => basename(k) === name);
    if (key === undefined) return { error: `no such file in ~/downloads: ${name}` };
    const sep = key.indexOf(':');
    const file = findFile(nodeAt(s, key.substring(0, sep))!.files, key.substring(sep + 1))!;
    return { lines: file.lines, path: file.path };
  }
  if (!hasAccess(s)) return { error: LOCKED };
  const file = findFile(node.files, resolvePath(s.cwd, name));
  if (file === undefined) return { error: `no such file: ${name}` };
  return { lines: file.lines, path: file.path };
}

function cat(s: GameState, args: string[]): CommandResult {
  if (args.length === 0) return usage(s, 'cat');
  const file = readFile(s, args[0]);
  if ('error' in file) return error(s, `cat: ${file.error}`);
  return ok(s, file.lines.map((text) => line(text)));
}

function grep(s: GameState, args: string[]): CommandResult {
  if (args.length < 2) return usage(s, 'grep');
  const word = args[0].toLowerCase();
  const file = readFile(s, args[1]);
  if ('error' in file) return error(s, `grep: ${file.error}`);

  // Case-insensitive, like `grep -i`, so beginners aren't tripped up by capitals.
  const matches = file.lines.filter((l) => l.toLowerCase().includes(word));
  return ok(s, [...matches.map((text) => line(text)), line(`-- ${plural(matches.length, 'matching line')}`, 'dim')]);
}

function download(s: GameState, args: string[]): CommandResult {
  const node = connectedNode(s);
  if (node === null) return error(s, `download: ${NOT_CONNECTED}`);
  if (args.length === 0) return usage(s, 'download');
  const file = readFile(s, args[0]);
  if ('error' in file) return error(s, `download: ${file.error}`);

  const key = `${node.ip}:${file.path}`;
  if (s.downloads.includes(key)) return ok(s, [line(`${basename(file.path)} is already in ~/downloads.`, 'dim')]);
  const next: GameState = { ...s, downloads: [...s.downloads, key] };
  const lines = [line(`Downloaded ${basename(file.path)} to ~/downloads.`, 'success')];
  const downloaded: DownloadedFile = { host: node.hostname, file: { path: file.path, lines: file.lines } };

  const goal = currentMission(s)?.objective;
  if (goal?.type === 'download' && goal.ip === node.ip && goal.path === file.path) {
    return completeMission(next, lines, downloaded);
  }
  return { ...ok(next, lines), downloaded };
}

function report(s: GameState, args: string[]): CommandResult {
  if (args.length === 0) return usage(s, 'report');
  const goal = currentMission(s)?.objective;
  if (goal?.type !== 'report') return error(s, 'report: this job has nothing to report.');

  const answer = args.join(' ').trim();
  if (answer.toLowerCase() !== goal.answer.toLowerCase()) {
    return error(s, "Report rejected: that doesn't match the evidence.");
  }
  return completeMission(s, [line(`Report accepted: ${answer}`, 'success')]);
}

function learn(s: GameState, args: string[]): CommandResult {
  const { topics } = s.data;
  if (args.length === 0) {
    return ok(s, [
      line('Topics:', 'dim'),
      line(`  ${Object.keys(topics).join(', ')}`),
      line("Type 'learn <topic>', for example 'learn ports'.", 'dim'),
    ]);
  }
  const topic = topics[args[0].toLowerCase()];
  if (topic === undefined) return error(s, `learn: no topic '${args[0]}'. Type 'learn' for the list.`);
  return ok(s, topic.map((text) => line(text)));
}
