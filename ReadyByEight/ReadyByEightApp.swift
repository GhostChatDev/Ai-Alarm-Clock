import SwiftUI
import SwiftData
import UserNotifications
import UniformTypeIdentifiers

@Model
final class MorningGoalRecord {
    var title: String
    var dayKey: String
    var isCompleted: Bool
    var createdAt: Date

    init(title: String, dayKey: String = SavedState.dayKey(), isCompleted: Bool = false, createdAt: Date = .now) {
        self.title = title
        self.dayKey = dayKey
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}

@main
struct ReadyByEightApp: App {
    @State private var store = AppStore()
    private let delegate = NotificationDelegate()

    init() {
        UNUserNotificationCenter.current().delegate = delegate
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: MorningGoalRecord.self)
    }
}

struct MorningCoachScreen: View {
    @Environment(AppStore.self) private var store
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MorningGoalRecord.createdAt, order: .reverse) private var savedGoals: [MorningGoalRecord]
    @State private var draft = ""
    @FocusState private var focused: Bool

    private let suggestions = ["Move my body", "Focus on work", "Feel less stressed"]
    private let planItems: [(id: String, title: String)] = [
        ("water", "Drink a glass of water"),
        ("stretch", "Stretch for two minutes"),
        ("task", "Pick your first task")
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Morning Coach")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(GhostTheme.textPrimary)
                    Text("Small steps. A stronger start.")
                        .font(.subheadline)
                        .foregroundStyle(GhostTheme.textSecondary)
                }
                Spacer()
                Button {
                    if let last = store.state.messages.last(where: { !$0.isUser })?.text {
                        try? store.device.say(last)
                    } else {
                        try? store.device.say("Good morning. What's one thing you want to get done today?")
                    }
                } label: {
                    GhostTheme.GhostMascot(isSpeaking: store.isCoachSpeaking || store.device.speaking, size: 58)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Rectangle().fill(GhostTheme.hairline).frame(height: 1)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Good morning. What’s one thing you want to get done today?")
                        .font(.body)
                        .foregroundStyle(.white)
                        .padding(16)
                        .background(Color(red: 0.45, green: 0.45, blue: 0.56), in: RoundedRectangle(cornerRadius: 20))

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            suggestionPill(suggestions[0])
                            suggestionPill(suggestions[1])
                        }
                        suggestionPill(suggestions[2])
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Morning plan")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                        ForEach(planItems, id: \.id) { item in
                            let done = store.isPlanItemCompleted(item.id)
                            Button {
                                store.togglePlanItem(item.id)
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(done ? GhostTheme.purpleSoft : Color.clear)
                                            .frame(width: 24, height: 24)
                                        Circle()
                                            .strokeBorder(GhostTheme.purpleSoft, lineWidth: 1.8)
                                            .frame(width: 24, height: 24)
                                        if done {
                                            Image(systemName: "checkmark")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(GhostTheme.ink)
                                        }
                                    }
                                    Text(item.title)
                                        .font(.body)
                                        .foregroundStyle(.white)
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        ForEach(savedGoals.prefix(3)) { goal in
                            Button {
                                goal.isCompleted.toggle()
                                try? modelContext.save()
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(goal.isCompleted ? GhostTheme.purpleSoft : Color.clear)
                                            .frame(width: 24, height: 24)
                                        Circle()
                                            .strokeBorder(GhostTheme.purpleSoft, lineWidth: 1.8)
                                            .frame(width: 24, height: 24)
                                        if goal.isCompleted {
                                            Image(systemName: "checkmark")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(GhostTheme.ink)
                                        }
                                    }
                                    Text(goal.title)
                                        .font(.body)
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                    .background(Color(red: 0.19, green: 0.14, blue: 0.34), in: RoundedRectangle(cornerRadius: 24))
                    .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(GhostTheme.purpleSoft.opacity(0.22)))

                    ForEach(store.state.messages) { msg in
                        HStack(alignment: .bottom, spacing: 10) {
                            if msg.isUser { Spacer(minLength: 40) }
                            if !msg.isUser {
                                GhostTheme.GhostMascot(isSpeaking: false, size: 28)
                            }
                            Text(msg.text)
                                .font(.subheadline)
                                .foregroundStyle(msg.isUser ? GhostTheme.ink : GhostTheme.textPrimary)
                                .padding(14)
                                .background(
                                    msg.isUser ? GhostTheme.purpleSoft : GhostTheme.cardElevated,
                                    in: RoundedRectangle(cornerRadius: 18)
                                )
                            if !msg.isUser {
                                Button {
                                    try? store.device.say(msg.text)
                                } label: {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.caption)
                                        .foregroundStyle(GhostTheme.purpleSoft)
                                }
                                Spacer(minLength: 20)
                            }
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }

            HStack(spacing: 12) {
                Button {
                    if let last = store.state.messages.last(where: { !$0.isUser })?.text {
                        try? store.device.say(last)
                    } else {
                        try? store.device.say("Good morning. What's one thing you want to get done today?")
                    }
                } label: {
                    Image(systemName: store.device.speaking ? "waveform" : "mic.fill")
                        .font(.title3)
                        .foregroundStyle(GhostTheme.textSecondary)
                        .frame(width: 36, height: 36)
                }

                TextField("Type a message...", text: $draft)
                    .focused($focused)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(GhostTheme.cardElevated, in: Capsule())
                    .foregroundStyle(GhostTheme.textPrimary)
                    .onSubmit { sendDraft() }

                Button { sendDraft() } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 46, height: 46)
                        .background(GhostTheme.purple, in: RoundedRectangle(cornerRadius: 16))
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(GhostTheme.ink.opacity(0.95))
            .overlay(alignment: .top) { Rectangle().fill(GhostTheme.hairline).frame(height: 1) }
        }
        .ghostScreen()
    }

    private func suggestionPill(_ title: String) -> some View {
        Button {
            Task { await store.send(title) }
        } label: {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(GhostTheme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().strokeBorder(GhostTheme.purpleSoft.opacity(0.55), lineWidth: 1.2))
        }
        .buttonStyle(GhostTheme.GhostPressStyle())
    }

    private func sendDraft() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        draft = ""
        focused = false
        modelContext.insert(MorningGoalRecord(title: text))
        try? modelContext.save()
        Task { await store.send(text) }
    }
}

