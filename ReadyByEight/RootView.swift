// MARK: - Wake-Up Alarm

extension RootView {
    /// The wake-up alarm screen from the photos: big ghost, big time,
    /// "I'm Awake" and "Snooze" buttons, weather at the bottom.
    struct WakeUpView: View {
        @Environment(AppStore.self) private var store
        @State private var animateGhost = false

        var body: some View {
            VStack(spacing: 0) {
                Spacer()

                // Animated ghost mascot
                GhostTheme.GhostMascot(
                    isSpeaking: animateGhost,
                    size: 110
                )
                .padding(.bottom, 16)

                // Greeting
                VStack(spacing: GhostTheme.Space.xs) {
                    Text("Good morning")
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color(red: 1, green: 0.85, blue: 0.55))
                    Text("Let's take the first small step.")
                        .font(.subheadline)
                        .foregroundStyle(GhostTheme.textSecondary)
                }
                .padding(.bottom, 24)

                // Big time
                Text("7:00")
                    .font(.system(size: 96, weight: .thin, design: .rounded))
                    .foregroundStyle(GhostTheme.textPrimary)
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Text("Monday, October 28")
                    .font(.subheadline)
                    .foregroundStyle(GhostTheme.textSecondary)
                    .padding(.bottom, 40)

                // Buttons
                GhostTheme.GhostPillButton("I'm Awake", systemImage: "checkmark.circle.fill", prominent: true) {
                    withAnimation { animateGhost.toggle() }
                }
                .padding(.horizontal, 20)

                GhostTheme.GhostPillButton("Snooze · 5 min", systemImage: "clock.fill", prominent: false) {
                    store.snooze(5)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)

                // Weather at bottom
                HStack(spacing: GhostTheme.Space.s) {
                    Image(systemName: "cloud.rain.fill")
                        .font(.subheadline)
                        .foregroundStyle(GhostTheme.textSecondary)
                    Text("Rain today · 12°C")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(GhostTheme.textSecondary)
                }
                .padding(.bottom, 26)

                Spacer(minLength: 30)
            }
            .onAppear {
                animateGhost = true
            }
        }
    }
}

// MARK: - AI Morning Coach

extension RootView {
    /// The coach tab: a chat-style morning plan with suggested replies
    /// and a checkable morning plan, matching the last photo.
    struct CoachTabView: View {
        @Environment(AppStore.self) private var store
        @State private var messageText = ""

        var body: some View {
            VStack(spacing: 0) {
                // Header with ghost
                HStack {
                    Text("Your Morning Coach")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(GhostTheme.textPrimary)
                    Spacer()
                    GhostTheme.GhostMascot(isSpeaking: false, size: 28)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 2)

                Text("Small steps. A stronger start.")
                    .font(.subheadline)
                    .foregroundStyle(GhostTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                ScrollView {
                    VStack(alignment: .leading, spacing: GhostTheme.Space.m) {
                        // Chat bubble
                        chatBubble

                        // Suggested chips
                        HStack(spacing: GhostTheme.Space.s) {
                            ForEach(["Have a few", "Suggestions", "Few minutes"], id: \.self) { chip in
                                Button { /* handled by store */ } label: {
                                    Text(chip)
                                        .font(.caption.weight(.medium))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(GhostTheme.glass, in: Capsule())
                                        .foregroundStyle(GhostTheme.textPrimary)
                                }
                                .buttonStyle(GhostTheme.GhostPressStyle(scale: 0.96))
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 20)

                        // Morning plan
                        VStack(alignment: .leading, spacing: GhostTheme.Space.s) {
                            Text("Morning plan")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(GhostTheme.textPrimary)
                            ForEach(planItems, id: \.title) { item in
                                HStack(spacing: GhostTheme.Space.s) {
                                    Button {
                                        store.togglePlanItem(item.title)
                                    } label: {
                                        Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 18))
                                            .foregroundStyle(item.done ? GhostTheme.mint : GhostTheme.textSecondary)
                                    }
                                    .buttonStyle(.plain)
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
                        .padding(.horizontal, 20)

                        Spacer(minLength: 120)
                    }
                }

                // Message input bar
                VStack(spacing: 0) {
                    Divider().background(GhostTheme.border)
                    HStack(spacing: GhostTheme.Space.s) {
                        Image(systemName: "mic.fill")
                            .font(.subheadline)
                            .foregroundStyle(GhostTheme.textSecondary)
                        TextField("Type a message...", text: $messageText)
                            .textFieldStyle(.plain)
                            .foregroundStyle(GhostTheme.textPrimary)
                        Button {
                            sendMessage()
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.white)
                                .padding(12)
                                .background(GhostTheme.accentGradient, in: Circle())
                        }
                        .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .buttonStyle(GhostTheme.GhostPressStyle(scale: 0.92))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Theme.background)
                }
            }
        }

        private var chatBubble: some View {
            VStack(alignment: .leading, spacing: GhostTheme.Space.m) {
                GhostTheme.GhostHeader("AI Coach", subtitle: nil)
                    .padding(.bottom, 2)
                Text("Good morning. What's one thing you want to get done today?")
                    .font(.body)
                    .foregroundStyle(GhostTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .ghostCard()
            .padding(.horizontal, 20)
        }

        private var planItems: [PlanItem] {
            [
                PlanItem(title: "Drink a glass of water", done: true),
                PlanItem(title: "Stretch for two minutes", done: true),
                PlanItem(title: "Pick your first task", done: false)
            ]
        }

        private func sendMessage() {
            let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return }
            messageText = ""
            store.addUserMessage(text)
        }
    }

    struct PlanItem: Identifiable, Hashable {
        let title: String
        var done: Bool
        var id: String { title }
    }
}

// MARK: - Add Alarm (sheet)

struct AddAlarmView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var hour = 7
    @State private var minute = 0
    @State private var enabled = true
    @State private var repeatRule: RepeatRule = .weekdays
    @State private var label = "Alarm"

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Time")
                        Spacer()
                        DatePicker("", selection: .constant(Date()), displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                } header: {
                    Text("Alarm")
                }

                Section {
                    Toggle("Enabled", isOn: $enabled)
                    Picker("Repeat", selection: $repeatRule) {
                        ForEach(RepeatRule.allCases) { rule in
                            Text(rule.rawValue).tag(rule)
                        }
                    }
                    .pickerStyle(.menu)
                    TextField("Label", text: $label)
                }

                Section {
                    GhostTheme.GhostPillButton("Save", prominent: true) {
                        let alarm = Alarm(
                            hour: hour, minute: minute,
                            enabled: enabled, repeatRule: repeatRule,
                            label: label.isEmpty ? "Alarm" : label
                        )
                        store.addAlarm(alarm)
                        dismiss()
                    }
                }
            }
            .navigationTitle("New Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
