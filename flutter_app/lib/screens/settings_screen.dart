import 'package:flutter/material.dart';

import '../game_controller.dart';
import '../settings.dart';
import '../theme.dart';
import '../widgets/app_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final settings = controller.settings;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppHeader(title: 'SETTINGS'),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Text speed'),
                      const Text(
                        'How fast terminal output types out. Tap the output to skip.',
                        style: TextStyle(color: TerminalColors.textDim, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (final speed in TextSpeed.values)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(speed.label),
                                selected: settings.textSpeed == speed,
                                onSelected: (_) => controller.updateSettings(settings.copyWith(textSpeed: speed)),
                                selectedColor: TerminalColors.text,
                                backgroundColor: TerminalColors.surface,
                                labelStyle: TextStyle(
                                  color: settings.textSpeed == speed ? TerminalColors.background : TerminalColors.text,
                                ),
                                showCheckmark: false,
                                side: const BorderSide(color: TerminalColors.textDim),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Haptics'),
                        subtitle: const Text(
                          'Vibrate when a job is done or a trace catches you.',
                          style: TextStyle(color: TerminalColors.textDim, fontSize: 12),
                        ),
                        value: settings.haptics,
                        onChanged: (on) => controller.updateSettings(settings.copyWith(haptics: on)),
                        activeThumbColor: TerminalColors.background,
                        activeTrackColor: TerminalColors.text,
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
