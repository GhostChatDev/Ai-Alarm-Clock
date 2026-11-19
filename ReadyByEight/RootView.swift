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
    @State private var showingNightTip = false

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
