// Saved data on the device (AsyncStorage; Flutter uses shared_preferences).

import AsyncStorage from '@react-native-async-storage/async-storage';

import type { Saved, SavedFile } from './reducer';
import { DEFAULT_SETTINGS, type Settings } from './settings';

const KEYS = {
  missionIndex: 'missionIndex',
  completed: 'completed',
  mailReadFor: 'mailReadFor',
  files: 'files',
  settings: 'settings',
} as const;

const json = <T>(value: string | null): T | undefined => (value === null ? undefined : (JSON.parse(value) as T));

export async function loadSaved(): Promise<Partial<Saved>> {
  const values = Object.fromEntries(
    await AsyncStorage.multiGet(Object.values(KEYS)),
  ) as Record<string, string | null>;
  return {
    missionIndex: json<number>(values[KEYS.missionIndex]),
    completed: json<string[]>(values[KEYS.completed]),
    mailReadFor: json<number>(values[KEYS.mailReadFor]),
    files: json<SavedFile[]>(values[KEYS.files]),
    settings: { ...DEFAULT_SETTINGS, ...json<Partial<Settings>>(values[KEYS.settings]) },
  };
}

export async function save(saved: Saved): Promise<void> {
  await AsyncStorage.multiSet([
    [KEYS.missionIndex, JSON.stringify(saved.missionIndex)],
    [KEYS.completed, JSON.stringify(saved.completed)],
    [KEYS.mailReadFor, JSON.stringify(saved.mailReadFor)],
    [KEYS.files, JSON.stringify(saved.files)],
    [KEYS.settings, JSON.stringify(saved.settings)],
  ]);
}
