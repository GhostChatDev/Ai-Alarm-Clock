import SwiftUI
import AVFoundation

/// Real-time procedural cosmic soundscape synthesizer using AVAudioEngine + AVAudioSourceNode.
/// Generates zero-loop-seam harmonic pads, Delta/Theta binaural beats, and filtered cosmic rain/noise.
@Observable @MainActor
final class SleepSoundEngine {
    enum Preset: String, CaseIterable, Identifiable {
        case deepSpaceDrift = "Deep Space Drift"
        case remStarlight = "REM Starlight"
        case nebulaRain = "Nebula Rain"
        case healing432 = "432Hz Healing"

        var id: String { rawValue }
        var subtitle: String {
            switch self {
            case .deepSpaceDrift: "432Hz pad + 2.5Hz Delta deep sleep waves"
            case .remStarlight: "528Hz shimmer + 6Hz Theta dream waves"
            case .nebulaRain: "Warm brown noise + gentle cosmic rain"
            case .healing432: "Pure harmonic chord pad + light stardust"
            }
        }
        var icon: String {
            switch self {
            case .deepSpaceDrift: "moon.zzz.fill"
            case .remStarlight: "sparkles"
            case .nebulaRain: "cloud.rain.fill"
            case .healing432: "waveform.path.ecg"
            }
        }
    }

    var isPlaying = false
    var activePreset: Preset = .deepSpaceDrift
    var cosmicDroneVolume: Double = 0.65 { didSet { syncParams() } }
    var deltaBeatVolume: Double = 0.45 { didSet { syncParams() } }
    var thetaWaveVolume: Double = 0.25 { didSet { syncParams() } }
    var nebulaRainVolume: Double = 0.35 { didSet { syncParams() } }
    var masterGain: Double = 1.0 { didSet { syncParams() } }
    var currentAmplitude: Double = 0.0
    var timerMinutes: Int = 30
    var remainingSeconds: Int = 0

    private var engine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    private var timerTask: Task<Void, Never>?

    private final class SynthBox: @unchecked Sendable {
        var drone: Float = 0.65
        var delta: Float = 0.45
        var theta: Float = 0.25
        var rain: Float = 0.35
        var master: Float = 1.0
        var phase432: Double = 0
        var phase528: Double = 0
        var phaseDeltaL: Double = 0
        var phaseDeltaR: Double = 0
        var phaseThetaL: Double = 0
        var phaseThetaR: Double = 0
        var phaseLFO: Double = 0
        var brownStateL: Float = 0
        var brownStateR: Float = 0
        var rngState: UInt64 = 0xCAFEBABE12345678

        func nextWhite() -> Float {
            rngState = rngState &* 6364136223846793005 &+ 1442695040888963407
            let bits = UInt32(truncatingIfNeeded: rngState >> 32)
            return (Float(bits) / Float(UInt32.max)) * 2.0 - 1.0
        }
    }

    private let box = SynthBox()

    func applyPreset(_ preset: Preset) {
        activePreset = preset
        switch preset {
        case .deepSpaceDrift:
            cosmicDroneVolume = 0.68
            deltaBeatVolume = 0.55
            thetaWaveVolume = 0.10
            nebulaRainVolume = 0.30
        case .remStarlight:
            cosmicDroneVolume = 0.55
            deltaBeatVolume = 0.15
            thetaWaveVolume = 0.60
            nebulaRainVolume = 0.25
        case .nebulaRain:
            cosmicDroneVolume = 0.35
            deltaBeatVolume = 0.25
            thetaWaveVolume = 0.20
            nebulaRainVolume = 0.75
        case .healing432:
            cosmicDroneVolume = 0.80
            deltaBeatVolume = 0.30
            thetaWaveVolume = 0.30
            nebulaRainVolume = 0.15
        }
        if !isPlaying {
            start(minutes: timerMinutes)
        }
    }

    func toggle(minutes: Int? = nil) {
        if isPlaying {
            stop()
        } else {
            start(minutes: minutes ?? timerMinutes)
        }
    }

    func start(minutes: Int = 30) {
        timerMinutes = minutes
        remainingSeconds = minutes * 60
        masterGain = 1.0
        syncParams()

        if engine == nil {
            setupEngine()
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            try engine?.start()
            isPlaying = true
            startCountdown()
        } catch {
            // In Simulator or headless environments where audio hardware is unavailable, still run visual state.
            isPlaying = true
            startCountdown()
        }
    }

    func stop() {
        timerTask?.cancel()
        timerTask = nil
        engine?.stop()
        isPlaying = false
        currentAmplitude = 0
        remainingSeconds = 0
    }

    private func syncParams() {
        box.drone = Float(cosmicDroneVolume)
        box.delta = Float(deltaBeatVolume)
        box.theta = Float(thetaWaveVolume)
        box.rain = Float(nebulaRainVolume)
        box.master = Float(masterGain)
    }

