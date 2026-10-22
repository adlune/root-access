import 'package:flutter/material.dart';

/// Terminal look for the Flutter version (green phosphor).
/// The React Native version uses the same layout with an amber palette.
abstract final class TerminalColors {
  static const background = Color(0xFF0A0A0A);
  static const surface = Color(0xFF141414);
  static const text = Color(0xFF33FF66);
  static const textDim = Color(0xFF1A8033);
  static const danger = Color(0xFFFF4D4D);
  static const success = Color(0xFF7CFF6B);
}

const terminalFont = 'monospace';

ThemeData buildTerminalTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: TerminalColors.background,
    colorScheme: base.colorScheme.copyWith(
      primary: TerminalColors.text,
      surface: TerminalColors.surface,
      error: TerminalColors.danger,
    ),
    textTheme: base.textTheme.apply(
      fontFamily: terminalFont,
      bodyColor: TerminalColors.text,
      displayColor: TerminalColors.text,
    ),
  );
}
