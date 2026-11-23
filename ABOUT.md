# Who made this?

**Paul Bernard, also known as Ghost.**

Hi, I'm Paul. Online I go by Ghost. I'm the person behind Ghost Chat
(ghostchat.tech), Ghost Code and this app, Ghost Mascot.

I'm not a traditional programmer. I had an idea: a small, kind ghost that keeps
you company at night and wakes you gently in the morning. I described what I
wanted in plain words, and AI turned those words into a real iPhone app.

## How it was made

- **The idea and every decision: Paul Bernard.** What the app does, how it
  looks, what it must never do. That part is mine.
- **The app code: Ghost Code.** Ghost Code is my own AI app builder. It wrote
  the ghost mascot, the live wallpapers, Nightstand mode, alarms, sleep sounds
  and sleep tracking.
- **Review, fixes and testing: Claude Code**, the coding agent from Anthropic.
  Claude wrote the missing sleep-sound mixer screen that got the build green,
  built the app with Xcode 27.2, and ran it on an iPhone 18 Pro simulator to
  confirm it opens to the Home screen.

Total cost to build: about $35.

No human wrote the Swift by hand. I'm saying that openly, so you know exactly
what you're looking at.

## Privacy

Ghost Mascot is built to keep your data on your phone.

- **No account.** No sign-up, no login, no email.
- **No tracking.** No analytics, no ads, no third-party SDKs. The app uses only
  Apple's own frameworks.
- **Your data stays on the device.** Alarms, preferences, goals and imported
  audio are saved inside the app's own storage on your phone.
- **Sleep data stays with Apple Health.** The app asks permission before it
  reads your sleep stages or saves a sleep session. Nothing is uploaded.
- **Motion is optional.** It is used for the wallpaper tilt effect and the
  optional mattress sleep estimate, on the device only.
- **Voice is on-device.** The ghost speaks with the iPhone's built-in
  text-to-speech.
- **One optional network use.** If you paste an image link as a custom
  wallpaper, the app downloads that one image from the address you gave it.
  Nothing else in the app goes online.
- **No secrets in the repository.** The `.gitignore` blocks API keys and
  secrets files from ever being committed.

## For developers

- Native SwiftUI, iOS 17 and later, iPhone and iPad.
- 13 Swift files, about 3,000 lines. No external dependencies.
- The project is generated from `project.yml` with XcodeGen:
  `xcodegen generate`, then open `GhostMascot.xcodeproj` and run the
  `GhostMascot` scheme.
- GitHub Actions runs the logic tests and an iOS Simulator build on each change.
- Two honest notes:
  - The committed `ReadyByEight.xcodeproj` is out of date and does not build.
    Use the generated `GhostMascot.xcodeproj`.
  - `AppStore.swift` still holds unused code from an earlier "AI coach" idea
    (a chat request to an AI provider). No screen calls it, and it cannot run
    without an API key, which the app does not ship with.
- Licensed under the terms in `LICENSE`.

## Contact

Find me at ghostchat.tech, or on GitHub as GhostChatDev.

— Paul Bernard (Ghost)
