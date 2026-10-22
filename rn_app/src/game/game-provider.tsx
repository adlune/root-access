// Shares the game with every screen through React Context, and handles the
// side effects the pure reducer can't: loading/saving, the trace timer and haptics.

import * as Haptics from 'expo-haptics';
import { type ReactNode, createContext, use, useCallback, useEffect, useMemo, useReducer, useRef, useState } from 'react';

import { prompt } from '@/engine/commands';
import { gameData } from '@/engine/data';

import { type Action, type UiState, gameReducer, hasProgress, hasUnreadMail, initialUiState } from './reducer';
import type { Settings } from './settings';
import { loadSaved, save } from './storage';

type GameContextValue = UiState & {
  ready: boolean; // false until saved data has been read
  prompt: string;
  unreadMail: boolean;
  progress: boolean; // anything worth continuing?
  dispatch: (action: Action) => void;
  submit: (input: string) => void;
  finishCrack: (success: boolean) => void;
  markMailRead: () => void;
  setSettings: (settings: Settings) => void;
  newGame: () => void;
  bootShown: boolean; // the boot sequence plays once per launch
  markBootShown: () => void;
};

const GameContext = createContext<GameContextValue | null>(null);

export function GameProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(gameReducer, gameData, (data) => initialUiState(data));
  const [ready, setReady] = useState(false);
  const [bootShown, setBootShown] = useState(false);
  const { game, files, mailReadFor, settings } = state;

  // Load saved data once.
  useEffect(() => {
    loadSaved()
      .then((saved) => dispatch({ type: 'load', saved }))
      .finally(() => setReady(true));
  }, []);

  // Save whenever something worth keeping changes.
  useEffect(() => {
    if (!ready) return;
    save({ missionIndex: game.missionIndex, completed: [...game.completed], mailReadFor, files, settings });
  }, [ready, game.missionIndex, game.completed, mailReadFor, files, settings]);

  // Trace timer: tick once a second while a trace is running.
  const tracing = game.traceRemaining !== null;
  useEffect(() => {
    if (!tracing) return;
    const timer = setInterval(() => dispatch({ type: 'tick' }), 1000);
    return () => clearInterval(timer);
  }, [tracing]);

  // Haptics: buzz on a finished job, vibrate hard when a trace catches you.
  const hapticsOn = useRef(settings.haptics);
  useEffect(() => {
    hapticsOn.current = settings.haptics;
  }, [settings.haptics]);
  useEffect(() => {
    if (state.jobsCompleted > 0 && hapticsOn.current) Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  }, [state.jobsCompleted]);
  useEffect(() => {
    if (state.traceFailures > 0 && hapticsOn.current) Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
  }, [state.traceFailures]);

  const submit = useCallback((input: string) => dispatch({ type: 'command', input }), []);
  const finishCrack = useCallback((success: boolean) => dispatch({ type: 'crackDone', success }), []);
  const markMailRead = useCallback(() => dispatch({ type: 'markMailRead' }), []);
  const setSettings = useCallback((s: Settings) => dispatch({ type: 'setSettings', settings: s }), []);
  const newGame = useCallback(() => dispatch({ type: 'reset' }), []);
  const markBootShown = useCallback(() => setBootShown(true), []);

  const value = useMemo<GameContextValue>(
    () => ({
      ...state,
      ready,
      prompt: prompt(state.game),
      unreadMail: hasUnreadMail(state),
      progress: hasProgress(state),
      dispatch,
      submit,
      finishCrack,
      markMailRead,
      setSettings,
      newGame,
      bootShown,
      markBootShown,
    }),
    [state, ready, submit, finishCrack, markMailRead, setSettings, newGame, bootShown, markBootShown],
  );
  return <GameContext value={value}>{children}</GameContext>;
}

export function useGame(): GameContextValue {
  const value = use(GameContext);
  if (value === null) throw new Error('useGame must be used inside <GameProvider>');
  return value;
}
