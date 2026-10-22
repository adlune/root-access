// Port of flutter_app/lib/engine/paths.dart
// Helpers for the fake file system. A machine only stores a flat list of
// files with absolute paths; folders exist because some file path contains them.

import type { VirtualFile } from './types';

/** Turns `arg` into an absolute path, starting from `cwd`.
 *  resolvePath('/home', '../var/log') === '/var/log' */
export function resolvePath(cwd: string, arg: string): string {
  const parts = arg.startsWith('/') ? [] : cwd.split('/').filter((p) => p !== '');
  for (const segment of arg.split('/')) {
    if (segment === '' || segment === '.') continue;
    if (segment === '..') {
      parts.pop();
    } else {
      parts.push(segment);
    }
  }
  return `/${parts.join('/')}`;
}

export function basename(path: string): string {
  return path.split('/').pop()!;
}

export function isDirectory(files: VirtualFile[], path: string): boolean {
  return path === '/' || files.some((f) => f.path.startsWith(`${path}/`));
}

export function findFile(files: VirtualFile[], path: string): VirtualFile | undefined {
  return files.find((f) => f.path === path);
}

/** Entries directly inside `dir`: folders first (ending in '/'), then files. */
export function listDirectory(files: VirtualFile[], dir: string): string[] {
  const prefix = dir === '/' ? '/' : `${dir}/`;
  const folders = new Set<string>();
  const names = new Set<string>();
  for (const f of files) {
    if (!f.path.startsWith(prefix)) continue;
    const rest = f.path.substring(prefix.length);
    const slash = rest.indexOf('/');
    if (slash === -1) {
      names.add(rest);
    } else {
      folders.add(`${rest.substring(0, slash)}/`);
    }
  }
  return [...[...folders].sort(), ...[...names].sort()];
}
