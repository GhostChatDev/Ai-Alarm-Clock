import SwiftUI

struct RootView: View {
    @Environment(AppStore.self) private var store
    @State private var tab = 0

    var body: some View {
        Group {
            switch tab {
            case 0: HomeView(switchTab: { tab = $0 })
            case 1: WakeTabView(switchTab: { tab = $0 })
            case 2: MorningCoachScreen()
            default: SettingsTabView()
            }
        }
        .ghostScreen()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(spacing: 0) {
                tabButton(0, "Home", "house.fill")
                tabButton(1, "Wake", "alarm.fill")
                tabButton(2, "Coach", "bubble.left.and.bubble.right.fill")
                tabButton(3, "Settings", "gearshape.fill")
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .background(GhostTheme.ink.opacity(0.96))
            .overlay(alignment: .top) { Rectangle().fill(GhostTheme.hairline).frame(height: 1) }
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
    var switchTab: (Int) -> Void = { _ in }
    @State private var adding = false
    @State private var editing: WakeAlarm?
    @State private var track = GhostDevice.tracks[0]
    @State private var minutes = 30
    @State private var weatherIndex = 0
    private let forecasts: [(temp: String, desc: String)] = [
        ("18°C", "Clear sky"),
        ("12°C", "Rain today · Bring an umbrella"),
        ("15°C", "Crisp morning breeze")
    ]

    private var primaryAlarm: WakeAlarm? {
        store.state.alarms.first(where: \.enabled) ?? store.state.alarms.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ghost Coach")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(GhostTheme.purpleSoft)
                        Text("A better morning starts tonight.")
                            .font(.subheadline)
                            .foregroundStyle(GhostTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    alarmHeroCard

                    HStack {
                        Spacer()
                        Button {
                            try? store.device.say("A better morning starts tonight. Ready for tomorrow?")
                        } label: {
                            GhostTheme.GhostMascot(isSpeaking: store.device.speaking || store.isCoachSpeaking, size: 96)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.vertical, -6)

                    Button { switchTab(2) } label: {
                        HStack(alignment: .bottom, spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("AI Coach")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(GhostTheme.purpleSoft)
                                Text("Ready for tomorrow?")
                                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                                    .foregroundStyle(GhostTheme.textPrimary)
                                Text("Tell me what you want to accomplish.")
                                    .font(.subheadline)
                                    .foregroundStyle(GhostTheme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "sparkles")
                                .font(.title2)
                                .foregroundStyle(GhostTheme.purpleSoft)
                        }
                        .ghostCard()
                    }
                    .buttonStyle(GhostTheme.GhostPressStyle())

                    Button {
                        weatherIndex = (weatherIndex + 1) % forecasts.count
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(forecasts[weatherIndex].temp)
                                    .font(.system(size: 46, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                Text(forecasts[weatherIndex].desc)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.white.opacity(0.88))
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles")
                                    Text("Tap to cycle tonight's outlook")
                                }
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.75))
                                .padding(.top, 2)
                            }
                            Spacer()
                            ZStack {
                                Image(systemName: "moon.stars.fill")
                                    .font(.system(size: 48))
                                    .foregroundStyle(GhostTheme.purpleSoft)
                                    .offset(x: 10, y: -8)
                                Image(systemName: "cloud.fill")
                                    .font(.system(size: 44))
                                    .foregroundStyle(.white.opacity(0.92))
                                    .offset(x: -8, y: 12)
                            }
                            .frame(width: 84, height: 72)
                        }
                        .padding(22)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.39, green: 0.32, blue: 0.92), Color(red: 0.56, green: 0.31, blue: 0.88)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 26)
                        )
                        .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(.white.opacity(0.16)))
                        .shadow(color: GhostTheme.purple.opacity(0.28), radius: 20, y: 8)
                    }
                    .buttonStyle(GhostTheme.GhostPressStyle())

                    sleepMusicCard
                }
                .padding(20)
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }
            .ghostScreen()
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $adding) { AddAlarmView() }
            .sheet(item: $editing) { AddAlarmView(alarm: $0) }
        }
    }

    private var alarmHeroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let alarm = primaryAlarm {
                Button { editing = alarm } label: {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Alarm")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(GhostTheme.textSecondary)
                        Spacer()
                        Text(alarm.displayDate, style: .time)
                            .font(.system(size: 54, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(GhostTheme.textPrimary)
                    }
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(GhostTheme.hairline)
                    .frame(height: 1)

                HStack {
                    Text("Tomorrow · \(alarm.rule.rawValue)")
                        .font(.subheadline)
                        .foregroundStyle(GhostTheme.purpleSoft)
                    Spacer()
                    GhostTheme.GhostAlarmToggle(isOn: Binding(
                        get: { alarm.enabled },
                        set: { _ in Task { await store.toggle(alarm) } }
                    ))
                }
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Alarm")
                            .font(.headline)
                            .foregroundStyle(GhostTheme.textSecondary)
                        Text("7:00 AM")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(GhostTheme.textPrimary.opacity(0.6))
                        Text("Tap + to schedule your wake-up reminder")
                            .font(.caption)
                            .foregroundStyle(GhostTheme.purpleSoft)
                    }
                    Spacer()
                    Button { adding = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 38))
                            .foregroundStyle(GhostTheme.purple)
                    }
                }
            }

            HStack(spacing: 10) {
                Button { adding = true } label: {
                    Label("Add Alarm", systemImage: "plus")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(GhostTheme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(GhostTheme.cardElevated, in: Capsule())
                }
                Button { switchTab(1) } label: {
                    Label("Wake Screen", systemImage: "sunrise.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(GhostTheme.purpleSoft)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(GhostTheme.purple.opacity(0.18), in: Capsule())
                }
                Spacer()
            }

            if store.state.alarms.count > 1 {
                VStack(spacing: 8) {
                    ForEach(store.state.alarms.dropFirst()) { item in
                        HStack {
                            Button { editing = item } label: {
                                HStack {
                                    Text(item.displayDate, style: .time)
                                        .font(.headline.monospacedDigit())
                                        .foregroundStyle(GhostTheme.textPrimary)
                                    Text("· \(item.label) (\(item.rule.rawValue))")
                                        .font(.caption)
                                        .foregroundStyle(GhostTheme.textSecondary)
                                        .lineLimit(1)
                                }
                            }
                            .buttonStyle(.plain)
                            Spacer()
                            GhostTheme.GhostAlarmToggle(isOn: Binding(
                                get: { item.enabled },
                                set: { _ in Task { await store.toggle(item) } }
                            ))
                            Button(role: .destructive) { store.delete(item) } label: {
                                Image(systemName: "trash")
                                    .font(.caption)
                                    .foregroundStyle(GhostTheme.danger)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
        .ghostCard(elevated: true)
    }

    private var sleepMusicCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Sleep Music & Ambient", systemImage: "moon.zzz.fill")
                    .font(.headline)
                    .foregroundStyle(GhostTheme.textPrimary)
                Spacer()
                if let playing = store.device.playing {
                    Text("Playing: \(playing)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(GhostTheme.purpleSoft)
                }
            }
            Picker("Track", selection: $track) {
                ForEach(GhostDevice.tracks, id: \.self) { Text($0).tag($0) }
                if store.device.hasMusic {
                    Text("Imported music").tag("Imported music")
                }
            }
            .pickerStyle(.menu)
            .tint(GhostTheme.purpleSoft)

            HStack {
                Text("Timer: \(minutes) min")
                    .font(.caption)
                    .foregroundStyle(GhostTheme.textSecondary)
                Spacer()
                Picker("Timer", selection: $minutes) {
                    Text("15m").tag(15)
                    Text("30m").tag(30)
                    Text("60m").tag(60)
                }
                .pickerStyle(.segmented)
                .frame(width: 170)
            }

            HStack(spacing: 10) {
                Button {
                    if store.device.playing != nil {
                        store.device.stopMusic()
                    } else {
                        do { try store.device.play(track, minutes: minutes) }
                        catch { store.error = error.localizedDescription }
                    }
                } label: {
                    Label(store.device.playing != nil ? "Stop Sleep Audio" : "Play Sleep Audio",
                          systemImage: store.device.playing != nil ? "stop.fill" : "play.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .foregroundStyle(GhostTheme.ink)
                        .background(GhostTheme.purpleSoft, in: Capsule())
                }
            }
        }
        .ghostCard()
    }
}

struct WakeTabView: View {
    @Environment(AppStore.self) private var store
    var switchTab: (Int) -> Void = { _ in }
    @State private var snoozeBanner: String?

    private var activeAlarm: WakeAlarm? {
        store.state.alarms.first(where: \.enabled) ?? store.state.alarms.first
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 26) {
                Spacer(minLength: 16)
                Button {
                    try? store.device.say("Good morning! Let's take the first small step.")
                } label: {
                    GhostTheme.GhostMascot(isSpeaking: store.device.speaking, size: 108)
                }
                .buttonStyle(.plain)

                VStack(spacing: 8) {
                    Text("Good morning")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(GhostTheme.warmCream)
                    Text("Let’s take the first small step.")
                        .font(.body)
                        .foregroundStyle(GhostTheme.textSecondary)
                }

                VStack(spacing: 6) {
                    if let alarm = activeAlarm {
                        Text(alarm.displayDate, style: .time)
                            .font(.system(size: 76, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                    } else {
                        Text("7:00")
                            .font(.system(size: 76, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                    }
                    Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                        .font(.title3)
                        .foregroundStyle(GhostTheme.textSecondary)
                }
                .padding(.vertical, 10)

                if let banner = snoozeBanner {
                    Text(banner)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(GhostTheme.purpleSoft)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(GhostTheme.purple.opacity(0.18), in: Capsule())
                }

                VStack(spacing: 14) {
                    Button {
                        store.device.stopMusic()
                        store.cancelSnooze()
                        if !store.challengeCompleted { store.completeChallenge() }
                        try? store.device.say("Awesome job waking up! Let's check your morning plan.")
                        switchTab(2)
                    } label: {
                        Text(store.challengeCompleted ? "I’m Awake ✓" : "I’m Awake")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(GhostTheme.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(GhostTheme.purpleSoft, in: Capsule())
                            .shadow(color: GhostTheme.purple.opacity(0.45), radius: 18, y: 6)
                    }
                    .buttonStyle(GhostTheme.GhostPressStyle())

                    Button {
                        Task {
                            if await store.snooze() {
                                snoozeBanner = "Snoozed for 5 minutes · Reminder scheduled"
                            }
                        }
                    } label: {
                        Text("Snooze · 5 min")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(GhostTheme.purpleSoft)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 17)
                            .background(Capsule().strokeBorder(GhostTheme.purpleSoft.opacity(0.65), lineWidth: 1.4))
                    }
                    .buttonStyle(GhostTheme.GhostPressStyle())
                }
                .padding(.horizontal, 12)

                HStack(spacing: 8) {
                    Image(systemName: "cloud.rain.fill")
                        .foregroundStyle(GhostTheme.purpleSoft)
                    Text("Rain today · 12°C")
                        .font(.subheadline)
                        .foregroundStyle(GhostTheme.textSecondary)
                }
                .padding(.top, 12)
            }
            .padding(24)
            .frame(maxWidth: 540)
            .frame(maxWidth: .infinity)
        }
        .ghostScreen()
    }
}