struct SettingsTabView: View {
    @Environment(AppStore.self) private var store
    @State private var importingTone = false
    @State private var importingMusic = false
    @State private var keyInput = ""
    @State private var keySavedBanner = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(GhostTheme.textPrimary)
                    Text("Device audio, voice, and private AI configuration.")
                        .font(.subheadline)
                        .foregroundStyle(GhostTheme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Label("Alarm Tone & Sleep Music", systemImage: "music.note.list")
                        .font(.headline)
                        .foregroundStyle(GhostTheme.textPrimary)
                    Text("Current alarm tone: \(store.device.toneName)")
                        .font(.subheadline)
                        .foregroundStyle(GhostTheme.purpleSoft)
                    HStack(spacing: 10) {
                        Button { importingTone = true } label: {
                            Label("Import Alarm Tone", systemImage: "bell.badge.fill")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(GhostTheme.purple.opacity(0.22), in: Capsule())
                                .foregroundStyle(GhostTheme.purpleSoft)
                        }
                        Button { importingMusic = true } label: {
                            Label("Import Sleep Music", systemImage: "waveform")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(GhostTheme.cardElevated, in: Capsule())
                                .foregroundStyle(GhostTheme.textPrimary)
                        }
                    }
                    HStack {
                        Text("Sleep volume")
                            .font(.caption)
                            .foregroundStyle(GhostTheme.textSecondary)
                        Slider(value: Binding(
                            get: { store.device.volume },
                            set: { store.device.volume = $0 }
                        ), in: 0.05...1.0)
                        .tint(GhostTheme.purple)
                    }
                }
                .ghostCard()

