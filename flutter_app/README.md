# ROOT_ACCESS: Flutter version

Flutter + Dart. Green terminal theme.

## Run
```bash
flutter pub get
flutter run        # with the Android emulator running
```

## Layout
- `lib/main.dart`: app entry point
- `lib/theme.dart`: colors and the terminal theme
- `lib/screens/`: `boot_screen`, `terminal_screen`, `inbox_screen`
- `lib/widgets/`: reusable UI pieces (terminal output, trace bar, minigame), added from Day 5
- `lib/engine/`: game logic, no UI code (`models.dart` for now)
- `assets/missions.json`: copied from `../shared/missions.json`. Don't edit it here; run `node scripts/sync-missions.mjs` from the repo root

## Checks
```bash
flutter analyze
flutter test
```
