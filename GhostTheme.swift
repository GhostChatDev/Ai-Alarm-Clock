import SwiftUI

enum GhostTheme {
    // MARK: - Reference Palette (exact match to 4 attached screens)
    static let ghostWhite = Color(red: 0.96, green: 0.96, blue: 1.0)
    static let ghostGlow = Color(red: 0.78, green: 0.72, blue: 0.98)
    static let lavenderTitle = Color(red: 0.73, green: 0.67, blue: 0.98)
    static let purple = Color(red: 0.66, green: 0.56, blue: 0.96)
    static let purpleSoft = Color(red: 0.78, green: 0.73, blue: 0.98)
    static let purpleDeep = Color(red: 0.42, green: 0.30, blue: 0.88)
    static let weatherTop = Color(red: 0.37, green: 0.25, blue: 0.85)
    static let weatherBottom = Color(red: 0.48, green: 0.36, blue: 0.89)
    static let planCardBg = Color(red: 0.19, green: 0.15, blue: 0.33)
    static let chatBubbleCoach = Color(red: 0.40, green: 0.40, blue: 0.50)
    static let warmCream = Color(red: 0.94, green: 0.85, blue: 0.72)
    static let warmBrown = Color(red: 0.62, green: 0.46, blue: 0.31)
    static let sendPurple = Color(red: 0.42, green: 0.27, blue: 0.87)

    static let mint = Color(red: 0.76, green: 0.91, blue: 0.62)
    static let mintBright = Color(red: 0.85, green: 0.98, blue: 0.72)
    static let teal = Color(red: 0.35, green: 0.72, blue: 0.68)
    static let pink = Color(red: 1.0, green: 0.72, blue: 0.80)
    static let pinkSoft = Color(red: 1.0, green: 0.85, blue: 0.92)
    static let yellow = Color(red: 0.98, green: 0.82, blue: 0.56)

    static let inkDeep = Color(red: 0.055, green: 0.055, blue: 0.082)
    static let ink = Color(red: 0.082, green: 0.082, blue: 0.118)
    static let inkRaised = Color(red: 0.16, green: 0.16, blue: 0.21)
    static let textPrimary = Color.white.opacity(0.96)
    static let textSecondary = Color(red: 0.65, green: 0.65, blue: 0.74)
    static let hairline = Color.white.opacity(0.11)
    static let glass = Color.white.opacity(0.06)
    static let glassStrong = Color.white.opacity(0.11)

    enum Radius {
        static let card: CGFloat = 24
        static let chip: CGFloat = 18
        static let sheet: CGFloat = 32
        static let ghost: CGFloat = 28
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
        static let fade = Animation.easeOut(duration: 0.22)
        static let bounce = Animation.spring(response: 0.42, dampingFraction: 0.72)
    }

