import SwiftUI

/// Shared native design system & synchronized live-wallpaper engine, iOS 17+.
enum GhostTheme {
    static let inkDeep = Color(red: 0.04, green: 0.032, blue: 0.078)
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

    /// Shared global heartbeat frequency (rad/sec) so the live wallpaper, cards, and Ghost mascot move in sync.
    static let syncSpeed: Double = 1.35

    static func syncWave(at date: Date = .now, phase: Double = 0) -> Double {
        sin(date.timeIntervalSinceReferenceDate * syncSpeed + phase)
    }

    static var accentGradient: LinearGradient {
        LinearGradient(colors: [purpleSoft, purple, teal], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    struct GhostAurora: View {
        var animated = true
        var nightstand = false
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            TimelineView(.animation(minimumInterval: 0.05, paused: !animated || reduceMotion)) { context in
                let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
                let beat = sin(t * GhostTheme.syncSpeed)
                let slow = t * 0.42

                Canvas { ctx, size in
                    let w = size.width
                    let h = size.height

                    // Base deep night sky
                    ctx.fill(
                        Path(CGRect(origin: .zero, size: size)),
                        with: .color(nightstand ? Color(red: 0.015, green: 0.01, blue: 0.035) : GhostTheme.inkDeep)
                    )

                    // Synchronized drifting aurora blobs
                    let dimFactor: Double = nightstand ? 0.55 : 1.0
                    let center1 = CGPoint(
                        x: w * (0.72 + 0.18 * cos(slow)),
                        y: h * (0.18 + 0.09 * sin(t * GhostTheme.syncSpeed))
                    )
                    let center2 = CGPoint(
                        x: w * (0.24 + 0.16 * sin(slow * 0.85)),
                        y: h * (0.58 + 0.10 * cos(t * GhostTheme.syncSpeed))
                    )
                    let center3 = CGPoint(
                        x: w * (0.55 + 0.20 * sin(slow * 0.6 + 1.4)),
                        y: h * (0.85 + 0.07 * sin(t * GhostTheme.syncSpeed + 0.8))
                    )

                    let r1 = max(w, h) * CGFloat(0.55 + 0.05 * beat)
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: center1.x - r1, y: center1.y - r1, width: r1 * 2, height: r1 * 2)),
                        with: .radialGradient(
                            Gradient(colors: [GhostTheme.purple.opacity(0.27 * dimFactor), .clear]),
                            center: center1, startRadius: 8, endRadius: r1
                        )
                    )

                    let r2 = max(w, h) * CGFloat(0.50 - 0.04 * beat)
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: center2.x - r2, y: center2.y - r2, width: r2 * 2, height: r2 * 2)),
                        with: .radialGradient(
                            Gradient(colors: [GhostTheme.teal.opacity(0.24 * dimFactor), .clear]),
                            center: center2, startRadius: 8, endRadius: r2
                        )
                    )

                    let r3 = max(w, h) * CGFloat(0.45 + 0.04 * beat)
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: center3.x - r3, y: center3.y - r3, width: r3 * 2, height: r3 * 2)),
                        with: .radialGradient(
                            Gradient(colors: [GhostTheme.pink.opacity(0.14 * dimFactor), .clear]),
                            center: center3, startRadius: 8, endRadius: r3
                        )
                    )

                    // Flowing aurora wave ribbon synced with mascot bobbing
                    var ribbon = Path()
                    ribbon.move(to: CGPoint(x: 0, y: h * 0.32))
                    for step in stride(from: 0.0, through: Double(w), by: 16.0) {
                        let nx = step / max(1.0, Double(w))
                        let y = Double(h) * (0.30 + 0.045 * sin(nx * .pi * 2.5 + t * GhostTheme.syncSpeed) + 0.02 * cos(nx * .pi * 4 - slow))
                        ribbon.addLine(to: CGPoint(x: step, y: y))
                    }
                    ribbon.addLine(to: CGPoint(x: w, y: 0))
                    ribbon.addLine(to: CGPoint(x: 0, y: 0))
                    ribbon.closeSubpath()
                    ctx.fill(
                        ribbon,
                        with: .linearGradient(
                            Gradient(colors: [GhostTheme.purpleSoft.opacity(0.10 * dimFactor), .clear]),
                            startPoint: CGPoint(x: w * 0.5, y: 0),
                            endPoint: CGPoint(x: w * 0.5, y: h * 0.42)
                        )
                    )

                    // Twinkling starfield & floating spirit orbs moving in sync
                    for i in 0..<22 {
                        let seed = Double(i) * 1.6180339
                        let baseX = ( seed * 0.37 ).truncatingRemainder(dividingBy: 1.0)
                        let baseY = ( seed * 0.73 ).truncatingRemainder(dividingBy: 1.0)
                        let driftX = 0.025 * sin(t * GhostTheme.syncSpeed * 0.5 + seed * 3.0)
                        let driftY = 0.03 * cos(t * GhostTheme.syncSpeed * 0.5 + seed * 2.1)
                        let px = CGFloat((baseX + driftX + 1.0).truncatingRemainder(dividingBy: 1.0)) * w
                        let py = CGFloat((baseY + driftY + 1.0).truncatingRemainder(dividingBy: 1.0)) * h
                        let twinkle = 0.25 + 0.65 * (0.5 + 0.5 * sin(t * GhostTheme.syncSpeed + seed * 2.4))
                        let radius: CGFloat = (i % 5 == 0) ? 2.8 : 1.5
                        let rect = CGRect(x: px - radius, y: py - radius, width: radius * 2, height: radius * 2)
                        ctx.fill(
                            Path(ellipseIn: rect),
                            with: .color((i % 4 == 0 ? GhostTheme.purpleSoft : GhostTheme.ghostWhite).opacity(twinkle * dimFactor))
                        )
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
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        func body(content: Content) -> some View {
            TimelineView(.animation(minimumInterval: 0.12, paused: !glow || reduceMotion)) { context in
                let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
                let pulse = 0.5 + 0.5 * sin(t * GhostTheme.syncSpeed)
                content
                    .padding(20)
                    .background(GhostTheme.inkRaised.opacity(0.84), in: RoundedRectangle(cornerRadius: radius))
                    .overlay(
                        RoundedRectangle(cornerRadius: radius)
                            .strokeBorder(
                                glow
                                    ? GhostTheme.purpleSoft.opacity(0.18 + 0.16 * pulse)
                                    : GhostTheme.hairline,
                                lineWidth: glow ? 1.2 : 1.0
                            )
                    )
                    .shadow(color: glow ? GhostTheme.purple.opacity(0.16 + 0.14 * pulse) : .clear, radius: 22, y: 6)
            }
        }
    }

    struct GhostPressStyle: ButtonStyle {
        var scale: CGFloat = 0.97
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .opacity(configuration.isPressed ? 0.72 : 1)
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
                Text(title)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(GhostTheme.purpleSoft)
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
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .foregroundStyle(prominent ? GhostTheme.inkDeep : GhostTheme.purpleSoft)
                .background {
                    if prominent { GhostTheme.accentGradient }
                    else { GhostTheme.glassStrong }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(GhostPressStyle())
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
                }
                .foregroundStyle(isSelected ? GhostTheme.purpleSoft : GhostTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? GhostTheme.purple.opacity(0.14) : .clear,
                            in: RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(GhostPressStyle())
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
    }

    struct GhostMascot: View {
        var isSpeaking = false
        var isSleeping = false
        var size: CGFloat = 100
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            TimelineView(.animation(minimumInterval: 0.06, paused: reduceMotion)) { context in
                let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
                let syncSin = sin(t * GhostTheme.syncSpeed)
                let syncCos = cos(t * GhostTheme.syncSpeed)
                let blink = !reduceMotion && (isSleeping || t.truncatingRemainder(dividingBy: 4.2) < 0.16)

                ZStack {
                    // Synchronized aura halo
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [
                                    GhostTheme.purple.opacity(0.36 + 0.12 * syncSin),
                                    GhostTheme.pink.opacity(0.14),
                                    .clear
                                ],
                                center: .center,
                                startRadius: size * 0.05,
                                endRadius: size * 0.58
                            )
                        )
                        .frame(width: size * (1.08 + 0.06 * CGFloat(syncSin)), height: size * (0.82 + 0.05 * CGFloat(syncSin)))

                    // Orbiting spirit sparkles moving in sync
                    ForEach(0..<3, id: \.self) { idx in
                        let angle = t * GhostTheme.syncSpeed + Double(idx) * (.pi * 2.0 / 3.0)
                        Circle()
                            .fill(idx == 0 ? GhostTheme.yellow : GhostTheme.purpleSoft)
                            .frame(width: size * 0.065, height: size * 0.065)
                            .shadow(color: GhostTheme.purpleSoft, radius: 4)
                            .offset(
                                x: CGFloat(cos(angle)) * size * 0.48,
                                y: CGFloat(sin(angle * 0.8)) * size * 0.34 - size * 0.06
                            )
                            .opacity(0.55 + 0.45 * sin(angle))
                    }

                    // 3D-shaded Ghost body
                    GhostShape(wavePhase: t * GhostTheme.syncSpeed)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white,
                                    Color(red: 0.89, green: 0.86, blue: 0.99),
                                    Color(red: 0.75, green: 0.68, blue: 0.96)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            GhostShape(wavePhase: t * GhostTheme.syncSpeed)
                                .stroke(.white.opacity(0.85), lineWidth: 1.2)
                        )
                        .frame(width: size * 0.78, height: size * 0.87)
                        .scaleEffect(
                            x: 1.0 + (reduceMotion ? 0 : CGFloat(syncCos) * 0.022),
                            y: 1.0 - (reduceMotion ? 0 : CGFloat(syncCos) * 0.022)
                        )

                    // Eyes (closed/happy arcs when sleeping or blinking)
                    HStack(spacing: size * 0.18) {
                        ForEach(0..<2, id: \.self) { _ in
                            Capsule()
                                .fill(GhostTheme.inkDeep)
                                .frame(
                                    width: isSleeping ? size * 0.095 : size * 0.068,
                                    height: blink ? size * 0.024 : size * 0.11
                                )
                        }
                    }
                    .offset(y: -size * 0.06)

                    // Rosy cheeks
                    HStack(spacing: size * 0.30) {
                        ForEach(0..<2, id: \.self) { _ in
                            Ellipse()
                                .fill(GhostTheme.pink.opacity(0.68))
                                .frame(width: size * 0.14, height: size * 0.068)
                        }
                    }
                    .offset(y: size * 0.035)

                    // Mouth
                    Capsule()
                        .fill(GhostTheme.inkDeep.opacity(0.82))
                        .frame(
                            width: isSleeping ? size * 0.065 : size * 0.12,
                            height: isSpeaking
                                ? size * (0.045 + abs(sin(t * 13)) * 0.085)
                                : (isSleeping ? size * 0.055 : size * 0.038)
                        )
                        .offset(y: size * 0.10)

                    // Floating "Zzz" bubbles in Sleep / Nightstand mode
                    if isSleeping {
                        ForEach(0..<2, id: \.self) { z in
                            let progress = ((t * 0.45 + Double(z) * 0.5).truncatingRemainder(dividingBy: 1.0))
                            Text("z")
                                .font(.system(size: size * (0.14 + CGFloat(progress) * 0.08), weight: .bold, design: .rounded))
                                .foregroundStyle(GhostTheme.purpleSoft.opacity(1.0 - progress))
                                .offset(
                                    x: size * (0.34 + CGFloat(progress) * 0.16),
                                    y: -size * (0.24 + CGFloat(progress) * 0.32)
                                )
                        }
                    }
                }
                .frame(width: size * 1.18, height: size * 1.14)
                .rotationEffect(.degrees(reduceMotion ? 0 : syncCos * 2.8))
                .offset(y: CGFloat(syncSin) * (reduceMotion ? 0 : 5.5))
            }
            .frame(width: size * 1.18, height: size * 1.14)
            .accessibilityLabel(isSleeping ? "Sleeping Ghost mascot" : (isSpeaking ? "Ghost mascot speaking" : "Friendly Ghost mascot"))
        }
    }

    struct GhostShape: Shape {
        var wavePhase: Double = 0
        func path(in r: CGRect) -> Path {
            var p = Path()
            let w = r.width, h = r.height
            let sway = CGFloat(sin(wavePhase)) * (h * 0.025)
            p.move(to: CGPoint(x: 0, y: h * 0.9))
            p.addLine(to: CGPoint(x: 0, y: h * 0.45))
            p.addCurve(
                to: CGPoint(x: w, y: h * 0.45),
                control1: CGPoint(x: 0, y: -h * 0.15),
                control2: CGPoint(x: w, y: -h * 0.15)
            )
            p.addLine(to: CGPoint(x: w, y: h * 0.9))
            for i in stride(from: 4, through: 1, by: -1) {
                let x = CGFloat(i) * w / 4
                let crest = (i.isMultiple(of: 2) ? h * 1.08 : h * 0.72) + (i.isMultiple(of: 2) ? sway : -sway)
                p.addQuadCurve(
                    to: CGPoint(x: x - w / 4, y: h * 0.9),
                    control: CGPoint(x: x - w / 8, y: crest)
                )
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
    func ghostScreen(animated: Bool = true, nightstand: Bool = false) -> some View {
        background(GhostTheme.GhostAurora(animated: animated, nightstand: nightstand))
            .foregroundStyle(GhostTheme.textPrimary)
            .tint(GhostTheme.purple)
    }
}
