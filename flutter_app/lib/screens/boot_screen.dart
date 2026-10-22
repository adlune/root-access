import 'package:flutter/material.dart';

import '../theme.dart';
import 'inbox_screen.dart';
import 'terminal_screen.dart';

/// Boot / title screen. TODO (Day 5): boot-sequence typewriter animation.
class BootScreen extends StatelessWidget {
  const BootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ROOT_ACCESS',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'v0.1 // flutter build',
                      style: TextStyle(color: TerminalColors.textDim),
                    ),
                  ],
                ),
              ),
              _MenuLink(label: '> start session', screen: const TerminalScreen()),
              _MenuLink(label: '> open inbox', screen: const InboxScreen()),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuLink extends StatelessWidget {
  const _MenuLink({required this.label, required this.screen});

  final String label;
  final Widget screen;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(label),
      ),
    );
  }
}
