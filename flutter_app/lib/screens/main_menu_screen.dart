import 'dart:async';

import 'package:flutter/material.dart';

import '../game_controller.dart';
import '../theme.dart';
import 'desktop_screen.dart';
import 'settings_screen.dart';

const bootLines = [
  'ROOT/OS bootloader v0.1',
  'cpu0: entropy-vm x86_64 @ 2.6GHz',
  'memory check ............ 4096 MB ok',
  'mounting /home/rookie ... ok',
  'starting netd ........... ok',
  'starting traced ......... ok',
  'loading entropy client .. ok',
  'handshake entropy.net ... ok',
  '',
  'welcome back, rookie.',
];

/// First screen: a fake boot sequence (once per launch, tap to skip), then the main menu.
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key, required this.controller});

  final GameController controller;

  static const lineDelay = Duration(milliseconds: 140);

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  late int _shown = widget.controller.bootShown ? bootLines.length : 1;
  Timer? _timer;

  bool get _booting => _shown < bootLines.length;
  GameController get _game => widget.controller;

  @override
  void initState() {
    super.initState();
    if (_booting) {
      _timer = Timer.periodic(MainMenuScreen.lineDelay, (_) {
        setState(() => _shown++);
        if (!_booting) _finishBoot();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _finishBoot() {
    _timer?.cancel();
    _game.bootShown = true;
    setState(() => _shown = bootLines.length);
  }

  void _openDesktop() =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => DesktopScreen(controller: _game)));

  Future<void> _newGame() async {
    if (_game.hasProgress) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: TerminalColors.surface,
          shape: const RoundedRectangleBorder(side: BorderSide(color: TerminalColors.danger)),
          title: const Text('Start a new game?', style: TextStyle(color: TerminalColors.danger)),
          content: const Text('Your finished jobs and saved files are erased.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('cancel')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('erase', style: TextStyle(color: TerminalColors.danger)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await _game.resetProgress();
    }
    _openDesktop();
  }

  void _about() => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: TerminalColors.surface,
          shape: const RoundedRectangleBorder(side: BorderSide(color: TerminalColors.textDim)),
          title: const Text('ROOT_ACCESS v0.1'),
          content: const Text(
            'A Hacknet-style terminal game, built twice: in Flutter and in React Native.\n\n'
            'Every machine, IP and password is fictional, and nothing here touches a real network. '
            "Type 'learn' in the terminal to read about the real ideas behind each command.",
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('close'))],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _booting ? _finishBoot : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _booting ? _bootLog() : _menu(),
          ),
        ),
      ),
    );
  }

  Widget _bootLog() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in bootLines.take(_shown)) Text(line, style: const TextStyle(fontSize: 13)),
          const Spacer(),
          const Center(child: Text('tap to skip', style: TextStyle(color: TerminalColors.textDim, fontSize: 12))),
        ],
      );

  Widget _menu() => ListenableBuilder(
        listenable: _game,
        builder: (context, _) {
          final state = _game.state;
          final total = state.data.missions.length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('ROOT_ACCESS', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    const Text('v0.1 // flutter build', style: TextStyle(color: TerminalColors.textDim)),
                    const SizedBox(height: 24),
                    Text(
                      state.finished ? 'all jobs complete' : 'jobs complete: ${state.completed.length}/$total',
                      style: const TextStyle(color: TerminalColors.textDim, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (_game.hasProgress) _MenuItem(label: '> continue', onTap: _openDesktop),
              _MenuItem(label: '> new game', onTap: _newGame),
              _MenuItem(
                label: '> settings',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SettingsScreen(controller: _game)),
                ),
              ),
              _MenuItem(label: '> about', onTap: _about),
            ],
          );
        },
      );
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(label)),
    );
  }
}
