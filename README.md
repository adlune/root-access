# ROOT_ACCESS

A terminal hacking game for Android, built twice: once in **Flutter** and once in **React Native**, so the two frameworks can be compared.

You play a rookie hacker at a terminal. You scan a fictional network, connect to machines, read files, crack ports and complete missions from your inbox. Everything is simulated.

## Repository layout
| Path | What |
|---|---|
| `flutter_app/` | Flutter version (Dart), black & white theme |
| `rn_app/` | React Native version (Expo + TypeScript), black & white theme |
| `shared/missions.json` | All game content. |
| `scripts/sync-missions.mjs` | Copies `shared/missions.json` into both apps |

## Prerequisites
- Flutter SDK (`flutter doctor` all green for Android)
- Node.js LTS
- Android Studio with the `Pixel_8` emulator

## Run
Start the emulator first: Android Studio → Device Manager → ▶ on Pixel_8.

Flutter:
```bash
cd flutter_app
flutter run
```

React Native:
```bash
cd rn_app
npm install
npm run android
```
This starts the Expo dev server and opens the app in Expo Go on the emulator. It runs in localhost mode over adb, so Windows Firewall can't block it.

After editing missions:
```bash
node scripts/sync-missions.mjs
```

## License
This project is licensed under [MIT](LICENSE)
