# ROOT_ACCESS: React Native version

Expo (SDK 58) + TypeScript + Expo Router. Amber terminal theme.

## Run
```bash
npm install
npm run android    # with the Android emulator running
```

`npm run android` runs Expo in `--localhost` mode, so the emulator reaches the dev server through adb instead of your network, which Windows Firewall may block. `.npmrc` makes Node prefer IPv4 so that tunnel can connect. If Expo Go shows "Something went wrong / Failed to download remote update", you probably ran plain `npx expo start`.

## Layout
- `src/app/`: screens (file-based routing): `index` (boot), `terminal`, `inbox`
- `src/components/`: shared UI pieces
- `src/engine/`: game logic, no UI code (ported from `flutter_app/lib/engine/`)
- `src/constants/theme.ts`: colors, fonts, spacing
- `assets/missions.json`: copied from `../shared/missions.json`. Don't edit it here; run `node scripts/sync-missions.mjs` from the repo root

## Checks
```bash
npm run typecheck
npm run lint
```
