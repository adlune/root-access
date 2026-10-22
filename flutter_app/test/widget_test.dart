import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:root_access/game_controller.dart';
import 'package:root_access/main.dart';
import 'package:root_access/screens/main_menu_screen.dart';
import 'package:root_access/widgets/crack_minigame.dart';
import 'package:root_access/widgets/notice_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_data.dart';

/// Starts the app with fake saved data ([saved] is what's "on disk").
/// Text appears instantly and the boot sequence is skipped unless asked for.
Future<(GameController, SharedPreferences)> startApp(
  WidgetTester tester, {
  Map<String, Object> saved = const {},
  bool boot = false,
}) async {
  SharedPreferences.setMockInitialValues({'textSpeed': 'instant', ...saved});
  final prefs = await SharedPreferences.getInstance();
  final controller = GameController(loadGameData(), prefs)..bootShown = !boot;
  await tester.pumpWidget(RootAccessApp(controller: controller));
  return (controller, prefs);
}

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Main menu -> desktop (continue if there's progress, otherwise new game).
Future<void> openDesktop(WidgetTester tester) async {
  final cont = find.text('> continue');
  await tapAndSettle(tester, cont.evaluate().isNotEmpty ? cont : find.text('> new game'));
}

Future<void> openTerminal(WidgetTester tester) async {
  await openDesktop(tester);
  await tapAndSettle(tester, find.text('Terminal'));
}

Future<void> typeCommand(WidgetTester tester, String command) async {
  await tester.enterText(find.byType(TextField), command);
  await tester.testTextInput.receiveAction(TextInputAction.send);
  await tester.pump();
}

const mission2 = {'missionIndex': 1, 'completed': ['m1_hello_world'], 'mailReadFor': 1};

void main() {
  group('main menu', () {
    testWidgets('boot sequence types out, and a tap skips to the menu', (tester) async {
      await startApp(tester, boot: true);
      expect(find.text(bootLines.first), findsOneWidget);
      expect(find.text('> new game'), findsNothing);

      await tester.pump(MainMenuScreen.lineDelay * 3);
      expect(find.text(bootLines[2]), findsOneWidget);

      await tapAndSettle(tester, find.text('tap to skip'));
      expect(find.text('ROOT_ACCESS'), findsOneWidget);
      expect(find.text('> new game'), findsOneWidget);
      expect(find.text('> continue'), findsNothing); // nothing to continue yet
    });

    testWidgets('new game with progress asks first, then erases it', (tester) async {
      final (_, prefs) = await startApp(tester, saved: mission2);
      expect(find.text('jobs complete: 1/3'), findsOneWidget);
      expect(find.text('> continue'), findsOneWidget);

      await tapAndSettle(tester, find.text('> new game'));
      await tapAndSettle(tester, find.text('cancel'));
      expect(prefs.getInt('missionIndex'), 1);

      await tapAndSettle(tester, find.text('> new game'));
      await tapAndSettle(tester, find.text('erase'));
      expect(prefs.getInt('missionIndex'), isNull);
      expect(find.text('CURRENT JOB 1/3'), findsOneWidget); // landed on the desktop
    });
  });

  group('desktop', () {
    testWidgets('shows the apps and the current job; Mail clears its badge', (tester) async {
      final (controller, _) = await startApp(tester);
      await openDesktop(tester);
      for (final app in ['Terminal', 'Mail', 'Files', 'Settings']) {
        expect(find.text(app), findsOneWidget);
      }
      expect(find.text('Hello, World'), findsOneWidget);
      expect(controller.hasUnreadMail, isTrue);
      expect(find.text('1'), findsOneWidget); // unread badge

      await tapAndSettle(tester, find.text('Mail'));
      expect(find.text('MAIL'), findsOneWidget);
      expect(controller.hasUnreadMail, isFalse);
    });

    testWidgets('inbox shows done, current and encrypted mail', (tester) async {
      await startApp(tester, saved: mission2);
      await openDesktop(tester);
      await tapAndSettle(tester, find.text('Mail'));

      expect(find.text('Welcome to Entropy'), findsOneWidget);
      expect(find.text('Job: Kestrel Logistics pentest'), findsOneWidget);
      expect(find.textContaining('written permission'), findsOneWidget); // current mail is open
      expect(find.text('[encrypted message]'), findsOneWidget);
    });

    testWidgets('settings are saved', (tester) async {
      final (controller, prefs) = await startApp(tester);
      await openDesktop(tester);
      await tapAndSettle(tester, find.text('Settings'));

      await tapAndSettle(tester, find.text('classic'));
      await tapAndSettle(tester, find.byType(Switch));
      expect(prefs.getString('textSpeed'), 'classic');
      expect(prefs.getBool('haptics'), isFalse);
      expect(controller.settings.haptics, isFalse);
    });
  });

  group('terminal', () {
    testWidgets('typing a command prints its output', (tester) async {
      await startApp(tester);
      await openTerminal(tester);
      expect(find.textContaining("Type 'mail'"), findsOneWidget);

      await typeCommand(tester, 'scan');
      expect(find.textContaining('practice-srv'), findsOneWidget);
      expect(find.text(r'rookie@localhost:~$ scan'), findsOneWidget);
    });

    testWidgets('quick command chips run or prefill commands', (tester) async {
      await startApp(tester);
      await openTerminal(tester);

      await tester.tap(find.widgetWithText(ActionChip, 'scan'));
      await tester.pump();
      expect(find.textContaining('1 host found'), findsOneWidget);

      await tester.tap(find.widgetWithText(ActionChip, 'connect'));
      await tester.pump();
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'connect ');
    });

    testWidgets('typewriter types output gradually; a tap skips it', (tester) async {
      await startApp(tester, saved: {'textSpeed': 'classic'});
      await openTerminal(tester);

      await typeCommand(tester, 'help');
      expect(find.text(r'rookie@localhost:~$ help'), findsOneWidget); // your command shows at once
      expect(find.text('List all commands.', findRichText: true), findsNothing); // output not typed yet

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('help'), findsWidgets); // first line typed

      await tester.tap(find.byType(ListView).first);
      await tester.pumpAndSettle(); // one frame to type everything, one to scroll to the end
      expect(find.textContaining('Clear the screen.'), findsOneWidget); // last line, after skipping
    });

    testWidgets('finishing a job saves progress, keeps the file and shows a toast', (tester) async {
      final (controller, prefs) = await startApp(tester);
      await openTerminal(tester);
      for (final cmd in ['connect 10.0.0.5', 'cd home', 'download welcome.txt']) {
        await typeCommand(tester, cmd);
      }
      expect(find.textContaining('JOB COMPLETE'), findsOneWidget);
      expect(find.text('JOB 2/3'), findsOneWidget);
      expect(prefs.getInt('missionIndex'), 1);
      expect(prefs.getStringList('completed'), ['m1_hello_world']);

      expect(find.text('Job complete · new mail from bit@entropy.net'), findsOneWidget);
      await tester.pump(NoticeOverlay.showFor);
      await tester.pumpAndSettle();
      expect(find.textContaining('Job complete ·'), findsNothing); // toast went away

      expect(controller.files.single.name, 'welcome.txt');
      expect(prefs.getString('files'), contains('welcome.txt'));
      await tapAndSettle(tester, find.byTooltip('Back'));
      await tapAndSettle(tester, find.text('Files'));
      await tapAndSettle(tester, find.text('welcome.txt'));
      expect(find.textContaining('Tutorial complete'), findsOneWidget);
    });

    testWidgets('crack opens the minigame overlay; abort fails the crack', (tester) async {
      await startApp(tester, saved: mission2);
      await openTerminal(tester);
      await typeCommand(tester, 'connect 10.0.2.44');
      await typeCommand(tester, 'crack 21');
      await tester.pump();
      expect(find.byType(CrackMinigame), findsOneWidget);
      expect(find.text('CRACKING PORT 21'), findsOneWidget);

      await tester.tap(find.text('abort'));
      await tester.pump();
      expect(find.byType(CrackMinigame), findsNothing);
      expect(find.textContaining('Crack failed'), findsOneWidget);
    });

    testWidgets('trace bar counts down and announces itself', (tester) async {
      await startApp(tester, saved: mission2);
      await openTerminal(tester);
      await typeCommand(tester, 'connect 10.0.2.10');
      expect(find.text('45s'), findsOneWidget);
      expect(find.text('Trace detected: 45s'), findsOneWidget); // toast

      await tester.pump(const Duration(seconds: 3));
      expect(find.text('42s'), findsOneWidget);

      await typeCommand(tester, 'disconnect'); // stops the timer so the test can end cleanly
      await tester.pumpAndSettle(NoticeOverlay.showFor);
      expect(find.text('TRACE'), findsNothing);
    });
  });
}
