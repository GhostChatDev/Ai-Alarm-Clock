import SwiftUI

/// Cute bedside saving mode: one shared timeline keeps the sky, ghost, and bubbles in sync.
/// iOS cannot draw over the system Lock Screen; this is an in-app bedside/StandBy-style view.
struct NightstandModeView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("nightstand.keepAwake") private var keepAwake = true
    @AppStorage("nightstand.dreamBubbles") private var dreamBubbles = true
    @State private var dimmed = true
    @State private var showControls = true
    @State private var clock = Date()
    @State private var hideTask: Task<Void, Never>?

    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter
    }()

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 60 : (dimmed ? 1.0 / 20.0 : 1.0 / 30.0))) { context in
            let time = reduceMotion ? 0.0 : context.date.timeIntervalSinceReferenceDate
            GeometryReader { proxy in
                let size = proxy.size
                ZStack {
                    Color.black.ignoresSafeArea()
                    GhostTheme.GhostAurora(animated: !reduceMotion)
                        .opacity(dimmed ? 0.10 : 0.24)
                        .ignoresSafeArea()
                    if dreamBubbles && !reduceMotion {
                        ForEach(0..<6, id: \.self) { index in
                            DreamBubble(index: index, time: time, size: size)
                        }
                        .opacity(dimmed ? 0.3 : 0.65)
                        .allowsHitTesting(false)
                    }
                    Group {
                        if size.width > size.height {
                            HStack(spacing: 36) {
                                clockBlock(time)
                                Spacer()
                                ghostBlock(time)
                            }
                            .padding(.horizontal, 48)
                        } else {
                            VStack(spacing: 12) {
                                clockBlock(time)
                                Spacer()
                                ghostBlock(time)
                            }
                            .padding(.vertical, 36)
                        }
                    }
                    .opacity(dimmed ? 0.62 : 1)
                    .animation(.easeInOut(duration: 1.2), value: dimmed)

                    controls
                }
                .contentShape(Rectangle())
                .onTapGesture { toggleDim() }
                .statusBarHidden(dimmed)
                .persistentSystemOverlays(dimmed ? .hidden : .automatic)
            }
        }
        .ghostWallpaperDimmed(true)
        .onAppear {
            updateIdleTimer()
            clock = Date()
        }
        .onChange(of: keepAwake) { _, _ in updateIdleTimer() }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { date in
            clock = date
        }
        .onDisappear {
            hideTask?.cancel()
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private func clockBlock(_ time: TimeInterval) -> some View {
        VStack(spacing: 4) {
            Text(clock.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 110, weight: .thin, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.45)
                .foregroundStyle(GhostTheme.purpleSoft)
                .shadow(color: GhostTheme.purple.opacity(0.55 + 0.12 * sin(time * 0.5)), radius: 28)
            if let alarm = store.nextAlarm {
                Text(alarm.date, format: .dateTime.weekday(.abbreviated).hour().minute())
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .labelStyle(.titleAndIcon)
            }
            Text(clock, format: .dateTime.weekday(.wide).month().day())
                .font(.caption)
                .foregroundStyle(.white.opacity(0.42))
        }
    }

    private func ghostBlock(_ time: TimeInterval) -> some View {
        VStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                GhostTheme.GhostMascot(mood: .sleeping, size: 180)
                SleepZzz(time: time)
                    .offset(x: 12, y: -12)
            }
            Text("shh… your ghost is dreaming")
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.48))
        }
    }

    private var controls: some View {
        VStack {
            HStack {
                Spacer()
                if showControls {
                    HStack(spacing: 14) {
                        Button { keepAwake.toggle() } label: {
                            Label(keepAwake ? "Awake" : "Auto-lock", systemImage: keepAwake ? "sun.max.fill" : "moon.fill")
                                .font(.caption.weight(.semibold))
                        }
                        Button { dreamBubbles.toggle() } label: {
                            Image(systemName: dreamBubbles ? "sparkles" : "sparkle")
                                .font(.caption)
                        }
                    }
                    .foregroundStyle(GhostTheme.purpleSoft)
                    .padding(14)
                    .background(.ultraThinMaterial, in: Capsule())
                    .environment(\.colorScheme, .dark)
                    .transition(.opacity)
                }
            }
            Spacer()
            if showControls {
                Text("Tap to \(dimmed ? "brighten" : "dim") · Sweet dreams 🌙")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.38))
                    .padding(.bottom, 12)
            }
        }
        .padding(20)
    }

    private func toggleDim() {
        dimmed.toggle()
        showControls = true
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            await MainActor.run { withAnimation { showControls = false } }
        }
    }

    private func updateIdleTimer() {
        UIApplication.shared.isIdleTimerDisabled = keepAwake
    }
}

private struct SleepZzz: View {
    let time: TimeInterval
    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                let phase = (time / 3.2 + Double(index) / 3).truncatingRemainder(dividingBy: 1)
                Text("z")
                    .font(.system(size: CGFloat(14 + index * 6), weight: .bold, design: .rounded))
                    .foregroundStyle(GhostTheme.purpleSoft.opacity(0.8 * (1 - phase)))
                    .offset(x: CGFloat(index) * 12, y: 10 - phase * 64)
            }
        }
    }
}

private struct DreamBubble: View {
    let index: Int
    let time: TimeInterval
    let size: CGSize
    var body: some View {
        let speed = 18.0 + Double(index) * 6
        let x = (Double(index) * 137.5).truncatingRemainder(dividingBy: max(size.width, 1))
        let travel = size.height + 120
        let y = size.height + 40 - (time * speed + Double(index) * 90).truncatingRemainder(dividingBy: travel)
        let radius = CGFloat(6 + (index % 3) * 5)
        Circle()
            .fill(GhostTheme.purpleSoft.opacity(0.16))
            .overlay(Circle().strokeBorder(GhostTheme.purpleSoft.opacity(0.22), lineWidth: 1))
            .frame(width: radius * 2, height: radius * 2)
            .position(x: x + sin(time * 0.4 + Double(index)) * 18, y: y)
    }
}
