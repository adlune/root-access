import 'models.dart';

/// How the UI should color a line of terminal output.
enum LineStyle { input, normal, dim, error, success, warning }

class OutputLine {
  const OutputLine(this.text, [this.style = LineStyle.normal]);

  final String text;
  final LineStyle style;

  @override
  String toString() => text;
}

/// Something the UI has to do besides printing lines.
enum Effect { none, clearScreen, startCrack }

/// Everything the game remembers. Immutable: commands return a new state
/// instead of changing this one, which keeps the engine easy to test and
/// maps directly onto React's useReducer in the React Native version.
class GameState {
  const GameState._({
    required this.data,
    required this.missionIndex,
    required this.completed,
    required this.connectedIp,
    required this.cwd,
    required this.unlocked,
    required this.downloads,
    required this.traceRemaining,
    required this.crackPort,
  });

  /// A fresh session at [missionIndex] (use the saved value to resume).
  factory GameState.start(GameData data, {int missionIndex = 0, Set<String> completed = const {}}) =>
      GameState._(
        data: data,
        missionIndex: missionIndex,
        completed: completed,
        connectedIp: null,
        cwd: '/',
        unlocked: const {},
        downloads: const {},
        traceRemaining: null,
        crackPort: null,
      );

  final GameData data;

  // Progress that gets saved.
  final int missionIndex;
  final Set<String> completed; // mission ids

  // The current job's session. Reset when a job ends or a trace catches you.
  final String? connectedIp; // null = on your own machine
  final String cwd; // folder on the connected machine
  final Set<String> unlocked; // ips you've cracked or logged into
  final Set<String> downloads; // "ip:path" keys
  final int? traceRemaining; // seconds, null = no trace running
  final int? crackPort; // set while the crack minigame is open

  Mission? get mission => missionIndex < data.missions.length ? data.missions[missionIndex] : null;

  bool get finished => mission == null;

  NetworkNode? nodeAt(String ip) {
    for (final n in mission?.nodes ?? const <NetworkNode>[]) {
      if (n.ip == ip) return n;
    }
    return null;
  }

  NetworkNode? get node => connectedIp == null ? null : nodeAt(connectedIp!);

  /// True when the connected machine has no lock left.
  bool get hasAccess {
    final n = node;
    return n != null && (n.lock == null || unlocked.contains(n.ip));
  }

  GameState copyWith({
    int? missionIndex,
    Set<String>? completed,
    Object? connectedIp = _keep,
    String? cwd,
    Set<String>? unlocked,
    Set<String>? downloads,
    Object? traceRemaining = _keep,
    Object? crackPort = _keep,
  }) =>
      GameState._(
        data: data,
        missionIndex: missionIndex ?? this.missionIndex,
        completed: completed ?? this.completed,
        connectedIp: identical(connectedIp, _keep) ? this.connectedIp : connectedIp as String?,
        cwd: cwd ?? this.cwd,
        unlocked: unlocked ?? this.unlocked,
        downloads: downloads ?? this.downloads,
        traceRemaining: identical(traceRemaining, _keep) ? this.traceRemaining : traceRemaining as int?,
        crackPort: identical(crackPort, _keep) ? this.crackPort : crackPort as int?,
      );

  /// Back to your own machine with the current job's progress wiped.
  GameState resetSession() => copyWith(
        connectedIp: null,
        cwd: '/',
        unlocked: const {},
        downloads: const {},
        traceRemaining: null,
        crackPort: null,
      );
}

// Marks a copyWith argument as "not passed", so null can still mean "clear it".
const _keep = Object();

/// What running a command produced.
class CommandResult {
  const CommandResult(this.state, this.lines, [this.effect = Effect.none, this.downloaded]);

  final GameState state;
  final List<OutputLine> lines;
  final Effect effect;

  /// Set when this command downloaded a file, so the UI can keep a copy
  /// (the session's downloads are wiped when a job ends).
  final DownloadedFile? downloaded;
}

class DownloadedFile {
  const DownloadedFile({required this.host, required this.file});

  final String host; // hostname it came from
  final VirtualFile file;
}
