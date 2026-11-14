# Ready by Eight

A minimalist iPhone clock with a private, encouraging morning chatbot named **Eight**. Built with SwiftUI and Swift 6.

> **This version schedules notification reminders, not system alarms.** Notifications cannot continuously ring, bypass silent mode or Focus, or guarantee that you wake up. Set a backup alarm in Apple Clock.

## Implemented

- Dark clock dashboard with a live time display and next-reminder summary.
- Create, edit, enable, disable, and delete up to eight reminders.
- Repeat once, daily, on weekdays, or on weekends.
- Local notifications with the system notification sound.
- A small morning challenge with a daily completion marker.
- Chat interface with quick prompts, selectable messages, and conversation clearing.
- Optional on-device generative coaching using Apple's Foundation Models framework when available.
- Clearly labeled, built-in guided responses when the on-device model is unavailable or fails.
- Local JSON storage for reminders, recent conversation, and today's challenge completion.
- Plain Swift regression tests for scheduling, persistence, and guided coaching.

Eight offers suggestions, not medical advice. Chat cannot create or change reminders; use the Clock tab.

## Requirements

- **Xcode 26 or later** for the iOS 26 SDK and optional Foundation Models integration.
- **Swift 6**, **iOS 17 or later** deployment target.
- Generative chat requires **iOS 26 or later**, a compatible Apple Intelligence device, Apple Intelligence enabled, and its model downloaded and available. Device, language, and regional availability can vary.
- Other devices use built-in guided replies, not a remote language model.
- No account, API key, server, or third-party dependency required.

## Open and run

1. Clone this repository and open `ReadyByEight.xcodeproj` in Xcode.
2. Select the **ReadyByEight** scheme.
3. For a physical device, select the **ReadyByEight** target → **Signing & Capabilities**, choose your development team, and change the bundle identifier to a unique value.
4. Select an iPhone simulator or connected iPhone in the run destination menu.
5. Choose **Product → Run** (`⌘R`).
6. On the Clock tab, tap **+**, choose a time and repeat pattern, and save. Allow notifications when prompted.
7. Open the **Eight** tab and send a message. The header identifies whether on-device AI or guided responses are active.

Use a physical iPhone to assess notification sound and Apple Intelligence behavior. Simulator behavior is not a substitute for these checks.

### Permissions and capabilities

The app requests notification authorization when an enabled reminder is saved. If denied, use the dashboard's **Open notification settings** button to enable it in Settings.

No notification usage-description Info.plist key, push-notification entitlement, background-audio mode, or special capability is required for these local notifications. Xcode generates the app's Info.plist from project settings. No microphone, location, calendar, or contacts permission is requested.

## Repository structure

```text
ReadyByEight.xcodeproj/
└── project.pbxproj             # iOS app target and build settings
ReadyByEight/
├── ReadyByEightApp.swift       # App entry, clock dashboard, reminder editor
├── AlarmModels.swift           # Scheduling models, saved state, guided coach
├── AppStore.swift              # Persistence, notifications, optional AI orchestration
└── CoachView.swift             # Chat screen and shared visual styling
Tests/
└── main.swift                  # Standalone Foundation-only regression checks
```

## Run the logic tests

From the repository root on a machine with Swift 6 installed:

```sh
swiftc ReadyByEight/AlarmModels.swift Tests/main.swift -o /tmp/ready-by-eight-tests
/tmp/ready-by-eight-tests
```

Expected output:

```text
PASS: 25 scheduling, DST, persistence and coach checks
```

The tests cover future and expired reminders, weekday/weekend selection, daylight-saving gaps and overlaps, stable notification identifiers, JSON round trips, daily completion keys, and guided response behavior. They do not compile SwiftUI or test actual notification delivery or Foundation Models.

## Manual acceptance checks in Xcode

- Build and launch on an iOS 17+ destination; verify the guided chat fallback.
- Create a reminder a few minutes ahead, background the app, and verify delivery with notifications enabled and silent mode/Focus disabled.
- Edit, toggle, and delete reminders; verify pending requests match the saved configuration.
- Deny notification authorization and verify the app explains the problem and opens Settings.
- Relaunch and confirm reminders, messages, and today's completion marker persist.
- Send messages and complete the challenge while a reminder permission request is open; confirm those updates survive saving.
- Clear the conversation and confirm it stays cleared after relaunch.
- Test dark-mode contrast, large Dynamic Type, VoiceOver, keyboard dismissal, and small-screen layout.
- On a compatible iOS 26+ device, verify generative coaching and fallback if the model is unavailable.

## Privacy

The app stores data in `Application Support/state.json` inside its sandbox, with iOS file protection. It sends no chat messages to a developer-operated server and includes no analytics or advertising SDK. The generative coach uses Apple's on-device model when available. Local data can be included in device backups according to system settings; local storage is not a promise that no backup copy exists. Clearing chat removes the conversation from the app's current saved state, not from existing backups.

## Limitations and verification status

- **Not AlarmKit:** no continuously ringing alarm, snooze, lock-screen alarm controls, or critical alerts. Notification delivery and sound depend on iOS and user settings.
- No weather, calendar integration, departure planning, custom sounds, streak history, or remote AI provider is implemented.
- Repeating reminders follow calendar-based notification scheduling; verify time-zone and DST behavior on a real device before relying on it.
- The app limits reminders to eight to stay below the pending-notification budget with weekly repeating schedules.
- The project has no app icon or App Store distribution assets yet.
- **25 plain Swift tests passed in the Linux Swift runner. Apple-only code has been reviewed but has not been compiled or device-tested in this environment.** Run the Xcode build and manual checks above before considering this release-ready.
- No GitHub Actions workflow is configured; there is no automated Apple-platform build result.

## Product principles

Encourage without shame. Keep challenges small. Be useful without generative AI. State alarm limitations clearly. Never embed provider secrets in the client.
