import 'package:flutter/material.dart';

import '../engine/models.dart';
import '../game_controller.dart';
import '../theme.dart';
import '../widgets/app_header.dart';

/// Mission emails: finished jobs, the current one (opened by default),
/// and locked future ones shown as encrypted.
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key, required this.controller});

  final GameController controller;

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  late int? _open = widget.controller.state.missionIndex;

  @override
  void initState() {
    super.initState();
    // Opening Mail reads the current job's message (clears the desktop badge).
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.controller.markMailRead());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final state = widget.controller.state;
            final missions = state.data.missions;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppHeader(
                  title: 'MAIL',
                  trailing: [
                    Text(
                      '${state.completed.length}/${missions.length} done',
                      style: const TextStyle(color: TerminalColors.textDim, fontSize: 12),
                    ),
                  ],
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      for (var i = 0; i < missions.length; i++)
                        _MailItem(
                          mission: missions[i],
                          status: i < state.missionIndex
                              ? _MailStatus.done
                              : i == state.missionIndex
                                  ? _MailStatus.current
                                  : _MailStatus.locked,
                          open: _open == i,
                          onTap: () => setState(() => _open = _open == i ? null : i),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

enum _MailStatus { done, current, locked }

class _MailItem extends StatelessWidget {
  const _MailItem({required this.mission, required this.status, required this.open, required this.onTap});

  final Mission mission;
  final _MailStatus status;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (status == _MailStatus.locked) {
      return const _Row(
        marker: '#',
        title: '[encrypted message]',
        subtitle: 'finish your current job to decrypt',
        color: TerminalColors.textDim,
      );
    }

    final current = status == _MailStatus.current;
    final color = current ? TerminalColors.text : TerminalColors.textDim;
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Row(
            marker: current ? '>' : '✓',
            title: mission.subject,
            subtitle: '${mission.sender} · ${mission.title}',
            color: color,
            bold: current,
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 8, 16),
              child: Text(mission.body.join('\n'), style: TextStyle(color: color, fontSize: 13, height: 1.4)),
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.marker, required this.title, required this.subtitle, required this.color, this.bold = false});

  final String marker;
  final String title;
  final String subtitle;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 24, child: Text(marker, style: TextStyle(color: color))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
                Text(subtitle, style: const TextStyle(color: TerminalColors.textDim, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
