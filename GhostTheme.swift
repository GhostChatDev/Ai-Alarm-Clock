import SwiftUI

/// Design tokens and reusable effects for Ready by Eight.
/// iOS 17+, Swift 6. Add this file to the ReadyByEight app target to use it.
///
/// Performance notes:
/// - `GhostAurora(animated:)` renders static by default. Animated mode runs at 60 fps
///   and skips continuous motion when Reduce Motion is enabled.
/// - Glow uses `shadow`, which the compositor caches; avoid animating it per frame.
/// - Cards use one material layer plus one hairline border: no extra blend passes.
enum GhostTheme {

    // MARK: - Palette

    static let mintBright = Color(red: 0.85, green: 0.98, blue: 0.72)
    static let mint = Color(red: 0.76, green: 0.91, blue: 0.62)
    static let teal = Color(red: 0.35, green: 0.72, blue: 0.68)
    static let inkDeep = Color(red: 0.025, green: 0.030, blue: 0.040)
    static let ink = Color(red: 0.055, green: 0.065, blue: 0.075)
    static let inkRaised = Color(red: 0.10, green: 0.115, blue: 0.13)
    static let textPrimary = Color.white.opacity(0.92)
    static let textSecondary = Color.white.opacity(0.58)
    static let hairline = Color.white.opacity(0.10)
    static let glass = Color.white.opacity(0.06)
    static let glassStrong = Color.white.opacity(0.10)

    // MARK: - Metrics

    enum Radius {
        static let card: CGFloat = 24
        static let chip: CGFloat = 14
        static let sheet: CGFloat = 32
    }

    enum Space {
        static let xs: CGFloat = 6
        static let s: CGFloat = 10
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Motion {
        static let press = Animation.spring(response: 0.28, dampingFraction: 0.72)
        static let fade = Animation.easeOut(duration: 0.22)
    }

    // MARK: - Gradients

