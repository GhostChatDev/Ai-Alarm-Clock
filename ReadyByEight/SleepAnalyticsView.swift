import SwiftUI
import Charts

struct SleepAnalyticsView: View {
    @Environment(AppStore.self) private var store
    @Environment(SleepTrackerManager.self) private var tracker

    var body: some View {
        let report = tracker.report

        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("REM & Deep Sleep Tracker", systemImage: "waveform.path.ecg.rectangle.fill")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(GhostTheme.textPrimary)
                Spacer()
                Text("Score \(report.sleepScore)")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(GhostTheme.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(GhostTheme.purple.opacity(0.28), in: Capsule())
                    .overlay(Capsule().strokeBorder(GhostTheme.purpleSoft.opacity(0.45), lineWidth: 1))
            }

            Text(tracker.statusBanner)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(GhostTheme.textSecondary)

            // 4 Metric cards: Score, REM, Deep, Efficiency
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                metricTile(title: "Score", value: "\(report.sleepScore)", sub: "Optimal", color: GhostTheme.purpleSoft)
                metricTile(title: "REM", value: SleepNightReport.formatDuration(report.remMinutes), sub: "\(report.remPercent)% dream", color: SleepStageKind.rem.color)
                metricTile(title: "Deep", value: SleepNightReport.formatDuration(report.deepMinutes), sub: "\(report.deepPercent)% restore", color: SleepStageKind.deep.color)
                metricTile(title: "Efficiency", value: "\(report.efficiencyPercent)%", sub: SleepNightReport.formatDuration(report.totalAsleepMinutes), color: SleepStageKind.core.color)
            }

            // Sleep Stages Hypnogram Chart
            Chart {
                ForEach(report.samples) { sample in
                    BarMark(
                        xStart: .value("Start", sample.startDate),
                        xEnd: .value("End", sample.endDate),
                        y: .value("Stage", sample.stage.rawValue)
                    )
                    .foregroundStyle(sample.stage.color.gradient)
                    .cornerRadius(4)
                }
            }
            .chartYScale(domain: ["Awake", "REM", "Core", "Deep"])
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: 2)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3]))
                        .foregroundStyle(Color.white.opacity(0.10))
                    AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)))
                        .foregroundStyle(GhostTheme.textMuted)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .foregroundStyle(GhostTheme.textSecondary)
                }
            }
            .frame(height: 155)
            .padding(10)
            .background(Color.black.opacity(0.26), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            // Smart Wake Window toggle
            Toggle(isOn: Binding(
                get: { tracker.smartWakeEnabled },
                set: { tracker.smartWakeEnabled = $0 }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Smart Wake: 20m light-sleep window")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(GhostTheme.textPrimary)
                    Text("Rings gently when exiting Deep/REM near your wake alarm")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(GhostTheme.textSecondary)
                }
            }
            .toggleStyle(GhostTheme.GhostSwitchStyle())

            if let smartMsg = tracker.smartWakeTriggeredMessage {
                Text(smartMsg)
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundStyle(GhostTheme.mint)
            }

            // Actions: Track Tonight, Simulate 8h Data, Sync Apple Health
            HStack(spacing: 8) {
                Button {
                    let target = store.nextAlarm?.date
                    tracker.toggleOvernightTracking(targetAlarmDate: target)
                } label: {
                    Label(
                        tracker.isTrackingOvernight ? "Stop Tracking" : "Track Tonight",
                        systemImage: tracker.isTrackingOvernight ? "stop.circle.fill" : "bed.double.fill"
                    )
                    .font(.system(.caption, design: .rounded).weight(.bold))
                }
                .buttonStyle(GhostTheme.GhostPillButtonStyle(filled: true))

                Button {
                    tracker.simulateLastNight()
                } label: {
                    Label("Simulate 8h", systemImage: "wand.and.stars")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                }
                .buttonStyle(GhostTheme.GhostPillButtonStyle(filled: false))

                Button {
                    Task { await tracker.syncFromHealthKit() }
                } label: {
                    Label("HealthKit", systemImage: "heart.text.square.fill")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                }
                .buttonStyle(GhostTheme.GhostPillButtonStyle(filled: false))
            }
        }
        .ghostCard(glow: tracker.isTrackingOvernight)
        .accessibilityElement(children: .contain)
    }

    private func metricTile(title: String, value: String, sub: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(GhostTheme.textSecondary)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(color)
                .minimumScaleFactor(0.75)
                .lineLimit(1)
            Text(sub)
                .font(.system(size: 9.5, weight: .medium, design: .rounded))
                .foregroundStyle(GhostTheme.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(color.opacity(0.28), lineWidth: 1)
        )
    }
}
