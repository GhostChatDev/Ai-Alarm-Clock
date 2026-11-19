import SwiftUI

struct RootView: View {
    @Environment(AppStore.self) private var store
    @State private var tab = 0
    var body: some View {
        Group {
            switch tab {
            case 0: HomeView()
            case 1: WakeTabView()
            case 2: MorningCoachScreen()
            default: SettingsTabView()
            }
        }
        .ghostScreen()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(spacing: 0) {
                tabButton(0, "Home", "house.fill")
                tabButton(1, "Wake", "alarm.fill")
                tabButton(2, "Coach", "sparkles")
                tabButton(3, "Settings", "gearshape.fill")
            }.padding(.horizontal, 12).background(GhostTheme.ink)
        }
        .alert("Something needs attention", isPresented: Binding(
            get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
                Button("OK") { store.error = nil }
            } message: { Text(store.error ?? "") }
    }
    private func tabButton(_ index: Int, _ title: String, _ icon: String) -> some View {
        GhostTheme.GhostTabItem(icon: icon, title: title, isSelected: tab == index) { tab = index }
    }
}

struct HomeView: View {
    @Environment(AppStore.self) private var store
    @State private var adding = false
    @State private var track = GhostDevice.tracks[0]
    @State private var minutes = 30
    private let tasks = ["Drink a glass of water", "Two-minute stretch", "Choose today's top priority"]
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        GhostTheme.GhostHeader("Good evening,\nsleepy soul.", subtitle: "A softer night. A brighter tomorrow.")
                        GhostTheme.GhostMascot(size: 95)
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Label("YOUR NEXT WAKE-UP", systemImage: "moon.stars.fill")
                            .font(.caption.weight(.bold)).foregroundStyle(GhostTheme.purpleSoft)
                        Text(store.nextAlarm?.formatted(date: .omitted, time: .shortened) ?? "No alarm yet")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                        Text(store.nextAlarm?.formatted(date: .complete, time: .omitted) ?? "Set a gentle reminder for tomorrow.")
                            .font(.subheadline).foregroundStyle(GhostTheme.textSecondary)
                        GhostTheme.GhostPillButton("Set wake-up alarm", systemImage: "alarm") { adding = true }
                    }.ghostCard(glow: true)
                    VStack(alignment: .leading, spacing: 14) {
                        Label("Sleep sounds", systemImage: "music.note").font(.title3.bold())
                        Picker("Soundscape", selection: $track) {
                            ForEach(GhostDevice.tracks, id: \.self) { Text($0).tag($0) }
                            if store.device.hasMusic { Text("Imported music").tag("Imported music") }
                        }.tint(GhostTheme.purpleSoft)
                        Picker("Sleep timer", selection: $minutes) {
                            ForEach([15, 30, 60, 120], id: \.self) { Text("\($0) min").tag($0) }
                        }.pickerStyle(.segmented)
                        GhostTheme.GhostPillButton(store.device.playing == nil ? "Drift off to sleep" : "Stop music",
                                                  systemImage: store.device.playing == nil ? "play.fill" : "stop.fill") {
                            if store.device.playing != nil { store.device.stopMusic() }
                            else {
                                do { try store.device.play(track, minutes: minutes) }
                                catch { store.error = error.localizedDescription }
                            }
                        }
                        if let playing = store.device.playing {
                            Text("Playing \(playing) · stops after \(minutes) minutes")
                                .font(.caption).foregroundStyle(GhostTheme.textSecondary)
                        }
                    }.ghostCard()
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your morning plan").font(.title3.bold())
                        ForEach(tasks, id: \.self) { title in
                            Button { store.togglePlanItem(title) } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: store.isPlanItemCompleted(title) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(GhostTheme.purpleSoft)
                                    Text(title).foregroundStyle(GhostTheme.textPrimary)
                                        .strikethrough(store.isPlanItemCompleted(title))
                                    Spacer()
                                }.padding(.vertical, 5)
                            }.buttonStyle(.plain)
                        }
                    }.ghostCard()
                }.padding(22).frame(maxWidth: 680)
                    .frame(maxWidth: .infinity)
            }.ghostScreen().toolbar(.hidden, for: .navigationBar)
                .sheet(isPresented: $adding) { AddAlarmView() }
        }
    }
}

struct WakeTabView: View {
    @Environment(AppStore.self) private var store
    @State private var adding = false
    @State private var editing: WakeAlarm?
    @State private var deleting: WakeAlarm?
    @State private var snoozed = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        GhostTheme.GhostHeader("Wake-up alarm", subtitle: "Let's make mornings feel good.")
                        GhostTheme.GhostMascot(size: 65)
                    }
                    if store.state.alarms.isEmpty {
                        ContentUnavailableView("A fresh start awaits", systemImage: "alarm", description: Text("Add your first wake-up reminder below."))
                            .ghostCard()
                    }
                    ForEach(store.state.alarms) { alarm in
                        HStack {
                            Button { editing = alarm } label: {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(alarm.displayDate.formatted(date: .omitted, time: .shortened))
                                        .font(.system(size: 36, weight: .semibold, design: .rounded))
                                    Text(alarm.label).font(.subheadline)
                                    Text(alarm.rule.rawValue).font(.caption).foregroundStyle(GhostTheme.textSecondary)
                                }.foregroundStyle(alarm.enabled ? GhostTheme.textPrimary : GhostTheme.textSecondary)
                            }.buttonStyle(.plain).accessibilityHint("Edit alarm")
                            Spacer(minLength: 8)
                            VStack(spacing: 14) {
                                Toggle("Enable \(alarm.label)", isOn: Binding(get: { alarm.enabled }, set: { _ in
                                    Task { await store.toggle(alarm) }
                                })).labelsHidden().tint(GhostTheme.purple).disabled(store.busy)
                                Button("Delete", systemImage: "trash") { deleting = alarm }
                                    .labelStyle(.iconOnly).foregroundStyle(GhostTheme.textSecondary)
                            }
                        }.ghostCard(glow: alarm.enabled)
                    }
                    GhostTheme.GhostPillButton("Add alarm", systemImage: "plus") { adding = true }
                    GhostTheme.GhostPillButton(snoozed ? "Cancel five-minute snooze" : "Remind me in five minutes",
                                              systemImage: "zzz", prominent: false) {
                        if snoozed { store.cancelSnooze(); snoozed = false }
                        else { Task { snoozed = await store.snooze() } }
                    }
                    GhostTheme.GhostPillButton(store.challengeCompleted ? "You're up. Well done!" : "I'm awake!",
                                              systemImage: "sun.max.fill") {
                        store.cancelSnooze(); snoozed = false
                        store.device.stopMusic(); store.device.stopSpeech(); store.completeChallenge()
                    }.disabled(store.challengeCompleted)
                    Text("These are local notification reminders, not system Clock alarms. Silent Mode, Focus and notification settings can mute them. Keep a Clock alarm as a backup.")
                        .font(.caption).foregroundStyle(GhostTheme.textSecondary)
                }.padding(22).frame(maxWidth: 680).frame(maxWidth: .infinity)
            }.ghostScreen().toolbar(.hidden, for: .navigationBar)
                .sheet(isPresented: $adding) { AddAlarmView() }
                .sheet(item: $editing) { AddAlarmView(alarm: $0) }
                .confirmationDialog("Delete this alarm?", isPresented: Binding(
                    get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
                        Button("Delete alarm", role: .destructive) {
                            if let deleting { store.delete(deleting) }; deleting = nil
                        }
                    }
        }
    }
}
