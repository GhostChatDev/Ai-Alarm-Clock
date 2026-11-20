# Ghost Mascot — native iPhone & iPad app

Native SwiftUI for iOS 17+, with synchronized live-wallpaper animation and Nightstand Saving Mode.

**Made by Agent.Ghost Coded**
**Total Cost 10$**
**ghostchat.tech via Ghost Code**

Ghost Mascot is a living, breathing ghost companion with notification-based
wake-up reminders, generated sleep audio, on-device text-to-speech, and a
**Nightstand / Lock-Screen Saving Mode** — a cute OLED bedside clock with a
sleeping ghost, floating dream bubbles, and drifting "z Z z". Requires **iOS 17+**.
The interface uses SwiftUI, `@Observable` stores, and SwiftData morning goals.

## What is implemented

- **Live wallpaper:** a single shared clock (`TimelineView`) drives the aurora
  ribbons, twinkling stars, floating spirit orbs, mascot breathing/sway, and the
  breathing glow on cards — everything moves in sync.
- **Home:** create/edit alarms, toggle reminders, open the wake screen, play/stop
  four generated audio loops, select a 15/30/60-minute sleep timer, and a hero
  card with a synced pulse.
- **Wake:** five-minute notification snooze and an "I'm Awake" action that
  completes the daily challenge.
- **Nightstand (Lock-Screen Saving Mode):** dim OLED clock, sleeping ghost,
  floating dream bubbles, a keep-awake toggle (`isIdleTimerDisabled`), and
  tap-to-dim. iOS cannot draw over the real Lock Screen (no public API), so this
  is an in-app always-on bedside mode: enable Keep Awake and leave it open.
- **Settings:** import sleep audio and a notification tone from Files, adjust
  playback volume, select an installed speech voice, and configure a remote API.
- **Storage:** alarms, chat and daily challenge state use a JSON file; checklist
  and preferences use UserDefaults; goals use SwiftData; imported audio remains
  in the app sandbox; API keys stay in the Keychain.

## Four release checks

1. **Build passes:** GitHub Actions `iOS Simulator Build` runs the SwiftPM logic
   tests and an XcodeGen `generic/platform=iOS Simulator` build.
2. **Buttons work:** every control is wired to the `@Observable` store or a local
   state action; interactive taps are verified in the Simulator / Playgrounds.
3. **Data survives a refresh:** alarms, checklist, goals, imported audio and
   preferences persist across relaunch (JSON + UserDefaults + SwiftData + Keychain).
4. **README isn't lying:** this file is updated in the same change as the code.

## Credits

Made by Agent.Ghost Coded · Total Cost 10$ · ghostchat.tech via Ghost Code
