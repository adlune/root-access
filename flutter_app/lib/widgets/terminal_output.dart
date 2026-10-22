import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../engine/game_state.dart';
import '../theme.dart';

/// The scrollback, colored by style, with a typewriter effect: new output
/// types itself out at [charsPerSecond] (0 = instantly). Your own commands
/// appear at once, and tapping the output skips to the end.
class TerminalOutput extends StatefulWidget {
  const TerminalOutput({
    super.key,
    required this.lines,
    required this.linesAdded,
    required this.charsPerSecond,
    required this.scrollController,
  });

  final List<OutputLine> lines;
  final int linesAdded; // total ever printed; tells us which lines are new
  final int charsPerSecond;
  final ScrollController scrollController;

  @override
  State<TerminalOutput> createState() => _TerminalOutputState();
}

class _TerminalOutputState extends State<TerminalOutput> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  late int _done = widget.linesAdded; // lines fully typed (counted like linesAdded); old lines show at once
  int _chars = 0; // characters typed so far of the next line
  double _budget = 0; // characters we're allowed to type but haven't yet
  Duration _lastTick = Duration.zero;

  int get _pending => widget.linesAdded - _done;

  @override
  void didUpdateWidget(TerminalOutput old) {
    super.didUpdateWidget(old);
    if (_pending > widget.lines.length) {
      // Lines were cleared or scrolled away before they finished typing.
      _done = widget.linesAdded - widget.lines.length;
      _chars = 0;
    }
    if (widget.charsPerSecond == 0) {
      _revealAll();
      return;
    }
    _showEchoes();
    if (_pending > 0 && !_ticker.isActive) {
      _lastTick = Duration.zero;
      _budget = 0;
      _ticker.start();
    }
    _scrollToEnd();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    _budget += (elapsed - _lastTick).inMicroseconds / 1e6 * widget.charsPerSecond;
    _lastTick = elapsed;
    setState(() {
      while (_pending > 0) {
        final line = widget.lines[widget.lines.length - _pending];
        final left = line.text.length - _chars;
        if (line.style == LineStyle.input || _budget >= left) {
          if (line.style != LineStyle.input) _budget -= left;
          _done++;
          _chars = 0;
        } else {
          final typed = _budget.floor();
          _chars += typed;
          _budget -= typed;
          break;
        }
      }
    });
    if (_pending == 0) _ticker.stop();
    _scrollToEnd();
  }

  /// Your own commands appear right away; only the output types out.
  void _showEchoes() {
    while (_pending > 0 && _chars == 0 && widget.lines[widget.lines.length - _pending].style == LineStyle.input) {
      _done++;
    }
  }

  void _revealAll() {
    if (_pending == 0) return;
    _ticker.stop();
    setState(() {
      _done = widget.linesAdded;
      _chars = 0;
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scroll = widget.scrollController;
      if (scroll.hasClients) scroll.jumpTo(scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final full = widget.lines.length - _pending; // lines shown completely
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _revealAll,
      child: ListView.builder(
        controller: widget.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: full + (_pending > 0 ? 1 : 0),
        itemBuilder: (context, i) {
          final line = widget.lines[i];
          final text = i < full ? line.text : '${line.text.substring(0, _chars.clamp(0, line.text.length))}█';
          return Text(
            text,
            style: TextStyle(
              color: colorForLine(line.style),
              fontSize: 13,
              height: 1.35,
              fontWeight: line.style == LineStyle.input ? FontWeight.bold : FontWeight.normal,
            ),
          );
        },
      ),
    );
  }
}
