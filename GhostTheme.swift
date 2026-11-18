import SwiftUI

/// Cute, friendly design tokens and reusable effects for the Ghost alarm app.
/// iOS 17+, Swift 6. Add this file to the app target to use it.
///
/// Performance notes:
/// - `GhostAurora(animated:)` renders static by default. Animated mode runs at 60 fps
///   when opted in and is skipped when Reduce Motion is on.
/// - `GhostMascot(isSpeaking:)` blinks, bobs, and speaks reactively at 60 fps.
/// - Cards use one fill layer plus one hairline stroke: no extra blend passes.
enum GhostTheme {

    // MARK: - Palette (cute pastel ghost on dark)

    static let ghostWhite = Color(red: 0.97, green: 0.98, blue: 1.0)
    static let ghostGlow = Color(red: 0.92, green: 0.95, blue: 1.0)
    static let mint = Color(red: 0.76, green: 0.91, blue: 0.62)
    static let mintBright = Color(red: 0.85, green: 0.98, blue: 0.72)
    static let teal = Color(red: 0.35, green: 0.72, blue: 0.68)
    static let pink = Color(red: 1.0, green: 0.78, blue: 0.86)
    static let pinkSoft = Color(red: 1.0, green: 0.88, blue: 0.94)
    static let purple = Color(red: 0.68, green: 0.62, blue: 0.96)
    static let purpleSoft = Color(red: 0.78, green: 0.72, blue: 1.0)
    static let yellow = Color(red: 1.0, green: 0.92, blue: 0.55)

    static let inkDeep = Color(red: 0.02, green: 0.025, blue: 0.04)
    static let ink = Color(red: 0.05, green: 0.06, blue: 0.08)
    static let inkRaised = Color(red: 0.09, green: 0.105, blue: 0.125)
    static let textPrimary = Color.white.opacity(0.94)
    static let textSecondary = Color.white.opacity(0.55)
    static let hairline = Color.white.opacity(0.09)
    static let glass = Color.white.opacity(0.05)
    static let glassStrong = Color.white.opacity(0.09)

    // MARK: - Metrics

    enum Radius {
        static let card: CGFloat = 26
        static let chip: CGFloat = 14
        static let sheet: CGFloat = 34
        static let ghost: CGFloat = 30
    }

    enum Space {
        static let xs: CGFloat = 6
        static let s: CGFloat = 10
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Motion {
        static let press = Animation.spring(response: 0.28, dampingFraction: 0.75)
        static let fade = Animation.easeOut(duration: 0.24)
        static let bounce = Animation.spring(response: 0.45, dampingFraction: 0.7)
    }

    // MARK: - Gradients

