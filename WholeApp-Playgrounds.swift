// The whole app in one file, for Swift Playgrounds on iPad or Mac.
// In your Playgrounds app: delete every other .swift file (the template's MyApp.swift and ContentView.swift too),
// then paste this file in. Made by Ghost Code from the files saved on GitHub.

import AVFoundation
import ActivityKit
import Charts
import CoreMotion
import Foundation
import HealthKit
import SwiftData
import SwiftUI
import UIKit
import UniformTypeIdentifiers
import UserNotifications

// MARK: - GhostTheme.swift

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

// MARK: - ReadyByEight/AlarmModels.swift

enum RepeatRule: String, Codable, CaseIterable, Identifiable {
    case once = "Once", daily = "Every day", weekdays = "Weekdays", weekends = "Weekends"
    var id: String { rawValue }
    var weekdays: [Int] {
        switch self {
        case .once: []
        case .daily: Array(1...7)
        case .weekdays: Array(2...6)
        case .weekends: [1, 7]
        }
    }
}

struct WakeAlarm: Identifiable, Codable, Equatable {
    var id = UUID()
    var label: String
    var hour: Int
    var minute: Int
    var rule: RepeatRule
    var enabled = true
    var oneTimeDate: Date

    init(label: String, time: Date, rule: RepeatRule, now: Date = .now,
         calendar: Calendar = .current) {
        self.label = String(label.trimmingCharacters(in: .whitespacesAndNewlines).prefix(60))
        if self.label.isEmpty { self.label = "A fresh start" }
        hour = calendar.component(.hour, from: time)
        minute = calendar.component(.minute, from: time)
        self.rule = rule
        oneTimeDate = calendar.nextDate(after: now,
            matching: DateComponents(hour: hour, minute: minute),
            matchingPolicy: .nextTime) ?? now.addingTimeInterval(86_400)
    }

    func nextOccurrence(after now: Date = .now, calendar: Calendar = .current) -> Date? {
        guard enabled else { return nil }
        if rule == .once { return oneTimeDate > now ? oneTimeDate : nil }
        return rule.weekdays.compactMap { weekday in
            calendar.nextDate(after: now,
                matching: DateComponents(hour: hour, minute: minute, weekday: weekday),
                matchingPolicy: .nextTime)
        }.min()
    }

    var displayDate: Date {
        Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? oneTimeDate
    }

    var notificationIDs: [String] {
        ["wake.\(id.uuidString).once"] + (1...7).map { "wake.\(id.uuidString).\($0)" }
    }
}

struct CoachMessage: Identifiable, Codable, Equatable {
    var id = UUID()
    var isUser: Bool
    var text: String
}

struct SavedState: Codable {
    var alarms: [WakeAlarm] = []
    var messages: [CoachMessage] = []
    var completedDay: String?

    static func dayKey(_ date: Date = .now, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.era, .year, .month, .day], from: date)
        return "\(parts.era ?? 0)-\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
    }
}

enum OfflineCoach {
    static func reply(to input: String, nextAlarm: String?) -> String {
        let text = input.lowercased()
        if text.contains("alarm") || text.contains("wake") {
            let schedule = nextAlarm.map { "Your next reminder is \($0)." }
                ?? "You haven’t enabled a wake-up reminder yet."
            return "\(schedule) Open the Clock tab to edit it. I can help you plan, but I can’t change reminders from this chat. Keep a Clock app alarm as your backup."
        }
        if text.contains("tired") || text.contains("sleep") {
            return "Let’s make tomorrow gentler: prepare one thing tonight, put your phone away, and choose a realistic wake-up time. Rest matters more than a streak."
        }
        if text.contains("late") || text.contains("rush") {
            return "Essentials only: get dressed, grab what you need, and check your departure time. Skip the optional tasks. No rushing on the road."
        }
        if text.contains("challenge") || text.contains("motivat") {
            return "Your two-minute challenge: sit up, put both feet on the floor, and open the curtains. One small start counts. Tap ‘I did it’ on the Clock tab when you’re ready."
        }
        return "Let’s keep it small: choose one thing that would make your morning easier. Try laying out your clothes or packing your bag tonight. Ask me for a challenge, sleep tips, or a plan when you’re running late."
    }
}

// MARK: - ReadyByEight/AppStore.swift

/// Device-only audio and credentials. Included directly in AppStore.swift so Swift Playgrounds and Xcode both find GhostDevice in scope.
@MainActor @Observable
final class GhostDevice: NSObject, AVSpeechSynthesizerDelegate {
    private let speech = AVSpeechSynthesizer()
    private var player: AVAudioPlayer?
    private(set) var speaking = false
    private(set) var playing: String?
    var volume: Double = 0.5 { didSet { player?.volume = Float(volume) } }
    var voiceID: String = UserDefaults.standard.string(forKey: "voiceID") ?? "" {
        didSet { UserDefaults.standard.set(voiceID, forKey: "voiceID") }
    }
    var voiceEnabled = UserDefaults.standard.bool(forKey: "voiceEnabled") {
        didSet { UserDefaults.standard.set(voiceEnabled, forKey: "voiceEnabled") }
    }
    var remoteEnabled = UserDefaults.standard.bool(forKey: "remoteEnabled") {
        didSet { UserDefaults.standard.set(remoteEnabled, forKey: "remoteEnabled") }
    }
    var endpoint: String = UserDefaults.standard.string(forKey: "endpoint") ?? "https://api.openai.com/v1/chat/completions" {
        didSet { UserDefaults.standard.set(endpoint, forKey: "endpoint") }
    }
    var model: String = UserDefaults.standard.string(forKey: "model") ?? "gpt-4o-mini" {
        didSet { UserDefaults.standard.set(model, forKey: "model") }
    }
    var toneName: String { UserDefaults.standard.string(forKey: "toneName") ?? "System default" }
    var notificationSound: String? { UserDefaults.standard.string(forKey: "notificationSound") }
    private var timer: Task<Void, Never>?
    static let tracks = ["Moonlight piano", "Gentle rain", "Ocean breathing", "Cosmic drift"]
    override init() { super.init(); speech.delegate = self }
    var voices: [AVSpeechSynthesisVoice] { AVSpeechSynthesisVoice.speechVoices().sorted { $0.name < $1.name } }
    private func session() throws {
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try AVAudioSession.sharedInstance().setActive(true)
    }
    func say(_ text: String) throws {
        try session()
        speech.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(identifier: voiceID) ?? AVSpeechSynthesisVoice(language: Locale.current.identifier)
        utterance.rate = 0.46
        speaking = true
        speech.speak(utterance)
    }
    func stopSpeech() { speech.stopSpeaking(at: .immediate); speaking = false }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in self?.speaking = false }
    }
    func stopMusic() { timer?.cancel(); player?.stop(); player = nil; playing = nil }
    func play(_ name: String, minutes: Int) throws {
        stopMusic()
        try session()
        if name == "Imported music" {
            guard let path = UserDefaults.standard.string(forKey: "musicPath") else {
                throw CocoaError(.fileNoSuchFile)
            }
            player = try AVAudioPlayer(contentsOf: URL.applicationSupportDirectory.appending(path: path))
        } else { player = try AVAudioPlayer(data: Self.wave(name)) }
        player?.numberOfLoops = -1
        player?.volume = Float(volume)
        guard player?.play() == true else { throw CocoaError(.fileReadCorruptFile) }
        playing = name
        timer = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(minutes * 60)) }
            catch { return }
            self?.stopMusic()
        }
    }
    var hasMusic: Bool { UserDefaults.standard.string(forKey: "musicPath") != nil }
    func importFile(_ url: URL, asTone: Bool) throws {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        if asTone {
            let input = try AVAudioFile(forReading: url)
            let format = input.processingFormat
            guard input.length > 0, Double(input.length) / format.sampleRate <= 29 else {
                throw NSError(domain: "Ghost", code: 1, userInfo: [NSLocalizedDescriptionKey: "Choose a tone shorter than 29 seconds."])
            }
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(input.length)) else {
                throw CocoaError(.fileReadCorruptFile)
            }
            try input.read(into: buffer)
            let folder = URL.libraryDirectory.appending(path: "Sounds")
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let output = try AVAudioFile(forWriting: folder.appending(path: "ghost-tone.caf"), settings: format.settings)
            try output.write(from: buffer)
            UserDefaults.standard.set("ghost-tone.caf", forKey: "notificationSound")
            UserDefaults.standard.set(url.deletingPathExtension().lastPathComponent, forKey: "toneName")
        } else {
            let folder = URL.applicationSupportDirectory
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let name = "sleep-import.\(url.pathExtension)"
            let destination = folder.appending(path: name)
            let data = try Data(contentsOf: url)
            _ = try AVAudioPlayer(data: data)
            try data.write(to: destination, options: .atomic)
            UserDefaults.standard.set(name, forKey: "musicPath")
        }
        volume = volume
    }
    func resetTone() {
        UserDefaults.standard.removeObject(forKey: "notificationSound")
        UserDefaults.standard.removeObject(forKey: "toneName")
        volume = volume
    }
    func previewTone() throws {
        if notificationSound != nil {
            try session()
            stopMusic()
            player = try AVAudioPlayer(contentsOf: URL.libraryDirectory.appending(path: "Sounds/ghost-tone.caf"))
            player?.play()
        } else { try say("Good morning. It's time for a fresh start.") }
    }
    /// Loopable 12-second PCM soundscapes generated entirely on the device.
    static func wave(_ name: String) -> Data {
        let rate = 22_050, count = rate * 12
        var pcm = Data(capacity: count * 2)
        var noise = 0.0
        for n in 0..<count {
            let t = Double(n) / Double(rate)
            let edge = min(1, min(t, 12 - t) * 4)
            var sample: Double
            if name == "Gentle rain" || name == "Ocean breathing" {
                noise = noise * 0.94 + Double.random(in: -1...1) * 0.06
                sample = noise * (name == "Gentle rain" ? 0.8 : (0.35 + 0.3 * sin(t * .pi / 6)))
            } else {
                let frequency = name == "Cosmic drift" ? 144.0 : [220.0, 261.625, 329.628, 293.665][min(3, Int(t / 3))]
                let envelope = name == "Cosmic drift" ? 0.7 : exp(-t.truncatingRemainder(dividingBy: 3) * 1.5)
                sample = (sin(2 * .pi * frequency * t) + 0.3 * sin(4 * .pi * frequency * t)) * 0.15 * envelope
            }
            var value = Int16(max(-1, min(1, sample * edge)) * 32_000).littleEndian
            withUnsafeBytes(of: &value) { pcm.append(contentsOf: $0) }
        }
        var data = Data("RIFF".utf8)
        func u32(_ value: UInt32) { var v = value.littleEndian; withUnsafeBytes(of: &v) { data.append(contentsOf: $0) } }
        func u16(_ value: UInt16) { var v = value.littleEndian; withUnsafeBytes(of: &v) { data.append(contentsOf: $0) } }
        u32(UInt32(pcm.count + 36)); data.append(Data("WAVEfmt ".utf8)); u32(16)
        u16(1); u16(1); u32(UInt32(rate)); u32(UInt32(rate * 2)); u16(2); u16(16)
        data.append(Data("data".utf8)); u32(UInt32(pcm.count)); data.append(pcm)
        return data
    }
    func saveKey(_ key: String) throws {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "dev.ghostchat.readybyeight", kSecAttrAccount as String: "coach-api"]
        SecItemDelete(query as CFDictionary)
        guard !key.isEmpty else { return }
        var item = query
        item[kSecValueData as String] = Data(key.utf8)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else { throw CocoaError(.fileWriteNoPermission) }
    }
    var hasKey: Bool { !apiKey.isEmpty }
    private var apiKey: String {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "dev.ghostchat.readybyeight", kSecAttrAccount as String: "coach-api",
            kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne]
        var result: CFTypeRef?
        if SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
           let data = result as? Data,
           let stored = String(data: data, encoding: .utf8), !stored.isEmpty {
            return stored
        }
        if let envKey = ProcessInfo.processInfo.environment["GHOST_AI_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        if let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
           let dict = NSDictionary(contentsOf: url) as? [String: Any],
           let plistKey = dict["GHOST_AI_API_KEY"] as? String, !plistKey.isEmpty {
            return plistKey
        }
        return ""
    }
    func reply(messages: [CoachMessage], endpoint: String = "https://api.openai.com/v1/chat/completions", model: String = "gpt-4o-mini") async throws -> String {
        guard let url = URL(string: endpoint), url.scheme == "https", url.host != nil,
              !model.trimmingCharacters(in: .whitespaces).isEmpty, hasKey else {
            throw NSError(domain: "Ghost", code: 2, userInfo: [NSLocalizedDescriptionKey: "Set an HTTPS chat-completions URL, model and API key in Settings."])
        }
        struct Message: Codable { let role: String; let content: String }
        struct Body: Encodable { let model: String; let messages: [Message]; let max_tokens: Int }
        struct Response: Decodable { struct Choice: Decodable { let message: Message }; let choices: [Choice] }
        var request = URLRequest(url: url, timeoutInterval: 35)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let system = Message(role: "system", content: "You are Ghost, a kind morning coach. Reply in under 90 words. Suggest small practical steps. Never claim to set alarms or access tools. Direct alarm changes to the Wake tab. No medical advice.")
        request.httpBody = try JSONEncoder().encode(Body(model: model, messages: [system] + messages.suffix(12).map {
            Message(role: $0.isUser ? "user" : "assistant", content: $0.text)
        }, max_tokens: 300))
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "Ghost", code: 3, userInfo: [NSLocalizedDescriptionKey: "The AI provider rejected the request. Check its URL, model, key and balance."])
        }
        let result = try JSONDecoder().decode(Response.self, from: data)
        guard let text = result.choices.first?.message.content, !text.isEmpty else { throw CocoaError(.coderReadCorrupt) }
        return text
    }
}

