// Port of flutter_app/lib/engine/game_state.dart

import type { GameData, Mission, NetworkNode, VirtualFile } from './types';

/** How the UI should color a line of terminal output. */
export type LineStyle = 'input' | 'normal' | 'dim' | 'error' | 'success' | 'warning';

export type OutputLine = {
  text: string;
  style: LineStyle;
};

export const line = (text: string, style: LineStyle = 'normal'): OutputLine => ({ text, style });

/** Something the UI has to do besides printing lines. */
export type Effect = 'none' | 'clearScreen' | 'startCrack';

/** Everything the game remembers. Treated as immutable: commands return a new
 *  state instead of changing this one, which is exactly what useReducer wants.
 *  (Arrays instead of the Dart version's Sets, so the state is plain JSON.) */
export type GameState = {
  readonly data: GameData;

  // Progress that gets saved.
  readonly missionIndex: number;
  readonly completed: readonly string[]; // mission ids

  // The current job's session. Reset when a job ends or a trace catches you.
  readonly connectedIp: string | null; // null = on your own machine
  readonly cwd: string; // folder on the connected machine
  readonly unlocked: readonly string[]; // ips you've cracked or logged into
  readonly downloads: readonly string[]; // "ip:path" keys
  readonly traceRemaining: number | null; // seconds, null = no trace running
  readonly crackPort: number | null; // set while the crack minigame is open
};

/** What running a command produced. */
export type CommandResult = {
  state: GameState;
  lines: OutputLine[];
  effect: Effect;
  /** Set when this command downloaded a file, so the UI can keep a copy
   *  (the session's downloads are wiped when a job ends). */
  downloaded?: DownloadedFile;
};

export type DownloadedFile = {
  host: string; // hostname it came from
  file: VirtualFile;
};

/** A fresh session at `missionIndex` (use the saved value to resume). */
export function startGame(data: GameData, missionIndex = 0, completed: readonly string[] = []): GameState {
  return {
    data,
    missionIndex,
    completed,
    connectedIp: null,
    cwd: '/',
    unlocked: [],
    downloads: [],
    traceRemaining: null,
    crackPort: null,
  };
}

export function currentMission(s: GameState): Mission | null {
  return s.data.missions[s.missionIndex] ?? null;
}

export function isFinished(s: GameState): boolean {
  return currentMission(s) === null;
}

export function nodeAt(s: GameState, ip: string): NetworkNode | null {
  return currentMission(s)?.nodes.find((n) => n.ip === ip) ?? null;
}

export function connectedNode(s: GameState): NetworkNode | null {
  return s.connectedIp === null ? null : nodeAt(s, s.connectedIp);
}

/** True when the connected machine has no lock left. */
export function hasAccess(s: GameState): boolean {
  const n = connectedNode(s);
  return n !== null && (n.lock === null || s.unlocked.includes(n.ip));
}

/** Back to your own machine with the current job's progress wiped. */
export function resetSession(s: GameState): GameState {
  return {
    ...s,
    connectedIp: null,
    cwd: '/',
    unlocked: [],
    downloads: [],
    traceRemaining: null,
    crackPort: null,
  };
}
