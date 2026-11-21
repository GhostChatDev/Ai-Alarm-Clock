import SwiftUI

/// The companion, not the alarm controls, is the first thing you see.
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
                    burst += 1
                }
                onGreeting()
            } label: {
                Label(delighted ? "Dance with Ghost" : "Say hello", systemImage: "sparkles")
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
                // A small Lissajous roam keeps the companion inside its 290pt stage.
                GhostTheme.GhostMascot(mood: delighted ? .awake : .idle, size: 170)
                    .rotationEffect(.degrees(delighted ? sin(time * 7) * 9 : 0))
                    .scaleEffect((delighted ? 1.08 : 1) + sin(time * 2) * 0.015)
                    .offset(x: sin(time * 0.42) * 14,
                            y: sin(time * 0.84) * 12)
                    .shadow(color: GhostTheme.purpleSoft.opacity(0.3), radius: 24)
                if delighted {
                    ForEach(0..<12, id: \.self) { index in
                        let angle = Double(index) * .pi * 2 / 12
                        let travel = (time * 0.8).truncatingRemainder(dividingBy: 1)
                        Image(systemName: index.isMultiple(of: 2) ? "heart.fill" : "star.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(index.isMultiple(of: 2) ? GhostTheme.pink : GhostTheme.yellow)
                            .opacity(1 - travel)
                            .offset(x: cos(angle) * (45 + travel * 100),
                                    y: sin(angle) * (45 + travel * 100))
                    }
                }
            }
            .frame(height: 270)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
                    delighted.toggle()
                    burst += 1
                }
            }
            .accessibilityLabel("Floating ghost. Tap to wave and dance.")
        }
        .accessibilityIdentifier("ghostMascotStage")
        .accessibilityAddTraits(.isButton)
    }
}