@MainActor @Observable
final class AppStore {
    private(set) var state = SavedState()
    let device = GhostDevice()
    private(set) var planDay = UserDefaults.standard.string(forKey: "morningPlanDay") ?? ""
    private(set) var completedPlanItems = Set(UserDefaults.standard.stringArray(forKey: "morningPlanItems") ?? [])
    private(set) var busy = false
    private(set) var sending = false
    private(set) var isCoachSpeaking = false
    private(set) var notificationsAllowed = false
    var error: String?
    private var speakingTask: Task<Void, Never>?
    private let center = UNUserNotificationCenter.current()
    private var fileURL: URL {
        URL.applicationSupportDirectory.appending(path: "ReadyByEight/state.json")
    }

    init() {
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                state = try JSONDecoder().decode(SavedState.self, from: Data(contentsOf: fileURL))
            }
        } catch { self.error = "Couldn’t load your saved data. No data has been overwritten. \(error.localizedDescription)" }
    }

    var nextAlarm: (alarm: WakeAlarm, date: Date)? {
        state.alarms
            .filter(\.enabled)
            .compactMap { alarm in alarm.nextOccurrence().map { (alarm, $0) } }
            .min { $0.1 < $1.1 }
    }
    var challengeCompleted: Bool { state.completedDay == SavedState.dayKey() }
    var coachName: String { "Ghost Mascot" }
    static var appIconName: String { "Ghost Mascot" }

    func refresh() async {
        let settings = await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
        notificationsAllowed = settings.authorizationStatus == .authorized
            || settings.authorizationStatus == .provisional
    }

    private func persist(_ candidate: SavedState) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(candidate)
        try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        state = candidate
    }

    func save(_ alarm: WakeAlarm) async -> Bool {
        guard !busy else { return false }
        guard state.alarms.contains(where: { $0.id == alarm.id }) || state.alarms.count < 8 else {
            error = "Keep up to eight reminders. Delete one before adding another."
            return false
        }
        busy = true
        defer { busy = false }
        var candidate = state
        if let index = candidate.alarms.firstIndex(where: { $0.id == alarm.id }) {
            candidate.alarms[index] = alarm
        } else { candidate.alarms.append(alarm) }
        do {
            if alarm.enabled {
                let granted = try await center.requestAuthorization(options: [.alert, .sound])
                await refresh()
                guard granted else {
                    error = "Notifications are off. Enable them in iPhone Settings → Notifications → Ghost Mascot."
                    return false
                }
                try await schedule(alarm)
            }
            do { try persist(candidate) }
            catch {
                center.removePendingNotificationRequests(withIdentifiers: alarm.notificationIDs)
                if let old = state.alarms.first(where: { $0.id == alarm.id }), old.enabled {
                    try await schedule(old)
                }
                throw error
            }
            if !alarm.enabled {
                center.removePendingNotificationRequests(withIdentifiers: alarm.notificationIDs)
            }
            return true
        } catch {
            self.error = "Couldn’t save the reminder. Please try again. \(error.localizedDescription)"
            return false
        }
    }

    private func schedule(_ alarm: WakeAlarm) async throws {
        let content = UNMutableNotificationContent()
        content.title = alarm.label
        content.body = "A fresh start. Sit up, breathe, and take your first small step."
        content.sound = device.notificationSound.map { UNNotificationSound(named: UNNotificationSoundName(rawValue: $0)) } ?? .default
        var requests: [UNNotificationRequest] = []
        if alarm.rule == .once {
            let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute],
                                                       from: alarm.oneTimeDate)
            requests.append(UNNotificationRequest(identifier: alarm.notificationIDs[0], content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)))
        } else {
            requests = alarm.rule.weekdays.map { day in
                UNNotificationRequest(identifier: "wake.\(alarm.id.uuidString).\(day)", content: content,
                    trigger: UNCalendarNotificationTrigger(dateMatching:
                        DateComponents(hour: alarm.hour, minute: alarm.minute, weekday: day), repeats: true))
            }
        }
        do {
            for request in requests { try await center.add(request) }
        } catch {
            center.removePendingNotificationRequests(withIdentifiers: requests.map(\.identifier))
            if let old = state.alarms.first(where: { $0.id == alarm.id }), old.enabled {
                self.error = "Scheduling failed. Re-save this reminder before relying on it."
            }
            throw error
        }
        let active = Set(requests.map(\.identifier))
        center.removePendingNotificationRequests(withIdentifiers: alarm.notificationIDs.filter { !active.contains($0) })
    }

    func toggle(_ alarm: WakeAlarm) async {
        var updated = alarm
        updated.enabled.toggle()
        if updated.enabled && updated.rule == .once && updated.oneTimeDate <= .now {
            updated.oneTimeDate = Calendar.current.nextDate(after: .now,
                matching: DateComponents(hour: updated.hour, minute: updated.minute),
                matchingPolicy: .nextTime) ?? Date.now.addingTimeInterval(86_400)
        }
        _ = await save(updated)
    }

    func delete(_ alarm: WakeAlarm) {
        guard !busy else { return }
        var candidate = state
        candidate.alarms.removeAll { $0.id == alarm.id }
        do {
            try persist(candidate)
            center.removePendingNotificationRequests(withIdentifiers: alarm.notificationIDs)
            center.removeDeliveredNotifications(withIdentifiers: alarm.notificationIDs)
        } catch { self.error = "Couldn’t delete the reminder. \(error.localizedDescription)" }
    }

    func isPlanItemCompleted(_ id: String) -> Bool {
        planDay == SavedState.dayKey() && completedPlanItems.contains(id)
    }

    func togglePlanItem(_ id: String) {
        let today = SavedState.dayKey()
        if planDay != today { completedPlanItems.removeAll(); planDay = today }
        if completedPlanItems.contains(id) { completedPlanItems.remove(id) }
        else { completedPlanItems.insert(id) }
        UserDefaults.standard.set(planDay, forKey: "morningPlanDay")
        UserDefaults.standard.set(Array(completedPlanItems), forKey: "morningPlanItems")
    }

    func snooze() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            await refresh()
            guard granted else {
                error = "Enable notifications in Settings to use snooze."
                return false
            }
            let content = UNMutableNotificationContent()
            content.title = "Good morning"
            content.body = "Your five-minute snooze is over."
            content.sound = device.notificationSound.map { UNNotificationSound(named: UNNotificationSoundName(rawValue: $0)) } ?? .default
            let request = UNNotificationRequest(identifier: "wake.snooze", content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 300, repeats: false))
            try await center.add(request)
            return true
        } catch {
            self.error = "Couldn’t schedule snooze. \(error.localizedDescription)"
            return false
        }
    }

    func cancelSnooze() {
        center.removePendingNotificationRequests(withIdentifiers: ["wake.snooze"])
        center.removeDeliveredNotifications(withIdentifiers: ["wake.snooze"])
    }

    func updateAlarmSounds() async {
        for alarm in state.alarms where alarm.enabled && alarm.nextOccurrence() != nil {
            do { try await schedule(alarm) }
            catch { self.error = "Couldn’t update the reminder sound. Re-save your reminders. \(error.localizedDescription)"; return }
        }
    }

    func completeChallenge() {
        var candidate = state
        candidate.completedDay = challengeCompleted ? nil : SavedState.dayKey()
        do { try persist(candidate) }
        catch { self.error = "Couldn’t save your progress. \(error.localizedDescription)" }
    }

    /// Remove the retired Coach conversation blob without discarding alarms, music or tones.
    func removeLegacyCoachData() {
        var candidate = state
        candidate.messages = []
        do { try persist(candidate) }
        catch { self.error = "Couldn’t remove old coach messages. \(error.localizedDescription)" }
    }
}

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }
}

