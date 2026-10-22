import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Flutter's crack minigame (tap timing): a cursor sweeps across a bar and you
/// tap INJECT while it's inside the target window. Each hit makes the window
/// smaller and the cursor faster. (The React Native version uses a code-guess game.)
class CrackMinigame extends StatefulWidget {
  const CrackMinigame({super.key, required this.port, required this.onFinished, this.random});

  final int port;
  final ValueChanged<bool> onFinished;
  final Random? random; // pass a seeded Random in tests

  static const hitsNeeded = 3;
  static const missesAllowed = 3;

  // Difficulty. Each hit multiplies the window size and the sweep time by
  // [rampPerHit], so round 3 has a window 72% as wide at 1.4x the speed.
  static const startWindow = 0.25; // fraction of the bar
  static const startSweep = Duration(milliseconds: 1600); // one pass across the bar
  static const rampPerHit = 0.85;
  static const tolerance = 0.02; // forgiveness on each side of the window

  @override
  State<CrackMinigame> createState() => _CrackMinigameState();
}

class _CrackMinigameState extends State<CrackMinigame> with SingleTickerProviderStateMixin {
  late final Random _random = widget.random ?? Random();
  late final AnimationController _sweep;

  int _hits = 0;
  int _misses = 0;
  double _windowStart = 0;
  double _windowWidth = CrackMinigame.startWindow;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(vsync: this, duration: CrackMinigame.startSweep)..repeat(reverse: true);
    _moveWindow();
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  void _moveWindow() => _windowStart = _random.nextDouble() * (1 - _windowWidth);

  void _inject() {
    if (_done) return;
    const tolerance = CrackMinigame.tolerance;
    final pos = _sweep.value; // the cursor's center, as a fraction of the bar
    final hit = pos >= _windowStart - tolerance && pos <= _windowStart + _windowWidth + tolerance;
    setState(() {
      if (hit) {
        _hits++;
        _windowWidth *= CrackMinigame.rampPerHit;
        _sweep.duration = _sweep.duration! * CrackMinigame.rampPerHit;
        _sweep.repeat(reverse: true);
        _moveWindow();
      } else {
        _misses++;
      }
    });
    if (_hits >= CrackMinigame.hitsNeeded) _finish(true);
    if (_misses >= CrackMinigame.missesAllowed) _finish(false);
  }

  void _finish(bool won) {
    _done = true;
    _sweep.stop();
    widget.onFinished(won);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: TerminalColors.surface,
            border: Border.all(color: TerminalColors.text),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'CRACKING PORT ${widget.port}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap INJECT while the cursor is inside the window.',
                textAlign: TextAlign.center,
                style: TextStyle(color: TerminalColors.textDim, fontSize: 12),
              ),
              const SizedBox(height: 20),
              _SweepBar(sweep: _sweep, windowStart: _windowStart, windowWidth: _windowWidth),
              const SizedBox(height: 12),
              Text(
                'hits $_hits/${CrackMinigame.hitsNeeded}   misses $_misses/${CrackMinigame.missesAllowed}',
                textAlign: TextAlign.center,
                style: TextStyle(color: _misses > 0 ? TerminalColors.warning : TerminalColors.textDim),
              ),
              const SizedBox(height: 16),
              // Fires the moment the finger touches the screen. A button's onPressed
              // waits for the finger to lift (~100 ms), and by then the cursor has moved.
              Listener(
                onPointerDown: (_) => _inject(),
                child: OutlinedButton(
                  onPressed: () {}, // only for the press ripple; the Listener does the work
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TerminalColors.text,
                    side: const BorderSide(color: TerminalColors.text, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: const Text('INJECT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              TextButton(
                onPressed: () => _finish(false),
                child: const Text('abort', style: TextStyle(color: TerminalColors.textDim)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SweepBar extends StatelessWidget {
  const _SweepBar({required this.sweep, required this.windowStart, required this.windowWidth});

  final Animation<double> sweep;
  final double windowStart;
  final double windowWidth;

  static const _height = 28.0;
  static const _cursorWidth = 4.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return SizedBox(
          height: _height,
          child: Stack(
            clipBehavior: Clip.none, // the cursor can poke out at the very ends
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(border: Border.all(color: TerminalColors.textDim)),
                ),
              ),
              Positioned(
                left: windowStart * width,
                width: windowWidth * width,
                top: 0,
                bottom: 0,
                child: ColoredBox(color: TerminalColors.text.withValues(alpha: 0.35)),
              ),
              AnimatedBuilder(
                animation: sweep,
                // Centered on sweep.value, exactly where the hit check measures.
                builder: (context, _) => Positioned(
                  left: sweep.value * width - _cursorWidth / 2,
                  width: _cursorWidth,
                  top: 0,
                  bottom: 0,
                  child: const ColoredBox(color: TerminalColors.warning),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
