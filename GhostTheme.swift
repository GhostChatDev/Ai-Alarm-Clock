import SwiftUI

/// Exact Ghost Coach design tokens, 3D glowing Ghost mascot, custom ON toggle,
/// weather illustrations, and tab bar badges matching the reference screens.
/// iOS 17+, Swift 6.
enum GhostTheme {

    // MARK: - Reference Palette

    static let ghostWhite = Color(red: 0.96, green: 0.96, blue: 1.0)
    static let ghostGlow = Color(red: 0.84, green: 0.78, blue: 1.0)
    static let ghostBodyBottom = Color(red: 0.76, green: 0.68, blue: 0.98)

    // Lavender & Purple Accents from Reference Photos
    static let lavenderTitle = Color(red: 0.69, green: 0.56, blue: 0.98)
    static let lavenderSoft = Color(red: 0.84, green: 0.80, blue: 0.98)
    static let purple = Color(red: 0.62, green: 0.44, blue: 0.98)
    static let purpleDeep = Color(red: 0.44, green: 0.27, blue: 0.88)
    static let purpleSoft = Color(red: 0.78, green: 0.72, blue: 1.0)

    // Compatibility aliases so existing views adopt the lavender theme seamlessly
    static let mint = Color(red: 0.72, green: 0.60, blue: 0.98)
    static let mintBright = Color(red: 0.84, green: 0.78, blue: 1.0)
    static let teal = Color(red: 0.46, green: 0.29, blue: 0.88)

    // Warm cream card & greeting accents (Reference 1 & 3)
    static let warmCream = Color(red: 0.95, green: 0.87, blue: 0.76)
    static let warmCreamText = Color(red: 0.14, green: 0.11, blue: 0.10)
    static let warmGold = Color(red: 0.96, green: 0.88, blue: 0.72)

    // Weather Card & Morning Plan Surfaces (Reference 2 & 4)
    static let weatherTop = Color(red: 0.41, green: 0.24, blue: 0.85)
    static let weatherBottom = Color(red: 0.53, green: 0.37, blue: 0.93)
    static let planCardBg = Color(red: 0.20, green: 0.15, blue: 0.36)
    static let chatBubbleCoach = Color(red: 0.38, green: 0.37, blue: 0.48)
    static let coachCardDark = Color(red: 0.17, green: 0.17, blue: 0.22)

    static let pink = Color(red: 0.98, green: 0.68, blue: 0.78)
    static let pinkSoft = Color(red: 1.0, green: 0.76, blue: 0.84)
    static let yellow = Color(red: 1.0, green: 0.86, blue: 0.48)

    // Dark Surfaces
    static let inkDeep = Color(red: 0.06, green: 0.06, blue: 0.09)
    static let ink = Color(red: 0.09, green: 0.09, blue: 0.13)
    static let inkRaised = Color(red: 0.14, green: 0.14, blue: 0.19)
    static let textPrimary = Color.white.opacity(0.96)
    static let textSecondary = Color(red: 0.68, green: 0.67, blue: 0.76)
    static let hairline = Color.white.opacity(0.11)
    static let glass = Color.white.opacity(0.06)
    static let glassStrong = Color.white.opacity(0.11)

    // MARK: - Metrics

    enum Radius {
        static let card: CGFloat = 26
        static let chip: CGFloat = 18
        static let sheet: CGFloat = 34
        static let ghost: CGFloat = 30
    }

    enum Space {
        static let xs: CGFloat = 6
        static let s: CGFloat = 10
        static let m: CGFloat = 16
        static let l: CGFloat = 22
        static let xl: CGFloat = 30
    }

    enum Motion {
        static let press = Animation.spring(response: 0.28, dampingFraction: 0.75)
        static let fade = Animation.easeOut(duration: 0.24)
        static let bounce = Animation.spring(response: 0.42, dampingFraction: 0.74)
    }

    // MARK: - Gradients