    static var accentGradient: LinearGradient {
        LinearGradient(colors: [purpleSoft, purple], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var ghostGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.98, blue: 1.0),
                Color(red: 0.86, green: 0.82, blue: 0.99),
                Color(red: 0.75, green: 0.69, blue: 0.96)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var weatherGradient: LinearGradient {
        LinearGradient(colors: [weatherTop, weatherBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var cardGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.18, green: 0.18, blue: 0.23), Color(red: 0.13, green: 0.13, blue: 0.18)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var borderGradient: LinearGradient {
        LinearGradient(colors: [Color.white.opacity(0.18), Color.white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    struct GhostAurora: View {
        var animated: Bool = false
        var body: some View {
            ZStack {
                LinearGradient(colors: [GhostTheme.inkDeep, GhostTheme.ink], startPoint: .top, endPoint: .bottom)
                Circle()
                    .fill(GhostTheme.purple.opacity(0.18))
                    .frame(width: 320, height: 320)
                    .blur(radius: 95)
                    .offset(x: 0, y: -230)
                Circle()
                    .fill(GhostTheme.weatherTop.opacity(0.14))
                    .frame(width: 280, height: 280)
                    .blur(radius: 95)
                    .offset(x: 80, y: 220)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }

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
                        .strokeBorder(
                            glow
                                ? LinearGradient(colors: [GhostTheme.purpleSoft.opacity(0.85), GhostTheme.purple.opacity(0.45)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : GhostTheme.borderGradient,
                            lineWidth: glow ? 1.5 : 1
                        )
                }
                .shadow(color: Color.black.opacity(0.42), radius: 18, x: 0, y: 10)
                .shadow(color: glow ? GhostTheme.purple.opacity(0.38) : .clear, radius: glow ? 22 : 0)
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

    struct GhostHeader: View {
        let title: String
        let subtitle: String?
        var centered: Bool = false
        var lavenderHeader: Bool = false

        init(_ title: String, subtitle: String? = nil, centered: Bool = false, lavenderHeader: Bool = false) {
            self.title = title
            self.subtitle = subtitle
            self.centered = centered
            self.lavenderHeader = lavenderHeader
        }

        var body: some View {
            VStack(alignment: centered ? .center : .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(lavenderHeader ? GhostTheme.lavenderTitle : GhostTheme.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(GhostTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
        }
    }

    struct GhostPillButton: View {
        let title: String
        let systemImage: String?
        var prominent: Bool
        let action: () -> Void

        init(_ title: String, systemImage: String? = nil, prominent: Bool = true, action: @escaping () -> Void) {
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
                        .font(.system(size: 18, weight: .semibold))
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background {
                    if prominent {
                        Capsule().fill(GhostTheme.purpleSoft)
                    } else {
                        Capsule().fill(Color.white.opacity(0.03))
                    }
                }
                .overlay {
                    if !prominent {
                        Capsule().strokeBorder(GhostTheme.purpleSoft.opacity(0.55), lineWidth: 1.3)
                    }
                }
                .foregroundStyle(prominent ? Color(red: 0.08, green: 0.07, blue: 0.14) : GhostTheme.purpleSoft)
                .shadow(color: prominent ? GhostTheme.purple.opacity(0.45) : .clear, radius: 18, x: 0, y: 4)
            }
            .buttonStyle(GhostPressStyle())
        }
    }

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
                ZStack(alignment: isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(
                            isOn
                                ? LinearGradient(colors: [GhostTheme.purple, GhostTheme.purpleDeep], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [Color.white.opacity(0.16), Color.white.opacity(0.10)], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: 74, height: 36)
                        .overlay(
                            HStack {
                                if isOn {
                                    Text("ON")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.leading, 12)
                                    Spacer()
                                } else {
                                    Spacer()
                                    Text("OFF")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(GhostTheme.textSecondary)
                                        .padding(.trailing, 10)
                                }
                            }
                        )
                    Circle()
                        .fill(Color.white)
                        .frame(width: 28, height: 28)
                        .padding(4)
                        .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 1)
                }
                .shadow(color: isOn ? GhostTheme.purple.opacity(0.45) : .clear, radius: 10)
            }
            .buttonStyle(GhostPressStyle())
            .accessibilityLabel(isOn ? "Alarm On" : "Alarm Off")
        }
    }

    // MARK: - 3D Glowing Ghost Mascot
    enum GhostMood {
        case happy
        case winking
        case sleeping
        case waving
    }

    struct GhostBodyShape: Shape {
        func path(in rect: CGRect) -> Path {
            let w = rect.width
            let h = rect.height
            var p = Path()

            p.move(to: CGPoint(x: w * 0.14, y: h * 0.56))
            p.addQuadCurve(
                to: CGPoint(x: w * 0.50, y: h * 0.05),
                control: CGPoint(x: w * 0.12, y: h * 0.06)
            )
            p.addQuadCurve(
                to: CGPoint(x: w * 0.86, y: h * 0.56),
                control: CGPoint(x: w * 0.88, y: h * 0.06)
            )
            p.addQuadCurve(
                to: CGPoint(x: w * 0.97, y: h * 0.45),
                control: CGPoint(x: w * 0.96, y: h * 0.38)
            )
            p.addQuadCurve(
                to: CGPoint(x: w * 0.85, y: h * 0.64),
                control: CGPoint(x: w * 0.99, y: h * 0.56)
            )
            p.addQuadCurve(
                to: CGPoint(x: w * 0.88, y: h * 0.92),
                control: CGPoint(x: w * 0.85, y: h * 0.82)
            )
            p.addQuadCurve(
                to: CGPoint(x: w * 0.65, y: h * 0.90),
                control: CGPoint(x: w * 0.77, y: h * 0.99)
            )
            p.addQuadCurve(
                to: CGPoint(x: w * 0.48, y: h * 0.94),
                control: CGPoint(x: w * 0.56, y: h * 0.84)
            )
            p.addQuadCurve(
                to: CGPoint(x: w * 0.28, y: h * 0.89),
                control: CGPoint(x: w * 0.38, y: h * 0.99)
            )
            p.addQuadCurve(
                to: CGPoint(x: w * 0.15, y: h * 0.91),
                control: CGPoint(x: w * 0.21, y: h * 0.84)
            )
            p.addQuadCurve(
                to: CGPoint(x: w * 0.15, y: h * 0.64),
                control: CGPoint(x: w * 0.12, y: h * 0.84)
            )
            p.addQuadCurve(
                to: CGPoint(x: w * 0.03, y: h * 0.45),
                control: CGPoint(x: w * 0.01, y: h * 0.56)
            )
            p.addQuadCurve(
                to: CGPoint(x: w * 0.14, y: h * 0.56),
                control: CGPoint(x: w * 0.04, y: h * 0.38)
            )
            p.closeSubpath()
            return p
        }
    }

    struct GhostMascot: View {
        var size: CGFloat = 86
        var mood: GhostMood = .happy
        var warmTint: Bool = false

        var body: some View {
            ZStack {
                if !warmTint {
                    Circle()
                        .fill(GhostTheme.purple.opacity(0.42))
                        .frame(width: size * 1.38, height: size * 1.38)
                        .blur(radius: size * 0.26)
                }

                GhostBodyShape()
                    .fill(
                        warmTint
                            ? LinearGradient(colors: [GhostTheme.warmBrown, GhostTheme.warmBrown.opacity(0.88)], startPoint: .top, endPoint: .bottom)
                            : GhostTheme.ghostGradient
                    )
                    .frame(width: size, height: size)
                    .overlay(
                        GhostBodyShape()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(warmTint ? 0.25 : 0.9), GhostTheme.purpleSoft.opacity(warmTint ? 0.1 : 0.4)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: size * 0.022
                            )
                    )
                    .shadow(color: warmTint ? .clear : GhostTheme.purple.opacity(0.55), radius: size * 0.20, x: 0, y: size * 0.06)

                if !warmTint {
                    HStack(spacing: size * 0.28) {
                        Ellipse()
                            .fill(GhostTheme.pink.opacity(0.52))
                            .frame(width: size * 0.12, height: size * 0.07)
                        Ellipse()
                            .fill(GhostTheme.pink.opacity(0.52))
                            .frame(width: size * 0.12, height: size * 0.07)
                    }
                    .offset(y: -size * 0.02)
                }

                VStack(spacing: size * 0.045) {
                    HStack(spacing: size * 0.18) {
                        eyeView(isLeft: true)
                        eyeView(isLeft: false)
                    }
                    mouthView
                }
                .offset(y: -size * 0.08)
            }
            .frame(width: size, height: size)
            .accessibilityHidden(true)
        }

        @ViewBuilder
        private func eyeView(isLeft: Bool) -> some View {
            let eyeColor = warmTint ? GhostTheme.warmCream : Color(red: 0.13, green: 0.11, blue: 0.20)
            switch mood {
            case .winking where !isLeft:
                Capsule().fill(eyeColor).frame(width: size * 0.11, height: size * 0.035)
            case .sleeping:
                Capsule().fill(eyeColor).frame(width: size * 0.11, height: size * 0.032)
            default:
                Circle().fill(eyeColor).frame(width: size * 0.088, height: size * 0.088)
            }
        }

        @ViewBuilder
        private var mouthView: some View {
            let mouthColor = warmTint ? GhostTheme.warmCream : Color(red: 0.13, green: 0.11, blue: 0.20)
            Capsule().fill(mouthColor).frame(width: size * 0.11, height: size * 0.042)
        }
    }
}

extension View {
    func ghostCard(radius: CGFloat = GhostTheme.Radius.card, glow: Bool = false) -> some View {
        modifier(GhostTheme.GhostCard(radius: radius, glow: glow))
    }

    func ghostShimmer(_ active: Bool = true) -> some View {
        modifier(GhostTheme.GhostShimmer(active: active))
    }
}
