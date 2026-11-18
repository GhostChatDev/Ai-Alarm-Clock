import SwiftUI
import AVFoundation
import AudioToolbox

/// Exact reference design tokens, glowing 3D Ghost mascot, sleep music synthesizer,
/// device alarm tone engine, on-device AVSpeechSynthesizer TTS, and gitignored AI API config.
/// iOS 17+, Swift 6.
enum GhostTheme {

    // MARK: - Exact Reference Palette

    static let inkDeep = Color(red: 0.055, green: 0.051, blue: 0.090)        // #0E0D17
    static let ink = Color(red: 0.078, green: 0.071, blue: 0.125)            // #141220
    static let inkRaised = Color(red: 0.125, green: 0.118, blue: 0.188)      // #201E30
    static let cardSurface = Color(red: 0.153, green: 0.149, blue: 0.216)    // #272637

    static let lavenderTitle = Color(red: 0.690, green: 0.569, blue: 0.973)  // #B091F8
    static let purple = Color(red: 0.655, green: 0.545, blue: 0.980)         // #A78BFA
    static let purpleDeep = Color(red: 0.451, green: 0.306, blue: 0.910)     // #734EE8
    static let purpleSoft = Color(red: 0.859, green: 0.816, blue: 0.992)     // #DBD0FD
    static let lilacPill = Color(red: 0.784, green: 0.725, blue: 0.988)      // #C8B9FC

    static let weatherTop = Color(red: 0.388, green: 0.275, blue: 0.918)     // #6346EA
    static let weatherBottom = Color(red: 0.486, green: 0.349, blue: 0.933)  // #7C59EE

    static let planCardBg = Color(red: 0.188, green: 0.141, blue: 0.345)     // #302458
    static let chatBubbleCoach = Color(red: 0.412, green: 0.396, blue: 0.525)// #696586
    static let chatBubbleUser = Color(red: 0.435, green: 0.302, blue: 0.898) // #6F4CE5

    static let warmCream = Color(red: 0.945, green: 0.855, blue: 0.733)      // #F1DABB
    static let warmGold = Color(red: 0.961, green: 0.871, blue: 0.702)       // #F5DEB3
    static let ghostWhite = Color(red: 0.975, green: 0.975, blue: 1.0)
    static let ghostGlow = Color(red: 0.835, green: 0.784, blue: 1.0)
    static let pinkSoft = Color(red: 0.965, green: 0.659, blue: 0.784)
    static let pink = Color(red: 0.957, green: 0.447, blue: 0.714)
    static let mint = Color(red: 0.655, green: 0.545, blue: 0.980)
    static let mintBright = Color(red: 0.784, green: 0.725, blue: 0.988)
    static let teal = Color(red: 0.486, green: 0.349, blue: 0.933)
    static let yellow = Color(red: 0.984, green: 0.827, blue: 0.451)