    private func setupEngine() {
        let audioEngine = AVAudioEngine()
        let mainMixer = audioEngine.mainMixerNode
        let outputFormat = mainMixer.outputFormat(forBus: 0)
        let sampleRate = max(outputFormat.sampleRate, 44_100)
        guard let stereoFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2) else { return }

        let synthBox = self.box
        let node = AVAudioSourceNode(format: stereoFormat) { _, _, frameCount, audioBufferList -> OSStatus in
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let twoPi = Double.pi * 2.0
            let inc432 = twoPi * 216.0 / sampleRate
            let inc528 = twoPi * 264.0 / sampleRate
            let incDeltaL = twoPi * 108.0 / sampleRate
            let incDeltaR = twoPi * 110.5 / sampleRate // 2.5 Hz Delta beat
            let incThetaL = twoPi * 160.0 / sampleRate
            let incThetaR = twoPi * 166.0 / sampleRate // 6.0 Hz Theta beat
            let incLFO = twoPi * 0.12 / sampleRate

            for frame in 0..<Int(frameCount) {
                synthBox.phase432 += inc432
                synthBox.phase528 += inc528
                synthBox.phaseDeltaL += incDeltaL
                synthBox.phaseDeltaR += incDeltaR
                synthBox.phaseThetaL += incThetaL
                synthBox.phaseThetaR += incThetaR
                synthBox.phaseLFO += incLFO

                if synthBox.phase432 > twoPi { synthBox.phase432 -= twoPi }
                if synthBox.phase528 > twoPi { synthBox.phase528 -= twoPi }
                if synthBox.phaseDeltaL > twoPi { synthBox.phaseDeltaL -= twoPi }
                if synthBox.phaseDeltaR > twoPi { synthBox.phaseDeltaR -= twoPi }
                if synthBox.phaseThetaL > twoPi { synthBox.phaseThetaL -= twoPi }
                if synthBox.phaseThetaR > twoPi { synthBox.phaseThetaR -= twoPi }
                if synthBox.phaseLFO > twoPi { synthBox.phaseLFO -= twoPi }

                let lfo = Float(0.75 + 0.25 * sin(synthBox.phaseLFO))
                let pad = Float(sin(synthBox.phase432) * 0.6 + sin(synthBox.phase528) * 0.4) * synthBox.drone * lfo
                let deltaL = Float(sin(synthBox.phaseDeltaL)) * synthBox.delta
                let deltaR = Float(sin(synthBox.phaseDeltaR)) * synthBox.delta
                let thetaL = Float(sin(synthBox.phaseThetaL)) * synthBox.theta
                let thetaR = Float(sin(synthBox.phaseThetaR)) * synthBox.theta

                // Filtered brown noise + soft rain swell
                synthBox.brownStateL = (synthBox.brownStateL + 0.02 * synthBox.nextWhite()) / 1.02
                synthBox.brownStateR = (synthBox.brownStateR + 0.02 * synthBox.nextWhite()) / 1.02
                let rainL = synthBox.brownStateL * 3.2 * synthBox.rain * lfo
                let rainR = synthBox.brownStateR * 3.2 * synthBox.rain * lfo

                let left = max(-0.95, min(0.95, (pad + deltaL + thetaL + rainL) * 0.22 * synthBox.master))
                let right = max(-0.95, min(0.95, (pad + deltaR + thetaR + rainR) * 0.22 * synthBox.master))

                if abl.count >= 2 {
                    abl[0].mData?.assumingMemoryBound(to: Float.self)[frame] = left
                    abl[1].mData?.assumingMemoryBound(to: Float.self)[frame] = right
                } else if abl.count == 1 {
                    abl[0].mData?.assumingMemoryBound(to: Float.self)[frame] = (left + right) * 0.5
                }
            }
            return noErr
        }

        audioEngine.attach(node)
        audioEngine.connect(node, to: mainMixer, format: stereoFormat)
        self.sourceNode = node
        self.engine = audioEngine
    }

    private func startCountdown() {
        timerTask?.cancel()
        timerTask = Task {
            var tick = 0
            while !Task.isCancelled && isPlaying && remainingSeconds > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, isPlaying else { break }
                remainingSeconds -= 1
                tick += 1
                let wave = 0.5 + 0.5 * sin(Double(tick) * 0.6)
                currentAmplitude = min(1.0, (cosmicDroneVolume * 0.4 + deltaBeatVolume * 0.3 + thetaWaveVolume * 0.2 + nebulaRainVolume * 0.3) * (0.7 + 0.3 * wave) * masterGain)
                // Gentle fade-out over the final 30 seconds
                if remainingSeconds <= 30 {
                    masterGain = max(0.05, Double(remainingSeconds) / 30.0)
                }
            }
            if remainingSeconds <= 0 && !Task.isCancelled {
                stop()
            }
        }
    }
}
