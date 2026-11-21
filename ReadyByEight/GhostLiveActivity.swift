import SwiftUI
#if canImport(ActivityKit)
import ActivityKit

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
struct GhostLiveActivityPill: View {
    @Environment(AppStore.self) private var store
    @State private var isExpanded = false

    var body: some View {
        let sound = store.soundEngine
        let tracker = store.sleepTracker
        let nextAlarmText = store.nextScheduledAlarm?.summary ?? "No alarm set"

        VStack(spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Circle()
                        .fill(sound.isPlaying || tracker.isTrackingOvernight ? GhostTheme.mint : GhostTheme.lavender)
                        .frame(width: 8, height: 8)
                        .shadow(color: GhostTheme.lavender, radius: 6)

                    Text(statusHeadline(sound: sound, tracker: tracker, nextAlarmText: nextAlarmText))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(GhostTheme.textPrimary)
                        .lineLimit(1)

                    // Mini animated waveform bars
                    HStack(spacing: 2.5) {
                        ForEach(0..<4, id: \.self) { idx in
                            Capsule()
                                .fill(GhostTheme.lavender)
                                .frame(
                                    width: 2.5,
                                    height: sound.isPlaying
                                        ? CGFloat(5 + ((idx * 3 + Int(sound.currentAmplitude * 10)) % 9))
                                        : 5
                                )
                        }
                    }
                    .frame(height: 13)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(GhostTheme.textSecondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(red: 0.04, green: 0.03, blue: 0.09).opacity(0.90), in: Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(GhostTheme.lavender.opacity(0.38), lineWidth: 1)
                )
                .shadow(color: GhostTheme.purpleGlow.opacity(0.28), radius: 14, y: 4)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Ghost Live Session Island")

            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label(sound.activePreset.rawValue, systemImage: sound.activePreset.icon)
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundStyle(GhostTheme.lavender)
                        Spacer()
                        Text(tracker.isTrackingOvernight ? "Stage: \(tracker.currentLiveStage.rawValue)" : "Score \(tracker.report.sleepScore)")
                            .font(.system(.caption2, design: .rounded).weight(.semibold))
                            .foregroundStyle(GhostTheme.mint)
                    }

                    HStack(spacing: 8) {
                        Button {
                            sound.toggle(minutes: store.sleepMinutes)
                        } label: {
                            Label(sound.isPlaying ? "Pause Synth" : "Play Synth", systemImage: sound.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(.caption, design: .rounded).weight(.bold))
                        }
                        .buttonStyle(GhostPillButtonStyle(filled: true))

                        Button {
                            tracker.toggleOvernightTracking(targetAlarmDate: store.nextScheduledAlarm?.date)
                        } label: {
                            Label(tracker.isTrackingOvernight ? "Stop Track" : "Track Sleep", systemImage: "bed.double.fill")
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                        }
                        .buttonStyle(GhostPillButtonStyle(filled: false))

                        Button {
                            store.wallpaperTheme = store.wallpaperTheme.next
                        } label: {
                            Label(store.wallpaperTheme.title, systemImage: "sparkles")
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                        }
                        .buttonStyle(GhostPillButtonStyle(filled: false))
                    }
                }
                .padding(12)
                .frame(maxWidth: 420)
                .background(GhostTheme.cardTop.opacity(0.95), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(GhostTheme.lavender.opacity(0.32), lineWidth: 1)
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private func statusHeadline(sound: SleepSoundEngine, tracker: SleepTrackerManager, nextAlarmText: String) -> String {
        if sound.isPlaying {
            let mins = max(1, sound.remainingSeconds / 60)
            return "Ghost Live · \(sound.activePreset.rawValue) (\(mins)m)"
        }
        if tracker.isTrackingOvernight {
            return "Tracking Sleep · \(tracker.currentLiveStage.rawValue) Stage"
        }
        return "Ghost Live · Wake \(nextAlarmText)"
    }
}
