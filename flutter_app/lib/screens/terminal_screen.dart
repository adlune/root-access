import 'package:flutter/material.dart';

import '../game_controller.dart';
import '../theme.dart';
import '../widgets/crack_minigame.dart';
import '../widgets/quick_commands.dart';
import '../widgets/terminal_output.dart';
import '../widgets/trace_bar.dart';
import 'inbox_screen.dart';

/// The main game screen: status bar, scrollback, quick commands and the prompt.
class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key, required this.controller});

  final GameController controller;

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();

  late int? _crackPort = _game.state.crackPort;

  GameController get _game => widget.controller;

  @override
  void initState() {
    super.initState();
    _game.addListener(_onGameChanged);
    _scrollToEnd();
  }

  @override
  void dispose() {
    _game.removeListener(_onGameChanged);
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onGameChanged() {
    _scrollToEnd();
    // Hide the keyboard while the crack minigame is open, then bring it back.
    final port = _game.state.crackPort;
    if (port != _crackPort) {
      port != null ? _focus.unfocus() : _focus.requestFocus();
      _crackPort = port;
    }
  }

  /// Keeps the newest output in view (after the new lines have been laid out).
  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  void _submit(String text) {
    _game.submit(text);
    _input.clear();
    // Keep the keyboard open for the next command, unless the crack minigame just opened.
    if (_game.state.crackPort == null) _focus.requestFocus();
  }

  void _quickCommand(String cmd) {
    if (cmd.endsWith(' ')) {
      _input.value = TextEditingValue(text: cmd, selection: TextSelection.collapsed(offset: cmd.length));
      _focus.requestFocus();
    } else {
      _submit(cmd);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _game,
          builder: (context, _) {
            final state = _game.state;
            final trace = state.traceRemaining;
            final crackPort = state.crackPort;
            return Stack(
              children: [
                Column(
                  children: [
                    _StatusBar(controller: _game),
                    if (trace != null) TraceBar(remaining: trace, total: _game.traceTotal),
                    const Divider(height: 1, color: TerminalColors.textDim),
                    Expanded(
                      child: TerminalOutput(
                        lines: _game.lines,
                        linesAdded: _game.linesAdded,
                        charsPerSecond: _game.settings.textSpeed.charsPerSecond,
                        scrollController: _scroll,
                      ),
                    ),
                    QuickCommands(onTap: _quickCommand),
                    _PromptRow(prompt: _game.prompt, controller: _input, focusNode: _focus, onSubmit: _submit),
                  ],
                ),
                if (crackPort != null)
                  Positioned.fill(
                    child: CrackMinigame(
                      key: ValueKey(crackPort),
                      port: crackPort,
                      onFinished: (won) => _game.finishCrack(success: won),
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

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final node = state.node;
    final total = state.data.missions.length;
    final job = state.finished ? 'ALL JOBS DONE' : 'JOB ${state.missionIndex + 1}/$total';
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: TerminalColors.text),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        Expanded(
          child: Text(
            node == null ? 'localhost' : '${node.hostname} (${node.ip})',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: node == null ? TerminalColors.textDim : TerminalColors.success),
          ),
        ),
        Text(job, style: const TextStyle(color: TerminalColors.textDim, fontSize: 12)),
        IconButton(
          icon: const Icon(Icons.mail_outline, color: TerminalColors.text),
          tooltip: 'Inbox',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => InboxScreen(controller: controller)),
          ),
        ),
      ],
    );
  }
}

class _PromptRow extends StatelessWidget {
  const _PromptRow({
    required this.prompt,
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
  });

  final String prompt;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: TerminalColors.text, fontSize: 13, fontFamily: terminalFont);
    return Container(
      color: TerminalColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text(prompt, style: style.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              style: style,
              cursorColor: TerminalColors.text,
              // Terminal input: no autocorrect, suggestions or auto-capitals.
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.send,
              decoration: const InputDecoration(border: InputBorder.none, isDense: true),
              onSubmitted: onSubmit,
            ),
          ),
        ],
      ),
    );
  }
}
