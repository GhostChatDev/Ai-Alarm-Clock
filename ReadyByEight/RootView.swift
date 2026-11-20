import SwiftUI

struct RootView: View {
    @Environment(AppStore.self) private var store
    @State private var tab = 0

    var body: some View {
        Group {
            switch tab {
            case 0: HomeView(switchTab: { tab = $0 })
            case 1: WakeTabView(switchTab: { tab = $0 })
            case 2: NightstandModeView()
            default: SettingsTabView()
            }
        }
        .ghostScreen(animated: true)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(spacing: 0) {
                tabButton(0, "Home", "house.fill")
                tabButton(1, "Wake", "alarm.fill")
                tabButton(2, "Nightstand", "moon.stars.fill")
                tabButton(3, "Settings", "gearshape.fill")
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .background(GhostTheme.ink.opacity(0.96))
            .overlay(alignment: .top) { Rectangle().fill(GhostTheme.hairline).frame(height: 1) }
        }
        .alert("Something needs attention", isPresented: Binding(
            get: { store.error != nil }, set: { if !$0 { store.error = nil } }
        )) {
            Button("OK") { store.error = nil }
        } message: { Text(store.error ?? "") }
        .task { await store.refresh() }
    }

    private func tabButton(_ id: Int, _ title: String, _ icon: String) -> some View {
        Button { tab = id } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: tab == id ? .bold : .regular))
                    .symbolEffect(.bounce, value: tab == id)
                Text(title).font(.caption2.weight(.medium))
            }
            .foregroundStyle(tab == id ? GhostTheme.purple : GhostTheme.textSecondary)
            .frame(maxWidth: .infinity).padding(.vertical, 8)
            .contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
}

struct HomeView: View {
    @Environment(AppStore.self) private var store
    var switchTab: (Int) -> Void
    @State private var editingAlarm: WakeAlarm?
    @State private var addingAlarm = false
    @State private var sleepMinutes = 30

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Good evening")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(GhostTheme.textSecondary)
                        Text("Ghost Mascot")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(GhostTheme.textPrimary)
                    }
                    Spacer()
                    Button {
                        try? store.device.say("Good evening! Sweet dreams.")
                    } label: {
                        GhostTheme.GhostMascot(isSpeaking: store.device.speaking, size: 48)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 20)

                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Image(systemName: "bell.and.waves.left.and.right.fill")
                            .foregroundStyle(GhostTheme.purple)
                        Text("Wake-Up Alarm")
                            .font(.headline.weight(.semibold))
                        Spacer()
                        GhostTheme.GhostAlarmToggle(isOn: store.nextAlarm?.enabled ?? false)
                    }
                    if let alarm = store.nextAlarm {
                        HStack(alignment: .firstTextBaseline) {
                            Text(alarm.displayDate, format: .dateTime.hour().minute())
                                .font(.system(size: 58, weight: .bold, design: .rounded))
                                .contentTransition(.numericText())
                            Text(alarm.displayDate, format: .dateTime.hour(.twoDigits(amPM: .omitted)).minute())
                                .hidden()
                        }
                        .foregroundStyle(.white)
                        HStack(spacing: 12) {
                            Image(systemName: "calendar")
                            Text(alarm.label).font(.subheadline)
                            Spacer()
                            Text(alarm.rule.rawValue)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(GhostTheme.purple.opacity(0.22), in: Capsule())
                                .foregroundStyle(GhostTheme.purple)
                        }
                        .foregroundStyle(GhostTheme.textSecondary)
                        HStack(spacing: 12) {
                            Button("Set Alarm") { editingAlarm = alarm }
                                .buttonStyle(.borderedProminent).tint(GhostTheme.purple)
                            if let first = store.state.alarms.first {
                                Button {
                                    Task { await store.toggle(first) }
                                } label: {
                                    Text(store.nextAlarm?.enabled == true ? "Turn Off" : "Turn On")
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    } else {
                        Button { addingAlarm = true } label: {
                            Label("Create your first alarm", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent).tint(GhostTheme.purple)
                    }
                }
                .ghostCard(glow: true)

                Button { switchTab(2) } label: {
                    HStack(spacing: 16) {
                        Image(systemName: "moon.stars.fill")
                            .font(.title2).foregroundStyle(GhostTheme.purpleSoft)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Nightstand Saving Mode")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(GhostTheme.textPrimary)
                            Text("A sleepy ghost keeps you company")
                                .font(.caption)
                                .foregroundStyle(GhostTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(GhostTheme.textSecondary)
                    }
                }
                .buttonStyle(.plain)
                .ghostCard()

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "cloud.rain.fill").font(.title3)
                        VStack(alignment: .leading) {
                            Text("Tonight").font(.headline.weight(.semibold))
                            Text("Light rain · 12°C").font(.caption).opacity(0.8)
                        }
                        Spacer()
                        Text("19°").font(.system(size: 36, weight: .light, design: .rounded))
                    }
                    Text("Sleep well. Your ghost will wake you gently.")
                        .font(.subheadline).opacity(0.85)
                }
                .foregroundStyle(.white)
                .padding(22)
                .background(GhostTheme.weatherGradient, in: RoundedRectangle(cornerRadius: 24))

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "moon.zzz.fill").foregroundStyle(GhostTheme.purple)
                        Text("Sleep Music").font(.headline.weight(.semibold))
                        Spacer()
                        if store.device.playing != nil {
                            EqualizerBars(color: GhostTheme.purpleSoft)
                        }
                    }
                    HStack(spacing: 10) {
                        ForEach([15, 30, 60], id: \.self) { min in
                            Button {
                                sleepMinutes = min
                            } label: {
                                Text("\(min)m")
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(sleepMinutes == min ? GhostTheme.purpleSoft : Color.white.opacity(0.06), in: Capsule())
                                    .foregroundStyle(sleepMinutes == min ? GhostTheme.ink : GhostTheme.textSecondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    ForEach(GhostDevice.tracks + (store.device.hasMusic ? ["Imported music"] : []), id: \.self) { track in
                        HStack {
                            Button {
                                if store.device.playing == track { store.device.stopMusic() }
                                else {
                                    do { try store.device.play(track, minutes: sleepMinutes) }
                                    catch { store.error = error.localizedDescription }
                                }
                            } label: {
                                Image(systemName: store.device.playing == track ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.title2)
                                    .contentTransition(.symbolEffect(.replace))
                            }
                            Text(track).font(.subheadline.weight(.medium))
                            Spacer()
                            if store.device.playing == track {
                                Text("Playing").font(.caption2).foregroundStyle(GhostTheme.purple)
                            }
                        }
                    }
                }
                .ghostCard()

                Text("Your ghost is resting. Tap to say hello.")
                    .font(.caption).foregroundStyle(GhostTheme.textSecondary)
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: 640).frame(maxWidth: .infinity)
        }
        .sheet(item: $editingAlarm) { alarm in AddAlarmView(alarm: alarm) }
        .sheet(isPresented: $addingAlarm) { AddAlarmView() }
    }
}

