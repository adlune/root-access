import 'package:flutter/material.dart';

import '../theme.dart';

/// Main game screen. TODO (Day 5): output log, command input, trace bar.
class TerminalScreen extends StatelessWidget {
  const TerminalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r'root@localhost:~$ _'),
              Text(
                'terminal not implemented yet',
                style: TextStyle(color: TerminalColors.textDim),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