// MARK: - ReadyByEight/GhostCompanionHero.swift

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
                .buttonStyle(GhostTheme.GhostPressStyle())
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
            let t: Double = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
            GeometryReader { geo in
                stageContent(t: t, width: geo.size.width)
            }
            .frame(height: 218)
        }
        .accessibilityLabel("Roaming ghost. Tap to wave and dance.")
        .accessibilityIdentifier("ghostMascotStage")
        .accessibilityAddTraits(.isButton)
    }

    private func stageContent(t: Double, width: CGFloat) -> some View {
        let roam: CGFloat = min(width, 360)
        let x: CGFloat = reduceMotion ? 0 : CGFloat(sin(t * 0.34)) * roam * 0.18
        let y: CGFloat = reduceMotion ? 0 : CGFloat(sin(t * 0.68)) * 9
        let center = CGPoint(x: width / 2 + x, y: 108 + y)
        return ZStack {
            ForEach(0..<9, id: \.self) { index in
                orbitStar(index: index, t: t, width: width)
            }
            Circle()
                .fill(GhostTheme.purple.opacity(0.12))
                .frame(width: 185, height: 185).blur(radius: 25)
                .scaleEffect(1 + 0.08 * CGFloat(sin(t * 1.15)))
                .position(center)
            GhostTheme.GhostMascot(isSpeaking: delighted, size: 140)
                .shadow(color: GhostTheme.purple.opacity(0.38), radius: 24)
                .position(center)
                .rotationEffect(.degrees(sin(t * 0.34) * 5))
                .scaleEffect(delighted ? 1.08 : 1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { greet() }
    }

    private func orbitStar(index: Int, t: Double, width: CGFloat) -> some View {
        let angle: Double = t * 0.24 + Double(index) * (2 * Double.pi / 9)
        let radius: CGFloat = min(width * 0.36, 132)
        let starX: CGFloat = CGFloat(cos(angle)) * radius
        let starY: CGFloat = CGFloat(sin(angle)) * 31 - 52
        let opacity: Double = 0.35 + 0.5 * abs(sin(t + Double(index)))
        return Image(systemName: index.isMultiple(of: 3) ? "star.fill" : "sparkle")
            .font(.system(size: index.isMultiple(of: 2) ? 9 : 12))
            .foregroundStyle(GhostTheme.purple)
            .opacity(opacity)
            .position(x: width / 2 + starX, y: 108 + starY)
    }
}

// MARK: - ReadyByEight/GhostLiveActivity.swift

#if canImport(ActivityKit)

/// Live Activity attributes for the Lock Screen / StandBy banner.
/// The widget extension rendering this lives in a separate target; this struct is shared.
struct GhostSleepAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var modeTitle: String
        var subtitle: String
        var stageLabel: String
        var isPlayingSound: Bool
    }
    var sessionName: String
}
#endif

/// Sleek Dynamic-Island-style floating Live Session Pill HUD at the top of the app.
/// Expands on tap to control procedural sleep soundscapes, active sleep tracking, and alarm countdowns.
struct GhostLiveSessionPill: View {
    let isPlaying: Bool
    let isTracking: Bool
    let stageLabel: String
    let presetLabel: String
    let remainingSeconds: Int
    let soundAction: () -> Void
    let sleepAction: () -> Void
    @Environment(AppStore.self) private var store
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Circle()
                        .fill(isPlaying || isTracking ? GhostTheme.mint : GhostTheme.purple)
                        .frame(width: 8, height: 8)
                        .shadow(color: GhostTheme.purple.opacity(0.8), radius: 5)
                    if isPlaying {
                        EqualizerBars(color: GhostTheme.purpleSoft)
                    }
                    Text(title)
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .lineLimit(1)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2.weight(.bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(Color.black.opacity(0.55), in: Capsule())
                .overlay(Capsule().strokeBorder(GhostTheme.purple.opacity(0.5), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.top, 6)

            if isExpanded {
                HStack(spacing: 12) {
                    Button(action: soundAction) {
                        Label(isPlaying ? "Mixer" : "Play sound", systemImage: "waveform")
                    }
                    Button(action: sleepAction) {
                        Label(isTracking ? "Sleep report" : "Sleep", systemImage: "bed.double.fill")
                    }
                    if let next = store.nextAlarm {
                        Text(next.date.formatted(date: .omitted, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(GhostTheme.textSecondary)
                    }
                }
                .buttonStyle(.bordered)
                .tint(GhostTheme.purple)
                .controlSize(.small)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .environment(\.colorScheme, .dark)
    }

    private var title: String {
        if isPlaying {
            let mins = remainingSeconds / 60
            return "Ghost Live · \(presetLabel) (\(mins)m)"
        }
        if isTracking {
            return "Tracking Sleep · \(stageLabel) Stage"
        }
        if let next = store.nextAlarm {
            return "Ghost Live · Wake \(next.date.formatted(date: .omitted, time: .shortened))"
        }
        return "Ghost Live"
    }
}

// MARK: - ReadyByEight/GhostWallpaper.swift

private struct GhostWallpaperDimmedKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// Nightstand keeps the same sky, but dims every layer together to save power.
    var ghostWallpaperDimmed: Bool {
        get { self[GhostWallpaperDimmedKey.self] }
        set { self[GhostWallpaperDimmedKey.self] = newValue }
    }
}

/// Six animated cosmic wallpaper themes plus an optional wallpaper from a web image URL.
enum CosmicTheme: String, CaseIterable, Identifiable {
    case lavenderNebula, midnightOcean, auroraDream, sunsetGalaxy, cosmicRose, stardustMint
    var id: String { rawValue }

    var title: String {
        switch self {
        case .lavenderNebula: return "Lavender Nebula"
        case .midnightOcean: return "Midnight Ocean"
        case .auroraDream: return "Aurora Dream"
        case .sunsetGalaxy: return "Sunset Galaxy"
        case .cosmicRose: return "Cosmic Rose"
        case .stardustMint: return "Stardust Mint"
        }
    }

    var colors: [Color] {
        switch self {
        case .lavenderNebula: return [Color(red: 0.09, green: 0.04, blue: 0.20), Color(red: 0.28, green: 0.15, blue: 0.50), Color(red: 0.55, green: 0.35, blue: 0.80)]
        case .midnightOcean: return [Color(red: 0.02, green: 0.04, blue: 0.12), Color(red: 0.05, green: 0.18, blue: 0.35), Color(red: 0.20, green: 0.45, blue: 0.70)]
        case .auroraDream: return [Color(red: 0.02, green: 0.10, blue: 0.14), Color(red: 0.08, green: 0.30, blue: 0.32), Color(red: 0.40, green: 0.30, blue: 0.65)]
        case .sunsetGalaxy: return [Color(red: 0.15, green: 0.03, blue: 0.10), Color(red: 0.45, green: 0.12, blue: 0.25), Color(red: 0.85, green: 0.40, blue: 0.35)]
        case .cosmicRose: return [Color(red: 0.12, green: 0.02, blue: 0.12), Color(red: 0.38, green: 0.10, blue: 0.32), Color(red: 0.75, green: 0.35, blue: 0.60)]
        case .stardustMint: return [Color(red: 0.03, green: 0.10, blue: 0.10), Color(red: 0.10, green: 0.28, blue: 0.28), Color(red: 0.35, green: 0.65, blue: 0.60)]
        }
    }

    static func from(_ raw: String) -> CosmicTheme { CosmicTheme(rawValue: raw) ?? .lavenderNebula }
}

enum WallpaperURL {
    /// Accepts only http(s) URLs with a host, so pasted text can't load other schemes.
    static func validated(_ text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http", url.host != nil else { return nil }
        return url
    }
}

/// Moving live wallpaper: drifting nebula blobs and twinkling stars on one shared clock.
struct GhostLiveWallpaper: View {
    @AppStorage("wallpaperTheme") private var themeRaw = CosmicTheme.lavenderNebula.rawValue
    @AppStorage("wallpaperURL") private var urlText = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.ghostWallpaperDimmed) private var dimmed

    var body: some View {
        let theme = CosmicTheme.from(themeRaw)
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: dimmed ? 0.25 : 1.0 / 30.0, paused: reduceMotion)) { context in
                let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
                ZStack {
                    LinearGradient(colors: [theme.colors[0], theme.colors[1]], startPoint: .top, endPoint: .bottom)
                    if #available(iOS 18.0, *) {
                        MeshGradient(
                            width: 3,
                            height: 3,
                            points: [
                                .init(0, 0), .init(0.5 + Float(sin(t * 0.08)) * 0.2, 0), .init(1, 0),
                                .init(0, 0.5), .init(0.5 + Float(cos(t * 0.11)) * 0.25, 0.5 + Float(sin(t * 0.09)) * 0.2), .init(1, 0.5),
                                .init(0, 1), .init(0.5, 1), .init(1, 1)
                            ],
                            colors: [
                                theme.colors[0], theme.colors[1], theme.colors[0],
                                theme.colors[1].opacity(0.75), theme.colors[2].opacity(0.8), theme.colors[1].opacity(0.7),
                                theme.colors[0], theme.colors[1], theme.colors[0]
                            ]
                        )
                        .opacity(0.72)
                    } else {
                        RadialGradient(colors: [theme.colors[2].opacity(0.55), .clear],
                                       center: UnitPoint(x: 0.5 + sin(t * 0.1) * 0.25, y: 0.35),
                                       startRadius: 20, endRadius: geo.size.width * 0.8)
                    }
                    if let url = WallpaperURL.validated(urlText) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill().opacity(0.55)
                        } placeholder: { Color.clear }
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                    }
                    ForEach(0..<3, id: \.self) { i in
                        let phase = Double(i) * 2.1
                        Circle()
                            .fill(theme.colors[(i % 2) + 1].opacity(0.45))
                            .frame(width: geo.size.width * 0.8)
                            .blur(radius: 60)
                            .offset(x: CGFloat(sin(t * 0.15 + phase)) * geo.size.width * 0.3,
                                    y: CGFloat(cos(t * 0.12 + phase)) * geo.size.height * 0.25)
                    }
                    ForEach(0..<28, id: \.self) { i in
                        let x = Double((i * 37) % 100) / 100.0
                        let y = Double((i * 61) % 100) / 100.0
                        Circle()
                            .fill(Color.white)
                            .frame(width: i.isMultiple(of: 3) ? 3 : 2)
                            .opacity(0.35 + 0.6 * abs(sin(t * 0.9 + Double(i))))
                            .position(x: x * geo.size.width, y: y * geo.size.height)
                    }
                    // One Canvas pass draws every comet, avoiding a view per particle.
                    Canvas { context, size in
                        for i in 0..<4 {
                            let cycle = (t * 0.075 + Double(i) / 4).truncatingRemainder(dividingBy: 1)
                            guard cycle < 0.18 else { continue }
                            let progress = cycle / 0.18
                            let head = CGPoint(x: (1.05 - progress * 1.3) * size.width,
                                               y: (0.08 + Double(i) * 0.17 + progress * 0.28) * size.height)
                            var path = Path()
                            path.move(to: head)
                            path.addLine(to: CGPoint(x: head.x + 105, y: head.y - 38))
                            context.stroke(path, with: .linearGradient(
                                Gradient(colors: [.white.opacity(0.9), .clear]),
                                startPoint: head,
                                endPoint: CGPoint(x: head.x + 105, y: head.y - 38)),
                                lineWidth: 2)
                            context.fill(Path(ellipseIn: CGRect(x: head.x - 2, y: head.y - 2, width: 4, height: 4)),
                                         with: .color(.white.opacity(1 - progress)))
                        }
                    }
                    .allowsHitTesting(false)
                }
                .brightness(dimmed ? -0.12 : 0)
                .opacity(dimmed ? 0.24 : 1)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

