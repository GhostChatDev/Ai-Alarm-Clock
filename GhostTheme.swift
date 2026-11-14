import SwiftUI

/// Design tokens and reusable effects for Ready by Eight.
/// iOS 17+, Swift 6. Add this file to the ReadyByEight app target to use it.
///
/// Performance notes:
/// - `GhostAurora(animated:)` renders static by default. Animated mode targets 60 fps
///   of blurred layers, so it is opt-in and skipped when Reduce Motion is on.
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

// MARK: - Speaking mascot

/// A visual speaking indicator, not an audio or lip-sync signal.
/// Pass the store's `isCoachSpeaking`; reduced motion keeps the mascot static.
struct GhostMascot: View {
    let isSpeaking: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(isSpeaking: Bool = false) {
        self.isSpeaking = isSpeaking
    }

    var body: some View {
        Group {
            if isSpeaking && !reduceMotion {
                TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
                    drawing(time: context.date.timeIntervalSinceReferenceDate, animated: true)
                }
            } else {
                drawing(time: 0, animated: false)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .allowsHitTesting(false)
        .accessibilityLabel(isSpeaking ? "Ghost coach is responding" : "Ghost coach")
    }

    private func drawing(time: TimeInterval, animated: Bool) -> some View {
        Canvas { context, size in
            let unit = min(size.width, size.height)
            let wave = animated ? sin(time * .pi * 4) : 0
            let bob = animated ? sin(time * .pi * 2) * unit * 0.025 : 0
            let width = unit * 0.66
            let height = unit * 0.70
            let origin = CGPoint(x: (size.width - width) / 2,
                                 y: (size.height - height) / 2 + bob)
            let body = CGRect(origin: origin, size: CGSize(width: width, height: height))
            let path = ghostPath(in: body, wave: wave)

            context.fill(path, with: .color(GhostTheme.mint.opacity(0.14)))
            context.stroke(path, with: .color(GhostTheme.mint), lineWidth: max(1.5, unit * 0.025))

            let eyeSize = CGSize(width: unit * 0.045, height: unit * (animated ? 0.065 : 0.05))
            for xFactor in [0.40, 0.60] {
                let eye = CGRect(x: size.width * xFactor - eyeSize.width / 2,
                                 y: origin.y + height * 0.32,
                                 width: eyeSize.width, height: eyeSize.height)
                context.fill(Path(ellipseIn: eye), with: .color(GhostTheme.mintBright))
            }

            let mouthHeight = unit * (animated ? 0.055 + 0.035 * abs(wave) : 0.025)
            let mouth = CGRect(x: size.width * 0.47,
                               y: origin.y + height * 0.47,
                               width: unit * 0.06, height: mouthHeight)
            context.fill(Path(ellipseIn: mouth), with: .color(GhostTheme.mintBright))
        }
    }

    private func ghostPath(in rect: CGRect, wave: Double) -> Path {
        Path { path in
            let left = rect.minX
            let right = rect.maxX
            let top = rect.minY
            let bottom = rect.maxY
            let waveOffset = rect.height * 0.025 * wave
            path.move(to: CGPoint(x: left, y: bottom))
            path.addLine(to: CGPoint(x: left, y: top + rect.width / 2))
            path.addArc(center: CGPoint(x: rect.midX, y: top + rect.width / 2),
                        radius: rect.width / 2,
                        startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: right, y: bottom))
            path.addQuadCurve(to: CGPoint(x: rect.midX + rect.width / 6, y: bottom - waveOffset),
                              control: CGPoint(x: rect.midX + rect.width / 3, y: bottom - rect.height * 0.10))
            path.addQuadCurve(to: CGPoint(x: rect.midX - rect.width / 6, y: bottom + waveOffset),
                              control: CGPoint(x: rect.midX, y: bottom + rect.height * 0.08))
            path.addQuadCurve(to: CGPoint(x: left, y: bottom),
                              control: CGPoint(x: rect.midX - rect.width / 3, y: bottom - rect.height * 0.10))
            path.closeSubpath()
        }
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
