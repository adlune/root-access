import 'package:shared_preferences/shared_preferences.dart';

/// How fast terminal output types itself out.
enum TextSpeed {
  instant('instant', 0),
  fast('fast', 1500),
  classic('classic', 400);

  const TextSpeed(this.label, this.charsPerSecond);

  final String label;
  final int charsPerSecond; // 0 = show everything at once
}

class Settings {
  const Settings({this.textSpeed = TextSpeed.fast, this.haptics = true});

  factory Settings.load(SharedPreferences prefs) => Settings(
        textSpeed: TextSpeed.values.asNameMap()[prefs.getString(_speedKey)] ?? TextSpeed.fast,
        haptics: prefs.getBool(_hapticsKey) ?? true,
      );

  static const _speedKey = 'textSpeed';
  static const _hapticsKey = 'haptics';

  final TextSpeed textSpeed;
  final bool haptics;

  Settings copyWith({TextSpeed? textSpeed, bool? haptics}) =>
      Settings(textSpeed: textSpeed ?? this.textSpeed, haptics: haptics ?? this.haptics);

  Future<void> save(SharedPreferences prefs) async {
    await prefs.setString(_speedKey, textSpeed.name);
    await prefs.setBool(_hapticsKey, haptics);
  }
}