struct EqualizerBars: View {
    var color: Color = GhostTheme.purple
    @State private var animating = false
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<4, id: \.self) { i in
                Capsule()
                    .fill(color)
                    .frame(width: 3, height: animating ? CGFloat([14, 22, 10, 18][i]) : 5)
                    .animation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true).delay(Double(i) * 0.12), value: animating)
            }
        }
        .onAppear { animating = true }
    }
}

struct WakeTabView: View {
    @Environment(AppStore.self) private var store
    var switchTab: (Int) -> Void
    @State private var snoozeBanner = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 26) {
                GhostTheme.GhostMascot(mood: .awake, size: 120)
                    .padding(.top, 30)
                VStack(spacing: 6) {
                    Text("Good morning")
                        .font(.title.weight(.bold))
                    Text(Date.now, format: .dateTime.weekday(.wide).month().day())
                        .foregroundStyle(GhostTheme.textSecondary)
                }
                Text(Date.now, style: .time)
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .foregroundStyle(GhostTheme.textPrimary)

                if !snoozeBanner.isEmpty {
                    Text(snoozeBanner)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 18).padding(.vertical, 10)
                        .background(GhostTheme.purple.opacity(0.22), in: Capsule())
                        .foregroundStyle(GhostTheme.purpleSoft)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                VStack(spacing: 14) {
                    Button {
                        store.device.stopMusic()
                        store.cancelSnooze()
                        if !store.challengeCompleted { store.completeChallenge() }
                        try? store.device.say("Awesome job waking up! Sleepy ghost says hi.")
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
                                withAnimation { snoozeBanner = "Snoozed for 5 minutes · Reminder scheduled" }
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
        .ghostScreen(animated: true)
    }
}
