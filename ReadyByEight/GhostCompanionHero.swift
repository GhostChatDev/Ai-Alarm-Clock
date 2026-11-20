import SwiftUI

/// The companion, not the alarm controls, is the first thing you see.
struct GhostCompanionHero: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var delighted = false
    var onGreeting: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 7) {
                Circle().fill(GhostTheme.purpleSoft).frame(width: 6, height: 6)
                Text(delighted ? "YOUR GHOST SAYS HELLO" : "YOUR LITTLE NIGHT COMPANION")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(2)
            }
            .foregroundStyle(GhostTheme.purpleSoft)
            stage
            Text(delighted ? "Hey, you. I'm right here." : "A little magic. Just for you.")
                .font(.system(size: 23, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)
            Text("Floating together, drifting into the night.")
                .font(.subheadline)
                .foregroundStyle(GhostTheme.textSecondary)
            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    delighted.toggle()
                }
                onGreeting()
            } label: {
                Label(delighted ? "Say hello again" : "Say hello", systemImage: "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .background(.white.opacity(0.09), in: Capsule())
                    .overlay(Capsule().strokeBorder(GhostTheme.purpleSoft.opacity(0.3)))
            }
            .buttonStyle(GhostTheme.GhostPressStyle())
            .accessibilityIdentifier("ghostGreeting")
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .accessibilityElement(children: .contain)
    }

    private var stage: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { context in
            let time = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [GhostTheme.purple.opacity(0.45), .clear],
                                         center: .center, startRadius: 10, endRadius: 145))
                    .frame(width: 290, height: 290)
                    .scaleEffect(1 + 0.08 * sin(time * 1.4))
                Ellipse()
                    .stroke(GhostTheme.purpleSoft.opacity(0.22), lineWidth: 1)
                    .frame(width: 280, height: 85)
                    .rotationEffect(.degrees(-18))
                    .offset(y: 60)
                ForEach(0..<9, id: \.self) { index in
                    let phase = Double(index) * .pi * 2 / 9
                    Image(systemName: index.isMultiple(of: 3) ? "star.fill" : "sparkle")
                        .font(.system(size: index.isMultiple(of: 3) ? 12 : 7))
                        .foregroundStyle(index.isMultiple(of: 2) ? GhostTheme.pink : GhostTheme.purpleSoft)
                        .offset(x: CGFloat(cos(time * 0.45 + phase) * 130),
                                y: CGFloat(sin(time * 0.45 + phase) * 105))
                }
                GhostTheme.GhostMascot(mood: delighted ? .awake : .idle, size: 170)
                    .scaleEffect(delighted ? 1.08 : 1)
            }
            .frame(height: 270)
            .frame(maxWidth: .infinity)
        }
        .allowsHitTesting(false)
        .accessibilityLabel("Floating ghost surrounded by orbiting stars")
    }
}
