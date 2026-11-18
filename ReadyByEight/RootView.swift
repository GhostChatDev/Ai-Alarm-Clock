import SwiftUI
import UIKit

// MARK: - Root view

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
            case .coach: CoachView()
            case .settings: SettingsTabView()
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
        .padding(.horizontal, 10)
    }
}

// MARK: - Morning plan item

struct PlanItem: Identifiable, Equatable {
    var id = UUID()
    var title: String
    var done = false
}

// MARK: - Home

struct HomeView: View {
    @Environment(AppStore.self) private var store
    @State private var showingAdd = false
    @State private var plan: [PlanItem] = [
        PlanItem(title: "Drink a glass of water"),
        PlanItem(title: "Two-minute stretch"),
        PlanItem(title: "Look at today's top task")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: GhostTheme.Space.l) {
                    HStack(alignment: .top) {
                        GhostTheme.GhostHeader(
                            title: greeting,
                            subtitle: subtitle
                        )
                        GhostTheme.GhostMascot(isSpeaking: store.isCoachSpeaking, size: 76)
                    }

                    nextAlarmCard

                    VStack(alignment: .leading, spacing: GhostTheme.Space.s) {
                        Text("Tonight's plan")
                            .font(.headline)
                            .foregroundStyle(GhostTheme.textPrimary)
                        ForEach(plan) { item in
                            Button {
                                togglePlanItem(item.id)
                            } label: {
                                HStack(spacing: GhostTheme.Space.s) {
                                    Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(item.done ? GhostTheme.mint : GhostTheme.textSecondary)
                                    Text(item.title)
                                        .strikethrough(item.done)
                                        .foregroundStyle(item.done ? GhostTheme.textSecondary : GhostTheme.textPrimary)
                                    Spacer(minLength: 0)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(GhostTheme.GhostPressStyle())
                        }
                    }
                    .ghostCard()

                    GhostTheme.GhostPillButton(
                        store.challengeCompleted ? "Done for today" : "I'm awake",
                        systemImage: store.challengeCompleted ? "checkmark.seal.fill" : "sunrise.fill"
                    ) {
                        store.completeChallenge()
                    }
                    .disabled(store.challengeCompleted)
                }
                .padding(GhostTheme.Space.m)
            }
            .ghostScreen(animated: true)
            .navigationTitle("Ready by Eight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add reminder")
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddAlarmView()
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<18: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var subtitle: String {
        if let next = store.nextAlarm {
            return "Next reminder \(next.formatted(date: .omitted, time: .shortened))"
        }
        return "No reminder yet. Tap + to set one."
    }

    private var nextAlarmCard: some View {
        VStack(alignment: .leading, spacing: GhostTheme.Space.xs) {
            Text("Next wake-up")
                .font(.caption.weight(.semibold))
                .foregroundStyle(GhostTheme.textSecondary)
            Text(store.nextAlarm.map { $0.formatted(date: .omitted, time: .shortened) } ?? "--:--")
                .font(.system(size: 46, weight: .bold, design: .rounded))
                .foregroundStyle(GhostTheme.ghostWhite)
            if let next = store.nextAlarm {
                Text(next.formatted(date: .complete, time: .omitted))
                    .font(.footnote)
                    .foregroundStyle(GhostTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ghostCard(glow: true)
    }

    private func togglePlanItem(_ id: UUID) {
        guard let index = plan.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(GhostTheme.Motion.bounce) {
            plan[index].done.toggle()
        }
    }
}

// MARK: - Wake tab

struct WakeTabView: View {
    @Environment(AppStore.self) private var store
    @State private var showingAdd = false
    @State private var pendingDelete: WakeAlarm?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: GhostTheme.Space.l) {
                    HStack {
                        GhostTheme.GhostHeader(
                            title: "Wake-up alarm",
                            subtitle: store.nextAlarm.map {
                                "Next \($0.formatted(date: .abbreviated, time: .shortened))"
                            } ?? "Nothing scheduled yet"
                        )
                        GhostTheme.GhostMascot(isSpeaking: false, size: 60)
                    }

                    if store.state.alarms.isEmpty {
                        emptyState
                    } else {
                        ForEach(store.state.alarms) { alarm in
                            alarmRow(alarm)
                        }
                    }

                    GhostTheme.GhostPillButton("New reminder", systemImage: "plus") {
                        showingAdd = true
                    }

                    if let error = store.error {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(GhostTheme.pink)
                    }
                }
                .padding(GhostTheme.Space.m)
            }
            .ghostScreen(animated: true)
            .navigationTitle("Wake")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAdd) {
                AddAlarmView()
            }
            .confirmationDialog(
                "Delete this reminder?",
                isPresented: Binding(
                    get: { pendingDelete != nil },
                    set: { if !$0 { pendingDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let alarm = pendingDelete { store.delete(alarm) }
                    pendingDelete = nil
                }
                Button("Keep", role: .cancel) { pendingDelete = nil }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: GhostTheme.Space.s) {
            Image(systemName: "alarm")
                .font(.system(size: 34))
                .foregroundStyle(GhostTheme.mint)
            Text("No reminders yet")
                .font(.headline)
                .foregroundStyle(GhostTheme.textPrimary)
            Text("Tap New reminder to set a gentle wake-up time.")
                .font(.footnote)
                .foregroundStyle(GhostTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, GhostTheme.Space.l)
        .ghostCard()
    }

    private func alarmRow(_ alarm: WakeAlarm) -> some View {
        HStack(spacing: GhostTheme.Space.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text(timeText(alarm))
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundStyle(alarm.enabled ? GhostTheme.ghostWhite : GhostTheme.textSecondary)
                Text(alarm.label)
                    .font(.subheadline)
                    .foregroundStyle(GhostTheme.textPrimary)
                Text(alarm.rule.rawValue)
                    .font(.caption)
                    .foregroundStyle(GhostTheme.textSecondary)
            }
            Spacer(minLength: 0)
            Toggle("", isOn: Binding(
                get: { alarm.enabled },
                set: { _ in
                    Task { await store.toggle(alarm) }
                }
            ))
            .labelsHidden()
            .tint(GhostTheme.mint)
        }
        .padding(GhostTheme.Space.m)
        .background(GhostTheme.glass, in: RoundedRectangle(cornerRadius: GhostTheme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: GhostTheme.Radius.card, style: .continuous)
                .strokeBorder(GhostTheme.hairline)
        )
        .contextMenu {
            Button("Delete", systemImage: "trash", role: .destructive) {
                pendingDelete = alarm
            }
        }
    }

    private func timeText(_ alarm: WakeAlarm) -> String {
        var parts = DateComponents()
        parts.hour = alarm.hour
        parts.minute = alarm.minute
        guard let date = Calendar.current.date(from: parts) else {
            return String(format: "%02d:%02d", alarm.hour, alarm.minute)
        }
        return date.formatted(date: .omitted, time: .shortened)
    }
}

// MARK: - Settings tab

struct SettingsTabView: View {
    @Environment(AppStore.self) private var store
    @State private var confirmingClear = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: GhostTheme.Space.l) {
                    GhostTheme.GhostHeader(
                        title: "Settings",
                        subtitle: "Gentle mornings, private by default"
                    )

                    VStack(alignment: .leading, spacing: GhostTheme.Space.s) {
                        Text("Coach")
                            .font(.headline)
                            .foregroundStyle(GhostTheme.textPrimary)
                        Text(store.coachName)
                            .font(.subheadline)
                            .foregroundStyle(GhostTheme.textSecondary)
                        Text(store.notificationsAllowed ? "Notifications allowed" : "Notifications off")
                            .font(.caption)
                            .foregroundStyle(store.notificationsAllowed ? GhostTheme.mint : GhostTheme.pink)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .ghostCard()

                    GhostTheme.GhostPillButton(
                        "Clear coach chat",
                        systemImage: "trash",
                        prominent: false
                    ) {
                        confirmingClear = true
                    }
                    .disabled(store.sending || store.state.messages.isEmpty)

                    Text("Ready by Eight keeps your reminders and chat on this device. No account, no API key.")
                        .font(.caption)
                        .foregroundStyle(GhostTheme.textSecondary)
                }
                .padding(GhostTheme.Space.m)
            }
            .ghostScreen(animated: true)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog(
                "Clear this conversation?",
                isPresented: $confirmingClear,
                titleVisibility: .visible
            ) {
                Button("Clear chat", role: .destructive) { store.clearChat() }
                Button("Cancel", role: .cancel) {}
            }
            .task { await store.refresh() }
        }
    }
}

