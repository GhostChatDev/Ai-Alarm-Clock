import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct RootView: View {
    @Environment(AppStore.self) private var store
    @State private var tab = 0
    @State private var showNightstand = false

    var body: some View {
        Group {
            switch tab {
            case 0:
                HomeView(
                    switchTab: { tab = $0 },
                    openNightstand: { withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { showNightstand = true } }
                )
            case 1:
                WakeTabView(
                    switchTab: { tab = $0 },
                    openNightstand: { withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { showNightstand = true } }
                )
            case 2:
                MorningCoachScreen()
            default:
                SettingsTabView(
                    openNightstand: { withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { showNightstand = true } }
                )
            }
        }
        .ghostScreen(animated: true)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(spacing: 0) {
                tabButton(0, "Home", "house.fill")
                tabButton(1, "Wake", "alarm.fill")
                tabButton(2, "Ghost", "sparkles")
                tabButton(3, "Settings", "gearshape.fill")
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .background(GhostTheme.ink.opacity(0.94))
            .overlay(alignment: .top) { Rectangle().fill(GhostTheme.hairline).frame(height: 1) }
        }
        .fullScreenCover(isPresented: $showNightstand) {
            GhostNightstandView(isPresented: $showNightstand)
                .environment(store)
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
    var openNightstand: () -> Void = {}
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
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Ghost")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(GhostTheme.purpleSoft)
                            Text("A better morning starts tonight.")
                                .font(.subheadline)
                                .foregroundStyle(GhostTheme.textSecondary)
                        }
                        Spacer()
                        Button(action: openNightstand) {
                            Label("Saver", systemImage: "moon.stars.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(GhostTheme.purpleSoft)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(GhostTheme.purple.opacity(0.18), in: Capsule())
                                .overlay(Capsule().strokeBorder(GhostTheme.purpleSoft.opacity(0.35)))
                        }
                        .buttonStyle(GhostTheme.GhostPressStyle())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    alarmHeroCard

                    HStack {
                        Spacer()
                        Button {
                            try? store.device.say("Hi! I'm Ghost. A better morning starts tonight.")
                        } label: {
                            GhostTheme.GhostMascot(
                                isSpeaking: store.device.speaking || store.isCoachSpeaking,
                                isSleeping: store.device.playing != nil,
                                size: 102
                            )
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.vertical, -4)

                    Button { switchTab(2) } label: {
                        HStack(alignment: .bottom, spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Ghost Mascot")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(GhostTheme.purpleSoft)
                                Text("Ready for tomorrow?")
                                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                                    .foregroundStyle(GhostTheme.textPrimary)
                                Text("Tell Ghost what you want to accomplish.")
                                    .font(.subheadline)
                                    .foregroundStyle(GhostTheme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "sparkles")
                                .font(.title2)
                                .foregroundStyle(GhostTheme.purpleSoft)
                        }
                        .ghostCard(glow: true)
                    }
                    .buttonStyle(GhostTheme.GhostPressStyle())

                    Button {
                        weatherIndex = (weatherIndex + 1) % forecasts.count
                    } label: {
                        TimelineView(.animation(minimumInterval: 0.08)) { context in
                            let wave = GhostTheme.syncWave(at: context.date)
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
                                        .offset(x: 10, y: -8 + CGFloat(wave) * 3.5)
                                    Image(systemName: "cloud.fill")
                                        .font(.system(size: 44))
                                        .foregroundStyle(.white.opacity(0.92))
                                        .offset(x: -8 + CGFloat(wave) * 2.5, y: 12)
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
                            .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(.white.opacity(0.18 + 0.08 * wave)))
                            .shadow(color: GhostTheme.purple.opacity(0.28), radius: 20, y: 8)
                        }
                    }
                    .buttonStyle(GhostTheme.GhostPressStyle())

                    sleepMusicCard
                }
                .padding(20)
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }
            .ghostScreen(animated: true)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $adding) { AddAlarmView() }
            .sheet(item: $editing) { AddAlarmView(alarm: $0) }
        }
    }

    private var alarmHeroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let alarm = primaryAlarm {
                HStack(alignment: .center, spacing: 16) {
                    Button { editing = alarm } label: {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(alarmTimeDigits(alarm))
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(GhostTheme.textPrimary)
                            Text(alarmPeriod(alarm))
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(GhostTheme.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    GhostTheme.GhostAlarmToggle(
                        isOn: Binding(
                            get: { alarm.enabled },
                            set: { _ in Task { await store.toggle(alarm.id) } }
                        )
                    )
                }

                HStack {
                    Text("\(alarm.label) · \(alarm.repeats.title)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(GhostTheme.textSecondary)
                    Spacer()
                    Button { adding = true } label: {
                        Label("Add", systemImage: "plus.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(GhostTheme.purpleSoft)
                    }
                    .buttonStyle(.plain)
                }

                if store.state.alarms.count > 1 {
                    Divider().background(GhostTheme.hairline)
                    ForEach(store.state.alarms.filter { $0.id != alarm.id }) { item in
                        HStack {
                            Button { editing = item } label: {
                                Text("\(item.timeText) · \(item.label)")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(GhostTheme.textPrimary)
                            }
                            .buttonStyle(.plain)
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { item.enabled },
                                set: { _ in Task { await store.toggle(item.id) } }
                            ))
                            .labelsHidden()
                            .tint(GhostTheme.purple)
                            Button(role: .destructive) {
                                Task { await store.delete(item.id) }
                            } label: {
                                Image(systemName: "trash").font(.caption).foregroundStyle(GhostTheme.textMuted)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No wake-up alarm")
                            .font(.headline)
                            .foregroundStyle(GhostTheme.textPrimary)
                        Text("Set your morning wake time.")
                            .font(.caption)
                            .foregroundStyle(GhostTheme.textSecondary)
                    }
                    Spacer()
                    Button { adding = true } label: {
                        Text("Add Alarm")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(GhostTheme.purpleGradient, in: Capsule())
                    }
                    .buttonStyle(GhostTheme.GhostPressStyle())
                }
            }
        }
        .ghostCard(glow: true)
    }

    private var sleepMusicCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Sleep Music & Lock Screen", systemImage: "moon.zzz.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(GhostTheme.textPrimary)
                Spacer()
                if let playing = store.device.playing {
                    Text(playing)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(GhostTheme.purpleSoft)
                } else {
                    Button(action: openNightstand) {
                        Text("Nightstand Mode")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(GhostTheme.purpleSoft)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 8) {
                Picker("Sound", selection: $track) {
                    ForEach(GhostDevice.tracks, id: \.self) { Text($0).tag($0) }
                }
                .tint(GhostTheme.purpleSoft)

                Picker("Timer", selection: $minutes) {
                    ForEach([15, 30, 60], id: \.self) { Text("\($0)m").tag($0) }
                }
                .pickerStyle(.segmented)

                Button(store.device.playing == nil ? "Play" : "Stop") {
                    do {
                        if store.device.playing == nil {
                            try store.device.playSleep(track, minutes: minutes)
                        } else {
                            store.device.stopSleep()
                        }
                    } catch {
                        store.error = error.localizedDescription
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(GhostTheme.purpleGradient, in: Capsule())
                .buttonStyle(GhostTheme.GhostPressStyle())
            }
        }
        .ghostCard()
    }

    private func alarmTimeDigits(_ alarm: WakeAlarm) -> String {
        let h12 = alarm.hour % 12 == 0 ? 12 : alarm.hour % 12
        return String(format: "%d:%02d", h12, alarm.minute)
    }

    private func alarmPeriod(_ alarm: WakeAlarm) -> String {
        alarm.hour < 12 ? "AM" : "PM"
    }
}

struct WakeTabView: View {
    @Environment(AppStore.self) private var store
    var switchTab: (Int) -> Void = { _ in }
    var openNightstand: () -> Void = {}
    @State private var statusBanner: String?

    private var primaryAlarm: WakeAlarm? {
        store.state.alarms.first(where: \.enabled) ?? store.state.alarms.first
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                HStack {
                    Spacer()
                    Button(action: openNightstand) {
                        Label("Lock-Screen Saver", systemImage: "lock.display")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(GhostTheme.purpleSoft)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(GhostTheme.purple.opacity(0.18), in: Capsule())
                            .overlay(Capsule().strokeBorder(GhostTheme.purpleSoft.opacity(0.35)))
                    }
                    .buttonStyle(GhostTheme.GhostPressStyle())
                }
                .padding(.top, 10)

                Text("Good morning")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(GhostTheme.textSecondary)

                Text(displayTime)
                    .font(.system(size: 84, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(GhostTheme.textPrimary)

                Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.title3.weight(.medium))
                    .foregroundStyle(GhostTheme.textSecondary)

                Button {
                    try? store.device.say("Good morning! Let's make today great.")
                } label: {
                    GhostTheme.GhostMascot(
                        isSpeaking: store.device.speaking || store.isCoachSpeaking,
                        isSleeping: false,
                        size: 156
                    )
                }
                .buttonStyle(.plain)
                .padding(.vertical, 6)

                if let statusBanner {
                    Text(statusBanner)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(GhostTheme.purpleSoft)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(GhostTheme.purple.opacity(0.18), in: Capsule())
                }

                VStack(spacing: 14) {
                    GhostTheme.GhostPillButton(title: "I'm Awake", filled: true) {
                        store.markDone()
                        store.device.stopSleep()
                        statusBanner = "Morning check-in complete!"
                        try? store.device.say("Good morning! You're awake and ready.")
                    }

                    GhostTheme.GhostPillButton(title: "Snooze · 5 min", filled: false) {
                        Task {
                            await store.snooze(minutes: 5)
                            statusBanner = "Snoozed for 5 minutes"
                        }
                    }
                }
                .padding(.top, 4)

                HStack(spacing: 10) {
                    Image(systemName: "cloud.rain.fill")
                        .font(.title3)
                        .foregroundStyle(GhostTheme.purpleSoft)
                    Text("12°C · Rain today")
                        .font(.headline.weight(.medium))
                        .foregroundStyle(GhostTheme.textSecondary)
                }
                .padding(.top, 14)
            }
            .padding(24)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .ghostScreen(animated: true)
    }

    private var displayTime: String {
        if let alarm = primaryAlarm {
            let h12 = alarm.hour % 12 == 0 ? 12 : alarm.hour % 12
            return String(format: "%d:%02d", h12, alarm.minute)
        }
        return Date().formatted(.dateTime.hour(.defaultDigits(amPM: .omitted)).minute(.twoDigits))
    }
}

struct GhostNightstandView: View {
    @Environment(AppStore.self) private var store
    @Binding var isPresented: Bool
    @State private var keepScreenAwake = true
    @State private var ultraDimOLED = false
    @State private var selectedTrack = GhostDevice.tracks[0]

    private var primaryAlarm: WakeAlarm? {
        store.state.alarms.first(where: \.enabled) ?? store.state.alarms.first
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { context in
            let wave = GhostTheme.syncWave(at: context.date)
            let driftX = CGFloat(sin(context.date.timeIntervalSinceReferenceDate * 0.18)) * 10
            let driftY = CGFloat(cos(context.date.timeIntervalSinceReferenceDate * 0.14)) * 8

            ZStack {
                Color.black.ignoresSafeArea()

                GhostTheme.GhostAurora(animated: true, dimmed: true)
                    .opacity(ultraDimOLED ? 0.35 : 0.85)

                VStack(spacing: 24) {
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: keepScreenAwake ? "bolt.shield.fill" : "lock.fill")
                                .foregroundStyle(GhostTheme.purpleSoft)
                            Text(keepScreenAwake ? "Nightstand Saver · Awake" : "Lock-Screen Audio Mode")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(GhostTheme.textSecondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.06), in: Capsule())

                        Spacer()

                        Button {
                            ultraDimOLED.toggle()
                        } label: {
                            Image(systemName: ultraDimOLED ? "sun.min.fill" : "moon.stars.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(GhostTheme.purpleSoft)
                                .padding(10)
                                .background(Color.white.opacity(0.07), in: Circle())
                        }
                        .buttonStyle(.plain)

                        Button {
                            setIdleTimer(disabled: false)
                            isPresented = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(GhostTheme.textSecondary)
                                .padding(10)
                                .background(Color.white.opacity(0.07), in: Circle())
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    VStack(spacing: 10) {
                        Text(context.date.formatted(.dateTime.hour(.defaultDigits(amPM: .omitted)).minute(.twoDigits)))
                            .font(.system(size: 88, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white.opacity(ultraDimOLED ? 0.55 : 0.96), GhostTheme.purpleSoft.opacity(ultraDimOLED ? 0.45 : 0.88)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: GhostTheme.purple.opacity(0.35 + 0.20 * wave), radius: 22)

                        Text(context.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(GhostTheme.textSecondary.opacity(ultraDimOLED ? 0.55 : 0.85))

                        if let alarm = primaryAlarm {
                            Label("Wake \(alarm.timeText) · \(alarm.label)", systemImage: "alarm.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(GhostTheme.purpleSoft.opacity(ultraDimOLED ? 0.65 : 0.95))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(GhostTheme.purple.opacity(0.16), in: Capsule())
                                .padding(.top, 4)
                        }
                    }
                    .offset(x: driftX, y: driftY)

                    GhostTheme.GhostMascot(
                        isSpeaking: store.device.speaking,
                        isSleeping: true,
                        size: 138
                    )
                    .opacity(ultraDimOLED ? 0.65 : 1.0)
                    .offset(x: -driftX * 0.5, y: -driftY * 0.5)
                    .onTapGesture {
                        try? store.device.say("Rest easy. Ghost is watching your alarm.")
                    }

                    Spacer()

                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Button {
                                do {
                                    if store.device.playing == nil {
                                        try store.device.playSleep(selectedTrack, minutes: 45)
                                    } else {
                                        store.device.stopSleep()
                                    }
                                } catch {
                                    store.error = error.localizedDescription
                                }
                            } label: {
                                Label(
                                    store.device.playing == nil ? "Play Sleep Sound" : "Stop (\(store.device.playing ?? ""))",
                                    systemImage: store.device.playing == nil ? "play.fill" : "stop.fill"
                                )
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(GhostTheme.purpleGradient, in: Capsule())
                            }
                            .buttonStyle(GhostTheme.GhostPressStyle())

                            Button {
                                keepScreenAwake.toggle()
                                setIdleTimer(disabled: keepScreenAwake)
                            } label: {
                                Label(
                                    keepScreenAwake ? "Keep Awake: ON" : "Keep Awake: OFF",
                                    systemImage: keepScreenAwake ? "iphone.radiowaves.left.and.right" : "lock.iphone"
                                )
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(GhostTheme.purpleSoft)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.08), in: Capsule())
                            }
                            .buttonStyle(GhostTheme.GhostPressStyle())
                        }

                        Text("Sleep audio continues when you lock your iPhone or iPad, or leave Saver on as your bedside clock.")
                            .font(.caption2)
                            .foregroundStyle(GhostTheme.textMuted)
                            .multilineTextAlignment(.center)
                    }
                    .opacity(ultraDimOLED ? 0.55 : 0.95)
                }
                .padding(24)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            setIdleTimer(disabled: keepScreenAwake)
        }
        .onDisappear {
            setIdleTimer(disabled: false)
        }
    }

    private func setIdleTimer(disabled: Bool) {
        #if canImport(UIKit)
        UIApplication.shared.isIdleTimerDisabled = disabled
        #endif
    }
}
