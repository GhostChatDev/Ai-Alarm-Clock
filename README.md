# Ready by Eight

**A motivating morning copilot that helps you feel prepared—not just wake up.**

Ready by Eight helps people turn a busy morning into a clear, encouraging plan. Users set when they need to be somewhere, then get a concise briefing, a practical checklist, and a small challenge to build momentum.

> The app supports a morning routine; it should not replace the iPhone Clock app as a guaranteed alarm.

## Product idea

Most alarm apps focus on waking people up. Ready by Eight focuses on what happens after they wake up: figuring out what matters, getting moving, and leaving on time.

### Example morning briefing

> Good morning! You need to leave by 8:20. It may rain, so take a jacket. First challenge: get dressed in 10 minutes. You’ve got this.

## First version (MVP)

- Set a wake-up time and the time you need to leave.
- Create a simple morning checklist, with tasks users can check off.
- Show one encouraging, achievable daily challenge.
- Send bedtime and morning reminders using local notifications.
- Offer a useful basic plan when AI or network access is unavailable.
- Let users mark a morning as complete and see a simple streak or history.

### Not in the first version

- A replacement for the built-in iPhone alarm.
- Automatic calendar access, location tracking, or weather alerts until the user explicitly opts in.
- Complicated social features, leaderboards, or subscriptions.

## Suggested technology

- **Platform:** iPhone
- **Language:** Swift 6
- **UI:** SwiftUI
- **Minimum OS:** iOS 17
- **Local persistence:** SwiftData, if needed for saved routines and progress
- **Reminders:** UserNotifications local notifications
- **AI:** Add behind a service interface. Never ship a provider API key in the app; use a secure backend for requests that require a secret.

## Project structure

```text
ReadyByEight/
├── App/
│   ├── ReadyByEightApp.swift
│   └── AppRouter.swift
├── Features/
│   ├── Onboarding/
│   │   ├── OnboardingView.swift
│   │   └── OnboardingViewModel.swift
│   ├── MorningPlan/
│   │   ├── MorningPlanView.swift
│   │   ├── MorningPlanViewModel.swift
│   │   └── ChallengeCard.swift
│   ├── Schedule/
│   │   ├── ScheduleView.swift
│   │   └── ScheduleViewModel.swift
│   └── Progress/
│       ├── ProgressView.swift
│       └── ProgressViewModel.swift
├── Models/
│   ├── MorningPlan.swift
│   ├── Challenge.swift
│   └── UserPreferences.swift
├── Services/
│   ├── AIPlanService.swift
│   ├── NotificationService.swift
│   └── WeatherService.swift
├── Shared/
│   ├── Components/
│   └── Theme/
└── Resources/
    └── Assets.xcassets
```

Keep the first implementation small. It is fine to begin with a single screen and add folders as features are built.

## Getting started

1. Open Xcode and create a new **iOS App** project named `ReadyByEight`.
2. Choose **SwiftUI** for the interface and **Swift** for the language. Set the deployment target to **iOS 17** or later.
3. Add the source files following the structure above, or start with the files Xcode creates and organize them as the project grows.
4. Select an iPhone simulator in Xcode’s run destination menu and press **Run**.
5. Add notification permission prompts only when the user turns on reminders, and explain what reminders they will receive.

No special capabilities or Info.plist keys are required for the initial offline MVP. If later versions use protected data such as Calendar, location, or weather based on location, request only the required access and include the appropriate usage description and privacy explanation.

## Product principles

- **Encourage, don’t shame.** Missing a task should never trigger guilt-based messages.
- **Keep challenges small.** A challenge should feel doable on a rushed morning.
- **Be useful without AI.** The basic checklist and schedule must work offline.
- **Be honest about timing.** Make it clear that notifications are reminders, not a guaranteed alarm.
- **Respect privacy.** Ask before accessing personal data, collect as little as possible, and explain what is sent to any AI service.
- **Let people personalize it.** Users should be able to edit or skip suggestions and choose a supportive tone.

## Possible next steps

1. Build the onboarding flow for wake-up time, leave-by time, and routine preferences.
2. Build the morning plan screen with a checklist and one challenge.
3. Add local reminders with opt-in notification permission.
4. Save routines and completion history locally.
5. Add optional AI-generated plans, with a reliable non-AI fallback.
6. Consider calendar or weather integrations only after the core routine feels useful.

## Status

Idea and initial product outline. Implementation has not started.
