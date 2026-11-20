# Ghost Coach — native iPhone & iPad app

**Made by Agent.Ghost Coded**  
**Total Cost 10$**  
**ghostchat.tech via Ghost Code**

Ghost Coach combines notification-based wake-up reminders, generated sleep audio,
on-device text-to-speech, and an optional AI morning coach. Requires **iOS 17+**.
The interface uses SwiftUI, `@Observable` stores, and SwiftData morning goals.

## What is implemented

- **Home:** create/edit alarms, toggle reminders, open the wake screen, play/stop
  four generated audio loops, and select a 15/30/60-minute sleep timer.
- **Wake:** five-minute notification snooze and an awake action that completes
  the daily challenge and opens the coach.
- **Coach:** chat, quick suggestions, spoken replies, daily checklist, and
  SwiftData goals created from typed messages.
- **Settings:** import sleep audio and a notification tone from Files, adjust
  playback volume, select an installed speech voice, and configure a remote API.
- **Storage:** alarms, chat and daily challenge state use a JSON file; checklist
  and selected preferences use UserDefaults; goals use SwiftData; imported audio
  remains in the app sandbox; API keys entered in Settings use Keychain.

### Important limitations

- Reminders use `UNUserNotificationCenter`, not Apple's Clock alarm system.
  Notification permission and device settings determine whether sound is heard.
  They do not guarantee bypassing Silent Mode or Focus. Keep a Clock backup alarm.
- Imported alarm tones must be no longer than 29 seconds. Choose an audio file
  accessible through Files; this is not an Apple Music/DRM library integration.
  Changing the tone does not automatically reschedule existing reminders: save
  or re-enable the reminder after importing a new tone.
- Built-in audio is generated PCM loops named **Moonlight piano**, **Gentle rain**,
  **Ocean breathing**, and **Cosmic drift**; these are not recorded music tracks.
- Weather cards contain **demo forecasts**, not live weather or location data.
- The microphone-shaped coach button **reads a reply aloud**. It does not record
  speech. Use the system keyboard's dictation feature to dictate a message.
- Remote AI needs an OpenAI-compatible chat-completions endpoint, model, and key.
  Without it, the coach uses offline rules or Apple Foundation Models when the
  OS, hardware, SDK and model availability support them. Chat cannot edit alarms.
- Playback volume resets on launch. A running sleep timer is not restored after
  the app is terminated. Alarm and chat persistence does not imply playback resumes.

## Build on a Mac with Xcode

Install Xcode with iOS Simulator support and XcodeGen. Then run:

```sh
brew install xcodegen
xcodegen generate --spec project.yml
open ReadyByEight.xcodeproj
```

Select the shared **ReadyByEight** scheme, choose an iPhone or iPad simulator,
and press **⌘R**. For a physical device, choose your signing team in Xcode.
The generated project disables signing for CI; enable signing for device use.
Always regenerate the project after pulling source/configuration changes.

### Swift Playgrounds scope fix

`ReadyByEight/AppStore.swift` includes both `AppStore` and `GhostDevice` so the
views can resolve the device services. Keep it with `AlarmModels.swift`,
`RootView.swift`, `ReadyByEightApp.swift`, `CoachView.swift`, and root
`GhostTheme.swift` in the app target. **Do not also add root `AppStore.swift`**:
it is an excluded legacy copy with overlapping types and the same filename.
Do not copy it to `DeviceServices.swift`. The XcodeGen spec selects the right files.

## Private API configuration

Prefer entering keys in Settings (Keychain). Development fallback reads
`GHOST_AI_API_KEY` from the process environment or `GHOST_AI_API_KEY` / `API_KEY`
from `Secrets.plist` in the app bundle. The plist is optional and not bundled by
this project spec. `.gitignore` excludes secret files; it cannot protect a key
that was already committed. Never distribute a bundled production API secret.
No microphone or location permissions are requested by the current app.

## Verification and release rule

`.github/workflows/ios.yml` runs SwiftPM logic tests and builds the shared scheme
on a macOS runner for a generic iOS Simulator, without code signing. A final
`[ui-test]` commit also runs simulator interaction and relaunch tests.
No iOS build is attempted in the Linux sandbox.

**Done requires all four checks, with evidence:**

1. **Build passes:** GitHub simulator build and logic checks pass.
2. **Buttons work:** interaction tests pass; test device audio/imports on hardware.
3. **Data survives relaunch:** persisted alarm and checklist tests pass; verify
   imported files, speech preferences, and Keychain on a physical device.
4. **README matches what shipped:** update features, limitations, setup and credits
   in the same change as the implementation. A build alone proves neither UI nor audio.
