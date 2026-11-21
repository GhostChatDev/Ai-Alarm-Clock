import SwiftUI

/// Sleep sounds: pick a cosmic preset, mix its four layers, set a sleep timer, then play or stop.
/// Opened from the live-session pill (as a sheet) and usable as its own screen.
struct CosmicSoundMixerSheet: View {
    @Environment(SleepSoundEngine.self) private var engine
    @Environment(\.dismiss) private var dismiss
    private let timerChoices = [15, 30, 45, 60, 90]

    var body: some View {
        @Bindable var mixer = engine
        ScrollView {
            VStack(alignment: .leading, spacing: GhostTheme.Space.m) {
                Text("Pick a sound, mix it the way you like, and let it fade out on its own.")
                    .font(.subheadline)
                    .foregroundStyle(GhostTheme.textSecondary)

                VStack(spacing: GhostTheme.Space.s) {
                    ForEach(SleepSoundEngine.Preset.allCases) { preset in
                        presetRow(preset)
                    }
                }

                VStack(alignment: .leading, spacing: GhostTheme.Space.s) {
                    Text("Mix").font(.headline).foregroundStyle(GhostTheme.textPrimary)
                    layerSlider("Cosmic drone", icon: "waveform", value: $mixer.cosmicDroneVolume)
                    layerSlider("Delta waves", icon: "moon.zzz.fill", value: $mixer.deltaBeatVolume)
                    layerSlider("Theta waves", icon: "sparkles", value: $mixer.thetaWaveVolume)
                    layerSlider("Nebula rain", icon: "cloud.rain.fill", value: $mixer.nebulaRainVolume)
                }
                .ghostCard()

                VStack(alignment: .leading, spacing: GhostTheme.Space.s) {
                    Text("Sleep timer").font(.headline).foregroundStyle(GhostTheme.textPrimary)
                    Picker("Sleep timer", selection: $mixer.timerMinutes) {
                        ForEach(timerChoices, id: \.self) { minutes in
                            Text("\(minutes) min").tag(minutes)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .ghostCard()

                Button {
                    engine.toggle(minutes: engine.timerMinutes)
                } label: {
                    Label(engine.isPlaying ? "Stop · \(engine.remainingText)" : "Play \(engine.presetLabel)",
                          systemImage: engine.isPlaying ? "stop.fill" : "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(GhostTheme.inkDeep)
                        .background(GhostTheme.purpleSoft, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(GhostTheme.Space.m)
        }
        .background(GhostTheme.inkDeep.ignoresSafeArea())
        .navigationTitle("Sleep sounds")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }

    private func presetRow(_ preset: SleepSoundEngine.Preset) -> some View {
        let selected = engine.activePreset == preset
        return Button {
            engine.applyPreset(preset)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: preset.icon)
                    .font(.title3)
                    .frame(width: 32)
                    .foregroundStyle(GhostTheme.purpleSoft)
                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.rawValue).font(.headline).foregroundStyle(GhostTheme.textPrimary)
                    Text(preset.subtitle).font(.caption).foregroundStyle(GhostTheme.textSecondary)
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(GhostTheme.purple)
                }
            }
            .padding(14)
            .background(selected ? GhostTheme.cardElevated : GhostTheme.glass, in: RoundedRectangle(cornerRadius: GhostTheme.Radius.chip))
            .overlay(RoundedRectangle(cornerRadius: GhostTheme.Radius.chip).strokeBorder(selected ? GhostTheme.purple.opacity(0.6) : GhostTheme.hairline))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func layerSlider(_ title: String, icon: String, value: Binding<Double>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).frame(width: 22).foregroundStyle(GhostTheme.purpleSoft)
            Text(title).font(.subheadline).foregroundStyle(GhostTheme.textPrimary).frame(width: 110, alignment: .leading)
            Slider(value: value, in: 0...1)
                .tint(GhostTheme.purple)
                .accessibilityLabel(title)
        }
    }
}
