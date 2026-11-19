import SwiftUI
import AVFoundation
import Security

/// Device-only audio and credentials. This file is included by the generated Xcode project.
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
    var endpoint = UserDefaults.standard.string(forKey: "endpoint") ?? "https://api.openai.com/v1/chat/completions" {
        didSet { UserDefaults.standard.set(endpoint, forKey: "endpoint") }
    }
    var model = UserDefaults.standard.string(forKey: "model") ?? "gpt-4o-mini" {
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
        // Invalidate computed settings when an import changes UserDefaults.
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
    func reply(messages: [CoachMessage]) async throws -> String {
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
