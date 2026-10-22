import 'dart:async';

import 'package:flutter/material.dart';

import '../game_controller.dart';
import '../theme.dart';

/// The desktop's top bar: who and where you are, the trace (if any) and a clock.
class StatusBar extends StatelessWidget {
  const StatusBar({super.key, required this.controller, this.leading});

  final GameController controller;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final node = state.node;
    final trace = state.traceRemaining;
    return Container(
      color: TerminalColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          ?leading,
          Expanded(
            child: Text(
              '${state.data.playerUser}@${node?.hostname ?? state.data.playerHostname}',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: node == null ? TerminalColors.text : TerminalColors.success),
            ),
          ),
          if (trace != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                'TRACE ${trace}s',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: trace <= 10 ? TerminalColors.danger : TerminalColors.warning,
                ),
              ),
            ),
          const _Clock(),
        ],
      ),
    );
  }
}

class _Clock extends StatefulWidget {
  const _Clock();

  @override
  State<_Clock> createState() => _ClockState();
}

class _ClockState extends State<_Clock> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return Text('${two(now.hour)}:${two(now.minute)}', style: const TextStyle(fontSize: 12));
  }
}