    static let textPrimary = Color.white.opacity(0.96)
    static let textSecondary = Color(red: 0.655, green: 0.639, blue: 0.769)  // #A7A3C4
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
        LinearGradient(colors: [lilacPill, purple], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var weatherGradient: LinearGradient {
        LinearGradient(colors: [weatherTop, weatherBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var ghostGradient: LinearGradient {
        LinearGradient(
            colors: [Color.white, Color(red: 0.91, green: 0.88, blue: 0.99), Color(red: 0.79, green: 0.73, blue: 0.97)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var cardGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.16, green: 0.15, blue: 0.23), Color(red: 0.12, green: 0.11, blue: 0.18)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var borderGradient: LinearGradient {
        LinearGradient(
            colors: [purple.opacity(0.55), Color.white.opacity(0.08)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Background with soft purple aurora glow

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
                    .fill(GhostTheme.purpleDeep.opacity(0.24))
                    .frame(width: 340, height: 340)
                    .blur(radius: 95)
                    .offset(x: -60 + drift * 18, y: -250 + drift * 14)

                Circle()
                    .fill(GhostTheme.purple.opacity(0.18))
                    .frame(width: 300, height: 300)
                    .blur(radius: 100)
                    .offset(x: 110 - drift * 16, y: 180 + drift * 12)

                RadialGradient(colors: [.clear, GhostTheme.inkDeep.opacity(0.88)],
                               center: .center, startRadius: 110, endRadius: 540)
            }
        }
    }

    // MARK: - Glass & Glow Cards

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
                            ? LinearGradient(colors: [GhostTheme.purple.opacity(0.85), GhostTheme.purpleDeep.opacity(0.45)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.white.opacity(0.14), Color.white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing),
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
        var scale: CGFloat = 0.97

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? scale : 1)
                .opacity(configuration.isPressed ? 0.92 : 1)
                .animation(GhostTheme.Motion.press, value: configuration.isPressed)
        }
    }

    struct GhostShimmer: ViewModifier {
        var active: Bool = true
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @State private var phase: CGFloat = -1

        func body(content: Content) -> some View {
            content.overlay {
                if active && !reduceMotion {
                    LinearGradient(colors: [.clear, Color.white.opacity(0.18), .clear],
                                   startPoint: .leading, endPoint: .trailing)
                        .scaleEffect(x: 0.5, y: 1)
                        .offset(x: phase * 260)
                        .blendMode(.plusLighter)
                        .clipped()
                        .allowsHitTesting(false)
                        .onAppear {
                            phase = -1
                            withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false)) {
                                phase = 1
                            }
                        }
                }
            }
        }
    }

    // MARK: - Header & Pill Buttons

    struct GhostHeader: View {
        let title: String
        let subtitle: String?
        var titleColor: Color = GhostTheme.textPrimary

        init(_ title: String, subtitle: String? = nil, titleColor: Color = GhostTheme.textPrimary) {
            self.title = title
            self.subtitle = subtitle
            self.titleColor = titleColor
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(titleColor)
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
                .frame(height: 54)
                .frame(maxWidth: prominent ? .infinity : nil)
                .background {
                    if prominent {
                        Capsule()
                            .fill(GhostTheme.accentGradient)
                    } else {
                        Capsule()
                            .fill(Color.white.opacity(0.03))
                            .overlay(
                                Capsule()
                                    .strokeBorder(GhostTheme.purple.opacity(0.65), lineWidth: 1.2)
                            )
                    }
                }
                .foregroundStyle(prominent ? Color(red: 0.08, green: 0.06, blue: 0.14) : GhostTheme.purpleSoft)
                .compositingGroup()
                .shadow(color: prominent ? GhostTheme.purple.opacity(0.42) : .clear, radius: 18, x: 0, y: 6)
            }
            .buttonStyle(GhostPressStyle())
        }
    }

    // MARK: - Custom Glowing Toggle (Exact Photo Match: Purple "ON" pill with white knob)

    struct GhostAlarmToggle: View {
        @Binding var isOn: Bool
        var showOnLabel: Bool = true

        var body: some View {
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.76)) {
                    isOn.toggle()
                }
            } label: {
                ZStack(alignment: isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(isOn ? GhostTheme.purple : Color.white.opacity(0.16))
                        .frame(width: showOnLabel ? 68 : 56, height: 34)
                        .shadow(color: isOn ? GhostTheme.purple.opacity(0.55) : .clear, radius: 10)

                    if showOnLabel && isOn {
                        Text("ON")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 11)
                    }

                    Circle()
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                        .padding(4)
                        .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)
                }
                .frame(width: showOnLabel ? 68 : 56, height: 34)
            }
            .buttonStyle(GhostPressStyle(scale: 0.94))
            .accessibilityLabel("Alarm toggle")
            .accessibilityValue(isOn ? "On" : "Off")
        }
    }

    // MARK: - Tab Bar Item (supports custom Ghost icon or SF Symbol)

    struct GhostTabItem: View {
        let icon: String
        let title: String
        var isGhostIcon: Bool = false
        var isSelected: Bool = false
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                VStack(spacing: 5) {
                    if isGhostIcon {
                        GhostMiniBadge(isSelected: isSelected)
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 21, weight: .semibold))
                            .symbolEffect(.bounce, value: isSelected)
                    }
                    Text(title)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(isSelected ? GhostTheme.purple : GhostTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(GhostPressStyle(scale: 0.94))
        }
    }

    struct GhostMiniBadge: View {
        var isSelected: Bool = true
        var body: some View {
            ZStack {
                UnevenRoundedRectangle(
                    topLeadingRadius: 11,
                    bottomLeadingRadius: 4,
                    bottomTrailingRadius: 4,
                    topTrailingRadius: 11,
                    style: .continuous
                )
                .fill(isSelected ? GhostTheme.purple : GhostTheme.textSecondary.opacity(0.65))
                .frame(width: 20, height: 22)

                HStack(spacing: 4) {
                    Circle().fill(GhostTheme.inkDeep).frame(width: 3.2, height: 3.2)
                    Circle().fill(GhostTheme.inkDeep).frame(width: 3.2, height: 3.2)
                }
                .offset(y: -1)
            }
        }
    }

    // MARK: - 3D Glowing Ghost Mascot (Exact Reference Photo Match)

    enum GhostMood {
        case cheerful
        case winking
        case happyClosedEyes
        case sleepy
    }

    struct GhostMascot: View {
        var isSpeaking: Bool = false
        var size: CGFloat = 84
        var mood: GhostMood = .cheerful
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @State private var blink: Bool = false
        @State private var floatUp: Bool = false

        var body: some View {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                GhostTheme.purple.opacity(isSpeaking ? 0.65 : 0.42),
                                GhostTheme.purpleDeep.opacity(0.18),
                                .clear
                            ],
                            center: .center,
                            startRadius: size * 0.08,
                            endRadius: size * 0.85
                        )
                    )
                    .frame(width: size * 1.7, height: size * 1.7)
                    .scaleEffect(isSpeaking ? 1.12 : 1.0)

                ZStack {
                    Ellipse()
                        .fill(GhostTheme.ghostGradient)
                        .frame(width: size * 0.24, height: size * 0.15)
                        .rotationEffect(.degrees(-28))
                        .offset(x: -size * 0.36, y: size * 0.02)

                    Ellipse()
                        .fill(GhostTheme.ghostGradient)
                        .frame(width: size * 0.24, height: size * 0.15)
                        .rotationEffect(.degrees(28))
                        .offset(x: size * 0.36, y: size * 0.02)

                    GhostSilhouetteShape()
                        .fill(GhostTheme.ghostGradient)
                        .frame(width: size * 0.84, height: size * 0.94)
                        .overlay(
                            GhostSilhouetteShape()
                                .stroke(Color.white.opacity(0.65), lineWidth: 1.2)
                        )
                        .shadow(color: GhostTheme.purple.opacity(0.48), radius: size * 0.22, x: 0, y: size * 0.08)

                    faceLayer
                }
                .offset(y: floatUp ? -4 : 4)
            }
            .frame(width: size * 1.35, height: size * 1.35)
            .accessibilityLabel(isSpeaking ? "Ghost coach speaking" : "Ghost coach")
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                    floatUp = true
                }
            }
        }

        private var faceLayer: some View {
            ZStack {
                HStack(spacing: size * 0.28) {
                    Ellipse()
                        .fill(GhostTheme.pinkSoft.opacity(0.75))
                        .frame(width: size * 0.13, height: size * 0.08)
                        .blur(radius: 1.5)
                    Ellipse()
                        .fill(GhostTheme.pinkSoft.opacity(0.75))
                        .frame(width: size * 0.13, height: size * 0.08)
                        .blur(radius: 1.5)
                }
                .offset(y: -size * 0.02)

                HStack(spacing: size * 0.18) {
                    leftEye
                    rightEye
                }
                .offset(y: -size * 0.10)

                if isSpeaking && !reduceMotion {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                        let t = context.date.timeIntervalSinceReferenceDate
                        let open = CGFloat(0.35 + 0.65 * abs(sin(t * 11.0)))
                        Capsule()
                            .fill(GhostTheme.inkDeep.opacity(0.88))
                            .frame(width: size * 0.13, height: max(size * 0.05, size * 0.13 * open))
                            .offset(y: size * 0.01)
                    }
                } else {
                    GhostSmileArc()
                        .stroke(GhostTheme.inkDeep.opacity(0.88), style: StrokeStyle(lineWidth: max(2, size * 0.032), lineCap: .round))
                        .frame(width: size * 0.12, height: size * 0.06)
                        .offset(y: size * 0.005)
                }
            }
        }

        @ViewBuilder
        private var leftEye: some View {
            if mood == .happyClosedEyes || blink {
                GhostHappyEyeArc()
                    .stroke(GhostTheme.inkDeep, style: StrokeStyle(lineWidth: max(2.2, size * 0.035), lineCap: .round))
                    .frame(width: size * 0.11, height: size * 0.06)
            } else {
                ZStack(alignment: .topLeading) {
                    Circle()
                        .fill(GhostTheme.inkDeep)
                        .frame(width: size * 0.105, height: size * 0.105)
                    Circle()
                        .fill(Color.white)
                        .frame(width: size * 0.035, height: size * 0.035)
                        .offset(x: size * 0.02, y: size * 0.02)
                }
            }
        }

        @ViewBuilder
        private var rightEye: some View {
            if mood == .winking || mood == .happyClosedEyes || blink {
                GhostHappyEyeArc()
                    .stroke(GhostTheme.inkDeep, style: StrokeStyle(lineWidth: max(2.2, size * 0.035), lineCap: .round))
                    .frame(width: size * 0.11, height: size * 0.06)
            } else {
                ZStack(alignment: .topLeading) {
                    Circle()
                        .fill(GhostTheme.inkDeep)
                        .frame(width: size * 0.105, height: size * 0.105)
                    Circle()
                        .fill(Color.white)
                        .frame(width: size * 0.035, height: size * 0.035)
                        .offset(x: size * 0.02, y: size * 0.02)
                }
            }
        }
    }

    struct GhostSilhouetteShape: Shape {
        func path(in rect: CGRect) -> Path {
            let w = rect.width
            let h = rect.height
            var path = Path()
            path.move(to: CGPoint(x: w * 0.10, y: h * 0.46))
            path.addQuadCurve(
                to: CGPoint(x: w * 0.50, y: h * 0.02),
                control: CGPoint(x: w * 0.10, y: h * 0.02)
            )
            path.addQuadCurve(
                to: CGPoint(x: w * 0.90, y: h * 0.46),
                control: CGPoint(x: w * 0.90, y: h * 0.02)
            )
            path.addCurve(
                to: CGPoint(x: w * 0.96, y: h * 0.86),
                control1: CGPoint(x: w * 0.91, y: h * 0.64),
                control2: CGPoint(x: w * 0.98, y: h * 0.76)
            )
            path.addQuadCurve(
                to: CGPoint(x: w * 0.72, y: h * 0.88),
                control: CGPoint(x: w * 0.86, y: h * 0.98)
            )
            path.addQuadCurve(
                to: CGPoint(x: w * 0.50, y: h * 0.94),
                control: CGPoint(x: w * 0.61, y: h * 0.80)
            )
            path.addQuadCurve(
                to: CGPoint(x: w * 0.28, y: h * 0.88),
                control: CGPoint(x: w * 0.39, y: h * 0.99)
            )
            path.addQuadCurve(
                to: CGPoint(x: w * 0.04, y: h * 0.86),
                control: CGPoint(x: w * 0.14, y: h * 0.97)
            )
            path.addCurve(
                to: CGPoint(x: w * 0.10, y: h * 0.46),
                control1: CGPoint(x: w * 0.02, y: h * 0.76),
                control2: CGPoint(x: w * 0.09, y: h * 0.64)
            )
            path.closeSubpath()
            return path
        }
    }

    struct GhostHappyEyeArc: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: rect.height * 0.85))
            path.addQuadCurve(
                to: CGPoint(x: rect.width, y: rect.height * 0.85),
                control: CGPoint(x: rect.width * 0.5, y: -rect.height * 0.25)
            )
            return path
        }
    }

    struct GhostSmileArc: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: rect.height * 0.15))
            path.addQuadCurve(
                to: CGPoint(x: rect.width, y: rect.height * 0.15),
                control: CGPoint(x: rect.width * 0.5, y: rect.height * 1.15)
            )
            return path
        }
    }
}

// MARK: - View convenience extensions

extension View {
    func ghostCard(radius: CGFloat = GhostTheme.Radius.card, glow: Bool = false) -> some View {
        modifier(GhostTheme.GhostCard(radius: radius, glow: glow))
    }

    func ghostShimmer(active: Bool = true) -> some View {
        modifier(GhostTheme.GhostShimmer(active: active))
    }

    func ghostScreen(animated: Bool = false) -> some View {
        background { GhostTheme.GhostAurora(animated: animated) }
            .preferredColorScheme(.dark)
    }
}
