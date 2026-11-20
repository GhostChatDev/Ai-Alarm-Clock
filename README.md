# Ghost Mascot — native iPhone & iPad app

A living ghost companion for your nights. Native SwiftUI for **iOS 17+**, with a
synchronized live wallpaper, wake-up reminders, sleep sounds and a cute
Nightstand Saving Mode.

**Made by Agent.Ghost Coded**
**Total Cost 10$**
**ghostchat.tech via Ghost Code**

## The design

Four tabs at the bottom: **Home · Wake · Nightstand · Settings**. Every screen
sits on the same dark lavender live wallpaper.

### Live wallpaper (`GhostTheme.GhostAurora`)
- One `TimelineView` clock moves everything together: a lavender glow drifting
  in the top corner, a pink/teal glow drifting in the bottom corner, and 14
  twinkling sparkles floating across the screen.
- Turns still when iOS **Reduce Motion** is on.

### Home (`HomeView` + `GhostCompanionHero`)
- **Ghost hero first:** a big floating ghost (size 170) with a breathing glow,
  a tilted orbit ring and 9 stars/sparkles circling it.
  Caption: "YOUR LITTLE NIGHT COMPANION" / "A little magic. Just for you."
- **Say hello** button: the ghost wakes up, grows a little, the text changes to
  "Hey, you. I'm right here." and it speaks with on-device text-to-speech.
- Tap the ghost itself for a sparkle burst. It floats, sways, waves and blinks.
- Below the ghost, under **Sleep & wake**:
  - **Wake-Up Alarm** card: on/off switch, big next-alarm time, label, repeat
    pill, **Set Alarm** (edit) and **Turn Off / Turn On**, or
    **Create your first alarm** when there is none.
  - **Nightstand Saving Mode** card (opens the Nightstand tab).
  - **Tonight** weather card (sample text, no live weather service).
  - **Sleep Music**: 15 / 30 / 60 min timer and four generated loops with
    play / pause.

### Wake (`WakeTabView`)
- Big live clock and date, **I'm Awake** (stops music, cancels snooze, says
  good morning) and **Snooze · 5 min** (schedules a notification and shows a
  banner).

### Nightstand Saving Mode (`NightstandModeView`)
- OLED-black bedside screen with a dimmed live wallpaper, a large glowing
  clock, the next alarm and the date.
- A sleeping ghost (size 180) with drifting "z z z" and floating dream bubbles.
- Tap anywhere to dim / brighten; controls hide again after 4 seconds.
- **Keep Awake** switch (`isIdleTimerDisabled`) and a dream-bubbles switch.
- **iOS limit:** apps cannot draw on the real Lock Screen (no public API). This
  is an in-app always-on mode: turn on Keep Awake and leave the app open,
  ideally charging in landscape.

### Settings (`SettingsTabView`)
- Import sleep audio and a notification tone from Files, sleep volume, pick an
  installed speech voice and test it, optional remote AI key, and the credits.

## Storage
- Alarms and daily state: JSON file in Application Support.
- Checklist and preferences: UserDefaults / `@AppStorage`.
- Goals: SwiftData (`MorningGoalRecord`).
- Imported audio: app sandbox. API key: iOS Keychain (or `GHOST_AI_API_KEY`
  / gitignored `Secrets.plist`). No key is ever in source.

## Files
- `GhostTheme.swift` — colors, live wallpaper, cards, buttons, `GhostMascot`.
- `ReadyByEight/GhostCompanionHero.swift` — Home ghost hero.
- `ReadyByEight/RootView.swift` — tab bar, Home, Wake.
- `ReadyByEight/NightstandModeView.swift` — Nightstand Saving Mode.
- `ReadyByEight/ReadyByEightApp.swift` — app entry, Settings, alarm editor.
- `ReadyByEight/AppStore.swift` — `@Observable` store and `GhostDevice`
  (audio, speech, notifications).
- `ReadyByEight/AlarmModels.swift` — alarm, repeat and saved-state logic.
- `project.yml` — XcodeGen project, shared `ReadyByEight` scheme, iOS 17.
- `.github/workflows/ios.yml` — logic tests + iOS Simulator build.

**Swift Playgrounds:** copy all the Swift files above into your app,
including `GhostCompanionHero.swift`, or you get "Cannot find ... in scope".

## Build
```sh
brew install xcodegen
xcodegen generate
open ReadyByEight.xcodeproj
```
Pick an iPhone or iPad simulator and press Run (⌘R).

## Four release checks
1. **Build passes:** GitHub Actions `iOS Simulator Build` runs the SwiftPM logic
   tests and an XcodeGen `generic/platform=iOS Simulator` build.
2. **Buttons work:** every control is wired to the store or local state; taps
   are checked by hand in the Simulator / Playgrounds (no automated UI test yet).
3. **Data survives a refresh:** alarms, checklist, goals, imported audio and
   preferences persist across relaunch.
4. **README isn't lying:** this file is updated in the same change as the code.

## Credits
Made by Agent.Ghost Coded · Total Cost 10$ · ghostchat.tech via Ghost Code