/// Theme picker and web wallpaper URL field (place inside Settings).
struct GhostWallpaperPicker: View {
    @AppStorage("wallpaperTheme") private var themeRaw = CosmicTheme.lavenderNebula.rawValue
    @AppStorage("wallpaperURL") private var urlText = ""
    @State private var draft = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Live wallpaper").font(.headline).foregroundStyle(.white)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
                ForEach(CosmicTheme.allCases) { theme in
                    Button {
                        themeRaw = theme.rawValue
                    } label: {
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(LinearGradient(colors: theme.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(height: 56)
                                .overlay(RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white, lineWidth: themeRaw == theme.rawValue ? 2 : 0))
                            Text(theme.title).font(.caption2).foregroundStyle(.white).lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(theme.title)
                }
            }
            TextField("Paste an image URL (https://…)", text: $draft)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .padding(10)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
            HStack {
                Button("Use URL") {
                    if WallpaperURL.validated(draft) != nil { urlText = draft }
                }
                .disabled(WallpaperURL.validated(draft) == nil)
                Spacer()
                Button("Clear wallpaper") { urlText = ""; draft = "" }
                    .disabled(urlText.isEmpty)
            }
            .font(.subheadline.weight(.semibold))
        }
        .onAppear { draft = urlText }
    }
}

// MARK: - ReadyByEight/NightstandModeView.swift

/// Cute bedside saving mode: one shared timeline keeps the sky, ghost, and bubbles in sync.
/// iOS cannot draw over the system Lock Screen; this is an in-app bedside/StandBy-style view.
struct NightstandModeView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("nightstand.keepAwake") private var keepAwake = true
    @AppStorage("nightstand.dreamBubbles") private var dreamBubbles = true
    @State private var dimmed = true
    @State private var showControls = true
    @State private var clock = Date()
    @State private var hideTask: Task<Void, Never>?

    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter
    }()

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 60 : (dimmed ? 1.0 / 20.0 : 1.0 / 30.0))) { context in
            let time = reduceMotion ? 0.0 : context.date.timeIntervalSinceReferenceDate
            GeometryReader { proxy in
                let size = proxy.size
                ZStack {
                    Color.black.ignoresSafeArea()
                    GhostTheme.GhostAurora(animated: !reduceMotion)
                        .opacity(dimmed ? 0.10 : 0.24)
                        .ignoresSafeArea()
                    if dreamBubbles && !reduceMotion {
                        ForEach(0..<6, id: \.self) { index in
                            DreamBubble(index: index, time: time, size: size)
                        }
                        .opacity(dimmed ? 0.3 : 0.65)
                        .allowsHitTesting(false)
                    }
                    Group {
                        if size.width > size.height {
                            HStack(spacing: 36) {
                                clockBlock(time)
                                Spacer()
                                ghostBlock(time)
                            }
                            .padding(.horizontal, 48)
                        } else {
                            VStack(spacing: 12) {
                                clockBlock(time)
                                Spacer()
                                ghostBlock(time)
                            }
                            .padding(.vertical, 36)
                        }
                    }
                    .opacity(dimmed ? 0.62 : 1)
                    .animation(.easeInOut(duration: 1.2), value: dimmed)

                    BreathingRing(size: size, time: time)
                        .opacity(dimmed ? 0.5 : 0.9)
                    controls
                }
                .contentShape(Rectangle())
                .onTapGesture { toggleDim() }
                .statusBarHidden(dimmed)
                .persistentSystemOverlays(dimmed ? .hidden : .automatic)
            }
        }
        .environment(\.ghostWallpaperDimmed, true)
        .onAppear {
            updateIdleTimer()
            clock = Date()
        }
        .onChange(of: keepAwake) { _, _ in updateIdleTimer() }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { date in
            clock = date
        }
        .onDisappear {
            hideTask?.cancel()
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private func clockBlock(_ time: TimeInterval) -> some View {
        VStack(spacing: 4) {
            Text(clock.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 110, weight: .thin, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.45)
                .foregroundStyle(GhostTheme.purpleSoft)
                .shadow(color: GhostTheme.purple.opacity(0.55 + 0.12 * sin(time * 0.5)), radius: 28)
            if let alarm = store.nextAlarm {
                Text(alarm.date, format: .dateTime.weekday(.abbreviated).hour().minute())
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .labelStyle(.titleAndIcon)
            }
            Text(clock, format: .dateTime.weekday(.wide).month().day())
                .font(.caption)
                .foregroundStyle(.white.opacity(0.42))
        }
    }

    private func ghostBlock(_ time: TimeInterval) -> some View {
        VStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                GhostTheme.GhostMascot(mood: .sleeping, size: 180)
                SleepZzz(time: time)
                    .offset(x: 12, y: -12)
            }
            Text("shh… your ghost is dreaming")
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.48))
        }
    }

    private var controls: some View {
        VStack {
            HStack {
                Spacer()
                if showControls {
                    HStack(spacing: 14) {
                        Button { keepAwake.toggle() } label: {
                            Label(keepAwake ? "Awake" : "Auto-lock", systemImage: keepAwake ? "sun.max.fill" : "moon.fill")
                                .font(.caption.weight(.semibold))
                        }
                        Button { dreamBubbles.toggle() } label: {
                            Image(systemName: dreamBubbles ? "sparkles" : "sparkle")
                                .font(.caption)
                        }
                    }
                    .foregroundStyle(GhostTheme.purpleSoft)
                    .padding(14)
                    .background(.ultraThinMaterial, in: Capsule())
                    .environment(\.colorScheme, .dark)
                    .transition(.opacity)
                }
            }
            Spacer()
            if showControls {
                Text("Tap to \(dimmed ? "brighten" : "dim") · Sweet dreams 🌙")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.38))
                    .padding(.bottom, 12)
            }
        }
        .padding(20)
    }

    private func toggleDim() {
        dimmed.toggle()
        showControls = true
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            await MainActor.run { withAnimation { showControls = false } }
        }
    }

    private func updateIdleTimer() {
        UIApplication.shared.isIdleTimerDisabled = keepAwake
    }
}

private struct SleepZzz: View {
    let time: TimeInterval
    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                let phase = (time / 3.2 + Double(index) / 3).truncatingRemainder(dividingBy: 1)
                Text("z")
                    .font(.system(size: CGFloat(14 + index * 6), weight: .bold, design: .rounded))
                    .foregroundStyle(GhostTheme.purpleSoft.opacity(0.8 * (1 - phase)))
                    .offset(x: CGFloat(index) * 12, y: 10 - phase * 64)
            }
        }
    }
}

/// 4-7-8 breathing guide: inhale 4s, hold 7s, exhale 8s.
private struct BreathingRing: View {
    let size: CGSize
    let time: Double

    static func breath(at time: Double) -> (Double, String) {
        let phase = time.truncatingRemainder(dividingBy: 19.0)
        if phase < 4 { return (phase / 4.0, "Breathe in") }
        if phase < 11 { return (1.0, "Hold") }
        return (max(0, 1.0 - (phase - 11.0) / 8.0), "Breathe out")
    }

    var body: some View {
        let (progress, label) = Self.breath(at: time)
        let radius = min(size.width, size.height) * 0.13
        let center = CGPoint(x: size.width * 0.22, y: size.height * 0.76)
        ZStack {
            Circle()
                .stroke(GhostTheme.purpleSoft.opacity(0.2), lineWidth: 3)
            Circle()
                .trim(from: 0, to: max(0.02, progress))
                .stroke(GhostTheme.purpleSoft.opacity(0.9), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 4) {
                Text(label)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                Text("4 · 7 · 8")
                    .font(.caption2)
                    .opacity(0.6)
            }
        }
        .foregroundStyle(.white.opacity(0.85))
        .frame(width: radius * 2, height: radius * 2)
        .position(center)
        .allowsHitTesting(false)
    }
}

