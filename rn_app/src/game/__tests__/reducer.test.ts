import { describe, expect, test } from '@jest/globals';

import { gameData } from '../../engine/data';
import {
  type Action,
  type UiState,
  WELCOME,
  gameReducer,
  hasProgress,
  hasUnreadMail,
  initialUiState,
} from '../reducer';

const play = (state: UiState, ...actions: Action[]) => actions.reduce(gameReducer, state);
const command = (input: string): Action => ({ type: 'command', input });
const texts = (state: UiState) => state.lines.map((l) => l.text).join('\n');

describe('gameReducer', () => {
  test('starts with the welcome message', () => {
    expect(initialUiState(gameData).lines).toEqual(WELCOME);
  });

  test('commands append their output to the scrollback', () => {
    const s = play(initialUiState(gameData), command('scan'));
    expect(texts(s)).toContain('rookie@localhost:~$ scan');
    expect(texts(s)).toContain('practice-srv');
  });

  test('clear empties the scrollback', () => {
    const s = play(initialUiState(gameData), command('scan'), command('clear'));
    expect(s.lines).toEqual([]);
  });

  test('scrollback is capped at 500 lines', () => {
    const s = play(initialUiState(gameData), ...Array.from({ length: 30 }, () => command('help')));
    expect(s.lines.length).toBe(500);
  });

  test('crackDone passes the minigame result to the engine', () => {
    const s = play(initialUiState(gameData, { missionIndex: 1, completed: [] }),
      command('connect 10.0.2.44'), command('crack 21'), { type: 'crackDone', success: true });
    expect(texts(s)).toContain('Port 21 cracked');
    expect(s.game.crackPort).toBeNull();
  });

  test('a trace running out counts as a failure; disconnecting does not', () => {
    let s = play(initialUiState(gameData, { missionIndex: 1, completed: [] }), command('connect 10.0.2.10'));
    s = play(s, ...Array.from({ length: 44 }, (): Action => ({ type: 'tick' })), command('disconnect'));
    expect(s.traceFailures).toBe(0); // left with 1 second to spare

    s = play(s, command('connect 10.0.2.10'), ...Array.from({ length: 45 }, (): Action => ({ type: 'tick' })));
    expect(s.traceFailures).toBe(1);
    expect(texts(s)).toContain('TRACE COMPLETE');
  });

  test('downloaded files are kept after the job ends', () => {
    const s = play(initialUiState(gameData), command('connect 10.0.0.5'), command('cd home'),
      command('download readme.txt'), command('download readme.txt'), command('download welcome.txt'));
    expect(s.game.missionIndex).toBe(1);
    expect(s.files.map((f) => f.path)).toEqual(['/home/readme.txt', '/home/welcome.txt']); // no duplicates
    expect(s.files[1]).toMatchObject({ host: 'practice-srv', lines: ['Nice work. Tutorial complete.', expect.any(String)] });
  });

  test('mail is unread until you open it or type mail, and comes back for each new job', () => {
    let s = initialUiState(gameData);
    expect(hasUnreadMail(s)).toBe(true);
    s = play(s, command('mail'));
    expect(hasUnreadMail(s)).toBe(false);
    s = play(s, command('connect 10.0.0.5'), command('download /home/welcome.txt'));
    expect(hasUnreadMail(s)).toBe(true); // job 2's mail
    s = play(s, { type: 'markMailRead' });
    expect(hasUnreadMail(s)).toBe(false);
  });

  test('notices announce traces and finished jobs', () => {
    let s = play(initialUiState(gameData, { missionIndex: 1 }), command('connect 10.0.2.10'));
    expect(s.notice).toMatchObject({ message: 'Trace detected: 45s', style: 'warning' });
    const firstId = s.notice!.id;

    s = play(s, ...Array.from({ length: 35 }, (): Action => ({ type: 'tick' })));
    expect(s.notice).toMatchObject({ message: '10 seconds until the trace completes!', id: firstId + 1 });

    s = play(initialUiState(gameData), command('connect 10.0.0.5'), command('download /home/welcome.txt'));
    expect(s.notice?.message).toBe('Job complete · new mail from bit@entropy.net');
    expect(s.jobsCompleted).toBe(1);
  });

  test('new game wipes progress and files but keeps settings', () => {
    const settings = { textSpeed: 'classic', haptics: false } as const;
    const s = play(initialUiState(gameData, { missionIndex: 2, files: [{ host: 'h', path: '/p', lines: [] }], settings }),
      { type: 'reset' });
    expect(s.game.missionIndex).toBe(0);
    expect(s.files).toEqual([]);
    expect(s.settings).toEqual(settings);
    expect(hasProgress(s)).toBe(false);
  });

  test('load resumes saved progress and reset starts over', () => {
    const loaded = play(initialUiState(gameData), { type: 'load', saved: { missionIndex: 2, completed: ['a', 'b'] } });
    expect(loaded.game.missionIndex).toBe(2);
    expect(loaded.game.completed).toEqual(['a', 'b']);

    const reset = play(loaded, { type: 'reset' });
    expect(reset.game.missionIndex).toBe(0);
    expect(reset.lines).toEqual(WELCOME);
  });
});
