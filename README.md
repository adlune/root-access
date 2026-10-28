# ROOT_ACCESS

A terminal hacking game for Android, built once in **Flutter** and once in **React Native**.

## Repository layout
| Path | What |
|---|---|
| `flutter_app/` | Flutter version (Dart) |
| `rn_app/` | React Native version (Expo + TypeScript) |
| `shared/missions.json` | All game content |
| `scripts/sync-missions.mjs` | Copies `shared/missions.json` into both apps |

## Prerequisites
- Flutter SDK
- Node.js LTS
- Android Studio with the Pixel_8 emulator

## Run
Start the emulator.

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

## Flutter vs React Native

Both apps are the same game. They share missions. The engine was written in Dart and then ported to TypeScript file by file, and both test suites play all three missions. So the differences below come from the frameworks, not from the game.

| | Flutter | React Native (Expo) |
|---|---|---|
| Language | Dart 3 | TypeScript 6 |
| How the UI is drawn | Flutter's own engine paints every pixel | React components become native Android views |
| State | One `ChangeNotifier` + `ListenableBuilder` | `useReducer` (pure reducer) + React Context |
| Navigation | `Navigator` push/pop | `expo-router` (one file per screen) |
| Saving | `shared_preferences` | `AsyncStorage` |
| Crack minigame | Tap timing | Code guess (higher/lower PIN) |
| Tests | 40: engine unit tests + widget tests that drive real screens | 43 Jest tests: engine, reducer, typewriter and minigame rules as pure functions |

### Size of the code

| | Flutter | React Native |
|---|---|---|
| Game engine | 578 | 462 |
| State layer (controller / reducer, settings, storage) | 199 | 306 |
| UI (screens, widgets, theme) | 1,354 | 1,193 |
| Tests | 482 | 369 |

- **Engine:** TypeScript is about 20% shorter, because `missions.json` only needs type declarations, while Dart needs `fromJson` parsing code (about 190 lines), and because immutable updates are `{ ...state, cwd: '/' }` instead of a hand-written `copyWith`.
- **State layer:** React Native's is bigger, because more logic lives in the pure reducer, including the typewriter as its own testable function. In Flutter that logic sits inside widgets.
- **UI:** roughly the same size in both. Flutter nests layout widgets (`Padding`, `Column`, `Expanded`); React Native uses flexbox styles in `StyleSheet` objects, similar to CSS.

### Building and running (Windows 11, Android emulator)
| | Flutter | React Native (Expo) |
|---|---|---|
| Setup | Flutter SDK + Android Studio, command-line tools, licenses | Node.js; Android Studio only for the emulator |
| First debug build | ~5 min (Gradle; had to install NDK 28.2 by hand) | None: Expo Go runs the JavaScript |
| Day-to-day reload | Hot reload; full reinstall when native config changes | First bundle ~17 s, then ~2 s |
| First frame, debug build | ~10–20 s on the emulator | n/a (runs in Expo Go) |
| Release build | `flutter build apk --release`: **4 min** | `expo prebuild` + Gradle compiles React Native's C++ for every CPU type: **~25 min, then failed** (see below) |
| Release size | **48.2 MB** universal APK (arm64, armv7, x86_64); debug APK is 143 MB | JavaScript bundle: **2.54 MB** of Hermes bytecode; full APK not measured |
| Cold start, release | **0.44 s** median to first frame (5 runs) | not measured |

### Language: Dart vs TypeScript
- **Data from JSON:** Dart parses it into classes, which is safe at runtime but verbose. TypeScript just declares the shape and trusts the file (`sync-missions.mjs` validates it instead).
- **"One of several kinds":** Dart has `sealed class` + exhaustive `switch`; TypeScript has discriminated unions (`objective.type === 'report'`). Both catch a missing case at compile time.
- **Gotchas:**
  - `parseInt('21abc')` is `21` in JavaScript, while Dart's `int.tryParse` returns `null`, so `crack 21abc` needed a stricter check in TypeScript.
  - TypeScript 6 no longer loads `@types/jest` automatically.
  - React Native 0.88 renamed some types (`TextInputInstance`).
- **Porting:** the port was mostly mechanical. The same 24 engine test cases passed on the first run.

### Building the UI
- **Flutter:** everything is a widget, even padding. Overlays such as the minigame are just a `Stack` child shown when needed. Widget tests can type into text fields and fast-forward time (`tester.pump(Duration)`), which made the trace timer, typewriter and minigame easy to test, including a bot that plays the tap-timing game.
- **React Native:** feels like web React. React's lint rules (React Compiler) were strict and useful: no `setState` inside effects, no reading refs during render. That pushed logic into pure functions, which made it easy to test without rendering screens.
- **Layout surprises:**
  - **React Native:** a horizontal `ScrollView` stretches to fill the screen unless you set `flexGrow: 0`.
  - **Flutter:** buttons fire when the finger *lifts*, about 100 ms late, which made the timing minigame unfair until it listened for the finger going down.

### Problems during development
| Flutter | React Native |
|---|---|
| Android command-line tools missing at first; NDK auto-install failed | Expo Go couldn't reach the dev server over Wi-Fi (firewall); fixed with `--localhost` |
| Default white launch screen (changed to black) | Metro listened only on IPv6, so the adb tunnel failed; fixed with an `.npmrc` setting |
| Keyboard popped over the minigame (focus order bug) | Release build blocked by Windows' 260-character path limit |

### Takeaways
- **Flutter:** smoother to ship. The release build was quick and painless, the app starts in under half a second, and its built-in widget testing is excellent. The cost is more code for data handling, and a first native build before you see anything.
- **React Native with Expo:** faster to start with. No native build for everyday development, a smaller engine, and TypeScript's lighter types. The cost appears when you need a real native build. On Windows that was the hardest part of the whole project.
- **Both:** keeping the game logic as a pure, UI-free engine with the same tests in both apps made the second version much faster to build than the first. That design choice mattered more than the choice of framework.

## License
This project is licensed under [MIT](LICENSE)