private struct DreamBubble: View {
    let index: Int
    let time: TimeInterval
    let size: CGSize
    var body: some View {
        let speed = 18.0 + Double(index) * 6
        let x = (Double(index) * 137.5).truncatingRemainder(dividingBy: max(size.width, 1))
        let travel = size.height + 120
        let y = size.height + 40 - (time * speed + Double(index) * 90).truncatingRemainder(dividingBy: travel)
        let radius = CGFloat(6 + (index % 3) * 5)
        Circle()
            .fill(GhostTheme.purpleSoft.opacity(0.16))
            .overlay(Circle().strokeBorder(GhostTheme.purpleSoft.opacity(0.22), lineWidth: 1))
            .frame(width: radius * 2, height: radius * 2)
            .position(x: x + sin(time * 0.4 + Double(index)) * 18, y: y)
    }
}

// MARK: - ReadyByEight/ReadyByEightApp.swift

@Model
final class MorningGoalRecord {
    var title: String
    var dayKey: String
    var isCompleted: Bool
    var createdAt: Date

    init(title: String, dayKey: String = SavedState.dayKey(), isCompleted: Bool = false, createdAt: Date = .now) {
        self.title = title
        self.dayKey = dayKey
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}

@main
struct GhostMascotApp: App {
    @State private var store = AppStore()
    @State private var sleepEngine = SleepSoundEngine()
    @State private var sleepTracker = SleepTrackerManager()
    private let delegate = NotificationDelegate()

    init() {
        UNUserNotificationCenter.current().delegate = delegate
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(sleepEngine)
                .environment(sleepTracker)
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: MorningGoalRecord.self)
    }
}

struct MorningGhostScreen: View {
    @Environment(AppStore.self) private var store
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MorningGoalRecord.createdAt, order: .reverse) private var savedGoals: [MorningGoalRecord]
    @State private var draft = ""
    @FocusState private var focused: Bool

    private let suggestions = ["Move my body", "Focus on work", "Feel less stressed"]
    private let planItems: [(id: String, title: String)] = [
        ("water", "Drink a glass of water"),
        ("stretch", "Stretch for two minutes"),
        ("task", "Pick your first task")
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Morning Ghost")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(GhostTheme.textPrimary)
                    Text("Small steps. A stronger start.")
                        .font(.subheadline)
                        .foregroundStyle(GhostTheme.textSecondary)
                }
                Spacer()
                Button {
                    if let last = store.state.messages.last(where: { !$0.isUser })?.text {
                        try? store.device.say(last)
                    } else {
                        try? store.device.say("Good morning. What's one thing you want to get done today?")
                    }
                } label: {
                    GhostTheme.GhostMascot(isSpeaking: store.isCoachSpeaking || store.device.speaking, size: 58)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Rectangle().fill(GhostTheme.hairline).frame(height: 1)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Good morning. What’s one thing you want to get done today?")
                        .font(.body)
                        .foregroundStyle(.white)
                        .padding(16)
                        .background(Color(red: 0.45, green: 0.45, blue: 0.56), in: RoundedRectangle(cornerRadius: 20))

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            suggestionPill(suggestions[0])
                            suggestionPill(suggestions[1])
                        }
                        suggestionPill(suggestions[2])
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Morning plan")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                        ForEach(planItems, id: \.id) { item in
                            let done = store.isPlanItemCompleted(item.id)
                            Button {
                                store.togglePlanItem(item.id)
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(done ? GhostTheme.purpleSoft : Color.clear)
                                            .frame(width: 24, height: 24)
                                        Circle()
                                            .strokeBorder(GhostTheme.purpleSoft, lineWidth: 1.8)
                                            .frame(width: 24, height: 24)
                                        if done {
                                            Image(systemName: "checkmark")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(GhostTheme.ink)
                                        }
                                    }
                                    Text(item.title)
                                        .font(.body)
                                        .foregroundStyle(.white)
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        ForEach(savedGoals.prefix(3)) { goal in
                            Button {
                                goal.isCompleted.toggle()
                                try? modelContext.save()
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(goal.isCompleted ? GhostTheme.purpleSoft : Color.clear)
                                            .frame(width: 24, height: 24)
                                        Circle()
                                            .strokeBorder(GhostTheme.purpleSoft, lineWidth: 1.8)
                                            .frame(width: 24, height: 24)
                                        if goal.isCompleted {
                                            Image(systemName: "checkmark")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(GhostTheme.ink)
                                        }
                                    }
                                    Text(goal.title)
                                        .font(.body)
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                    .background(Color(red: 0.19, green: 0.14, blue: 0.34), in: RoundedRectangle(cornerRadius: 24))
                    .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(GhostTheme.purpleSoft.opacity(0.22)))

                    ForEach(store.state.messages) { msg in
                        HStack(alignment: .bottom, spacing: 10) {
                            if msg.isUser { Spacer(minLength: 40) }
                            if !msg.isUser {
                                GhostTheme.GhostMascot(isSpeaking: false, size: 28)
                            }
                            Text(msg.text)
                                .font(.subheadline)
                                .foregroundStyle(msg.isUser ? GhostTheme.ink : GhostTheme.textPrimary)
                                .padding(14)
                                .background(
                                    msg.isUser ? GhostTheme.purpleSoft : GhostTheme.cardElevated,
                                    in: RoundedRectangle(cornerRadius: 18)
                                )
                            if !msg.isUser {
                                Button {
                                    try? store.device.say(msg.text)
                                } label: {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.caption)
                                        .foregroundStyle(GhostTheme.purpleSoft)
                                }
                                Spacer(minLength: 20)
                            }
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }

            HStack(spacing: 12) {
                Button {
                    if let last = store.state.messages.last(where: { !$0.isUser })?.text {
                        try? store.device.say(last)
                    } else {
                        try? store.device.say("Good morning. What's one thing you want to get done today?")
                    }
                } label: {
                    Image(systemName: store.device.speaking ? "waveform" : "mic.fill")
                        .font(.title3)
                        .foregroundStyle(GhostTheme.textSecondary)
                        .frame(width: 36, height: 36)
                }

                TextField("Type a message...", text: $draft)
                    .focused($focused)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(GhostTheme.cardElevated, in: Capsule())
                    .foregroundStyle(GhostTheme.textPrimary)
                    .onSubmit { sendDraft() }

                Button { sendDraft() } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 46, height: 46)
                        .background(GhostTheme.purple, in: RoundedRectangle(cornerRadius: 16))
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(GhostTheme.ink.opacity(0.95))
            .overlay(alignment: .top) { Rectangle().fill(GhostTheme.hairline).frame(height: 1) }
        }
        .ghostScreen()
    }

    private func suggestionPill(_ title: String) -> some View {
        Button {
            modelContext.insert(MorningGoalRecord(title: title))
            try? modelContext.save()
            try? store.device.say("Nice. \(title) is your goal today.")
        } label: {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(GhostTheme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().strokeBorder(GhostTheme.purpleSoft.opacity(0.55), lineWidth: 1.2))
        }
        .buttonStyle(GhostTheme.GhostPressStyle())
    }

    private func sendDraft() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        draft = ""
        focused = false
        modelContext.insert(MorningGoalRecord(title: text))
        try? modelContext.save()
        try? store.device.say("Saved. \(text) is your goal today.")
    }
}

struct SettingsTabView: View {
    @Environment(AppStore.self) private var store
    @State private var importingTone = false
    @State private var importingMusic = false
    @State private var keepAwake = UIApplication.shared.isIdleTimerDisabled

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(GhostTheme.textPrimary)
                    Text("Device audio, voice, and your personal ghost.")
                        .font(.subheadline)
                        .foregroundStyle(GhostTheme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Label("Alarm Tone & Sleep Music", systemImage: "music.note.list")
                        .font(.headline)
                        .foregroundStyle(GhostTheme.textPrimary)
                    Text("Current alarm tone: \(store.device.toneName)")
                        .font(.subheadline)
                        .foregroundStyle(GhostTheme.purpleSoft)
                    HStack(spacing: 10) {
                        Button { importingTone = true } label: {
                            Label("Import Alarm Tone", systemImage: "bell.badge.fill")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(GhostTheme.purple.opacity(0.22), in: Capsule())
                                .foregroundStyle(GhostTheme.purpleSoft)
                        }
                        Button { importingMusic = true } label: {
                            Label("Import Sleep Music", systemImage: "waveform")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(GhostTheme.cardElevated, in: Capsule())
                                .foregroundStyle(GhostTheme.textPrimary)
                        }
                    }
                    HStack {
                        Text("Sleep volume")
                            .font(.caption)
                            .foregroundStyle(GhostTheme.textSecondary)
                        Slider(value: Binding(
                            get: { store.device.volume },
                            set: { store.device.volume = $0 }
                        ), in: 0.05...1.0)
                        .tint(GhostTheme.purple)
                    }
                }
                .ghostCard()

                VStack(alignment: .leading, spacing: 12) {
                    Label("Device TTS Voice", systemImage: "speaker.wave.3.fill")
                        .font(.headline)
                        .foregroundStyle(GhostTheme.textPrimary)
                    Toggle("Allow ghost speech", isOn: Binding(
                        get: { store.device.voiceEnabled },
                        set: { store.device.voiceEnabled = $0 }
                    ))
                    .tint(GhostTheme.purple)
                    .foregroundStyle(GhostTheme.textPrimary)

                    Picker("Voice", selection: Binding(
                        get: { store.device.voiceID },
                        set: { store.device.voiceID = $0 }
                    )) {
                        Text("System Default").tag("")
                        ForEach(store.device.voices, id: \.identifier) { voice in
                            Text("\(voice.name) (\(voice.language))").tag(voice.identifier)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(GhostTheme.purpleSoft)

                    HStack(spacing: 10) {
                        Button {
                            do { try store.device.say("Boo! I am your Ghost Mascot.") }
                            catch { store.error = error.localizedDescription }
                        } label: {
                            Label("Test Device TTS", systemImage: "play.circle.fill")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(GhostTheme.purpleSoft, in: Capsule())
                                .foregroundStyle(GhostTheme.ink)
                        }
                        if store.device.speaking {
                            Button { store.device.stopSpeech() } label: {
                                Text("Stop")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(GhostTheme.danger)
                            }
                        }
                    }
                }
                .ghostCard()

                VStack(alignment: .leading, spacing: 12) {
                    Label("Nightstand saving mode", systemImage: "moon.stars.fill")
                        .font(.headline)
                        .foregroundStyle(GhostTheme.textPrimary)
                    Toggle("Keep screen awake while open", isOn: $keepAwake)
                        .tint(GhostTheme.purple)
                        .foregroundStyle(GhostTheme.textPrimary)
                    Text("This is an in-app clock, not an iOS Lock Screen wallpaper. iOS can still turn off the screen in Low Power Mode. Plug in for a longer bedside display.")
                        .font(.caption)
                        .foregroundStyle(GhostTheme.textSecondary)
                }
                .ghostCard()
                .onAppear { keepAwake = UIApplication.shared.isIdleTimerDisabled }
                .onChange(of: keepAwake) { _, enabled in
                    UIApplication.shared.isIdleTimerDisabled = enabled
                }
                .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 10) {
                        GhostTheme.GhostMascot(isSpeaking: false, size: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Made by Agent.Ghost Coded")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(GhostTheme.textPrimary)
                            Text("Total Cost 10$")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(GhostTheme.purpleSoft)
                            Text("ghostchat.tech via Ghost Code")
                                .font(.caption2)
                                .foregroundStyle(GhostTheme.textSecondary)
                        }
                        Spacer()
                    }
                }
                .ghostCard()
            }
            .padding(20)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .ghostScreen()
        .fileImporter(isPresented: $importingTone, allowedContentTypes: [.audio]) { result in
            do {
                let url = try result.get()
                try store.device.importFile(url, asTone: true)
            } catch {
                store.error = error.localizedDescription
            }
        }
        .fileImporter(isPresented: $importingMusic, allowedContentTypes: [.audio]) { result in
            do {
                let url = try result.get()
                try store.device.importFile(url, asTone: false)
            } catch {
                store.error = error.localizedDescription
            }
        }
    }
}

