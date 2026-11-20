import SwiftUI

/// Shared native design system, iOS 17+. No network assets or external fonts.
enum GhostTheme {
    static let inkDeep = Color(red: 0.055, green: 0.045, blue: 0.095)
    static let ink = Color(red: 0.085, green: 0.07, blue: 0.14)
    static let inkRaised = Color(red: 0.14, green: 0.12, blue: 0.22)
    static let purple = Color(red: 0.69, green: 0.55, blue: 0.98)
    static let purpleSoft = Color(red: 0.81, green: 0.74, blue: 1)
    static let mint = purple
    static let mintBright = purpleSoft
    static let teal = Color(red: 0.45, green: 0.30, blue: 0.80)
    static let pink = Color(red: 1, green: 0.70, blue: 0.81)
    static let yellow = Color(red: 1, green: 0.87, blue: 0.57)
    static let ghostWhite = Color(red: 0.98, green: 0.97, blue: 1)
    static let warmCream = Color(red: 0.98, green: 0.92, blue: 0.80)
    static let cardElevated = Color(red: 0.18, green: 0.16, blue: 0.28)
    static let danger = Color(red: 0.98, green: 0.42, blue: 0.48)
    static let textPrimary = ghostWhite
    static let textSecondary = Color(red: 0.70, green: 0.66, blue: 0.80)
    static let hairline = Color.white.opacity(0.09)
    static let glass = Color.white.opacity(0.045)
    static let glassStrong = Color.white.opacity(0.09)
    enum Space { static let xs: CGFloat = 6, s: CGFloat = 10, m: CGFloat = 20, l: CGFloat = 24 }
    enum Radius { static let card: CGFloat = 26, chip: CGFloat = 14 }
    enum Motion { static let bounce = Animation.spring(response: 0.35, dampingFraction: 0.78) }
    static var accentGradient: LinearGradient {
        LinearGradient(colors: [purpleSoft, purple, teal], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var weatherGradient: LinearGradient {
        LinearGradient(colors: [Color(red: 0.34, green: 0.24, blue: 0.62), Color(red: 0.18, green: 0.13, blue: 0.36)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    enum Mood { case idle, speaking, awake, sleeping }

    struct GhostAurora: View {
        var animated = false
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        var body: some View {
            TimelineView(.animation(minimumInterval: 0.08, paused: !animated || reduceMotion)) { context in
                let t = (!animated || reduceMotion) ? 0 : context.date.timeIntervalSinceReferenceDate
                ZStack {
                    GhostTheme.inkDeep
                    RadialGradient(
                        colors: [GhostTheme.purple.opacity(0.42 + 0.12 * sin(t * 0.9)), .clear],
                        center: UnitPoint(x: 0.78 + 0.12 * cos(t * 0.5), y: 0.16 + 0.08 * sin(t * 0.6)),
                        startRadius: 10, endRadius: 520
                    )
                    RadialGradient(
                        colors: [GhostTheme.pink.opacity(0.16 + 0.08 * cos(t * 0.7)), GhostTheme.teal.opacity(0.22), .clear],
                        center: UnitPoint(x: 0.22 + 0.10 * sin(t * 0.4), y: 0.78 + 0.08 * cos(t * 0.5)),
                        startRadius: 20, endRadius: 460
                    )
                    ForEach(0..<14, id: \.self) { i in
                        let phase = Double(i) * 0.83
                        Circle()
                            .fill(GhostTheme.purpleSoft.opacity(0.35 + 0.3 * sin(t * 1.2 + phase)))
                            .frame(width: CGFloat(6 + (i % 3) * 4), height: CGFloat(6 + (i % 3) * 4))
                            .blur(radius: 1.5)
                            .offset(x: CGFloat(cos(t * 0.45 + phase) * 140),
                                    y: CGFloat(sin(t * 0.55 + phase * 1.3) * 240))
                    }
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }

    struct GhostCard: ViewModifier {
        var radius: CGFloat = 26
        var glow = false
        func body(content: Content) -> some View {
            content.padding(20)
                .background(GhostTheme.inkRaised.opacity(0.85), in: RoundedRectangle(cornerRadius: radius))
                .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(GhostTheme.hairline))
                .shadow(color: glow ? GhostTheme.purple.opacity(0.15) : .clear, radius: 24)
        }
    }

    struct GhostPressStyle: ButtonStyle {
        var scale: CGFloat = 0.97
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .opacity(configuration.isPressed ? 0.7 : 1)
                .scaleEffect(configuration.isPressed ? scale : 1)
                .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
        }
    }

    struct GhostAlarmToggle: View {
        @Binding var isOn: Bool
        var body: some View {
            Button {
                withAnimation(GhostTheme.Motion.bounce) { isOn.toggle() }
            } label: {
                ZStack(alignment: isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(isOn ? GhostTheme.purple : GhostTheme.cardElevated)
                        .frame(width: 64, height: 34)
                    Circle().fill(.white).frame(width: 26, height: 26).padding(4)
                }
                .frame(width: 64, height: 34)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isOn ? "Alarm On" : "Alarm Off")
        }
    }

    /// Cheerful moving Ghost Mascot: floats, sways, waves, blinks and bursts sparkles on tap.
    struct GhostMascot: View {
        var mood: Mood
        var size: CGFloat
        @State private var burst = 0
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        init(mood: Mood = .idle, size: CGFloat = 80) {
            self.mood = mood
            self.size = size
        }

        init(isSpeaking: Bool, size: CGFloat = 80) {
            self.init(mood: isSpeaking ? .speaking : .idle, size: size)
        }

        var body: some View {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
                let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
                mascot(t: t)
            }
            .frame(width: size, height: size * 1.15)
            .contentShape(Rectangle())
            .onTapGesture { burst += 1 }
            .accessibilityLabel("Ghost Mascot")
        }

        private var speed: Double { mood == .sleeping ? 0.6 : (mood == .speaking ? 2.4 : 1.4) }

        private func mascot(t: TimeInterval) -> some View {
            let float = CGFloat(sin(t * speed)) * size * 0.06
            let sway = Angle.degrees(sin(t * speed * 0.8) * (mood == .sleeping ? 2 : 6))
            let wave = Angle.degrees(mood == .sleeping ? 10 : 25 + sin(t * 5) * 30)
            let blink = mood != .sleeping && t.truncatingRemainder(dividingBy: 3.2) < 0.12
            let mouthOpen = mood == .speaking ? CGFloat(0.5 + 0.5 * abs(sin(t * 9))) : 0.3
            return ZStack {
                Ellipse()
                    .fill(GhostTheme.purple.opacity(0.25))
                    .frame(width: size * 0.6, height: size * 0.1)
                    .offset(y: size * 0.55)
                ZStack {
                    Capsule()
                        .fill(LinearGradient(colors: [GhostTheme.ghostWhite, GhostTheme.purpleSoft],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: size * 0.16, height: size * 0.32)
                        .rotationEffect(wave, anchor: .bottom)
                        .offset(x: size * 0.40, y: -size * 0.02)
                    UnevenRoundedRectangle(topLeadingRadius: size * 0.42, bottomLeadingRadius: size * 0.12,
                                           bottomTrailingRadius: size * 0.12, topTrailingRadius: size * 0.42)
                        .fill(LinearGradient(colors: [GhostTheme.ghostWhite, GhostTheme.purpleSoft],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: size * 0.84, height: size * 0.95)
                        .shadow(color: GhostTheme.purple.opacity(0.55), radius: size * 0.15)
                    face(blink: blink, mouthOpen: mouthOpen)
                        .offset(y: -size * 0.08)
                    if mood == .sleeping {
                        Text("z")
                            .font(.system(size: size * 0.2, weight: .bold, design: .rounded))
                            .foregroundStyle(GhostTheme.purpleSoft)
                            .offset(x: size * 0.45, y: -size * 0.5)
                    }
                }
                .rotationEffect(sway)
                .offset(y: float)
                sparkles
            }
        }

        private func face(blink: Bool, mouthOpen: CGFloat) -> some View {
            HStack(spacing: size * 0.12) {
                Circle().fill(GhostTheme.pink.opacity(0.7)).frame(width: size * 0.1)
                VStack(spacing: size * 0.06) {
                    HStack(spacing: size * 0.16) {
                        eye(blink: blink)
                        eye(blink: blink)
                    }
                    Capsule().fill(GhostTheme.inkDeep)
                        .frame(width: size * 0.16, height: size * 0.1 * mouthOpen + 2)
                }
                Circle().fill(GhostTheme.pink.opacity(0.7)).frame(width: size * 0.1)
            }
        }

        private func eye(blink: Bool) -> some View {
            Group {
                if mood == .sleeping || blink {
                    Capsule().fill(GhostTheme.inkDeep).frame(width: size * 0.12, height: 3)
                } else {
                    Ellipse().fill(GhostTheme.inkDeep).frame(width: size * 0.1, height: size * 0.14)
                }
            }
            .frame(height: size * 0.14)
        }

        private var sparkles: some View {
            ZStack {
                ForEach(0..<6, id: \.self) { i in
                    let angle = Double(i) / 6 * 2 * .pi
                    Image(systemName: "sparkle")
                        .font(.system(size: size * 0.12))
                        .foregroundStyle(i.isMultiple(of: 2) ? GhostTheme.yellow : GhostTheme.pink)
                        .offset(x: burst.isMultiple(of: 2) ? 0 : CGFloat(cos(angle)) * size * 0.7,
                                y: burst.isMultiple(of: 2) ? 0 : CGFloat(sin(angle)) * size * 0.7)
                        .opacity(burst.isMultiple(of: 2) ? 0 : 1)
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: burst)
            .allowsHitTesting(false)
        }
    }
}

extension View {
    func ghostCard(glow: Bool = false) -> some View {
        modifier(GhostTheme.GhostCard(glow: glow))
    }

    func ghostScreen(animated: Bool = false) -> some View {
        background(GhostTheme.GhostAurora(animated: animated))
            .foregroundStyle(GhostTheme.textPrimary)
            .tint(GhostTheme.purple)
    }
}
