import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:root_access/theme.dart';
import 'package:root_access/widgets/crack_minigame.dart';

/// Shows the minigame and plays it like a bot: every few milliseconds it checks
/// where the cursor is, and presses INJECT when [shouldTap] says so, keeping
/// the finger down for [hold] like a person would.
Future<bool?> playMinigame(
  WidgetTester tester,
  bool Function(Rect cursor, Rect window) shouldTap, {
  Duration hold = Duration.zero,
}) async {
  bool? result;
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: CrackMinigame(port: 21, random: Random(7), onFinished: (won) => result = won),
    ),
  ));

  final window = find.byWidgetPredicate(
    (w) => w is ColoredBox && w.color == TerminalColors.text.withValues(alpha: 0.35),
  );
  final cursor = find.byWidgetPredicate((w) => w is ColoredBox && w.color == TerminalColors.warning);

  for (var frame = 0; frame < 3000 && result == null; frame++) {
    await tester.pump(const Duration(milliseconds: 8));
    if (shouldTap(tester.getRect(cursor), tester.getRect(window))) {
      final finger = await tester.startGesture(tester.getCenter(find.text('INJECT')));
      await tester.pump(hold);
      await finger.up();
      await tester.pump(const Duration(milliseconds: 200)); // don't double-tap the same pass
    }
  }
  return result;
}

void main() {
  testWidgets('three taps inside the window crack the port', (tester) async {
    final won = await playMinigame(
      tester,
      (cursor, window) => cursor.center.dx > window.left + 2 && cursor.center.dx < window.right - 2,
    );
    expect(won, isTrue);
  });

  testWidgets('the press counts, not the release (finger held 150 ms)', (tester) async {
    // Regression: hits used to register on release, after the cursor had moved on.
    // Press just before the cursor leaves the window, then hold: by release time
    // the cursor is outside, so only press-time detection can count it as a hit.
    double? lastX;
    final won = await playMinigame(
      tester,
      (cursor, window) {
        final x = cursor.center.dx;
        final movingRight = lastX != null && x > lastX!;
        lastX = x;
        return movingRight ? x > window.right - 9 && x < window.right - 1 : x < window.left + 9 && x > window.left + 1;
      },
      hold: const Duration(milliseconds: 150),
    );
    expect(won, isTrue);
  });

  testWidgets('the cursor is drawn exactly where the hit check measures', (tester) async {
    // Press just inside the drawn window's edges on every pass; all three must hit.
    var presses = 0;
    final won = await playMinigame(tester, (cursor, window) {
      final inside = cursor.center.dx > window.left + 1 && cursor.center.dx < window.left + 4;
      if (inside) presses++;
      return inside;
    });
    expect(won, isTrue);
    expect(presses, CrackMinigame.hitsNeeded);
  });

  testWidgets('three taps outside the window fail the crack', (tester) async {
    final won = await playMinigame(
      tester,
      (cursor, window) => cursor.center.dx < window.left - 20 || cursor.center.dx > window.right + 20,
    );
    expect(won, isFalse);
  });
}
