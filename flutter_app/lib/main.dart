import 'package:flutter/material.dart';

import 'screens/boot_screen.dart';
import 'theme.dart';

void main() {
  runApp(const RootAccessApp());
}

class RootAccessApp extends StatelessWidget {
  const RootAccessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ROOT_ACCESS',
      debugShowCheckedModeBanner: false,
      theme: buildTerminalTheme(),
      home: const BootScreen(),
    );
  }
}