    static var accentGradient: LinearGradient {
        LinearGradient(colors: [mintBright, teal], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var cardGradient: LinearGradient {
        LinearGradient(colors: [Color.white.opacity(0.10), Color.white.opacity(0.03)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var borderGradient: LinearGradient {
        LinearGradient(colors: [Color.white.opacity(0.24), Color.white.opacity(0.04)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Background with soft aurora glow

struct GhostAurora: View {
    var animated: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if animated && !reduceMotion {
            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
                layers(phase: context.date.timeIntervalSinceReferenceDate)
            }
        } else {
            layers(phase: 0)
        }
    }

    private func layers(phase: TimeInterval) -> some View {
        let drift = CGFloat(sin(phase * 0.35))
        return ZStack {
            LinearGradient(colors: [GhostTheme.inkDeep, GhostTheme.ink],
                           startPoint: .top, endPoint: .bottom)

            Circle()
                .fill(GhostTheme.mint.opacity(0.22))
                .frame(width: 320, height: 320)
                .blur(radius: 90)
                .offset(x: -110 + drift * 22, y: -240 + drift * 16)

            Circle()
                .fill(GhostTheme.teal.opacity(0.20))
                .frame(width: 280, height: 280)
                .blur(radius: 100)
                .offset(x: 130 - drift * 18, y: 230 + drift * 14)

            RadialGradient(colors: [.clear, GhostTheme.inkDeep.opacity(0.85)],
                           center: .center, startRadius: 90, endRadius: 480)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .compositingGroup()
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
            .shadow(color: Color.black.opacity(0.38), radius: 18, x: 0, y: 10)
            .shadow(color: glow ? GhostTheme.mint.opacity(0.30) : .clear,
                    radius: glow ? 26 : 0)
    }
}

// MARK: - Press feedback for every tappable surface

struct GhostPressStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(GhostTheme.Motion.press, value: configuration.isPressed)
    }
}

// MARK: - Light sweep (opt-in: gate it and it honours Reduce Motion)

struct GhostShimmer: ViewModifier {
    var active: Bool = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content.overlay {
            if active && !reduceMotion {
                LinearGradient(colors: [.clear, Color.white.opacity(0.28), .clear],
                               startPoint: .leading, endPoint: .trailing)
                    .scaleEffect(x: 0.5, y: 1)
                    .offset(x: phase * 240)
                    .blendMode(.plusLighter)
                    .clipped()
                    .allowsHitTesting(false)
                    .onAppear {
                        phase = -1
                        withAnimation(.linear(duration: 1.9).repeatForever(autoreverses: false)) {
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
            .padding(.vertical, 12)
            .frame(maxWidth: prominent ? .infinity : nil)
            .background {
                if prominent {
                    Capsule().fill(GhostTheme.accentGradient)
                } else {
                    Capsule().fill(GhostTheme.glass)
                        .overlay(Capsule().strokeBorder(GhostTheme.hairline, lineWidth: 1))
                }
            }
            .foregroundStyle(prominent ? GhostTheme.inkDeep : GhostTheme.textPrimary)
            .shadow(color: prominent ? GhostTheme.mint.opacity(0.35) : .clear, radius: 16, y: 6)
        }
        .buttonStyle(GhostPressStyle())
    }
}

struct GhostChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(GhostTheme.glass, in: Capsule())
            .overlay(Capsule().strokeBorder(GhostTheme.hairline, lineWidth: 1))
            .foregroundStyle(GhostTheme.textSecondary)
    }
}

// MARK: - 60 fps Speaking Ghost Mascot

struct GhostMascot: View {
    var isSpeaking: Bool
    var isThinking: Bool = false
    var size: CGFloat = 64
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if !reduceMotion && (isSpeaking || isThinking) {
            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
                mascotCanvas(time: context.date.timeIntervalSinceReferenceDate)
            }
        } else {
            mascotCanvas(time: 0)
        }
    }

    private func mascotCanvas(time: TimeInterval) -> some View {
        let active = !reduceMotion && (isSpeaking || isThinking)
        let bob = active ? CGFloat(sin(time * (isSpeaking ? 6.5 : 3.0))) * (size * 0.055) : 0
        let tilt = active ? sin(time * (isSpeaking ? 5.2 : 2.2)) * (isSpeaking ? 4.5 : 2.0) : 0
        let mouthOpen: CGFloat = (!reduceMotion && isSpeaking)
            ? CGFloat(0.35 + 0.65 * abs(sin(time * 11.0)))
            : (isSpeaking ? 0.6 : 0.15)
        let pulse: CGFloat = (!reduceMotion && isSpeaking)
            ? CGFloat(1.0 + 0.08 * sin(time * 9.0))
            : 1.0

        return ZStack {
            Circle()
                .fill(GhostTheme.mint.opacity(isSpeaking ? 0.24 : 0.12))
                .frame(width: size * 1.28, height: size * 1.28)
                .scaleEffect(pulse)

            GhostBodyShape()
                .fill(GhostTheme.accentGradient)
                .frame(width: size * 0.78, height: size * 0.90)
                .overlay(
                    GhostBodyShape()
                        .stroke(Color.white.opacity(0.40), lineWidth: 1.2)
                )
                .overlay {
                    VStack(spacing: size * 0.08) {
                        HStack(spacing: size * 0.16) {
                            Capsule()
                                .fill(GhostTheme.inkDeep)
                                .frame(width: size * 0.09, height: size * 0.13)
                            Capsule()
                                .fill(GhostTheme.inkDeep)
                                .frame(width: size * 0.09, height: size * 0.13)
                        }
                        Capsule()
                            .fill(GhostTheme.inkDeep)
                            .frame(
                                width: size * (isSpeaking ? 0.18 : 0.12),
                                height: max(size * 0.04, size * 0.16 * mouthOpen)
                            )
                    }
                    .offset(y: -size * 0.06)
                }
                .rotationEffect(.degrees(tilt))
                .offset(y: bob)
                .shadow(color: GhostTheme.mint.opacity(0.32), radius: 12, y: 5)
        }
        .frame(width: size * 1.35, height: size * 1.35)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isSpeaking ? "Eight mascot speaking" : (isThinking ? "Eight mascot thinking" : "Eight mascot"))
    }
}

struct GhostBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let domeRadius = w / 2

        path.move(to: CGPoint(x: 0, y: domeRadius))
        path.addArc(
            center: CGPoint(x: domeRadius, y: domeRadius),
            radius: domeRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: w, y: h * 0.88))

        let waveWidth = w / 3
        for index in 0..<3 {
            let startX = w - CGFloat(index) * waveWidth
            let midX = startX - waveWidth * 0.5
            let endX = startX - waveWidth
            path.addQuadCurve(
                to: CGPoint(x: midX, y: h),
                control: CGPoint(x: startX - waveWidth * 0.22, y: h)
            )
            path.addQuadCurve(
                to: CGPoint(x: endX, y: h * 0.86),
                control: CGPoint(x: midX - waveWidth * 0.25, y: h * 0.78)
            )
        }

        path.closeSubpath()
        return path
    }
}

// MARK: - One-line adoption helpers

extension View {
    /// Glass card: replaces the old `.card()` look.
    func ghostCard(radius: CGFloat = GhostTheme.Radius.card, glow: Bool = false) -> some View {
        modifier(GhostCard(radius: radius, glow: glow))
    }

    /// Full-screen look: aurora background, text colour and accent.
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
