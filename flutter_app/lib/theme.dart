import 'package:flutter/material.dart';

import 'engine/game_state.dart';

/// Terminal look for the Flutter version: monochrome black & white.
/// Color is reserved for functional text (errors, success, warnings, the trace).
/// The React Native version uses the same palette (rn_app/src/constants/theme.ts).
abstract final class TerminalColors {
  static const background = Color(0xFF0A0A0A);
  static const surface = Color(0xFF161616);
  static const text = Color(0xFFEDEDED);
  static const textDim = Color(0xFF808080);
  static const danger = Color(0xFFFF4D4D);
  static const success = Color(0xFF7CFF6B);
  static const warning = Color(0xFFFFB000);
}

const terminalFont = 'monospace';

Color colorForLine(LineStyle style) => switch (style) {
      LineStyle.input || LineStyle.normal => TerminalColors.text,
      LineStyle.dim => TerminalColors.textDim,
      LineStyle.error => TerminalColors.danger,
      LineStyle.success => TerminalColors.success,
      LineStyle.warning => TerminalColors.warning,
    };

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
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: TerminalColors.text,
      selectionColor: TerminalColors.textDim,
    ),
  );
}