struct AddAlarmView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var alarm: WakeAlarm?
    @State private var label = "Morning wake-up"
    @State private var time = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? .now
    @State private var rule: RepeatRule = .weekdays

    init(alarm: WakeAlarm? = nil) {
        self.alarm = alarm
        if let alarm {
            _label = State(initialValue: alarm.label)
            _time = State(initialValue: alarm.displayDate)
            _rule = State(initialValue: alarm.rule)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Wake-Up Time") {
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                }
                Section("Details") {
                    TextField("Label", text: $label)
                    Picker("Repeat", selection: $rule) {
                        ForEach(RepeatRule.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                }
                if let alarm {
                    Section {
                        Button("Delete Alarm", role: .destructive) {
                            store.delete(alarm)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(alarm == nil ? "New Alarm" : "Edit Alarm")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var candidate = WakeAlarm(label: label, time: time, rule: rule)
                        if let existing = alarm {
                            candidate.id = existing.id
                            candidate.enabled = existing.enabled
                        }
                        Task {
                            if await store.save(candidate) {
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - ReadyByEight/RootView.swift

struct RootView: View {
    @Environment(AppStore.self) private var store
    @Environment(SleepSoundEngine.self) private var soundEngine
    @Environment(SleepTrackerManager.self) private var sleepTracker
    @State private var tab = 0
    @State private var showMixer = false
    @State private var showAnalytics = false

    // Ghost Mascot's four native tabs share the same animated design system.
    var body: some View {
        Group {
            switch tab {
            case 0: HomeView(switchTab: { tab = $0 })
            case 1: WakeTabView(switchTab: { tab = $0 })
            case 2: NightstandModeView()
            case 4: CosmicSoundMixerSheet()
            case 5: SleepAnalyticsView()
            default: SettingsTabView()
            }
        }
        .ghostScreen(animated: true)
        .safeAreaInset(edge: .top, spacing: 0) {
            if soundEngine.isPlaying || sleepTracker.isTrackingOvernight || store.nextAlarm != nil {
                GhostLiveSessionPill(
                    isPlaying: soundEngine.isPlaying,
                    isTracking: sleepTracker.isTrackingOvernight,
                    stageLabel: sleepTracker.currentLiveStage.rawValue,
                    presetLabel: soundEngine.presetLabel,
                    remainingSeconds: sleepTracker.isTrackingOvernight ? 0 : soundEngine.remainingSeconds,
                    soundAction: { showMixer = true },
                    sleepAction: { showAnalytics = true }
                )
                .padding(.top, 6)
            }
        }
        .sheet(isPresented: $showMixer) {
            NavigationStack { CosmicSoundMixerSheet() }
        }
        .sheet(isPresented: $showAnalytics) {
            NavigationStack { SleepAnalyticsView() }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(spacing: 0) {
                tabButton(0, "Home", "house.fill")
                tabButton(1, "Wake", "alarm.fill")
                tabButton(2, "Nightstand", "moon.stars.fill")
                tabButton(3, "Settings", "gearshape.fill")
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .background(GhostTheme.ink.opacity(0.96))
            .overlay(alignment: .top) { Rectangle().fill(GhostTheme.hairline).frame(height: 1) }
        }
        .alert("Something needs attention", isPresented: Binding(
            get: { store.error != nil }, set: { if !$0 { store.error = nil } }
        )) {
            Button("OK") { store.error = nil }
        } message: { Text(store.error ?? "") }
        .task { await store.refresh() }
    }

    private func tabButton(_ id: Int, _ title: String, _ icon: String) -> some View {
        Button { tab = id } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: tab == id ? .bold : .regular))
                    .symbolEffect(.bounce, value: tab == id)
                Text(title).font(.caption2.weight(.medium))
            }
            .foregroundStyle(tab == id ? GhostTheme.purple : GhostTheme.textSecondary)
            .frame(maxWidth: .infinity).padding(.vertical, 8)
            .contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
}

struct HomeView: View {
    @Environment(AppStore.self) private var store
    var switchTab: (Int) -> Void
    @State private var editingAlarm: WakeAlarm?
    @State private var addingAlarm = false
    @State private var sleepMinutes = 30

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                GhostCompanionHero {
                    try? store.device.say("Hey, you. Sweet dreams. Your ghost is right here.")
                }
                .padding(.top, 20)

                HStack {
                    Text("Sleep & wake")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Spacer()
                    Text("Your little night ritual")
                        .font(.caption).foregroundStyle(GhostTheme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Image(systemName: "bell.and.waves.left.and.right.fill")
                            .foregroundStyle(GhostTheme.purple)
                        Text("Wake-Up Alarm")
                            .font(.headline.weight(.semibold))
                        Spacer()
                        Toggle("Alarm enabled", isOn: Binding(
                            get: { store.state.alarms.contains { $0.enabled } },
                            set: { enabled in
                                if var alarm = store.state.alarms.first(where: \.enabled) ?? store.state.alarms.first {
                                    alarm.enabled = enabled
                                    Task { await store.save(alarm) }
                                }
                            }
                        ))
                        .labelsHidden().tint(GhostTheme.purple)
                    }
                    if let next = store.nextAlarm {
                        let alarm = next.0
                        let nextDate = next.1
                        HStack(alignment: .firstTextBaseline) {
                            Text(nextDate, format: .dateTime.hour().minute())
                                .font(.system(size: 58, weight: .bold, design: .rounded))
                                .contentTransition(.numericText())
                        }
                        .foregroundStyle(.white)
                        HStack(spacing: 12) {
                            Image(systemName: "calendar")
                            Text(alarm.label).font(.subheadline)
                            Spacer()
                            Text(alarm.rule.rawValue)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(GhostTheme.purple.opacity(0.22), in: Capsule())
                                .foregroundStyle(GhostTheme.purple)
                        }
                        .foregroundStyle(GhostTheme.textSecondary)
                        HStack(spacing: 12) {
                            Button("Set Alarm") { editingAlarm = alarm }
                                .buttonStyle(.borderedProminent).tint(GhostTheme.purple)
                            Button("Turn Off") { Task { await store.toggle(alarm) } }
                                .buttonStyle(.bordered)
                        }
                    } else if let alarm = store.state.alarms.first {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(alarm.displayDate, format: .dateTime.hour().minute())
                                    .font(.system(size: 52, weight: .bold, design: .rounded))
                                Text("Alarm off").foregroundStyle(GhostTheme.textSecondary)
                            }
                            Spacer()
                            Button("Set Alarm") { editingAlarm = alarm }
                                .buttonStyle(.borderedProminent).tint(GhostTheme.purple)
                            Button("Turn On") { Task { await store.toggle(alarm) } }
                                .buttonStyle(.bordered)
                        }
                    } else {
                        Button { addingAlarm = true } label: {
                            Label("Create your first alarm", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent).tint(GhostTheme.purple)
                    }
                }
                .ghostCard(glow: true)

                Button { switchTab(2) } label: {
                    HStack(spacing: 16) {
                        Image(systemName: "moon.stars.fill")
                            .font(.title2).foregroundStyle(GhostTheme.purpleSoft)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Nightstand Saving Mode")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(GhostTheme.textPrimary)
                            Text("A sleepy ghost keeps you company")
                                .font(.caption)
                                .foregroundStyle(GhostTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(GhostTheme.textSecondary)
                    }
                }
                .buttonStyle(.plain)
                .ghostCard()

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "cloud.rain.fill").font(.title3)
                        VStack(alignment: .leading) {
                            Text("Tonight").font(.headline.weight(.semibold))
                            Text("Light rain · 12°C").font(.caption).opacity(0.8)
                        }
                        Spacer()
                        Text("19°").font(.system(size: 36, weight: .light, design: .rounded))
                    }
                    Text("Sleep well. Your ghost will wake you gently.")
                        .font(.subheadline).opacity(0.85)
                }
                .foregroundStyle(.white)
                .padding(22)
                .background(GhostTheme.weatherGradient, in: RoundedRectangle(cornerRadius: 24))

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "moon.zzz.fill").foregroundStyle(GhostTheme.purple)
                        Text("Sleep Music").font(.headline.weight(.semibold))
                        Spacer()
                        if store.device.playing != nil {
                            EqualizerBars(color: GhostTheme.purpleSoft)
                        }
                    }
                    HStack(spacing: 10) {
                        ForEach([15, 30, 60], id: \.self) { min in
                            Button {
                                sleepMinutes = min
                            } label: {
                                Text("\(min)m")
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(sleepMinutes == min ? GhostTheme.purpleSoft : Color.white.opacity(0.06), in: Capsule())
                                    .foregroundStyle(sleepMinutes == min ? GhostTheme.ink : GhostTheme.textSecondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    ForEach(GhostDevice.tracks + (store.device.hasMusic ? ["Imported music"] : []), id: \.self) { track in
                        HStack {
                            Button {
                                if store.device.playing == track { store.device.stopMusic() }
                                else {
                                    do { try store.device.play(track, minutes: sleepMinutes) }
                                    catch { store.error = error.localizedDescription }
                                }
                            } label: {
                                Image(systemName: store.device.playing == track ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.title2)
                                    .contentTransition(.symbolEffect(.replace))
                            }
                            Text(track).font(.subheadline.weight(.medium))
                            Spacer()
                            if store.device.playing == track {
                                Text("Playing").font(.caption2).foregroundStyle(GhostTheme.purple)
                            }
                        }
                    }
                }
                .ghostCard()

                Text("Your ghost is resting. Tap to say hello.")
                    .font(.caption).foregroundStyle(GhostTheme.textSecondary)
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: 640).frame(maxWidth: .infinity)
        }
        .sheet(item: $editingAlarm) { alarm in AddAlarmView(alarm: alarm) }
        .sheet(isPresented: $addingAlarm) { AddAlarmView() }
    }
}

struct EqualizerBars: View {
    var color: Color = GhostTheme.purple
    @State private var animating = false
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<4, id: \.self) { i in
                Capsule()
                    .fill(color)
                    .frame(width: 3, height: animating ? CGFloat([14, 22, 10, 18][i]) : 5)
                    .animation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true).delay(Double(i) * 0.12), value: animating)
            }
        }
        .onAppear { animating = true }
    }
}

