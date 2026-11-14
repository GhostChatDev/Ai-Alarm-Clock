import SwiftUI

/// Design tokens and reusable effects for Ready by Eight.
/// iOS 17+, Swift 6. Add this file to the ReadyByEight app target to use it.
///
/// Performance notes:
/// - The ambient background is static by default. Optional animation is capped at
///   15 fps, moves only opacity/offset, and respects Reduce Motion.
/// - Blur and glow values never animate. Keep animated effects off scrolling lists.
/// - Cards use one gradient fill plus a hairline, without animated expensive shadows.
enum GhostTheme {

    // MARK: - Palette

    static let mintBright = Color(red: 0.86, green: 0.96, blue: 0.82)
    static let mint = Color(red: 0.73, green: 0.87, blue: 0.72)
    static let teal = Color(red: 0.37, green: 0.66, blue: 0.59)
    static let inkDeep = Color(red: 0.018, green: 0.025, blue: 0.025)
    static let ink = Color(red: 0.043, green: 0.055, blue: 0.052)
    static let inkRaised = Color(red: 0.075, green: 0.092, blue: 0.085)
    static let textPrimary = Color(red: 0.92, green: 0.95, blue: 0.91)
    static let textSecondary = Color(red: 0.65, green: 0.71, blue: 0.66)
    static let hairline = Color.white.opacity(0.10)
    static let glass = Color.white.opacity(0.045)
    static let glassStrong = Color.white.opacity(0.085)

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
            TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { context in
                layers(phase: context.date.timeIntervalSinceReferenceDate)
            }
        } else {
            layers(phase: 0)
        }
    }

    private func layers(phase: TimeInterval) -> some View {
        let drift = CGFloat(sin(phase * 0.22))
        return ZStack {
            LinearGradient(colors: [GhostTheme.inkDeep, GhostTheme.ink],
                           startPoint: .top, endPoint: .bottom)

            // Fixed-size radial gradients are much cheaper than animating large blurs.
            Circle()
                .fill(RadialGradient(colors: [GhostTheme.mint.opacity(0.14), .clear],
                                     center: .center, startRadius: 0, endRadius: 180))
                .frame(width: 360, height: 360)
                .offset(x: -125 + drift * 12, y: -245 + drift * 8)

            Circle()
                .fill(RadialGradient(colors: [GhostTheme.teal.opacity(0.10), .clear],
                                     center: .center, startRadius: 0, endRadius: 160))
                .frame(width: 320, height: 320)
                .offset(x: 135 - drift * 10, y: 250 + drift * 8)

            LinearGradient(colors: [.clear, GhostTheme.inkDeep.opacity(0.35)],
                           startPoint: .center, endPoint: .bottom)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
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
            // Static shadows only; the background effect supplies the ambient light.
            .shadow(color: Color.black.opacity(0.28), radius: 12, x: 0, y: 6)
            .shadow(color: glow ? GhostTheme.mint.opacity(0.22) : .clear,
                    radius: glow ? 18 : 0)
    }
}

// MARK: - Reference-style icon button

struct GhostIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(GhostTheme.textPrimary)
            .frame(width: 44, height: 44)
            .background(GhostTheme.glass, in: Circle())
            .overlay(Circle().strokeBorder(GhostTheme.hairline, lineWidth: 0.75))
            .opacity(configuration.isPressed ? 0.72 : 1)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(GhostTheme.Motion.press, value: configuration.isPressed)
    }
}

// MARK: - Press feedback for every tappable surface

struct GhostPressStyle: ButtonStyle {
    var scale: CGFloat = 0.98

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .brightness(configuration.isPressed ? 0.04 : 0)
            .animation(GhostTheme.Motion.press, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GhostIconButtonStyle {
    static var ghostIcon: GhostIconButtonStyle { GhostIconButtonStyle() }
}

extension ButtonStyle where Self == GhostPressStyle {
    static var ghostPress: GhostPressStyle { GhostPressStyle() }
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
