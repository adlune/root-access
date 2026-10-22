# ROOT_ACCESS: React Native version

Expo (SDK 58) + TypeScript + Expo Router. Black & white terminal theme; color only for errors, success and warnings.

## Run
```bash
npm install
npm run android    # with the Android emulator running
```

`npm run android` runs Expo in `--localhost` mode, so the emulator reaches the dev server through adb instead of your network, which Windows Firewall may block. `.npmrc` makes Node prefer IPv4 so that tunnel can connect. If Expo Go shows "Something went wrong / Failed to download remote update", you probably ran plain `npx expo start`.

## Layout
- `src/app/`: screens (file-based routing): `index` (boot sequence + main menu), `desktop` (ROOT/OS home), and the apps: `terminal`, `inbox` (Mail), `files`, `settings`
- `src/game/`: the bridge between engine and screens
  - `reducer.ts`: pure `useReducer` reducer (engine state, scrollback, files, unread mail, settings, notices)
  - `game-provider.tsx`: React Context; trace timer, saving (AsyncStorage) and haptics
  - `typewriter.ts`: the terminal's typing effect as a pure function
  - `settings.ts`, `storage.ts`, `crack-code.ts` (rules of the code-guess crack minigame)
- `src/components/`: terminal output, trace bar, quick commands, prompt, crack minigame, status bar, app header, notice toast
- `src/engine/`: game logic, no UI code, ported file by file from `flutter_app/lib/engine/`
  - `commands.ts`: the engine's API: `execute`, `tick`, `completeCrack`, `prompt`
  - `gameState.ts`: the immutable `GameState` (plain object, ready for `useReducer`), output lines, effects
  - `types.ts`: the shape of `missions.json`; `data.ts` loads it
  - `parser.ts`, `paths.ts`: command parsing and the fake file system
  - `__tests__/engine.test.ts`: the same test cases as the Flutter engine
- `src/constants/theme.ts`: colors, fonts, spacing
- `assets/missions.json`: copied from `../shared/missions.json`. Don't edit it here; run `node scripts/sync-missions.mjs` from the repo root

## Checks
```bash
npm test
npm run typecheck
npm run lint
```