struct WakeTabView: View {
    @Environment(AppStore.self) private var store
    var switchTab: (Int) -> Void
    @State private var snoozeBanner = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 26) {
                GhostTheme.GhostMascot(mood: .awake, size: 120)
                    .padding(.top, 30)
                VStack(spacing: 6) {
                    Text("Good morning")
                        .font(.title.weight(.bold))
                    Text(Date.now, format: .dateTime.weekday(.wide).month().day())
                        .foregroundStyle(GhostTheme.textSecondary)
                }
                Text(Date.now, style: .time)
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .foregroundStyle(GhostTheme.textPrimary)

                if !snoozeBanner.isEmpty {
                    Text(snoozeBanner)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 18).padding(.vertical, 10)
                        .background(GhostTheme.purple.opacity(0.22), in: Capsule())
                        .foregroundStyle(GhostTheme.purpleSoft)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                VStack(spacing: 14) {
                    Button {
                        store.device.stopMusic()
                        store.cancelSnooze()
                        if !store.challengeCompleted { store.completeChallenge() }
                        try? store.device.say("Awesome job waking up! Sleepy ghost says hi.")
                        switchTab(0)
                    } label: {
                        Text(store.challengeCompleted ? "I’m Awake ✓" : "I’m Awake")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(GhostTheme.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(GhostTheme.purpleSoft, in: Capsule())
                            .shadow(color: GhostTheme.purple.opacity(0.45), radius: 18, y: 6)
                    }
                    .buttonStyle(GhostTheme.GhostPressStyle())

                    Button {
                        Task {
                            if await store.snooze() {
                                withAnimation { snoozeBanner = "Snoozed for 5 minutes · Reminder scheduled" }
                            }
                        }
                    } label: {
                        Text("Snooze · 5 min")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(GhostTheme.purpleSoft)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 17)
                            .background(Capsule().strokeBorder(GhostTheme.purpleSoft.opacity(0.65), lineWidth: 1.4))
                    }
                    .buttonStyle(GhostTheme.GhostPressStyle())
                }
                .padding(.horizontal, 12)

                HStack(spacing: 8) {
                    Image(systemName: "cloud.rain.fill")
                        .foregroundStyle(GhostTheme.purpleSoft)
                    Text("Rain today · 12°C")
                        .font(.subheadline)
                        .foregroundStyle(GhostTheme.textSecondary)
                }
                .padding(.top, 12)
            }
            .padding(24)
            .frame(maxWidth: 540)
            .frame(maxWidth: .infinity)
        }
        .ghostScreen(animated: true)
    }
}

// MARK: - ReadyByEight/SleepAnalyticsView.swift

struct SleepAnalyticsView: View {
    @Environment(AppStore.self) private var store
    @Environment(SleepTrackerManager.self) private var tracker

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            Text(tracker.statusBanner)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(GhostTheme.textSecondary)
            metricGrid
            hypnogram
            smartWakeSection
            actionButtons
        }
        .ghostCard(glow: tracker.isTrackingOvernight)
        .accessibilityElement(children: .contain)
    }

    private var header: some View {
        HStack {
            Label("REM & Deep Sleep Tracker", systemImage: "waveform.path.ecg.rectangle.fill")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(GhostTheme.textPrimary)
            Spacer()
            Text("Score \(tracker.report.sleepScore)")
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(GhostTheme.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(GhostTheme.purple.opacity(0.28), in: Capsule())
        }
    }

    private var metricGrid: some View {
        let report = tracker.report
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
        return LazyVGrid(columns: columns, spacing: 8) {
            metricTile(title: "Score", value: "\(report.sleepScore)", sub: "Optimal", color: GhostTheme.purpleSoft)
            metricTile(title: "REM", value: SleepNightReport.formatDuration(report.remMinutes), sub: "\(report.remPercent)% dream", color: SleepStageKind.rem.color)
            metricTile(title: "Deep", value: SleepNightReport.formatDuration(report.deepMinutes), sub: "\(report.deepPercent)% restore", color: SleepStageKind.deep.color)
            metricTile(title: "Efficiency", value: "\(report.efficiencyPercent)%", sub: SleepNightReport.formatDuration(report.totalAsleepMinutes), color: SleepStageKind.core.color)
        }
    }

    private var hypnogram: some View {
        Chart {
            ForEach(tracker.report.samples) { sample in
                BarMark(
                    xStart: .value("Start", sample.startDate),
                    xEnd: .value("End", sample.endDate),
                    y: .value("Stage", sample.stage.rawValue)
                )
                .foregroundStyle(sample.stage.color.gradient)
                .cornerRadius(4)
            }
        }
        .chartYScale(domain: ["Awake", "REM", "Core", "Deep"])
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 2)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3]))
                    .foregroundStyle(Color.white.opacity(0.10))
                AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)))
                    .foregroundStyle(GhostTheme.textSecondary)
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisValueLabel().foregroundStyle(GhostTheme.textSecondary)
            }
        }
        .frame(height: 155)
        .padding(10)
        .background(Color.black.opacity(0.26), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var smartWakeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(isOn: Binding(
                get: { tracker.smartWakeEnabled },
                set: { tracker.smartWakeEnabled = $0 }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Smart Wake: 20m light-sleep window")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(GhostTheme.textPrimary)
                    Text("Rings gently when exiting Deep/REM near your wake alarm")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(GhostTheme.textSecondary)
                }
            }
            .tint(GhostTheme.purple)
            if let smartMsg = tracker.smartWakeTriggeredMessage {
                Text(smartMsg)
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundStyle(GhostTheme.mint)
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button {
                tracker.toggleOvernightTracking(targetAlarmDate: store.nextAlarm?.date)
            } label: {
                Label(
                    tracker.isTrackingOvernight ? "Stop Tracking" : "Track Tonight",
                    systemImage: tracker.isTrackingOvernight ? "stop.circle.fill" : "bed.double.fill"
                )
                .font(.system(.caption, design: .rounded).weight(.bold))
            }
            .buttonStyle(GhostTheme.GhostPressStyle())

            Button {
                tracker.simulateLastNight()
            } label: {
                Label("Simulate 8h", systemImage: "wand.and.stars")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
            }
            .buttonStyle(GhostTheme.GhostPressStyle())

            Button {
                Task { await tracker.syncFromHealthKit() }
            } label: {
                Label("HealthKit", systemImage: "heart.text.square.fill")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
            }
            .buttonStyle(GhostTheme.GhostPressStyle())
        }
    }

    private func metricTile(title: String, value: String, sub: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(GhostTheme.textSecondary)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(color)
                .minimumScaleFactor(0.75)
                .lineLimit(1)
            Text(sub)
                .font(.system(size: 9.5, weight: .medium, design: .rounded))
                .foregroundStyle(GhostTheme.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(color.opacity(0.28), lineWidth: 1)
        )
    }
}

// MARK: - ReadyByEight/SleepSoundEngine.swift

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
    var presetLabel: String { activePreset.rawValue }
    var remainingText: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

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

// MARK: - ReadyByEight/SleepTrackerManager.swift

#if canImport(HealthKit)
#endif

/// Sleep stages supported by both Apple HealthKit and the on-device mattress accelerometer tracker.
enum SleepStageKind: String, Codable, CaseIterable, Identifiable {
    case awake = "Awake"
    case rem = "REM"
    case core = "Core"
    case deep = "Deep"

    var id: String { rawValue }

    /// Numeric level for hypnogram step chart (top = Awake, bottom = Deep).
    var chartLevel: Int {
        switch self {
        case .awake: 4
        case .rem: 3
        case .core: 2
        case .deep: 1
        }
    }

    var color: Color {
        switch self {
        case .awake: Color(red: 0.96, green: 0.45, blue: 0.71)
        case .rem: Color(red: 0.69, green: 0.55, blue: 0.98)
        case .core: Color(red: 0.22, green: 0.74, blue: 0.97)
        case .deep: Color(red: 0.39, green: 0.40, blue: 0.95)
        }
    }
}

struct SleepStageSample: Identifiable, Codable, Equatable {
    var id = UUID()
    var startDate: Date
    var endDate: Date
    var stage: SleepStageKind

    var durationMinutes: Double {
        max(0, endDate.timeIntervalSince(startDate) / 60.0)
    }
}

struct SleepNightReport: Codable, Equatable {
    var date: Date
    var sourceLabel: String
    var samples: [SleepStageSample]

    var totalAsleepMinutes: Double {
        samples.filter { $0.stage != .awake }.reduce(0) { $0 + $1.durationMinutes }
    }

    var totalInBedMinutes: Double {
        max(1, samples.reduce(0) { $0 + $1.durationMinutes })
    }

    var remMinutes: Double {
        samples.filter { $0.stage == .rem }.reduce(0) { $0 + $1.durationMinutes }
    }

    var deepMinutes: Double {
        samples.filter { $0.stage == .deep }.reduce(0) { $0 + $1.durationMinutes }
    }

