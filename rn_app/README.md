# ROOT_ACCESS: React Native version

Expo (SDK 58) + TypeScript + Expo Router. Amber terminal theme.

## Run
```bash
npm install
npx expo start     # then press "a" to open the Android emulator
```

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
