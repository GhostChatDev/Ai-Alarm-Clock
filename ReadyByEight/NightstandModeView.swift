import SwiftUI

/// Cute "Lock-Screen Saving Mode": a dim OLED bedside clock with a sleeping ghost.
/// Works great in landscape on a nightstand. iOS cannot draw over the real Lock
/// Screen (no public API), so this is an in-app always-on bedside mode instead.
/// Enable "Keep Screen Awake" and leave the app open on this screen.
struct NightstandModeView: View {
    @Environment(AppStore.self) private var store
    @AppStorage("nightstand.keepAwake") private var keepAwake = true
    @AppStorage("nightstand.dreamBubbles") private var dreamBubbles = true
    @State private var dimmed = false
    @State private var showControls = true

    var body: some View {
        GeometryReader { geo in
            let landscape = geo.size.width > geo.size.height
            ZStack {
                // Deep OLED black with a faint breathing aura so pixels barely move.
                Color.black.ignoresSafeArea()
                GhostTheme.GhostAurora(animated: true)
                    .opacity(dimmed ? 0.10 : 0.32)
                    .ignoresSafeArea()

                if dreamBubbles {
                    TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { context in
                        let t = context.date.timeIntervalSinceReferenceDate
                        ForEach(0..<6, id: \.self) { i in
                            DreamBubble(index: i, time: t, size: geo.size)
                        }
                    }
                    .opacity(dimmed ? 0.25 : 0.7)
                    .allowsHitTesting(false)
                }

                Group {
                    if landscape {
                        HStack(spacing: 30) {
                            clockBlock
                            Spacer()
                            ghostBlock
                        }
                        .padding(.horizontal, 40)
                    } else {
                        VStack(spacing: 8) {
                            clockBlock
                            Spacer(minLength: 0)
                            ghostBlock
                        }
                        .padding(.vertical, 30)
                    }
                }
                .opacity(dimmed ? 0.55 : 1.0)
                .animation(.easeInOut(duration: 1.2), value: dimmed)

                VStack {
                    HStack {
                        Spacer()
                        if showControls {
                            controlPanel
                                .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .topTrailing)))
                        }
                    }
                    Spacer()
                    if showControls {
                        Text("Tap anywhere to \(dimmed ? "brighten" : "dim") · Sweet dreams 🌙")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.35))
                            .padding(.bottom, 14)
                    }
                }
                .padding(20)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    dimmed.toggle()
                    showControls = true
                }
                // Auto-hide controls again shortly after a tap.
                Task {
                    try? await Task.sleep(for: .seconds(4))
                    withAnimation { showControls = false }
                }
            }
            .statusBarHidden(dimmed)
            .persistentSystemOverlays(dimmed ? .hidden : .automatic)
        }
        .onAppear { updateIdleTimer() }
        .onChange(of: keepAwake) { _, _ in updateIdleTimer() }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    // MARK: - Clock
    private var clockBlock: some View {
        VStack(spacing: 2) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(context.date, format: .dateTime.hour().minute())
                    .font(.system(size: 96, weight: .thin, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(GhostTheme.purpleSoft)
                    .shadow(color: GhostTheme.purple.opacity(0.55), radius: 26)
            }
            if let next = store.nextAlarm {
                HStack(spacing: 6) {
                    Image(systemName: "alarm.fill")
                    Text(next.date, format: .dateTime.weekday(.abbreviated).hour().minute())
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.55))
            }
            Text(Date.now, format: .dateTime.weekday(.wide).month().day())
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    // MARK: - Sleeping ghost
    private var ghostBlock: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                GhostTheme.GhostMascot(mood: .sleeping, size: 150)
                SleepZzz()
                    .offset(x: 6, y: -14)
            }
            Text("shh… your ghost is dreaming")
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.45))
        }
    }

    // MARK: - Controls
    private var controlPanel: some View {
        VStack(alignment: .trailing, spacing: 12) {
            Toggle(isOn: $keepAwake) {
                Label("Keep Awake", systemImage: "sun.max.fill")
                    .font(.caption.weight(.semibold))
            }
            .toggleStyle(.switch)
            .tint(GhostTheme.purple)
            .labelsHidden()
            .overlay(alignment: .leading) {
                Text(keepAwake ? "Awake" : "Auto-lock")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
                    .offset(x: -70)
            }
            Toggle(isOn: $dreamBubbles) {
                EmptyView()
            }
            .labelsHidden()
            .toggleStyle(.button)
            .buttonStyle(.plain)
            .overlay {
                Button {
                    dreamBubbles.toggle()
                } label: {
                    Image(systemName: dreamBubbles ? "sparkles" : "sparkle")
                        .font(.caption)
                        .foregroundStyle(GhostTheme.purpleSoft)
                        .padding(8)
                        .background(.white.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .environment(\.colorScheme, .dark)
    }

    private func updateIdleTimer() {
        UIApplication.shared.isIdleTimerDisabled = keepAwake
    }
}

/// Floating "z Z z" that drift up from the sleeping ghost.
private struct SleepZzz: View {
    @State private var rise = false
    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Text("z")
                    .font(.system(size: CGFloat(14 + i * 6), weight: .bold, design: .rounded))
                    .foregroundStyle(GhostTheme.purpleSoft.opacity(0.85 - Double(i) * 0.18))
                    .offset(x: CGFloat(i) * 12, y: rise ? -CGFloat(30 + i * 14) : CGFloat(8 - i * 6))
                    .opacity(rise ? 0 : 1)
                    .animation(
                        .easeInOut(duration: 2.4)
                        .repeatForever(autoreverses: false)
                        .delay(Double(i) * 0.8),
                        value: rise
                    )
            }
        }
        .onAppear { rise = true }
    }
}

/// Soft dream bubbles that float up the nightstand screen.
private struct DreamBubble: View {
    let index: Int
    let time: TimeInterval
    let size: CGSize
    var body: some View {
        let speed = 18.0 + Double(index) * 6
        let x = (Double(index) * 137.5).truncatingRemainder(dividingBy: max(size.width, 1))
        let travel = size.height + 120
        let y = size.height + 40 - (time * speed + Double(index) * 90).truncatingRemainder(dividingBy: travel)
        let r = CGFloat(6 + (index % 3) * 5)
        Circle()
            .fill(GhostTheme.purpleSoft.opacity(0.16))
            .overlay(Circle().strokeBorder(GhostTheme.purpleSoft.opacity(0.22), lineWidth: 1))
            .frame(width: r * 2, height: r * 2)
            .position(x: x + sin(time * 0.4 + Double(index)) * 18, y: y)
    }
}
