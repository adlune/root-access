import 'package:flutter/material.dart';

import '../theme.dart';

/// Mission emails. TODO (Day 5): list missions from assets/missions.json.
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('INBOX'),
              Text(
                'no messages yet',
                style: TextStyle(color: TerminalColors.textDim),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
