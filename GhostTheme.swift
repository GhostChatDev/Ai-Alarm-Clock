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
    enum Mood {
        case idle, speaking, awake, sleeping
    }
    struct GhostAurora: View {
        var animated = false
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        var body: some View {
            TimelineView(.animation(minimumInterval: 0.08, paused: !animated || reduceMotion)) { context in
                let t = (!animated || reduceMotion) ? 0 : context.date.timeIntervalSinceReferenceDate
                ZStack {
                    GhostTheme.inkDeep
                    RadialGradient(
                        colors: [GhostTheme.purple.opacity(0.24 + 0.06 * sin(t * 0.9)), .clear],
                        center: UnitPoint(x: 0.78 + 0.12 * cos(t * 0.5), y: 0.16 + 0.08 * sin(t * 0.6)),
                        startRadius: 10, endRadius: 520
                    )
                    RadialGradient(
                        colors: [GhostTheme.teal.opacity(0.20 + 0.05 * cos(t * 0.7)), .clear],
                        center: UnitPoint(x: 0.22 + 0.10 * sin(t * 0.4), y: 0.78 + 0.08 * cos(t * 0.5)),
                        startRadius: 20, endRadius: 460
                    )
                    ForEach(0..<6, id: \.self) { i in
                        let phase = Double(i) * 1.15
                        Circle()
                            .fill(GhostTheme.purpleSoft.opacity(0.18 + 0.12 * sin(t * 1.2 + phase)))
                            .frame(width: CGFloat(6 + (i % 3) * 4), height: CGFloat(6 + (i % 3) * 4))
                            .blur(radius: 1.5)
                            .offset(
                                x: CGFloat(cos(t * 0.45 + phase) * 140),
                                y: CGFloat(sin(t * 0.55 + phase * 1.3) * 240)
                            )
                    }
                }
            }.ignoresSafeArea().allowsHitTesting(false)
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
            configuration.label.opacity(configuration.isPressed ? 0.7 : 1)
                .scaleEffect(configuration.isPressed ? scale : 1)
                .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
        }
    }
    struct GhostHeader: View {
        let title: String
        let subtitle: String?
        init(_ title: String, subtitle: String? = nil) { self.title = title; self.subtitle = subtitle }
        var body: some View {
            VStack(alignment: .leading, spacing: 7) {
                Text(title).font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(GhostTheme.purpleSoft)
                if let subtitle { Text(subtitle).font(.subheadline).foregroundStyle(GhostTheme.textSecondary) }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    struct GhostPillButton: View {
        let title: String
        var systemImage: String?
        var prominent = true
        let action: () -> Void
        init(_ title: String, systemImage: String? = nil, prominent: Bool = true, action: @escaping () -> Void) {
            self.title = title; self.systemImage = systemImage; self.prominent = prominent; self.action = action
        }
        var body: some View {
            Button(action: action) {
                HStack {
                    if let systemImage { Image(systemName: systemImage) }
                    Text(title).fontWeight(.semibold)
                }.frame(maxWidth: .infinity).padding(16)
                    .foregroundStyle(prominent ? GhostTheme.inkDeep : GhostTheme.purpleSoft)
                    .background {
                        if prominent { GhostTheme.accentGradient }
                        else { GhostTheme.glassStrong }
                    }.clipShape(RoundedRectangle(cornerRadius: 18))
            }.buttonStyle(GhostPressStyle())
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
                    if isOn {
                        Text("ON")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 11)
                    }
                    Circle()
                        .fill(.white)
                        .frame(width: 26, height: 26)
                        .padding(4)
                }
                .frame(width: 64, height: 34)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isOn ? "Alarm On" : "Alarm Off")
        }
    }
    struct GhostTabItem: View {
        let icon: String
        let title: String
        var isSelected = false
        let action: () -> Void
        var body: some View {
            Button(action: action) {
                VStack(spacing: 6) {
                    Image(systemName: icon).font(.system(size: 21))
                    Text(title).font(.caption2.weight(.semibold))
                }.foregroundStyle(isSelected ? GhostTheme.purpleSoft : GhostTheme.textSecondary)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(isSelected ? GhostTheme.purple.opacity(0.12) : .clear,
                                in: RoundedRectangle(cornerRadius: 18))
            }.buttonStyle(GhostPressStyle()).accessibilityAddTraits(isSelected ? .isSelected : [])
        }
    }
    struct GhostMascot: View {
        var mood: Mood = .idle
        var isSpeaking = false
        var size: CGFloat = 100
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        var body: some View {
            TimelineView(.animation(minimumInterval: 0.08, paused: reduceMotion)) { context in
                let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
                let sleeping = (mood == .sleeping)
                let speaking = isSpeaking || (mood == .speaking)
                let blink = !reduceMotion && (sleeping || t.truncatingRemainder(dividingBy: 4.2) < 0.16)
                ZStack {
                    Ellipse().fill(GhostTheme.purple.opacity(0.26 + 0.08 * sin(t * 1.4))).blur(radius: size * 0.15)
                        .frame(width: size, height: size * 0.7)
                    GhostShape().fill(.linearGradient(colors: [.white, Color(red: 0.81, green: 0.79, blue: 0.97)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay(GhostShape().stroke(.white.opacity(0.8), lineWidth: 1))
                        .frame(width: size * 0.78, height: size * 0.87)
                    HStack(spacing: size * 0.18) {
                        ForEach(0..<2, id: \.self) { _ in
                            Capsule().fill(GhostTheme.inkDeep)
                                .frame(width: size * 0.065, height: blink ? size * 0.025 : size * 0.11)
                        }
                    }.offset(y: -size * 0.06)
                    HStack(spacing: size * 0.30) {
                        ForEach(0..<2, id: \.self) { _ in
                            Ellipse().fill(GhostTheme.pink.opacity(0.65)).frame(width: size * 0.14, height: size * 0.065)
                        }
                    }.offset(y: size * 0.035)
                    Capsule().fill(GhostTheme.inkDeep.opacity(0.8))
                        .frame(width: size * 0.12, height: speaking ? size * (0.04 + abs(sin(t * 13)) * 0.08) : size * 0.035)
                        .offset(y: size * 0.10)
                }.frame(width: size * 1.15, height: size * 1.1)
                    .offset(y: CGFloat(sin(t * 1.4)) * (reduceMotion ? 0 : 4))
            }.frame(width: size * 1.15, height: size * 1.1)
                .accessibilityLabel(isSpeaking ? "Ghost speaking" : "Ghost Mascot")
        }
    }
    struct GhostShape: Shape {
        func path(in r: CGRect) -> Path {
            var p = Path()
            let w = r.width, h = r.height
            p.move(to: CGPoint(x: 0, y: h * 0.9))
            p.addLine(to: CGPoint(x: 0, y: h * 0.45))
            p.addCurve(to: CGPoint(x: w, y: h * 0.45), control1: CGPoint(x: 0, y: -h * 0.15),
                       control2: CGPoint(x: w, y: -h * 0.15))
            p.addLine(to: CGPoint(x: w, y: h * 0.9))
            for i in stride(from: 4, through: 1, by: -1) {
                let x = CGFloat(i) * w / 4
                p.addQuadCurve(to: CGPoint(x: x - w / 4, y: h * 0.9),
                               control: CGPoint(x: x - w / 8, y: i.isMultiple(of: 2) ? h * 1.08 : h * 0.72))
            }
            p.closeSubpath()
            return p
        }
    }
}

extension View {
    func ghostCard(radius: CGFloat = 26, glow: Bool = false, elevated: Bool = false) -> some View {
        modifier(GhostTheme.GhostCard(radius: radius, glow: glow || elevated))
    }
    func ghostScreen(animated: Bool = false) -> some View {
        background(GhostTheme.GhostAurora(animated: animated))
            .foregroundStyle(GhostTheme.textPrimary).tint(GhostTheme.purple)
    }
}
