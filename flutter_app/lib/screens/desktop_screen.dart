import 'package:flutter/material.dart';

import '../game_controller.dart';
import '../theme.dart';
import '../widgets/status_bar.dart';
import 'files_screen.dart';
import 'inbox_screen.dart';
import 'settings_screen.dart';
import 'terminal_screen.dart';

/// ROOT/OS home screen: a status bar, app icons and the current job.
/// Everything you *do* happens in the Terminal; the other apps are for reading.
class DesktopScreen extends StatelessWidget {
  const DesktopScreen({super.key, required this.controller});

  final GameController controller;

  void _open(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final state = controller.state;
            final mission = state.mission;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StatusBar(
                  controller: controller,
                  leading: IconButton(
                    icon: const Icon(Icons.power_settings_new, size: 18, color: TerminalColors.textDim),
                    tooltip: 'Main menu',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('ROOT/OS', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, letterSpacing: 4)),
                const SizedBox(height: 32),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 28,
                  runSpacing: 24,
                  children: [
                    _AppIcon(
                      icon: Icons.terminal,
                      label: 'Terminal',
                      onTap: () => _open(context, TerminalScreen(controller: controller)),
                    ),
                    _AppIcon(
                      icon: Icons.mail_outline,
                      label: 'Mail',
                      badge: controller.hasUnreadMail ? '1' : null,
                      onTap: () => _open(context, InboxScreen(controller: controller)),
                    ),
                    _AppIcon(
                      icon: Icons.folder_outlined,
                      label: 'Files',
                      badge: controller.files.isEmpty ? null : '${controller.files.length}',
                      dimBadge: true,
                      onTap: () => _open(context, FilesScreen(controller: controller)),
                    ),
                    _AppIcon(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: () => _open(context, SettingsScreen(controller: controller)),
                    ),
                  ],
                ),
                const Spacer(),
                InkWell(
                  onTap: () => _open(context, InboxScreen(controller: controller)),
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(border: Border.all(color: TerminalColors.textDim)),
                    child: mission == null
                        ? const Text('ALL JOBS COMPLETE', style: TextStyle(color: TerminalColors.success))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CURRENT JOB ${state.missionIndex + 1}/${state.data.missions.length}',
                                style: const TextStyle(color: TerminalColors.textDim, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(mission.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(mission.sender, style: const TextStyle(color: TerminalColors.textDim, fontSize: 12)),
                            ],
                          ),
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

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.icon, required this.label, required this.onTap, this.badge, this.dimBadge = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;
  final bool dimBadge; // a count, not something waiting for you

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: TerminalColors.surface,
                    border: Border.all(color: TerminalColors.text),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: TerminalColors.text, size: 28),
                ),
                if (badge != null)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: dimBadge ? TerminalColors.textDim : TerminalColors.danger,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(badge!, style: const TextStyle(fontSize: 11, color: TerminalColors.background)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
