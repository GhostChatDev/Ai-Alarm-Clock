import SwiftUI
import UIKit
import UserNotifications

@main
struct ReadyByEightApp: App {
    @State private var store = AppStore()
    private let notificationDelegate = NotificationDelegate()
    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }
    var body: some Scene {
        WindowGroup {
            RootView().environment(store).preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        @Bindable var store = store
        TabView {
            ClockView().tabItem { Label("Clock", systemImage: "alarm") }
            CoachView().tabItem { Label("Eight", systemImage: "bubble.left.and.bubble.right") }
        }
        .tint(Theme.accent)
        .task { await store.refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await store.refresh() } }
        }
        .alert("Something needs attention", isPresented: Binding(
            get: { store.error != nil }, set: { if !$0 { store.error = nil } }
        )) { Button("OK") { store.error = nil } } message: { Text(store.error ?? "") }
    }
}

struct ClockView: View {
    @Environment(AppStore.self) private var store
    @State private var adding = false
    @State private var editing: WakeAlarm?
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(context.date, format: .dateTime.weekday(.wide).month().day())
                                .font(.subheadline).foregroundStyle(.secondary)
                            Text(context.date, style: .time)
                                .font(.system(size: 64, weight: .ultraLight, design: .rounded))
                                .monospacedDigit().minimumScaleFactor(0.5).lineLimit(1)
                            if let next = store.nextAlarm {
                                Text("Next reminder \(next.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.subheadline).foregroundStyle(Theme.accent)
                            } else { Text("Make room for a fresh start.").foregroundStyle(.secondary) }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Label("ONE SMALL WIN", systemImage: "sparkles")
                            .font(.caption.weight(.bold)).foregroundStyle(Theme.accent)
                        Text("Feet on the floor. Curtains open.").font(.title3.weight(.semibold))
                        Text("Give yourself two minutes. You don’t have to do everything at once.")
                            .foregroundStyle(.secondary)
                        Button(action: store.completeChallenge) {
                            Label(store.challengeCompleted ? "Done for today" : "I did it",
                                  systemImage: store.challengeCompleted ? "checkmark.circle.fill" : "circle")
                                .frame(maxWidth: .infinity).padding(.vertical, 8)
                        }.buttonStyle(.borderedProminent).tint(Theme.accent).foregroundStyle(.black)
                    }.card()
                    HStack {
                        Text("Your reminders").font(.title2.weight(.semibold))
                        Spacer()
                        Text("\(store.state.alarms.count)/8").foregroundStyle(.secondary)
                    }
                    if store.state.alarms.isEmpty {
                        ContentUnavailableView("A calmer morning starts here", systemImage: "sunrise",
                            description: Text("Tap + to create your first wake-up reminder."))
                    }
                    ForEach(store.state.alarms) { alarm in
                        HStack(spacing: 12) {
                            Button { editing = alarm } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(alarm.displayDate, style: .time)
                                        .font(.system(.largeTitle, design: .rounded).weight(.light))
                                    Text(alarm.label).font(.subheadline)
                                    Text(alarm.rule.rawValue + (alarm.enabled && alarm.nextOccurrence() == nil ? " · Finished" : ""))
                                        .font(.caption).foregroundStyle(.secondary)
                                }.foregroundStyle(.primary).frame(maxWidth: .infinity, alignment: .leading)
                            }.buttonStyle(.plain).accessibilityHint("Edit reminder")
                            Toggle("Enable \(alarm.label)", isOn: Binding(
                                get: { alarm.enabled }, set: { _ in Task { await store.toggle(alarm) } }))
                                .labelsHidden().disabled(store.busy)
                        }.card()
                    }
                    Label("Reminders use notifications, not system alarms. Silent mode, Focus, or notification settings can prevent sound. Set a backup in Apple Clock.", systemImage: "info.circle")
                        .font(.footnote).foregroundStyle(.secondary)
                    if !store.notificationsAllowed {
                        Button("Open notification settings", systemImage: "gearshape") {
                            if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }.font(.footnote)
                    }
                }.padding(20)
            }
            .background(Theme.background)
            .navigationTitle("Ready by Eight").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add reminder", systemImage: "plus") { adding = true }
                        .disabled(store.busy || store.state.alarms.count >= 8)
                }
            }
            .sheet(isPresented: $adding) { AlarmEditor(alarm: nil) }
            .sheet(item: $editing) { AlarmEditor(alarm: $0) }
        }
    }
}

struct AlarmEditor: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let alarm: WakeAlarm?
    @State private var label: String
    @State private var time: Date
    @State private var rule: RepeatRule
    @State private var deleting = false
    init(alarm: WakeAlarm?) {
        self.alarm = alarm
        _label = State(initialValue: alarm?.label ?? "A fresh start")
        _time = State(initialValue: alarm?.displayDate ?? Calendar.current.date(from: DateComponents(hour: 8)) ?? .now)
        _rule = State(initialValue: alarm?.rule ?? .weekdays)
    }
    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel).labelsHidden()
                Section("Make it yours") {
                    TextField("Label", text: $label).onChange(of: label) { _, value in label = String(value.prefix(60)) }
                    Picker("Repeat", selection: $rule) {
                        ForEach(RepeatRule.allCases) { Text($0.rawValue).tag($0) }
                    }
                }
                Section {
                    Text("Once schedules the next occurrence of this time. Allow notifications when asked. This is a reminder, not a continuously ringing alarm.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if alarm != nil {
                    Button("Delete reminder", role: .destructive) { deleting = true }
                }
            }
            .navigationTitle(alarm == nil ? "New reminder" : "Edit reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.disabled(store.busy) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var updated = WakeAlarm(label: label, time: time, rule: rule)
                        if let alarm { updated.id = alarm.id; updated.enabled = alarm.enabled }
                        Task { if await store.save(updated) { dismiss() } }
                    }.disabled(store.busy)
                }
            }
            .interactiveDismissDisabled(store.busy)
            .confirmationDialog("Delete this reminder?", isPresented: $deleting, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let alarm { store.delete(alarm); if store.error == nil { dismiss() } }
                }
            }
            .alert("Couldn’t update reminder", isPresented: Binding(
                get: { store.error != nil }, set: { if !$0 { store.error = nil } }
            )) { Button("OK") { store.error = nil } } message: { Text(store.error ?? "") }
        }.tint(Theme.accent)
    }
}
