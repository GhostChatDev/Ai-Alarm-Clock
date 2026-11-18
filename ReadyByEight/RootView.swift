import SwiftUI
import UIKit

/// Root shell with the four tabs from the photos:
/// Home / Tonight, Wake-Up Alarm, AI Morning Coach, Settings.
struct RootView: View {
    @Environment(AppStore.self) private var store
    @State private var selectedTab: Tab = .home

    enum Tab: String, CaseIterable, Identifiable {
        case home, wake, coach, settings
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .wake: return "alarm.fill"
            case .coach: return "person.circle.fill"
            case .settings: return "gear"
            }
        }
        var title: String {
            switch self {
            case .home: return "Home"
            case .wake: return "Wake"
            case .coach: return "Coach"
            case .settings: return "Settings"
            }
        }
    }

    var body: some View {
        Group {
            switch selectedTab {
            case .home: HomeView()
            case .wake: WakeTabView()
            case .coach: CoachTabView()
            case .settings: SettingsView()
            }
        }
        .ghostScreen(animated: true)
        .safeAreaInset(edge: .bottom) {
            tabBar
                .padding(.bottom, 8)
                .background(GhostTheme.ink.opacity(0.9))
        }
    }

    // MARK: - Tab bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases) { tab in
                GhostTheme.GhostTabItem(
                    icon: tab.icon,
                    title: tab.title,
                    isSelected: selectedTab == tab
                ) {
                    withAnimation(GhostTheme.Motion.bounce) { selectedTab = tab }
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background {
            Capsule()
                .fill(GhostTheme.inkRaised)
                .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 4)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Home / Tonight

extension RootView {
    /// Home screen: tonight's alarm, the coach card and the weather card.
    struct HomeView: View {
        @Environment(AppStore.self) private var store
        @State private var showingAddAlarm = false

        var body: some View {
            ScrollView {
                VStack(spacing: GhostTheme.Space.l) {
                    GhostTheme.GhostHeader("Ghost Coach", subtitle: "A better morning starts tonight.")
                        .padding(.horizontal, 20)

                    alarmCard

                    if !store.state.alarms.isEmpty {
                        alarmList
                    }

                    coachCard
                    weatherCard

                    Spacer(minLength: 120)
                }
            }
            .sheet(isPresented: $showingAddAlarm) {
                AddAlarmView()
            }
        }

        private var alarmCard: some View {
            VStack(alignment: .leading, spacing: GhostTheme.Space.s) {
                HStack {
                    Text("Alarm")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(GhostTheme.textSecondary)
                    Spacer()
                    Button {
                        showingAddAlarm = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(GhostTheme.accentGradient)
                    }
                    .accessibilityLabel("Add alarm")
                }
                if let alarm = ghostUpcomingAlarm(in: store) {
                    Text(alarm.displayDate.formatted(date: .omitted, time: .shortened))
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .foregroundStyle(GhostTheme.textPrimary)
                    Text(alarm.label + " · " + alarm.rule.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(GhostTheme.textSecondary)
                } else {
                    Text("No alarm set")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(GhostTheme.textPrimary)
                    Text("Set your wake-up time")
                        .font(.subheadline)
                        .foregroundStyle(GhostTheme.textSecondary)
                }
            }
            .padding(GhostTheme.Space.l)
            .ghostCard()
            .padding(.horizontal, 20)
        }

        private var alarmList: some View {
            VStack(alignment: .leading, spacing: GhostTheme.Space.s) {
                Text("Tonight's reminders")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(GhostTheme.textSecondary)
                ForEach(store.state.alarms) { alarm in
                    HStack(spacing: GhostTheme.Space.s) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(alarm.displayDate.formatted(date: .omitted, time: .shortened))
                                .font(.headline)
                                .foregroundStyle(GhostTheme.textPrimary)
                                .monospacedDigit()
                            Text(alarm.label + " · " + alarm.rule.rawValue)
                                .font(.caption)
                                .foregroundStyle(GhostTheme.textSecondary)
                        }
                        Spacer(minLength: 0)
                        Toggle("", isOn: Binding(
                            get: { alarm.enabled },
                            set: { _ in Task { await store.toggle(alarm) } }
                        ))
                        .labelsHidden()
                        .tint(GhostTheme.mint)
                        Button {
                            store.delete(alarm)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(GhostTheme.textSecondary)
                        }
                        .accessibilityLabel("Delete \(alarm.label)")
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(GhostTheme.Space.l)
            .ghostCard()
            .padding(.horizontal, 20)
        }

        private var coachCard: some View {
            VStack(alignment: .leading, spacing: GhostTheme.Space.s) {
                HStack(spacing: GhostTheme.Space.xs) {
                    GhostTheme.GhostMascot(isSpeaking: store.isCoachSpeaking, size: 24)
                    Text("AI Coach")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(GhostTheme.textPrimary)
                }
                Text("Ready for tomorrow?")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(GhostTheme.textPrimary)
                Text("Tell me what you want to accomplish.")
                    .font(.subheadline)
                    .foregroundStyle(GhostTheme.textSecondary)
                Text(store.challengeCompleted
                     ? "Today's challenge: done. Nice start."
                     : "Today's challenge: sit up, feet on the floor, open the curtains.")
                    .font(.caption)
                    .foregroundStyle(GhostTheme.textSecondary)
            }
            .padding(GhostTheme.Space.l)
            .ghostCard()
            .padding(.horizontal, 20)
        }

        private var weatherCard: some View {
            HStack(spacing: GhostTheme.Space.m) {
                Image(systemName: "cloud.moon.fill")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(GhostTheme.purpleSoft)
                VStack(alignment: .leading, spacing: 2) {
                    Text("18°C")
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .foregroundStyle(GhostTheme.textPrimary)
                    Text("Clear sky")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(GhostTheme.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(GhostTheme.Space.l)
            .ghostCard()
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Wake-Up Alarm

extension RootView {
    /// The wake-up alarm screen from the photo: big ghost, big time,
    /// "I'm Awake" and "Snooze", with a gentle weather line.
    struct WakeTabView: View {
        @Environment(AppStore.self) private var store
        @State private var ghostIsSpeaking = false
        @State private var snoozeNote: String?

        var body: some View {
            VStack(spacing: 0) {
                Spacer(minLength: 20)

                GhostTheme.GhostMascot(isSpeaking: ghostIsSpeaking, size: 110)
                    .padding(.bottom, 16)

                VStack(spacing: GhostTheme.Space.xs) {
                    Text(greeting)
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color(red: 1, green: 0.85, blue: 0.55))
                    Text("Let's take the first small step.")
                        .font(.subheadline)
                        .foregroundStyle(GhostTheme.textSecondary)
                }
                .multilineTextAlignment(.center)
                .padding(.bottom, 24)

                Text(ghostUpcomingAlarm(in: store)?.displayDate
                        .formatted(date: .omitted, time: .shortened) ?? "--:--")
                    .font(.system(size: 96, weight: .thin, design: .rounded))
                    .foregroundStyle(GhostTheme.textPrimary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.subheadline)
                    .foregroundStyle(GhostTheme.textSecondary)
                    .padding(.bottom, 32)

                GhostTheme.GhostPillButton("I'm Awake", systemImage: "checkmark.circle.fill", prominent: true) {
                    ghostIsSpeaking = true
                    store.completeChallenge()
                    Task {
                        try? await Task.sleep(for: .seconds(2.5))
                        ghostIsSpeaking = false
                    }
                }
                .padding(.horizontal, 20)

                GhostTheme.GhostPillButton("Snooze · 5 min", systemImage: "clock.fill", prominent: false) {
                    snoozeNote = "Stay close: your reminder is still set for "
                        + (ghostUpcomingAlarm(in: store)?.displayDate
                            .formatted(date: .omitted, time: .shortened) ?? "your wake-up time") + "."
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 18)

                if let snoozeNote {
                    Text(snoozeNote)
                        .font(.caption)
                        .foregroundStyle(GhostTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)
                }

                HStack(spacing: GhostTheme.Space.m) {
                    Image(systemName: "cloud.rain.fill")
                        .font(.subheadline)
                        .foregroundStyle(GhostTheme.textSecondary)
                    Text("Rain today · 12°C")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(GhostTheme.textSecondary)
                }
                .padding(.bottom, 20)

                Spacer(minLength: 20)
            }
        }

        private var greeting: String {
            let hour = Calendar.current.component(.hour, from: .now)
            switch hour {
            case 4..<12: return "Good morning"
            case 12..<17: return "Good afternoon"
            case 17..<22: return "Good evening"
            default: return "Rest well tonight"
            }
        }
    }
}

// MARK: - AI Morning Coach

extension RootView {
    /// Coach tab: a chat with the coach plus a checkable morning plan.
    struct CoachTabView: View {
        @Environment(AppStore.self) private var store
        @State private var messageText = ""
        @State private var planItems: [PlanItem] = [
            PlanItem(title: "Drink a glass of water"),
            PlanItem(title: "Stretch for two minutes"),
            PlanItem(title: "Pick your first task"),
        ]

        private let chips = ["Move my body", "Focus on work", "Feel less stressed"]

        var body: some View {
            VStack(spacing: 0) {
                header
                chatScroll
                inputBar
            }
        }

        private var header: some View {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Your Morning Coach")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(GhostTheme.textPrimary)
                    Spacer()
                    GhostTheme.GhostMascot(isSpeaking: store.isCoachSpeaking, size: 28)
                }
                Text(store.coachName)
                    .font(.subheadline)
                    .foregroundStyle(GhostTheme.textSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }

        private var chatScroll: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: GhostTheme.Space.m) {
                    ForEach(store.state.messages) { message in
                        bubble(for: message)
                    }
                    if store.state.messages.isEmpty {
                        Text("Good morning. What's one thing you want to get done today?")
                            .font(.body)
                            .foregroundStyle(GhostTheme.textPrimary)
                            .padding(GhostTheme.Space.m)
                            .background(GhostTheme.glass, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }

                    chipsRow
                    morningPlan

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
            }
            .scrollDismissesKeyboard(.interactively)
        }

        private func bubble(for message: CoachMessage) -> some View {
            HStack {
                if message.isUser { Spacer(minLength: 40) }
                Text(message.text)
                    .font(.subheadline)
                    .foregroundStyle(message.isUser ? Color.white : GhostTheme.textPrimary)
                    .padding(GhostTheme.Space.m)
                    .background {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(message.isUser ? AnyShapeStyle(GhostTheme.accentGradient)
                                                 : AnyShapeStyle(GhostTheme.glass))
                    }
                if !message.isUser { Spacer(minLength: 40) }
            }
        }

        private var chipsRow: some View {
            HStack(spacing: GhostTheme.Space.s) {
                ForEach(chips, id: \.self) { chip in
                    Button {
                        Task { await store.send(chip) }
                    } label: {
                        Text(chip)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(GhostTheme.glass, in: Capsule())
                            .foregroundStyle(GhostTheme.textPrimary)
                    }
                    .buttonStyle(GhostTheme.GhostPressStyle(scale: 0.96))
                    .disabled(store.sending)
                }
                Spacer(minLength: 0)
            }
        }

        private var morningPlan: some View {
            VStack(alignment: .leading, spacing: GhostTheme.Space.s) {
                Text("Morning plan")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(GhostTheme.textPrimary)
                ForEach($planItems) { $item in
                    HStack(spacing: GhostTheme.Space.s) {
                        Button {
                            item.done.toggle()
                        } label: {
                            Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 18))
                                .foregroundStyle(item.done ? GhostTheme.mint : GhostTheme.textSecondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(item.done ? "Mark \(item.title) not done" : "Mark \(item.title) done")
                        Text(item.title)
                            .font(.subheadline)
                            .foregroundStyle(GhostTheme.textPrimary)
                            .strikethrough(item.done)
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 2)
                }
            }
            .ghostCard()
        }

        private var inputBar: some View {
            HStack(spacing: GhostTheme.Space.s) {
                TextField("Type a message...", text: $messageText, axis: .vertical)
                    .lineLimit(1...4)
                    .textFieldStyle(.plain)
                    .foregroundStyle(GhostTheme.textPrimary)
                Button {
                    let text = messageText
                    messageText = ""
                    Task { await store.send(text) }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.white)
                        .padding(12)
                        .background(GhostTheme.accentGradient, in: Circle())
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.sending)
                .buttonStyle(GhostTheme.GhostPressStyle(scale: 0.92))
                .accessibilityLabel("Send message")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(GhostTheme.inkRaised)
            .overlay(alignment: .top) {
                Rectangle().fill(GhostTheme.hairline).frame(height: 1)
            }
        }
    }
}
