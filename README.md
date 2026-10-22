# ROOT_ACCESS

A Hacknet-lite terminal hacking game for Android, built twice: once in **Flutter** and once in **React Native**, so the two frameworks can be compared.

You play a rookie hacker at a terminal. You scan a fictional network, connect to machines, read files, crack ports and complete missions from your inbox. Everything is simulated: the app never makes real network requests.

## Repository layout
| Path | What |
|---|---|
| `flutter_app/` | Flutter version (Dart), green theme |
| `rn_app/` | React Native version (Expo + TypeScript), amber theme |
| `shared/missions.json` | All game content. **Edit missions here only.** |
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
npx expo start
```
Then press `a` in the Expo terminal to open the app on the emulator.

After editing missions:
```bash
node scripts/sync-missions.mjs
```

## License
[MIT](LICENSE) © 2026 Adrian Lara
