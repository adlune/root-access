// Helpers for the fake file system. A machine only stores a flat list of
// files with absolute paths; folders exist because some file path contains them.

import 'models.dart';

/// Turns [arg] into an absolute path, starting from [cwd].
/// resolvePath('/home', '../var/log') == '/var/log'
String resolvePath(String cwd, String arg) {
  final parts = arg.startsWith('/') ? <String>[] : cwd.split('/').where((p) => p.isNotEmpty).toList();
  for (final segment in arg.split('/')) {
    if (segment.isEmpty || segment == '.') continue;
    if (segment == '..') {
      if (parts.isNotEmpty) parts.removeLast();
    } else {
      parts.add(segment);
    }
  }
  return '/${parts.join('/')}';
}

String basename(String path) => path.split('/').last;

bool isDirectory(List<VirtualFile> files, String path) =>
    path == '/' || files.any((f) => f.path.startsWith('$path/'));

VirtualFile? findFile(List<VirtualFile> files, String path) {
  for (final f in files) {
    if (f.path == path) return f;
  }
  return null;
}

/// Entries directly inside [dir]: folders first (ending in '/'), then files.
List<String> listDirectory(List<VirtualFile> files, String dir) {
  final prefix = dir == '/' ? '/' : '$dir/';
  final folders = <String>{};
  final names = <String>{};
  for (final f in files) {
    if (!f.path.startsWith(prefix)) continue;
    final rest = f.path.substring(prefix.length);
    final slash = rest.indexOf('/');
    if (slash == -1) {
      names.add(rest);
    } else {
      folders.add('${rest.substring(0, slash)}/');
    }
  }
  return [...folders.toList()..sort(), ...names.toList()..sort()];
}
