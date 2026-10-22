import 'package:flutter/material.dart';

import '../theme.dart';

/// Countdown bar shown while a machine is tracing you. Turns red near the end.
class TraceBar extends StatelessWidget {
  const TraceBar({super.key, required this.remaining, required this.total});

  final int remaining;
  final int total;

  @override
  Widget build(BuildContext context) {
    final color = remaining <= 10 ? TerminalColors.danger : TerminalColors.warning;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Text('TRACE', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : remaining / total,
              minHeight: 6,
              color: color,
              backgroundColor: TerminalColors.surface,
            ),
          ),
          const SizedBox(width: 8),
          Text('${remaining}s', style: TextStyle(color: color)),
        ],
      ),
    );
  }
}