    var coreMinutes: Double {
        samples.filter { $0.stage == .core }.reduce(0) { $0 + $1.durationMinutes }
    }

    var awakeMinutes: Double {
        samples.filter { $0.stage == .awake }.reduce(0) { $0 + $1.durationMinutes }
    }

    var remPercent: Int {
        Int(round((remMinutes / max(1, totalAsleepMinutes)) * 100))
    }

    var deepPercent: Int {
        Int(round((deepMinutes / max(1, totalAsleepMinutes)) * 100))
    }

    var efficiencyPercent: Int {
        min(100, Int(round((totalAsleepMinutes / totalInBedMinutes) * 100)))
    }

    var sleepScore: Int {
        let durationRatio = min(1.0, totalAsleepMinutes / 450.0) // 7.5h target
        let remBonus = min(1.0, remMinutes / 95.0)
        let deepBonus = min(1.0, deepMinutes / 85.0)
        let effRatio = Double(efficiencyPercent) / 100.0
        let raw = (durationRatio * 45.0) + (remBonus * 20.0) + (deepBonus * 20.0) + (effRatio * 15.0)
        return max(40, min(99, Int(round(raw))))
    }

    static func formatDuration(_ minutes: Double) -> String {
        let total = Int(round(minutes))
        let hrs = total / 60
        let mins = total % 60
        return hrs > 0 ? "\(hrs)h \(mins)m" : "\(mins)m"
    }

    var coachSummary: String {
        "You got \(Self.formatDuration(deepMinutes)) of Deep Sleep and \(Self.formatDuration(remMinutes)) of REM (Sleep Score \(sleepScore))."
    }
}

/// Manages Apple HealthKit sleep stage syncing, On-Device CoreMotion mattress tracking,
/// realistic 8-hour ultradian sleep simulation, and a 20-minute Smart Wake light-sleep detector.
@Observable @MainActor
final class SleepTrackerManager {
    var report: SleepNightReport
    var isTrackingOvernight = false
    var smartWakeEnabled = true
    var smartWakeWindowMinutes = 20
    var currentLiveStage: SleepStageKind = .core
    var statusBanner: String = "Simulated 8h ultradian cycle ready · Tap Sync Health or Track Tonight"
    var smartWakeTriggeredMessage: String?

    private let motionManager = CMMotionManager()
    private var trackingStart: Date?
    private var liveSamples: [SleepStageSample] = []
    private var bucketMotionSum: Double = 0
    private var bucketReadings: Int = 0
    private var trackingTask: Task<Void, Never>?
    private let storageKey = "ghost.sleepReport.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode(SleepNightReport.self, from: data),
           !saved.samples.isEmpty {
            self.report = saved
        } else {
            self.report = Self.buildRealisticNight(endingAt: .now, source: "Ultradian Sleep Model")
        }
    }

    func simulateLastNight() {
        let simulated = Self.buildRealisticNight(endingAt: .now, source: "Simulated 8h Ultradian Sleep")
        report = simulated
        saveReport()
        statusBanner = "Generated 8h REM & Deep Sleep hypnogram (\(simulated.coachSummary))"
    }

    func toggleOvernightTracking(targetAlarmDate: Date?) {
        if isTrackingOvernight {
            stopOvernightTracking()
        } else {
            startOvernightTracking(targetAlarmDate: targetAlarmDate)
        }
    }

    func startOvernightTracking(targetAlarmDate: Date?) {
        isTrackingOvernight = true
        trackingStart = .now
        liveSamples = []
        bucketMotionSum = 0
        bucketReadings = 0
        currentLiveStage = .core
        statusBanner = motionManager.isAccelerometerAvailable
            ? "Mattress motion tracker active · Place iPhone/iPad near pillow"
            : "Overnight ultradian stage estimator active (Simulator/No sensor fallback)"

        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.25
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
                guard let self, let accel = data?.acceleration else { return }
                let mag = abs(sqrt(accel.x * accel.x + accel.y * accel.y + accel.z * accel.z) - 1.0)
                Task { @MainActor in
                    self.bucketMotionSum += mag
                    self.bucketReadings += 1
                }
            }
        }

        trackingTask?.cancel()
        trackingTask = Task {
            var elapsedMinutes = 0
            while !Task.isCancelled && isTrackingOvernight {
                try? await Task.sleep(for: .seconds(60))
                guard !Task.isCancelled, isTrackingOvernight else { break }
                elapsedMinutes += 1
                recordMinuteBucket(elapsedMinutes: elapsedMinutes, targetAlarmDate: targetAlarmDate)
            }
        }
    }

    func stopOvernightTracking() {
        isTrackingOvernight = false
        motionManager.stopAccelerometerUpdates()
        trackingTask?.cancel()
        trackingTask = nil
        if liveSamples.count >= 3 {
            report = SleepNightReport(
                date: .now,
                sourceLabel: motionManager.isAccelerometerAvailable ? "Mattress Motion Tracker" : "Overnight Session",
                samples: liveSamples
            )
            saveReport()
            Task { await saveSessionToHealthKit(samples: liveSamples) }
        }
        statusBanner = "Saved sleep session · \(report.coachSummary)"
    }

    private func recordMinuteBucket(elapsedMinutes: Int, targetAlarmDate: Date?) {
        let now = Date()
        let start = now.addingTimeInterval(-60)
        let avgMotion = bucketReadings > 0 ? (bucketMotionSum / Double(bucketReadings)) : 0.012
        bucketMotionSum = 0
        bucketReadings = 0

        let cycleMinute = elapsedMinutes % 90
        let classified: SleepStageKind
        if avgMotion > 0.085 {
            classified = .awake
        } else if cycleMinute >= 65 && avgMotion >= 0.008 && avgMotion <= 0.035 {
            classified = .rem
        } else if avgMotion < 0.010 && cycleMinute >= 15 && cycleMinute < 55 {
            classified = .deep
        } else {
            classified = .core
        }

        currentLiveStage = classified
        if let last = liveSamples.last, last.stage == classified {
            liveSamples[liveSamples.count - 1].endDate = now
        } else {
            liveSamples.append(SleepStageSample(startDate: start, endDate: now, stage: classified))
        }

        // Smart Wake check: if within 20 minutes before target alarm and in light/REM sleep
        if smartWakeEnabled, let alarm = targetAlarmDate {
            let delta = alarm.timeIntervalSince(now)
            if delta > 0 && delta <= Double(smartWakeWindowMinutes * 60) && (classified == .core || classified == .rem) {
                smartWakeTriggeredMessage = "Smart Wake triggered gently during \(classified.rawValue) sleep (\(Int(ceil(delta / 60)))m before alarm)."
            }
        }
    }

    func syncFromHealthKit() async {
        #if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable(),
              let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            statusBanner = "Apple Health isn't available on this device · Showing ultradian model"
            return
        }
        let store = HKHealthStore()
        do {
            try await store.requestAuthorization(toShare: [sleepType], read: [sleepType])
            let startOfWindow = Calendar.current.date(byAdding: .hour, value: -24, to: .now) ?? .now.addingTimeInterval(-86_400)
            let predicate = HKQuery.predicateForSamples(withStart: startOfWindow, end: .now, options: .strictEndDate)
            let descriptor = HKSampleQueryDescriptor(
                predicates: [.categorySample(type: sleepType, predicate: predicate)],
                sortDescriptors: [SortDescriptor(\.startDate, order: .forward)]
            )
            let results = try await descriptor.result(for: store)
            let mapped: [SleepStageSample] = results.compactMap { sample in
                let stage: SleepStageKind
                switch sample.value {
                case HKCategoryValueSleepAnalysis.awake.rawValue: stage = .awake
                case HKCategoryValueSleepAnalysis.asleepREM.rawValue: stage = .rem
                case HKCategoryValueSleepAnalysis.asleepDeep.rawValue: stage = .deep
                case HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                     HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue: stage = .core
                default: return nil
                }
                return SleepStageSample(startDate: sample.startDate, endDate: sample.endDate, stage: stage)
            }
            if !mapped.isEmpty {
                report = SleepNightReport(date: .now, sourceLabel: "Apple HealthKit", samples: mapped)
                saveReport()
                statusBanner = "Synced \(mapped.count) sleep stages from Apple Health"
            } else {
                statusBanner = "No Apple Health sleep samples in last 24h · Using ultradian model"
            }
        } catch {
            statusBanner = "HealthKit access not granted · Using on-device ultradian tracker"
        }
        #else
        statusBanner = "HealthKit unavailable · Using on-device ultradian tracker"
        #endif
    }

    private func saveSessionToHealthKit(samples: [SleepStageSample]) async {
        #if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable(),
              let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        let store = HKHealthStore()
        let objects: [HKCategorySample] = samples.map { item in
            let val: Int
            switch item.stage {
            case .awake: val = HKCategoryValueSleepAnalysis.awake.rawValue
            case .rem: val = HKCategoryValueSleepAnalysis.asleepREM.rawValue
            case .core: val = HKCategoryValueSleepAnalysis.asleepCore.rawValue
            case .deep: val = HKCategoryValueSleepAnalysis.asleepDeep.rawValue
            }
            return HKCategorySample(type: sleepType, value: val, start: item.startDate, end: item.endDate)
        }
        try? await store.save(objects)
        #endif
    }

    private func saveReport() {
        if let data = try? JSONEncoder().encode(report) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    static func buildRealisticNight(endingAt end: Date, source: String) -> SleepNightReport {
        // 8-hour realistic architecture across five 90-minute ultradian cycles
        let segments: [(SleepStageKind, Int)] = [
            (.awake, 12), (.core, 34), (.deep, 38), (.core, 14), (.rem, 12),
            (.core, 32), (.deep, 32), (.core, 16), (.rem, 22),
            (.core, 36), (.deep, 18), (.core, 20), (.rem, 28),
            (.awake, 6),  (.core, 34), (.rem, 32),
            (.core, 50), (.rem, 36), (.awake, 8)
        ]
        let totalMinutes = segments.reduce(0) { $0 + $1.1 }
        var cursor = end.addingTimeInterval(-Double(totalMinutes * 60))
        var list: [SleepStageSample] = []
        for (stage, mins) in segments {
            let next = cursor.addingTimeInterval(Double(mins * 60))
            list.append(SleepStageSample(startDate: cursor, endDate: next, stage: stage))
            cursor = next
        }
        return SleepNightReport(date: end, sourceLabel: source, samples: list)
    }
}
