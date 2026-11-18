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