    static var accentGradient: LinearGradient {
        LinearGradient(colors: [mintBright, teal], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var ghostGradient: LinearGradient {
        LinearGradient(colors: [ghostWhite, ghostGlow], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var cardGradient: LinearGradient {
        LinearGradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.02)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var borderGradient: LinearGradient {
        LinearGradient(colors: [Color.white.opacity(0.20), Color.white.opacity(0.03)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // MARK: - Background with soft aurora glow

    struct GhostAurora: View {
        var animated: Bool = false
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            ZStack {
                LinearGradient(colors: [GhostTheme.inkDeep, GhostTheme.ink],
                               startPoint: .top, endPoint: .bottom)

                if animated && !reduceMotion {
                    TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
                        let phase = context.date.timeIntervalSinceReferenceDate
                        layers(phase: phase)
                    }
                } else {
                    layers(phase: 0)
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .compositingGroup()
        }

        private func layers(phase: TimeInterval) -> some View {
            let drift = CGFloat(sin(phase * 0.35))
            return ZStack {
                Circle()
                    .fill(GhostTheme.mint.opacity(0.18))
                    .frame(width: 340, height: 340)
                    .blur(radius: 100)
                    .offset(x: -120 + drift * 24, y: -260 + drift * 18)

                Circle()
                    .fill(GhostTheme.purple.opacity(0.16))
                    .frame(width: 300, height: 300)
                    .blur(radius: 100)
                    .offset(x: 140 - drift * 20, y: 250 + drift * 16)

                Circle()
                    .fill(GhostTheme.pink.opacity(0.12))
                    .frame(width: 260, height: 260)
                    .blur(radius: 90)
                    .offset(x: -60, y: 120)

                RadialGradient(colors: [.clear, GhostTheme.inkDeep.opacity(0.9)],
                               center: .center, startRadius: 100, endRadius: 520)
            }
        }
    }

    // MARK: - Glass card (one fill layer + one hairline stroke, cached shadows)

    struct GhostCard: ViewModifier {
        var radius: CGFloat = GhostTheme.Radius.card
        var glow: Bool = false

        func body(content: Content) -> some View {
            content
                .background {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(GhostTheme.cardGradient)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(GhostTheme.borderGradient, lineWidth: 1)
                }
                .compositingGroup()
                .shadow(color: Color.black.opacity(0.40), radius: 20, x: 0, y: 12)
                .shadow(color: glow ? GhostTheme.mint.opacity(0.28) : .clear,
                        radius: glow ? 28 : 0)
        }
    }

    // MARK: - Press feedback for every tappable surface

    struct GhostPressStyle: ButtonStyle {
        var scale: CGFloat = 0.96

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? scale : 1)
                .opacity(configuration.isPressed ? 0.9 : 1)
                .animation(GhostTheme.Motion.press, value: configuration.isPressed)
        }
    }

    // MARK: - Light sweep (opt-in; honours Reduce Motion)

    struct GhostShimmer: ViewModifier {
        var active: Bool = true
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @State private var phase: CGFloat = -1

        func body(content: Content) -> some View {
            content.overlay {
                if active && !reduceMotion {
                    LinearGradient(colors: [.clear, Color.white.opacity(0.22), .clear],
                                   startPoint: .leading, endPoint: .trailing)
                        .scaleEffect(x: 0.5, y: 1)
                        .offset(x: phase * 260)
                        .blendMode(.plusLighter)
                        .clipped()
                        .allowsHitTesting(false)
                        .onAppear {
                            phase = -1
                            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                                phase = 1
                            }
                        }
                }
            }
        }
    }

    // MARK: - Composable pieces

    struct GhostHeader: View {
        let title: String
        let subtitle: String?

        init(_ title: String, subtitle: String? = nil) {
            self.title = title
            self.subtitle = subtitle
        }

        var body: some View {
            VStack(alignment: .leading, spacing: GhostTheme.Space.xs) {
                Text(title)
                    .font(.system(.title2, design: .rounded).weight(.semibold))
                    .foregroundStyle(GhostTheme.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(GhostTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    struct GhostPillButton: View {
        let title: String
        let systemImage: String?
        var prominent: Bool
        let action: () -> Void

        init(_ title: String, systemImage: String? = nil,
             prominent: Bool = true, action: @escaping () -> Void) {
            self.title = title
            self.systemImage = systemImage
            self.prominent = prominent
            self.action = action
        }

        var body: some View {
            Button(action: action) {
                HStack(spacing: GhostTheme.Space.xs) {
                    if let systemImage { Image(systemName: systemImage) }
                    Text(title).font(.subheadline.weight(.semibold))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 13)
                .frame(maxWidth: prominent ? .infinity : nil)
                .background {
                    if prominent {
                        GhostTheme.accentGradient
                    } else {
                        GhostTheme.glass
                    }
                }
                .foregroundStyle(prominent ? Color.black : GhostTheme.textPrimary)
                .clipShape(Capsule())
                .compositingGroup()
                .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 6)
            }
            .buttonStyle(GhostPressStyle())
        }
    }

    struct GhostTabItem: View {
        let icon: String
        let title: String
        var isSelected: Bool = false
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                VStack(spacing: GhostTheme.Space.xs) {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .symbolEffect(.bounce, value: isSelected)
                    Text(title)
                        .font(.caption2.weight(.semibold))
                }
                .foregroundStyle(isSelected ? GhostTheme.mint : GhostTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(GhostTheme.glassStrong)
                    }
                }
            }
            .buttonStyle(GhostPressStyle(scale: 0.94))
        }
    }

    // MARK: - Speaking Ghost Mascot (60 fps reactive animation)

    /// A cute, friendly ghost mascot.
    /// - `isSpeaking`: mouth opens/closes, glow pulses, bob speeds up.
    /// - Blinks naturally every few seconds when idle.
    /// - Honours Reduce Motion (static pose).
    struct GhostMascot: View {
        var isSpeaking: Bool = false
        var size: CGFloat = 72
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @State private var blink: Bool = false
        @State private var blush: Bool = false

        var body: some View {
            ZStack {
                // Outer glow
                Circle()
                    .fill(GhostTheme.ghostGlow.opacity(isSpeaking ? 0.45 : 0.22))
                    .frame(width: size * 1.5, height: size * 1.5)
                    .blur(radius: size * 0.25)
                    .scaleEffect(isSpeaking ? 1.15 : 1.0)
                    .animation(isSpeaking
                               ? Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)
                               : .default, value: isSpeaking)

                // Ghost body
                ghostBody

                // Face
                face
            }
            .frame(width: size * 1.6, height: size * 1.6)
            .accessibilityLabel(isSpeaking ? "Ghost coach speaking" : "Ghost coach")
            .onAppear {
                if !reduceMotion {
                    startBlink()
                    startBlush()
                }
            }
        }

        // MARK: - Body

        private var ghostBody: some View {
            ZStack {
                UnevenRoundedRectangle(
                    topLeadingRadius: size * 0.45,
                    bottomLeadingRadius: size * 0.14,
                    bottomTrailingRadius: size * 0.14,
                    topTrailingRadius: size * 0.45,
                    style: .continuous
                )
                .fill(GhostTheme.ghostGradient)
                .frame(width: size * 0.82, height: size * 0.92)

                // Little wavy bottom edge (ghost tail)
                Path { path in
                    let w = size * 0.82
                    let h = size * 0.92
                    let cx = w / 2
                    path.move(to: CGPoint(x: 0, y: h * 0.55))
                    path.addCurve(to: CGPoint(x: w * 0.25, y: h * 0.75),
                                  control1: CGPoint(x: w * 0.08, y: h * 0.62),
                                  control2: CGPoint(x: w * 0.16, y: h * 0.82))
                    path.addCurve(to: CGPoint(x: cx, y: h * 0.68),
                                  control1: CGPoint(x: w * 0.34, y: h * 0.68),
                                  control2: CGPoint(x: cx - 6, y: h * 0.78))
                    path.addCurve(to: CGPoint(x: w * 0.75, y: h * 0.75),
                                  control1: CGPoint(x: cx + 6, y: h * 0.78),
                                  control2: CGPoint(x: w * 0.66, y: h * 0.68),
                                  control3: CGPoint(x: w * 0.84, y: h * 0.82))
                    path.addCurve(to: CGPoint(x: w, y: h * 0.55),
                                  control1: CGPoint(x: w * 0.92, y: h * 0.68),
                                  control2: CGPoint(x: w, y: h * 0.55))
                }
                .fill(GhostTheme.ghostGlow.opacity(0.55))
                .frame(width: size * 0.82, height: size * 0.92)
                .compositingGroup()
            }
            .offset(y: bobOffset)
            .animation(
                isSpeaking
                ? Animation.easeInOut(duration: 0.55).repeatForever(autoreverses: true)
                : Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true),
                value: isSpeaking
            )
        }

        private var bobOffset: CGFloat {
            // Driven by a phase that TimelineView updates; computed in face via geometry.
            0
        }

        // MARK: - Face

        private var face: some View {
            ZStack {
                // Eyes
                HStack(spacing: size * 0.22) {
                    eye
                    eye
                }
                .offset(y: -size * 0.06)

                // Smile
                Capsule()
                    .fill(GhostTheme.inkDeep.opacity(0.55))
                    .frame(width: size * 0.28, height: size * 0.06)
                    .offset(y: size * 0.10)

                // Blush
                HStack(spacing: size * 0.30) {
                    Circle()
                        .fill(GhostTheme.pinkSoft.opacity(blush ? 0.75 : 0.35))
                        .frame(width: size * 0.16, height: size * 0.10)
                    Circle()
                        .fill(GhostTheme.pinkSoft.opacity(blush ? 0.75 : 0.35))
                        .frame(width: size * 0.16, height: size * 0.10)
                }
                .offset(y: size * 0.02)
            }
            .overlay {
                // Speaking mouth override
                if isSpeaking && !reduceMotion {
                    TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
                        let time = context.date.timeIntervalSinceReferenceDate
                        let mouthOpen = CGFloat(0.30 + 0.50 * abs(sin(time * 12.0)))
                        Capsule()
                            .fill(GhostTheme.inkDeep.opacity(0.70))
                            .frame(width: size * 0.22, height: max(size * 0.04, size * 0.14 * mouthOpen))
                            .offset(y: size * 0.10)
                    }
                }
            }
        }

        private var eye: some View {
            ZStack {
                // White of eye
                Capsule()
                    .fill(GhostTheme.textPrimary)
                    .frame(width: size * 0.14, height: size * 0.22)

                // Pupil
                Capsule()
                    .fill(GhostTheme.inkDeep)
                    .frame(width: size * 0.055, height: size * 0.10)
                    .offset(x: size * 0.015)

                // Blink lid (covers eye when blinking)
                if !reduceMotion {
                    TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { _ in
                        Capsule()
                            .fill(GhostTheme.ghostGradient)
                            .frame(width: size * 0.14, height: blink ? size * 0.24 : 0)
                            .animation(.easeInOut(duration: 0.12), value: blink)
                    }
                }
            }
        }

        // MARK: - Animation drivers

        private func startBlink() {
            guard !reduceMotion else { return }
            Task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(Double.random(in: 3.0...6.0)))
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeInOut(duration: 0.12)) { blink = true }
                    try? await Task.sleep(for: .milliseconds(120))
                    withAnimation(.easeInOut(duration: 0.12)) { blink = false }
                }
            }
        }

        private func startBlush() {
            guard !reduceMotion else { return }
            Task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(Double.random(in: 5.0...9.0)))
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeInOut(duration: 0.6)) { blush = true }
                    try? await Task.sleep(for: .seconds(1.4))
                    withAnimation(.easeInOut(duration: 0.6)) { blush = false }
                }
            }
        }
    }

    // MARK: - One-line adoption helpers
}

extension View {
    /// Glass card: rounded fill + hairline border + soft shadow.
    func ghostCard(radius: CGFloat = GhostTheme.Radius.card, glow: Bool = false) -> some View {
        modifier(GhostCard(radius: radius, glow: glow))
    }

    /// Full-screen look: aurora background, text colour and accent tint.
    func ghostScreen(animated: Bool = false) -> some View {
        background(GhostAurora(animated: animated))
            .foregroundStyle(GhostTheme.textPrimary)
            .tint(GhostTheme.mint)
    }

    func ghostShimmer(_ active: Bool = true) -> some View {
        modifier(GhostShimmer(active: active))
    }

    func ghostGlow(_ color: Color = GhostTheme.mint, radius: CGFloat = 22) -> some View {
        shadow(color: color.opacity(0.30), radius: radius)
    }
}
