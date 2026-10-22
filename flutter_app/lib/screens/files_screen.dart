import 'package:flutter/material.dart';

import '../game_controller.dart';
import '../theme.dart';
import '../widgets/app_header.dart';

/// Every file you've downloaded, kept across jobs. Tap one to read it.
class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key, required this.controller});

  final GameController controller;

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  int? _open;

  @override
  Widget build(BuildContext context) {
    final files = widget.controller.files;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppHeader(title: 'FILES  ~/downloads'),
            Expanded(
              child: files.isEmpty
                  ? const Center(
                      child: Text(
                        "No files yet.\nUse 'download' in the terminal.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: TerminalColors.textDim),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        for (var i = 0; i < files.length; i++) _fileItem(files[i], i),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fileItem(SavedFile file, int i) {
    final open = _open == i;
    return InkWell(
      onTap: () => setState(() => _open = open ? null : i),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(open ? Icons.description : Icons.description_outlined, size: 18, color: TerminalColors.text),
                const SizedBox(width: 8),
                Expanded(child: Text(file.name)),
                Text(file.host, style: const TextStyle(color: TerminalColors.textDim, fontSize: 12)),
              ],
            ),
            if (open)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                color: TerminalColors.surface,
                child: Text(file.lines.join('\n'), style: const TextStyle(fontSize: 13, height: 1.4)),
              ),
          ],
        ),
      ),
    );
  }
}
