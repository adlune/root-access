import 'dart:async';

import 'package:flutter/material.dart';

import '../game_controller.dart';
import '../theme.dart';

/// Shows the controller's notices (new mail, trace warnings...) as a toast at
/// the top of whatever screen is open. Wraps the whole app via MaterialApp.builder.
class NoticeOverlay extends StatefulWidget {
  const NoticeOverlay({super.key, required this.controller, required this.child});

  final GameController controller;
  final Widget child;

  static const showFor = Duration(seconds: 3);

  @override
  State<NoticeOverlay> createState() => _NoticeOverlayState();
}

class _NoticeOverlayState extends State<NoticeOverlay> {
  late final StreamSubscription<GameNotice> _subscription;
  GameNotice? _notice;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _subscription = widget.controller.notices.listen((notice) {
      setState(() => _notice = notice);
      _hideTimer?.cancel();
      _hideTimer = Timer(NoticeOverlay.showFor, _dismiss);
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _dismiss() {
    if (mounted) setState(() => _notice = null);
  }

  @override
  Widget build(BuildContext context) {
    final notice = _notice;
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: notice == null
                  ? const SizedBox.shrink()
                  : GestureDetector(
                      key: ObjectKey(notice),
                      onTap: _dismiss,
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(12, 44, 12, 0),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: TerminalColors.surface,
                          border: Border.all(color: colorForLine(notice.style)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          notice.message,
                          style: TextStyle(
                            color: colorForLine(notice.style),
                            fontSize: 13,
                            fontFamily: terminalFont,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
