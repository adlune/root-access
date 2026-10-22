import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'engine/commands.dart' as engine;
import 'engine/game_state.dart';
import 'engine/models.dart';
import 'engine/parser.dart';
import 'settings.dart';

/// A pop-up message for the toast overlay.
class GameNotice {
  const GameNotice(this.message, [this.style = LineStyle.normal]);

  final String message;
  final LineStyle style; // reuses the terminal's colors
}

/// A file the player has downloaded, kept in the Files app across jobs.
class SavedFile {
  const SavedFile({required this.host, required this.path, required this.lines});

  factory SavedFile.fromJson(Json json) => SavedFile(
        host: json['host'] as String,
        path: json['path'] as String,
        lines: (json['lines'] as List).cast<String>(),
      );

  final String host;
  final String path;
  final List<String> lines;

  String get name => path.split('/').last;

  Json toJson() => {'host': host, 'path': path, 'lines': lines};
}

/// Connects the pure engine to the UI: holds the current [GameState], the
/// terminal's scrollback, settings and saved files; runs the trace timer;
/// saves progress; and announces events (toasts, haptics).
/// Screens listen to it with ListenableBuilder and rebuild when it changes.
class GameController extends ChangeNotifier {
  GameController(GameData data, this._prefs)
      : _state = GameState.start(
          data,
          missionIndex: _prefs.getInt(_missionKey) ?? 0,
          completed: (_prefs.getStringList(_completedKey) ?? const []).toSet(),
        ),
        _settings = Settings.load(_prefs),
        _mailReadFor = _prefs.getInt(_mailReadKey) ?? -1,
        _files = [
          for (final f in jsonDecode(_prefs.getString(_filesKey) ?? '[]') as List) SavedFile.fromJson(f as Json),
        ] {
    _addLines(_welcome);
  }

  /// Reads missions.json from the app bundle and the saved progress from disk.
  static Future<GameController> load() async {
    final json = await rootBundle.loadString('assets/missions.json');
    final prefs = await SharedPreferences.getInstance();
    return GameController(GameData.fromJson(jsonDecode(json) as Json), prefs);
  }

  static const _missionKey = 'missionIndex';
  static const _completedKey = 'completed';
  static const _mailReadKey = 'mailReadFor';
  static const _filesKey = 'files';
  static const _maxLines = 500; // older lines scroll away for good

  static const _welcome = [
    OutputLine('ROOT_ACCESS terminal v0.1'),
    OutputLine("Type 'mail' to read your current job, or 'help' for commands.", LineStyle.dim),
    OutputLine(''),
  ];

  final SharedPreferences _prefs;
  final List<OutputLine> _lines = [];
  final List<SavedFile> _files;
  final _notices = StreamController<GameNotice>.broadcast();
  GameState _state;
  Settings _settings;
  int _mailReadFor; // mission index whose mail has been read
  int _linesAdded = 0;
  Timer? _traceTimer;

  /// The boot sequence plays once per app launch.
  bool bootShown = false;

  GameState get state => _state;
  Settings get settings => _settings;
  List<OutputLine> get lines => List.unmodifiable(_lines);
  List<SavedFile> get files => List.unmodifiable(_files);
  String get prompt => engine.prompt(_state);
  Stream<GameNotice> get notices => _notices.stream;

  /// Total lines ever printed (never goes down, even after `clear`).
  /// The typewriter effect uses it to know which lines are new.
  int get linesAdded => _linesAdded;

  /// Length of the running trace, for drawing the trace bar.
  int get traceTotal => _state.node?.traceSeconds ?? 0;

  bool get hasProgress => _state.missionIndex > 0 || _files.isNotEmpty;
  bool get hasUnreadMail => !_state.finished && _mailReadFor != _state.missionIndex;

  void submit(String input) {
    _apply(engine.execute(_state, input));
    if (parseCommand(input)?.name == 'mail') markMailRead();
  }

  void finishCrack({required bool success}) => _apply(engine.completeCrack(_state, success: success));

  void markMailRead() {
    if (!hasUnreadMail) return;
    _mailReadFor = _state.missionIndex;
    _prefs.setInt(_mailReadKey, _mailReadFor);
    notifyListeners();
  }

  Future<void> updateSettings(Settings settings) async {
    _settings = settings;
    notifyListeners();
    await settings.save(_prefs);
  }

  /// New Game: wipes progress and files, keeps settings.
  Future<void> resetProgress() async {
    for (final key in [_missionKey, _completedKey, _mailReadKey, _filesKey]) {
      await _prefs.remove(key);
    }
    _state = GameState.start(_state.data);
    _mailReadFor = -1;
    _files.clear();
    _lines.clear();
    _addLines(_welcome);
    _syncTraceTimer();
    notifyListeners();
  }

  void _tick() {
    final wasTraced = _state.traceRemaining != null;
    _apply(engine.tick(_state));
    if (wasTraced && _state.traceRemaining == null) {
      _notify(const GameNotice('TRACE COMPLETE: you were caught', LineStyle.error));
      _buzz(HapticFeedback.heavyImpact);
    }
  }

  void _apply(CommandResult result) {
    final before = _state;
    _state = result.state;

    if (result.effect == Effect.clearScreen) _lines.clear();
    _addLines(result.lines);

    final file = result.downloaded;
    if (file != null) _saveFile(SavedFile(host: file.host, path: file.file.path, lines: file.file.lines));

    _announce(before, _state);
    _syncTraceTimer();
    notifyListeners();
  }

  void _addLines(List<OutputLine> lines) {
    _lines.addAll(lines);
    _linesAdded += lines.length;
    if (_lines.length > _maxLines) _lines.removeRange(0, _lines.length - _maxLines);
  }

  /// Turns state changes into toasts and haptics, and saves finished jobs.
  void _announce(GameState before, GameState after) {
    if (before.traceRemaining == null && after.traceRemaining != null) {
      _notify(GameNotice('Trace detected: ${after.traceRemaining}s', LineStyle.warning));
    } else if (after.traceRemaining == 10 && before.traceRemaining != 10) {
      _notify(const GameNotice('10 seconds until the trace completes!', LineStyle.error));
    }

    if (after.missionIndex > before.missionIndex) {
      _saveProgress();
      _buzz(HapticFeedback.mediumImpact);
      final next = after.mission;
      _notify(GameNotice(
        next == null ? 'All jobs complete!' : 'Job complete · new mail from ${next.sender}',
        LineStyle.success,
      ));
    }
  }

  void _notify(GameNotice notice) => _notices.add(notice);

  void _buzz(Future<void> Function() haptic) {
    if (_settings.haptics) haptic();
  }

  void _saveFile(SavedFile file) {
    _files.removeWhere((f) => f.host == file.host && f.path == file.path);
    _files.add(file);
    _prefs.setString(_filesKey, jsonEncode([for (final f in _files) f.toJson()]));
  }

  void _saveProgress() {
    _prefs.setInt(_missionKey, _state.missionIndex);
    _prefs.setStringList(_completedKey, _state.completed.toList());
  }

  /// Ticks once a second while a trace is running, and stops when it ends.
  void _syncTraceTimer() {
    if (_state.traceRemaining != null) {
      _traceTimer ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    } else {
      _traceTimer?.cancel();
      _traceTimer = null;
    }
  }

  @override
  void dispose() {
    _traceTimer?.cancel();
    _notices.close();
    super.dispose();
  }
}