// MARK: - Add reminder sheet

struct AddAlarmView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var label = ""
    @State private var time = Date()
    @State private var rule: RepeatRule = .daily
    @State private var saving = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: GhostTheme.Space.l) {
                    GhostTheme.GhostHeader(title: "New reminder", subtitle: "A gentle start to the day")

                    VStack(alignment: .leading, spacing: GhostTheme.Space.m) {
                        TextField("Label, for example Wake up", text: $label)
                            .textInputAutocapitalization(.sentences)
                            .padding(12)
                            .background(GhostTheme.glass, in: RoundedRectangle(cornerRadius: GhostTheme.Radius.chip, style: .continuous))
                            .foregroundStyle(GhostTheme.textPrimary)

                        DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                            .foregroundStyle(GhostTheme.textPrimary)

                        Text("Repeats")
                            .font(.subheadline)
                            .foregroundStyle(GhostTheme.textSecondary)

                        Picker("Repeats", selection: $rule) {
                            ForEach(RepeatRule.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .ghostCard()

                    if let error = store.error {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(GhostTheme.pink)
                    }

                    GhostTheme.GhostPillButton(saving ? "Saving…" : "Save reminder", systemImage: "checkmark") {
                        save()
                    }
                    .disabled(saving || store.busy)

                    GhostTheme.GhostPillButton("Cancel", prominent: false) {
                        dismiss()
                    }
                }
                .padding(GhostTheme.Space.m)
            }
            .ghostScreen(animated: true)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                await store.refresh()
                if let next = store.nextAlarm {
                    time = next
                }
            }
        }
    }

    private func save() {
        saving = true
        var draft = WakeAlarm(label: label, time: time, rule: rule)
        draft.enabled = true
        Task {
            let ok = await store.save(draft)
            saving = false
            if ok { dismiss() }
        }
    }
}
