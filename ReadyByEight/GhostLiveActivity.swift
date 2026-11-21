import SwiftUI
#if canImport(ActivityKit)
import ActivityKit

/// Live Activity attributes for the Lock Screen / StandBy banner.
/// The widget extension rendering this lives in a separate target; this struct is shared.
struct GhostSleepAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var modeTitle: String
        var subtitle: String
        var stageLabel: String
        var isPlayingSound: Bool
    }
    var sessionName: String
}
#endif

/// Sleek Dynamic-Island-style floating Live Session Pill HUD at the top of the app.
/// Expands on tap to control procedural sleep soundscapes, active sleep tracking, and alarm countdowns.
struct GhostLiveSessionPill: View {
    let isPlaying: Bool
    let isTracking: Bool
    let stageLabel: String
    let presetLabel: String
    let remainingSeconds: Int
    let soundAction: () -> Void
    let sleepAction: () -> Void
    @Environment(AppStore.self) private var store
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Circle()
                        .fill(isPlaying || isTracking ? GhostTheme.mint : GhostTheme.purple)
                        .frame(width: 8, height: 8)
                        .shadow(color: GhostTheme.purple.opacity(0.8), radius: 5)
                    if isPlaying {
                        EqualizerBars(color: GhostTheme.purpleSoft)
                    }
                    Text(title)
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .lineLimit(1)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2.weight(.bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(Color.black.opacity(0.55), in: Capsule())
                .overlay(Capsule().strokeBorder(GhostTheme.purple.opacity(0.5), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.top, 6)

            if isExpanded {
                HStack(spacing: 12) {
                    Button(action: soundAction) {
                        Label(isPlaying ? "Mixer" : "Play sound", systemImage: "waveform")
                    }
                    Button(action: sleepAction) {
                        Label(isTracking ? "Sleep report" : "Sleep", systemImage: "bed.double.fill")
                    }
                    if let next = store.nextAlarm {
                        Label(next.date, format: .dateTime.hour().minute())
                            .labelStyle(.titleOnly)
                            .font(.caption2)
                            .foregroundStyle(GhostTheme.textSecondary)
                    }
                }
                .buttonStyle(.bordered)
                .tint(GhostTheme.purple)
                .controlSize(.small)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .environment(\.colorScheme, .dark)
    }

    private var title: String {
        if isPlaying {
            let mins = remainingSeconds / 60
            return "Ghost Live · \(presetLabel) (\(mins)m)"
        }
        if isTracking {
            return "Tracking Sleep · \(stageLabel) Stage"
        }
        if let next = store.nextAlarm {
            return "Ghost Live · Wake \(next.date, format: .dateTime.hour().minute())"
        }
        return "Ghost Live"
    }
}
