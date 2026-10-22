import 'package:flutter/material.dart';

import 'game_controller.dart';
import 'screens/main_menu_screen.dart';
import 'theme.dart';
import 'widgets/notice_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // needed before loading assets and prefs
  final controller = await GameController.load();
  runApp(RootAccessApp(controller: controller));
}

class RootAccessApp extends StatelessWidget {
  const RootAccessApp({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ROOT_ACCESS',
      debugShowCheckedModeBanner: false,
      theme: buildTerminalTheme(),
      builder: (context, child) => NoticeOverlay(controller: controller, child: child!),
      home: MainMenuScreen(controller: controller),
    );
  }
}