                VStack(alignment: .leading, spacing: 12) {
                    Label("Device TTS Voice", systemImage: "speaker.wave.3.fill")
                        .font(.headline)
                        .foregroundStyle(GhostTheme.textPrimary)
                    Toggle("Speak coach replies automatically", isOn: Binding(
                        get: { store.device.voiceEnabled },
                        set: { store.device.voiceEnabled = $0 }
                    ))
                    .tint(GhostTheme.purple)
                    .foregroundStyle(GhostTheme.textPrimary)

                    Picker("Voice", selection: Binding(
                        get: { store.device.voiceID },
                        set: { store.device.voiceID = $0 }
                    )) {
                        Text("System Default").tag("")
                        ForEach(store.device.voices, id: \.identifier) { voice in
                            Text("\(voice.name) (\(voice.language))").tag(voice.identifier)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(GhostTheme.purpleSoft)

                    HStack(spacing: 10) {
                        Button {
                            do { try store.device.say("Good morning! I am your Ghost Morning Coach.") }
                            catch { store.error = error.localizedDescription }
                        } label: {
                            Label("Test Device TTS", systemImage: "play.circle.fill")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(GhostTheme.purpleSoft, in: Capsule())
                                .foregroundStyle(GhostTheme.ink)
                        }
                        if store.device.speaking {
                            Button { store.device.stopSpeech() } label: {
                                Text("Stop")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(GhostTheme.danger)
                            }
                        }
                    }
                }
                .ghostCard()

                VStack(alignment: .leading, spacing: 12) {
                    Label("Private AI API (Gitignored / Keychain)", systemImage: "key.fill")
                        .font(.headline)
                        .foregroundStyle(GhostTheme.textPrimary)
                    Text("Keys are stored in iOS Keychain or loaded from a gitignored Secrets.plist / environment variable. Never committed to Git.")
                        .font(.caption)
                        .foregroundStyle(GhostTheme.textSecondary)

                    Toggle("Enable Remote AI Coach API", isOn: Binding(
                        get: { store.device.remoteEnabled },
                        set: { store.device.remoteEnabled = $0 }
                    ))
                    .tint(GhostTheme.purple)
                    .foregroundStyle(GhostTheme.textPrimary)

                    TextField("https://api.openai.com/v1/chat/completions", text: Binding(
                        get: { store.device.endpoint },
                        set: { store.device.endpoint = $0 }
                    ))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(10)
                    .background(GhostTheme.cardElevated, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(GhostTheme.textPrimary)

                    TextField("Model (e.g. gpt-4o-mini)", text: Binding(
                        get: { store.device.model },
                        set: { store.device.model = $0 }
                    ))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(10)
                    .background(GhostTheme.cardElevated, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(GhostTheme.textPrimary)

                    SecureField(store.device.hasKey ? "API Key saved in Keychain (enter new to replace)" : "Paste API Key (saved only in Keychain)", text: $keyInput)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(10)
                        .background(GhostTheme.cardElevated, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(GhostTheme.textPrimary)

                    HStack(spacing: 10) {
                        Button {
                            do {
                                try store.device.saveKey(keyInput.trimmingCharacters(in: .whitespacesAndNewlines))
                                keyInput = ""
                                keySavedBanner = true
                            } catch {
                                store.error = error.localizedDescription
                            }
                        } label: {
                            Text("Save Key to Keychain")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(GhostTheme.purpleSoft, in: Capsule())
                                .foregroundStyle(GhostTheme.ink)
                        }
                        if store.device.hasKey {
                            Button(role: .destructive) {
                                try? store.device.saveKey("")
                                keySavedBanner = false
                            } label: {
                                Text("Clear Key")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(GhostTheme.danger)
                            }
                        }
                    }
                    if keySavedBanner || store.device.hasKey {
                        Text("✓ API Key active in local Keychain")
                            .font(.caption2)
                            .foregroundStyle(GhostTheme.purpleSoft)
                    }
                }
                .ghostCard()
            }
            .padding(20)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .ghostScreen()
        .fileImporter(isPresented: $importingTone, allowedContentTypes: [.audio]) { result in
            do {
                let url = try result.get()
                try store.device.importFile(url, asTone: true)
            } catch {
                store.error = error.localizedDescription
            }
        }
        .fileImporter(isPresented: $importingMusic, allowedContentTypes: [.audio]) { result in
            do {
                let url = try result.get()
                try store.device.importFile(url, asTone: false)
            } catch {
                store.error = error.localizedDescription
            }
        }
    }
}

struct AddAlarmView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var alarm: WakeAlarm?
    @State private var label = "Morning wake-up"
    @State private var time = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? .now
    @State private var rule: RepeatRule = .weekdays

    init(alarm: WakeAlarm? = nil) {
        self.alarm = alarm
        if let alarm {
            _label = State(initialValue: alarm.label)
            _time = State(initialValue: alarm.displayDate)
            _rule = State(initialValue: alarm.rule)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Wake-Up Time") {
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                }
                Section("Details") {
                    TextField("Label", text: $label)
                    Picker("Repeat", selection: $rule) {
                        ForEach(RepeatRule.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                }
                if let alarm {
                    Section {
                        Button("Delete Alarm", role: .destructive) {
                            store.delete(alarm)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(alarm == nil ? "New Alarm" : "Edit Alarm")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var candidate = WakeAlarm(label: label, time: time, rule: rule)
                        if let existing = alarm {
                            candidate.id = existing.id
                            candidate.enabled = existing.enabled
                        }
                        Task {
                            if await store.save(candidate) {
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
