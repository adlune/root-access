// Everything the UI remembers: the engine's GameState plus the terminal
// scrollback, saved files, unread mail, settings and the latest notice.
// A pure reducer (no timers, storage or haptics), so it's easy to test.
// Plays the role of flutter_app/lib/game_controller.dart.

import { completeCrack, execute, tick } from '../engine/commands';
import {
  type CommandResult,
  type GameState,
  type LineStyle,
  type OutputLine,
  isFinished,
  line,
  startGame,
} from '../engine/gameState';
import { parseCommand } from '../engine/parser';
import type { GameData } from '../engine/types';
import { DEFAULT_SETTINGS, type Settings } from './settings';

const MAX_LINES = 500; // older lines scroll away for good

export const WELCOME: OutputLine[] = [
  line('ROOT_ACCESS terminal v0.1'),
  line("Type 'mail' to read your current job, or 'help' for commands.", 'dim'),
  line(''),
];

/** A file the player has downloaded, kept in the Files app across jobs. */
export type SavedFile = { host: string; path: string; lines: string[] };

/** A pop-up message for the toast. `id` changes every time, even for the same text. */
export type Notice = { id: number; message: string; style: LineStyle };

/** What's kept on the device between launches. */
export type Saved = {
  missionIndex: number;
  completed: string[];
  mailReadFor: number; // mission index whose mail has been read
  files: SavedFile[];
  settings: Settings;
};

export type UiState = {
  game: GameState;
  lines: OutputLine[];
  linesAdded: number; // total ever printed; the typewriter uses it to spot new lines
  files: SavedFile[];
  mailReadFor: number;
  settings: Settings;
  notice: Notice | null;
  traceFailures: number; // go up on each event, so the provider knows when to vibrate
  jobsCompleted: number;
};

export type Action =
  | { type: 'command'; input: string }
  | { type: 'tick' }
  | { type: 'crackDone'; success: boolean }
  | { type: 'load'; saved: Partial<Saved> }
  | { type: 'reset' }
  | { type: 'markMailRead' }
  | { type: 'setSettings'; settings: Settings };

export function initialUiState(data: GameData, saved: Partial<Saved> = {}): UiState {
  return {
    game: startGame(data, saved.missionIndex, saved.completed),
    lines: [...WELCOME],
    linesAdded: WELCOME.length,
    files: saved.files ?? [],
    mailReadFor: saved.mailReadFor ?? -1,
    settings: saved.settings ?? DEFAULT_SETTINGS,
    notice: null,
    traceFailures: 0,
    jobsCompleted: 0,
  };
}

export const hasUnreadMail = (s: UiState) => !isFinished(s.game) && s.mailReadFor !== s.game.missionIndex;
export const hasProgress = (s: UiState) => s.game.missionIndex > 0 || s.files.length > 0;

export function gameReducer(state: UiState, action: Action): UiState {
  switch (action.type) {
    case 'command': {
      const next = apply(state, execute(state.game, action.input));
      return parseCommand(action.input)?.name === 'mail' ? markMailRead(next) : next;
    }
    case 'tick': {
      const next = apply(state, tick(state.game));
      const caught = state.game.traceRemaining !== null && next.game.traceRemaining === null;
      if (!caught) return next;
      return {
        ...next,
        traceFailures: state.traceFailures + 1,
        notice: notice(state, 'TRACE COMPLETE: you were caught', 'error'),
      };
    }
    case 'crackDone':
      return apply(state, completeCrack(state.game, action.success));
    case 'load':
      return initialUiState(state.game.data, action.saved);
    case 'reset': // New Game: wipe progress and files, keep settings
      return initialUiState(state.game.data, { settings: state.settings });
    case 'markMailRead':
      return markMailRead(state);
    case 'setSettings':
      return { ...state, settings: action.settings };
  }
}

function markMailRead(state: UiState): UiState {
  return hasUnreadMail(state) ? { ...state, mailReadFor: state.game.missionIndex } : state;
}

const notice = (state: UiState, message: string, style: LineStyle): Notice => ({
  id: (state.notice?.id ?? 0) + 1,
  message,
  style,
});

function apply(state: UiState, result: CommandResult): UiState {
  const before = state.game;
  const after = result.state;
  let next: UiState = { ...state, game: after };

  if (result.effect === 'clearScreen' || result.lines.length > 0) {
    const kept = result.effect === 'clearScreen' ? [] : state.lines;
    next.lines = [...kept, ...result.lines].slice(-MAX_LINES);
    next.linesAdded = state.linesAdded + result.lines.length;
  }

  const file = result.downloaded;
  if (file) {
    const saved: SavedFile = { host: file.host, path: file.file.path, lines: file.file.lines };
    next.files = [...state.files.filter((f) => !(f.host === saved.host && f.path === saved.path)), saved];
  }

  // Turn state changes into toasts (the provider adds haptics and saving).
  if (before.traceRemaining === null && after.traceRemaining !== null) {
    next.notice = notice(state, `Trace detected: ${after.traceRemaining}s`, 'warning');
  } else if (after.traceRemaining === 10 && before.traceRemaining !== 10) {
    next.notice = notice(state, '10 seconds until the trace completes!', 'error');
  }
  if (after.missionIndex > before.missionIndex) {
    const upcoming = after.data.missions[after.missionIndex];
    next = {
      ...next,
      jobsCompleted: state.jobsCompleted + 1,
      notice: notice(state, upcoming ? `Job complete · new mail from ${upcoming.sender}` : 'All jobs complete!', 'success'),
    };
  }
  return next;
}
