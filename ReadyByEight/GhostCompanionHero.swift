import SwiftUI

/// A roaming companion whose drift, breathing and halo share one animation clock.
struct GhostCompanionHero: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var delighted = false
    @State private var burst = 0
    var onGreeting: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 7) {
                Circle().fill(GhostTheme.purpleSoft).frame(width: 6, height: 6)
                Text(delighted ? "YOUR GHOST SAYS HELLO" : "YOUR LITTLE NIGHT COMPANION")
                    .font(.system(size: 10, weight: .bold, design: .rounded)).tracking(2)
            }
            .foregroundStyle(GhostTheme.purpleSoft)
            stage
            Text(delighted ? "Hey, you. I'm right here." : "A little magic. Just for you.")
                .font(.system(size: 23, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center).contentTransition(.opacity)
            Text("Floating together, drifting into the night.")
                .font(.subheadline).foregroundStyle(GhostTheme.textSecondary)
            Button(delighted ? "Say hello again" : "Say hello", action: greet)
                .buttonStyle(GhostPrimaryButtonStyle())
                .frame(maxWidth: 230)
        }
        .frame(maxWidth: .infinity)
        .animation(.smooth(duration: 0.5), value: delighted)
    }

    private func greet() {
        onGreeting()
        delighted.toggle()
        burst += 1
    }

    private var stage: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 1.0 / 30.0, paused: reduceMotion)) { context in
            let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
            GeometryReader { geo in
                let width = min(geo.size.width, 360)
                let x = reduceMotion ? 0 : sin(t * 0.34) * width * 0.18
                let y = reduceMotion ? 0 : sin(t * 0.68) * 9
                ZStack {
                    ForEach(0..<9, id: \.self) { index in
                        let angle = t * 0.24 + Double(index) * (2 * Double.pi / 9)
                        let radius = min(geo.size.width * 0.36, 132)
                        let starX = cos(angle) * radius
                        let starY = sin(angle) * 31 - 52
                        Image(systemName: index.isMultiple(of: 3) ? "star.fill" : "sparkle")
                            .font(.system(size: index.isMultiple(of: 2) ? 9 : 12))
                            .foregroundStyle(GhostTheme.lavender)
                            .opacity(0.35 + 0.5 * abs(sin(t + Double(index))))
                            .position(x: geo.size.width / 2 + starX, y: 108 + starY)
                    }
                    Circle()
                        .fill(GhostTheme.purple.opacity(0.12))
                        .frame(width: 185, height: 185).blur(radius: 25)
                        .scaleEffect(1 + 0.08 * sin(t * 1.15))
                        .position(x: geo.size.width / 2 + x, y: 108 + y)
                    GhostMascot(isSpeaking: delighted, size: 140)
                        .shadow(color: GhostTheme.lavender.opacity(0.38), radius: 24)
                        .position(x: geo.size.width / 2 + x, y: 108 + y)
                        .rotationEffect(.degrees(sin(t * 0.34) * 5))
                        .scaleEffect(delighted ? 1.08 : 1)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { greet() }
            }
            .frame(height: 218)
        }
        .accessibilityLabel("Roaming ghost. Tap to wave and dance.")
        .accessibilityIdentifier("ghostMascotStage")
        .accessibilityAddTraits(.isButton)
    }
}