    static var accentGradient: LinearGradient {
        LinearGradient(colors: [lavenderTitle, purple], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var ghostGradient: LinearGradient {
        LinearGradient(
            colors: [ghostWhite, ghostGlow, ghostBodyBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var weatherGradient: LinearGradient {
        LinearGradient(
            colors: [weatherTop, weatherBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var cardGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.16, green: 0.15, blue: 0.22), Color(red: 0.11, green: 0.11, blue: 0.16)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var borderGradient: LinearGradient {
        LinearGradient(
            colors: [lavenderTitle.opacity(0.55), purple.opacity(0.20)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
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
                    .fill(GhostTheme.purple.opacity(0.22))
                    .frame(width: 340, height: 340)
                    .blur(radius: 95)
                    .offset(x: -80 + drift * 18, y: -240 + drift * 14)

                Circle()
                    .fill(GhostTheme.weatherTop.opacity(0.18))
                    .frame(width: 300, height: 300)
                    .blur(radius: 95)
                    .offset(x: 110 - drift * 16, y: 220 + drift * 12)
            }
        }
    }

    // MARK: - Glass Card & Press Feedback

    struct GhostCard: ViewModifier {
        var radius: CGFloat = GhostTheme.Radius.card
        var glow: Bool = false

        func body(content: Content) -> some View {
            content
                .padding(GhostTheme.Space.m)
                .background {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(GhostTheme.cardGradient)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(
                            glow ? GhostTheme.borderGradient : LinearGradient(
                                colors: [Color.white.opacity(0.14), Color.white.opacity(0.04)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: glow ? 1.5 : 1
                        )
                }
                .compositingGroup()
                .shadow(color: Color.black.opacity(0.42), radius: 18, x: 0, y: 10)
                .shadow(color: glow ? GhostTheme.purple.opacity(0.38) : .clear,
                        radius: glow ? 24 : 0)
        }
    }

    struct GhostPressStyle: ButtonStyle {
        var scale: CGFloat = 0.96

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? scale : 1)
                .opacity(configuration.isPressed ? 0.9 : 1)
                .animation(GhostTheme.Motion.press, value: configuration.isPressed)
        }
    }

    struct GhostShimmer: ViewModifier {
        var active: Bool = true
        func body(content: Content) -> some View { content }
    }

    // MARK: - Headers, Buttons, and Custom "ON" Pill Toggle (Reference 2)

    struct GhostHeader: View {
        let title: String
        let subtitle: String?

        init(_ title: String, subtitle: String? = nil) {
            self.title = title
            self.subtitle = subtitle
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(GhostTheme.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 16, weight: .regular))
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
                HStack(spacing: 8) {
                    if let systemImage { Image(systemName: systemImage) }
                    Text(title)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 16)
                .frame(maxWidth: prominent ? .infinity : nil)
                .background {
                    if prominent {
                        Capsule().fill(GhostTheme.lavenderSoft)
                    } else {
                        Capsule()
                            .fill(Color.white.opacity(0.03))
                            .overlay(
                                Capsule().strokeBorder(GhostTheme.lavenderSoft.opacity(0.55), lineWidth: 1.4)
                            )
                    }
                }
                .foregroundStyle(prominent ? Color(red: 0.08, green: 0.07, blue: 0.14) : GhostTheme.lavenderSoft)
                .shadow(color: prominent ? GhostTheme.purple.opacity(0.38) : .clear, radius: 18, x: 0, y: 6)
            }
            .buttonStyle(GhostPressStyle())
        }
    }

    /// Glowing purple "ON" pill switch matching Image 2 ("ON" label + white knob)
    struct GhostAlarmToggle: View {
        @Binding var isOn: Bool
        var onToggle: (() -> Void)? = nil

        var body: some View {
            Button {
                withAnimation(GhostTheme.Motion.bounce) {
                    isOn.toggle()
                }
                onToggle?()
            } label: {
                ZStack {
                    Capsule()
                        .fill(
                            isOn
                            ? LinearGradient(colors: [GhostTheme.lavenderTitle, GhostTheme.purple], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [Color.white.opacity(0.16), Color.white.opacity(0.10)], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: 78, height: 38)
                        .shadow(color: isOn ? GhostTheme.purple.opacity(0.55) : .clear, radius: 10, x: 0, y: 3)

                    HStack(spacing: 0) {
                        if isOn {
                            Text("ON")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.leading, 12)
                            Spacer(minLength: 4)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 30, height: 30)
                                .padding(.trailing, 4)
                        } else {
                            Circle()
                                .fill(Color.white.opacity(0.85))
                                .frame(width: 30, height: 30)
                                .padding(.leading, 4)
                            Spacer(minLength: 4)
                            Text("OFF")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.65))
                                .padding(.trailing, 10)
                        }
                    }
                    .frame(width: 78, height: 38)
                }
            }
            .buttonStyle(GhostPressStyle(scale: 0.94))
            .accessibilityLabel(isOn ? "Alarm On" : "Alarm Off")
        }
    }
