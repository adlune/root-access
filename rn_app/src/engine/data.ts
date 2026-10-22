// The game content, bundled with the app (copied from shared/missions.json).
// JSON imports are typed loosely (e.g. objective.type is just `string`), so we
// assert the real shape here; scripts/sync-missions.mjs validates the file.

import raw from '../../assets/missions.json';
import type { GameData } from './types';

export const gameData = raw as unknown as GameData;
