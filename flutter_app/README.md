# ROOT_ACCESS: Flutter version

Flutter + Dart. Black & white terminal theme; color only for errors, success and warnings.

## Run
```bash
flutter pub get
flutter run        # with the Android emulator running
```

## Layout
- `lib/main.dart`: app entry point; loads missions and saved data before showing the UI
- `lib/game_controller.dart`: `ChangeNotifier` between the engine and the screens (scrollback, files, unread mail, notices, haptics, trace timer, saving with `shared_preferences`)
- `lib/settings.dart`: text speed and haptics settings
- `lib/theme.dart`: colors and the terminal theme
- `lib/screens/`: `main_menu_screen` (boot sequence + menu), `desktop_screen` (ROOT/OS home), and the apps: `terminal_screen`, `inbox_screen` (Mail), `files_screen`, `settings_screen`
- `lib/widgets/`: `terminal_output` (typewriter), `trace_bar`, `quick_commands`, `crack_minigame` (tap-timing), `status_bar`, `app_header`, `notice_overlay` (toasts)
- `lib/engine/`: game logic, no UI code (the React Native version ports it file by file)
  - `commands.dart`: the engine's API: `execute`, `tick`, `completeCrack`, `prompt`
  - `game_state.dart`: immutable `GameState`, output lines, effects
  - `models.dart`: classes for `missions.json`
  - `parser.dart`, `paths.dart`: command parsing and the fake file system
- `assets/missions.json`: copied from `../shared/missions.json`. Don't edit it here; run `node scripts/sync-missions.mjs` from the repo root

## Checks
```bash
flutter analyze
flutter test
```
