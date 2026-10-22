import 'package:flutter/material.dart';

import '../theme.dart';

/// Typing on a phone is slow, so common commands are one tap away.
/// Entries ending in a space need an argument: they fill the input instead of running.
const quickCommands = ['help', 'mail', 'scan', 'connect ', 'probe', 'ls', 'cd ', 'cat ', 'disconnect', 'hint'];

class QuickCommands extends StatelessWidget {
  const QuickCommands({super.key, required this.onTap});

  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: quickCommands.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final cmd = quickCommands[i];
          return ActionChip(
            label: Text(cmd.trim(), style: const TextStyle(fontSize: 12)),
            onPressed: () => onTap(cmd),
            backgroundColor: TerminalColors.surface,
            side: const BorderSide(color: TerminalColors.textDim),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}
