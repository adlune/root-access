import 'package:flutter/material.dart';

import '../theme.dart';

/// Title bar for every "app" opened from the desktop: back arrow, title, optional extras.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.title, this.trailing = const []});

  final String title;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: TerminalColors.text),
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).pop(),
            ),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
            ...trailing,
            const SizedBox(width: 8),
          ],
        ),
        const Divider(height: 1, color: TerminalColors.textDim),
      ],
    );
  }
}
