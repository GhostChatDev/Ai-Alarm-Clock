import SwiftUI
import UserNotifications
import AVFoundation
import AudioToolbox
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Sleep Music Track & Device Alarm Tone Models

struct SleepTrack: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let baseFrequency: Double

    static let catalog: [SleepTrack] = [
        SleepTrack(id: "rain", title: "Gentle Night Rain", subtitle: "Warm pink-noise rain & soft chime", icon: "cloud.rain.fill", baseFrequency: 174.0),
        SleepTrack(id: "cosmic", title: "Cosmic Drift · 432 Hz", subtitle: "Deep lavender ambient drone", icon: "sparkles", baseFrequency: 216.0),
        SleepTrack(id: "ocean", title: "Midnight Ocean Waves", subtitle: "Slow rhythmic tide swells", icon: "water.waves", baseFrequency: 136.1),
        SleepTrack(id: "chimes", title: "Dream Lullaby Chimes", subtitle: "528 Hz harmonic sleep bells", icon: "moon.stars.fill", baseFrequency: 264.0)
    ]
}

struct DeviceAlarmTone: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let systemSoundID: SystemSoundID

    static let catalog: [DeviceAlarmTone] = [
        DeviceAlarmTone(id: "aurora", title: "Aurora Chime (Device)", subtitle: "Gentle ascending crystal chime", systemSoundID: 1005),
        DeviceAlarmTone(id: "harp", title: "Morning Harp (Device)", subtitle: "Warm acoustic harp arpeggio", systemSoundID: 1008),
        DeviceAlarmTone(id: "radar", title: "Classic Pulse (Device)", subtitle: "Crisp system wake-up beacon", systemSoundID: 1013),
        DeviceAlarmTone(id: "bell", title: "Temple Bell (Device)", subtitle: "Resonant mindfulness bell", systemSoundID: 1016),
        DeviceAlarmTone(id: "custom", title: "Custom Device Audio File", subtitle: "Tuned from your iPhone / iPad files", systemSoundID: 1005)
    ]
}

struct MorningPlanTask: Identifiable, Codable, Equatable, Sendable {
    var id = UUID()
    var title: String
    var done: Bool = false

    static let defaults: [MorningPlanTask] = [
        MorningPlanTask(title: "Drink a glass of water", done: true),
        MorningPlanTask(title: "Stretch for two minutes", done: true),
        MorningPlanTask(title: "Pick your first task", done: false)
    ]
}

// MARK: - Gitignored AI API Configuration Loader (Secrets.plist / .env / Environment)

enum GhostAIConfig {
    struct Credentials: Sendable {
        var apiKey: String
        var baseURL: String
        var model: String
    }

    private static let keyStorage = "ghost.ai.override.key"
    private static let urlStorage = "ghost.ai.override.url"
    private static let modelStorage = "ghost.ai.override.model"

    static func saveOverride(apiKey: String, baseURL: String, model: String) {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedModel = model.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(trimmedKey, forKey: keyStorage)
        UserDefaults.standard.set(trimmedURL.isEmpty ? "https://api.openai.com/v1" : trimmedURL, forKey: urlStorage)
        UserDefaults.standard.set(trimmedModel.isEmpty ? "gpt-4o-mini" : trimmedModel, forKey: modelStorage)
    }

    static func clearOverride() {
        UserDefaults.standard.removeObject(forKey: keyStorage)
    }

    static func load() -> Credentials? {
        // 1. Check user-entered local device override
        if let savedKey = UserDefaults.standard.string(forKey: keyStorage),
           !savedKey.isEmpty, !savedKey.contains("YOUR_API_KEY") {
            let url = UserDefaults.standard.string(forKey: urlStorage) ?? "https://api.openai.com/v1"
            let model = UserDefaults.standard.string(forKey: modelStorage) ?? "gpt-4o-mini"
            return Credentials(apiKey: savedKey, baseURL: url, model: model)
        }

        // 2. Check ProcessInfo environment variables (Xcode scheme or CI)
        let env = ProcessInfo.processInfo.environment
        if let envKey = env["GHOST_AI_API_KEY"] ?? env["OPENAI_API_KEY"],
           !envKey.isEmpty, !envKey.contains("YOUR_API_KEY") {
            let url = env["GHOST_AI_BASE_URL"] ?? "https://api.openai.com/v1"
            let model = env["GHOST_AI_MODEL"] ?? "gpt-4o-mini"
            return Credentials(apiKey: envKey, baseURL: url, model: model)
        }

        // 3. Check gitignored Secrets.plist in Bundle
        if let plistURL = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
           let dict = NSDictionary(contentsOf: plistURL) as? [String: Any],
           let plistKey = (dict["GHOST_AI_API_KEY"] as? String) ?? (dict["OPENAI_API_KEY"] as? String),
           !plistKey.isEmpty, !plistKey.contains("YOUR_API_KEY") {
            let url = (dict["GHOST_AI_BASE_URL"] as? String) ?? "https://api.openai.com/v1"
            let model = (dict["GHOST_AI_MODEL"] as? String) ?? "gpt-4o-mini"
            return Credentials(apiKey: plistKey, baseURL: url, model: model)
        }

        // 4. Check gitignored .env in Bundle or Documents
        let candidateEnvURLs: [URL?] = [
            Bundle.main.url(forResource: ".env", withExtension: nil),
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(".env")
        ]
        for case let url? in candidateEnvURLs {
            if let raw = try? String(contentsOf: url, encoding: .utf8) {
                var parsed: [String: String] = [:]
                for line in raw.components(separatedBy: .newlines) {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty, !trimmed.hasPrefix("#"),
                          let eq = trimmed.firstIndex(of: "=") else { continue }
                    let k = String(trimmed[..<eq]).trimmingCharacters(in: .whitespaces)
                    let v = String(trimmed[trimmed.index(after: eq)...])
                        .trimmingCharacters(in: .whitespaces)
                        .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                    parsed[k] = v
                }
                if let key = parsed["GHOST_AI_API_KEY"] ?? parsed["OPENAI_API_KEY"],
                   !key.isEmpty, !key.contains("YOUR_API_KEY") {
                    return Credentials(
                        apiKey: key,
                        baseURL: parsed["GHOST_AI_BASE_URL"] ?? "https://api.openai.com/v1",
                        model: parsed["GHOST_AI_MODEL"] ?? "gpt-4o-mini"
                    )
                }
            }
        }
        return nil
    }
}

// MARK: - On-Device TTS Delegate

final class SpeechDelegateProxy: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    var onStateChange: (@Sendable (Bool) -> Void)?

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        onStateChange?(true)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onStateChange?(false)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        onStateChange?(false)
    }
}

// MARK: - Main AppStore (@Observable, @MainActor)

@MainActor
@Observable
final class AppStore {
    var state: SavedState
    var sending = false
    var error: String?
    var permissionDenied = false
    var isCoachSpeaking = false

    // Wake-Up Screen & Snooze State
    var showingWakeUpScreen = false
    var snoozedUntil: Date?

    // Morning Plan Checklist (Reference 4)
    var morningPlan: [MorningPlanTask] = MorningPlanTask.defaults

    // Sleep Music State
    var selectedSleepTrackID: String = SleepTrack.catalog[0].id
    var isSleepMusicPlaying = false
    var sleepTimerMinutesRemaining: Int = 30
    var sleepVolume: Float = 0.65
    var customSleepAudioURL: URL?

    // Device Alarm Tone State
    var selectedAlarmToneID: String = DeviceAlarmTone.catalog[0].id
    var customAlarmAudioURL: URL?
    var isAlarmRinging = false

    // Device TTS Settings
    var ttsEnabled = true
    var selectedVoiceIdentifier: String = ""
    var speechRate: Float = 0.49

    // Weather Display (Reference 1, 2, 3)
    var tonightTemperatureC: Int = 18
    var tonightCondition: String = "Clear sky"
    var morningCondition: String = "Rain today · 12°C"

    // AI API Status
    var hasExternalAIKey: Bool = false
    var aiStatusLabel: String = "On-device / Guided Coach"

    private let fileURL: URL
    private let synthesizer = AVSpeechSynthesizer()
    private let speechProxy = SpeechDelegateProxy()
    private var sleepPlayer: AVAudioPlayer?
    private var alarmPlayer: AVAudioPlayer?
    private var sleepCountdownTask: Task<Void, Never>?

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = docs.appendingPathComponent("state.json")
        if let data = try? Data(contentsOf: fileURL),
           let loaded = try? JSONDecoder().decode(SavedState.self, from: data) {
            state = loaded
        } else {
            // Seed with the 7:00 AM Mon-Fri alarm from the reference photos
            let defaultAlarm = WakeAlarm(hour: 7, minute: 0, label: "Morning Wake-Up", rule: .weekdays, enabled: true)
            let initialCoachMsg = CoachMessage(
                isUser: false,
                text: "Good morning. What’s one thing you want to get done today?"
            )
            state = SavedState(alarms: [defaultAlarm], messages: [initialCoachMsg], lastCompletedDay: nil)
        }

        speechProxy.onStateChange = { [weak self] speaking in
            Task { @MainActor in
                self?.isCoachSpeaking = speaking
            }
        }
        synthesizer.delegate = speechProxy
        refreshAIConfigStatus()
    }

    // MARK: - Computed Properties

    var challengeCompleted: Bool {
        state.isDoneToday(calendar: .current, now: .now)
    }

    var nextAlarm: Date? {
        state.nextTrigger(after: .now)
    }

    var primaryAlarm: WakeAlarm {
        state.alarms.first ?? WakeAlarm(hour: 7, minute: 0, label: "Alarm", rule: .weekdays, enabled: true)
    }

    var selectedSleepTrack: SleepTrack {
        SleepTrack.catalog.first(where: { $0.id == selectedSleepTrackID }) ?? SleepTrack.catalog[0]
    }

    var selectedAlarmTone: DeviceAlarmTone {
        DeviceAlarmTone.catalog.first(where: { $0.id == selectedAlarmToneID }) ?? DeviceAlarmTone.catalog[0]
    }

    var availableVoices: [AVSpeechSynthesisVoice] {
        let english = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("en") }
        return english.isEmpty ? AVSpeechSynthesisVoice.speechVoices() : english
    }

    var coachName: String {
        if GhostAIConfig.load() != nil {
            return "Ghost AI · API Connected (Gitignored Key)"
        }
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *),
           SystemLanguageModel.default.availability == .available {
            return "On-device Apple Intelligence"
        }
        #endif
        return "Ghost Coach · Guided & Ready for API"
    }

    func refreshAIConfigStatus() {
        if let creds = GhostAIConfig.load() {
            hasExternalAIKey = true
            aiStatusLabel = "Connected (\(creds.model))"
        } else {
            hasExternalAIKey = false
            aiStatusLabel = coachName
        }
    }

    // MARK: - Persistence & Alarms

    func save() {
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            self.error = "Couldn’t save your changes on this device."
        }
    }

    func completeChallenge() {
        state.markDone(calendar: .current, now: .now)
        stopAlarmSound()
        showingWakeUpScreen = false
        snoozedUntil = nil
        save()
        if ttsEnabled {
            speak("Good morning! Let's take the first small step today.")
        }
    }

    func snoozeFiveMinutes() {
        stopAlarmSound()
        let target = Date.now.addingTimeInterval(5 * 60)
        snoozedUntil = target
        showingWakeUpScreen = false

        Task {
            let center = UNUserNotificationCenter.current()
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Ghost Coach · Snooze Over"
            content.body = "5 minutes are up. Let’s take the first small step."
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5 * 60, repeats: false)
            let req = UNNotificationRequest(identifier: "ghost-snooze-5min", content: content, trigger: trigger)
            try? await center.add(req)
        }
    }

    func triggerWakeUpPreview() {
        showingWakeUpScreen = true
        playSelectedAlarmTone()
        if ttsEnabled {
            speak("Good morning. Let's take the first small step.")
        }
    }

    func addAlarm(hour: Int, minute: Int, label: String, rule: RepeatRule) async {
        let clean = label.trimmingCharacters(in: .whitespacesAndNewlines)
        let alarm = WakeAlarm(hour: hour, minute: minute,
                              label: clean.isEmpty ? "Wake-up" : String(clean.prefix(60)),
                              rule: rule, enabled: true)
        state.alarms.append(alarm)
        state.alarms.sort { ($0.hour, $0.minute) < ($1.hour, $1.minute) }
        await syncNotification(for: alarm)
        save()
    }

    func updatePrimaryAlarmTime(hour: Int, minute: Int, rule: RepeatRule) async {
        if state.alarms.isEmpty {
            await addAlarm(hour: hour, minute: minute, label: "Morning Wake-Up", rule: rule)
            return
        }
        state.alarms[0].hour = max(0, min(23, hour))
        state.alarms[0].minute = max(0, min(59, minute))
        state.alarms[0].rule = rule
        await syncNotification(for: state.alarms[0])
        save()
    }

    func toggle(_ alarm: WakeAlarm) async {
        guard let i = state.alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        state.alarms[i].enabled.toggle()
        await syncNotification(for: state.alarms[i])
        save()
    }

    func delete(_ alarm: WakeAlarm) {
        removeNotifications(for: alarm)
        state.alarms.removeAll { $0.id == alarm.id }
        save()
    }

    private func syncNotification(for alarm: WakeAlarm) async {
        let center = UNUserNotificationCenter.current()
        removeNotifications(for: alarm)
        guard alarm.enabled else { return }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            permissionDenied = !granted
            guard granted else {
                if let i = state.alarms.firstIndex(where: { $0.id == alarm.id }) {
                    state.alarms[i].enabled = false
                }
                error = "Enable notifications in iOS Settings so wake-up reminders can alert you."
                return
            }
            for item in notificationRequests(for: alarm) {
                try await center.add(item)
            }
        } catch {
            self.error = "Couldn’t schedule notification: \(error.localizedDescription)"
        }
    }

    private func removeNotifications(for alarm: WakeAlarm) {
        let ids = (1...7).map { "\(alarm.id.uuidString)-\($0)" } + [alarm.id.uuidString]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    private func notificationRequests(for alarm: WakeAlarm) -> [UNNotificationRequest] {
        let content = UNMutableNotificationContent()
        content.title = alarm.label
        content.body = "Good morning — open Ghost Coach for your first small step."
        content.sound = .default

        let weekdays: [Int?] = switch alarm.rule {
        case .once, .daily: [nil]
        case .weekdays: [2, 3, 4, 5, 6]
        case .weekends: [1, 7]
        }

        return weekdays.map { day in
            var parts = DateComponents()
            parts.hour = alarm.hour
            parts.minute = alarm.minute
            parts.weekday = day
            let repeats = alarm.rule != .once
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: repeats)
            let id = day.map { "\(alarm.id.uuidString)-\($0)" } ?? alarm.id.uuidString
            return UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        }
    }

    // MARK: - Morning Plan Checklist (Reference 4)

    func togglePlanTask(_ taskID: UUID) {
        guard let idx = morningPlan.firstIndex(where: { $0.id == taskID }) else { return }
        morningPlan[idx].done.toggle()
    }

    func addPlanTask(_ title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        morningPlan.append(MorningPlanTask(title: trimmed, done: false))
    }

    // MARK: - Sleep Music Playback (Procedural WAV + Custom Device Audio)

    func toggleSleepMusic() {
        if isSleepMusicPlaying {
            stopSleepMusic()
        } else {
            startSleepMusic()
        }
    }

    func selectSleepTrack(_ track: SleepTrack) {
        selectedSleepTrackID = track.id
        customSleepAudioURL = nil
        if isSleepMusicPlaying {
            startSleepMusic()
        }
    }

    func setCustomSleepAudio(url: URL) {
        _ = url.startAccessingSecurityScopedResource()
        customSleepAudioURL = url
        startSleepMusic()
    }

    func startSleepMusic() {
        stopSleepMusic()
        configureAudioSession()

        do {
            if let customURL = customSleepAudioURL {
                let player = try AVAudioPlayer(contentsOf: customURL)
                player.numberOfLoops = -1
                player.volume = sleepVolume
                player.prepareToPlay()
                player.play()
                sleepPlayer = player
            } else {
                let wavData = Self.makeAmbientSleepWAV(frequency: selectedSleepTrack.baseFrequency, seconds: 6)
                let player = try AVAudioPlayer(data: wavData)
                player.numberOfLoops = -1
                player.volume = sleepVolume
                player.prepareToPlay()
                player.play()
                sleepPlayer = player
            }
            isSleepMusicPlaying = true
            startSleepTimerCountdown()
        } catch {
            self.error = "Unable to start sleep audio: \(error.localizedDescription)"
        }
    }

    func stopSleepMusic() {
        sleepCountdownTask?.cancel()
        sleepCountdownTask = nil
        sleepPlayer?.stop()
        sleepPlayer = nil
        isSleepMusicPlaying = false
    }

    func updateSleepVolume(_ value: Float) {
        sleepVolume = max(0.05, min(1.0, value))
        sleepPlayer?.volume = sleepVolume
    }

    private func startSleepTimerCountdown() {
        sleepCountdownTask?.cancel()
        let minutes = max(5, sleepTimerMinutesRemaining)
        sleepCountdownTask = Task {
            for _ in 0..<minutes {
                try? await Task.sleep(for: .seconds(60))
                if Task.isCancelled { return }
                if sleepTimerMinutesRemaining > 1 {
                    sleepTimerMinutesRemaining -= 1
                } else {
                    stopSleepMusic()
                    return
                }
            }
        }
    }

    // MARK: - Device Alarm Tones (System Alert Sound + Custom Device File)

    func selectAlarmTone(_ tone: DeviceAlarmTone) {
        selectedAlarmToneID = tone.id
        playSelectedAlarmTone()
    }

    func setCustomAlarmAudio(url: URL) {
        _ = url.startAccessingSecurityScopedResource()
        customAlarmAudioURL = url
        selectedAlarmToneID = "custom"
        playSelectedAlarmTone()
    }

    func playSelectedAlarmTone() {
        stopAlarmSound()
        configureAudioSession()
        isAlarmRinging = true

        if let customURL = customAlarmAudioURL, selectedAlarmToneID == "custom" {
            if let player = try? AVAudioPlayer(contentsOf: customURL) {
                player.numberOfLoops = 2
                player.volume = 0.9
                player.prepareToPlay()
                player.play()
                alarmPlayer = player
                return
            }
        }

        // Play system device alert sound + synthesized gentle harmonic bell fallback
        AudioServicesPlayAlertSound(selectedAlarmTone.systemSoundID)
        let freq: Double = switch selectedAlarmToneID {
        case "aurora": 528.0
        case "harp": 440.0
        case "radar": 660.0
        default: 396.0
        }
        let bellWAV = Self.makeBellChimeWAV(frequency: freq)
        if let player = try? AVAudioPlayer(data: bellWAV) {
            player.volume = 0.85
            player.prepareToPlay()
            player.play()
            alarmPlayer = player
        }
    }

    func stopAlarmSound() {
        alarmPlayer?.stop()
        alarmPlayer = nil
        isAlarmRinging = false
    }

    // MARK: - On-Device TTS (AVSpeechSynthesizer)

    func speak(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        configureAudioSession()
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: trimmed)
        if !selectedVoiceIdentifier.isEmpty,
           let voice = AVSpeechSynthesisVoice(identifier: selectedVoiceIdentifier) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        utterance.rate = max(0.35, min(0.60, speechRate))
        utterance.pitchMultiplier = 1.06
        synthesizer.speak(utterance)
    }

    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isCoachSpeaking = false
    }

    private func configureAudioSession() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
        try? session.setActive(true)
        #endif
    }

    // MARK: - AI Morning Coach Conversation (Gitignored API + Apple Intelligence + Offline Coach)

    func clearChat() {
        state.messages = [
            CoachMessage(isUser: false, text: "Good morning. What’s one thing you want to get done today?")
        ]
        save()
    }

    func send(_ raw: String) async {
        let prompt = String(raw.trimmingCharacters(in: .whitespacesAndNewlines).prefix(2_000))
        guard !prompt.isEmpty, !sending else { return }
        sending = true
        isCoachSpeaking = true
        defer {
            sending = false
            save()
        }

        state.messages.append(CoachMessage(isUser: true, text: prompt))
        let reply = await replyTo(prompt)
        state.messages.append(CoachMessage(isUser: false, text: reply))
        if ttsEnabled {
            speak(reply)
        } else {
            isCoachSpeaking = false
        }
    }

    private func replyTo(_ prompt: String) async -> String {
        // 1. If a gitignored AI API key is present (Secrets.plist / .env / environment / local override), call API
        if let creds = GhostAIConfig.load(),
           let remoteReply = await callExternalAI(prompt: prompt, credentials: creds) {
            return remoteReply
        }

        // 2. Otherwise check on-device Apple Intelligence
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *),
           SystemLanguageModel.default.availability == .available {
            do {
                let session = LanguageModelSession(instructions: """
                    You are Ghost Coach, a calm, brief morning and evening habit coach inside the Ghost Coach alarm app. \
                    Offer one small, kind, concrete next step in 2 to 4 short sentences.
                    """)
                let response = try await session.respond(to: prompt)
                let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty { return text }
            } catch {
                // Fall through to built-in coach
            }
        }
        #endif

        // 3. Built-in guided coach tailored to reference chips
        let lower = prompt.lowercased()
        if lower.contains("move my body") {
            return "Start with a two-minute shoulder roll and a slow calf stretch right beside your bed. Small movement wakes up your focus without overwhelm."
        } else if lower.contains("focus on work") {
            return "Pick just one 25-minute priority block before checking messages. Write the task title on your Morning Plan and start the timer."
        } else if lower.contains("feel less stressed") {
            return "Take three slow 4-second breaths and drink a full glass of water first. Let everything else wait five minutes while you settle in."
        }
        return OfflineCoach.reply(to: prompt)
    }

    private func callExternalAI(prompt: String, credentials: GhostAIConfig.Credentials) async -> String? {
        let base = credentials.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(base)/chat/completions") else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("Bearer \(credentials.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "model": credentials.model,
            "messages": [
                ["role": "system", "content": "You are Ghost Coach, a warm, concise morning and bedtime habit coach. Give one small, encouraging step in 2-3 sentences."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 180
        ]
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return nil }
        request.httpBody = body

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                return nil
            }
            let cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)
            return cleaned.isEmpty ? nil : cleaned
        } catch {
            return nil
        }
    }

    // MARK: - Procedural In-Memory WAV Synthesis (Zero External Assets Needed)

    static func makeAmbientSleepWAV(frequency: Double, seconds: Int) -> Data {
        let sampleRate = 22050
        let totalSamples = sampleRate * max(2, seconds)
        var pcm = [Int16](repeating: 0, count: totalSamples)
        var lfsr: UInt32 = 0xACE1

        for i in 0..<totalSamples {
            let t = Double(i) / Double(sampleRate)
            let envelope = 0.55 + 0.35 * sin(2.0 * .pi * 0.16 * t)
            let fundamental = sin(2.0 * .pi * frequency * t)
            let fifth = 0.45 * sin(2.0 * .pi * (frequency * 1.5) * t)
            let sub = 0.35 * sin(2.0 * .pi * (frequency * 0.5) * t)

            // Gentle pink-like rain shimmer
            lfsr = (lfsr >> 1) ^ (-(lfsr & 1) & 0xB400)
            let noise = (Double(lfsr & 0xFF) / 128.0 - 1.0) * 0.08

            let mixed = (fundamental * 0.45 + fifth * 0.25 + sub * 0.22 + noise) * envelope * 0.32
            let clamped = max(-0.95, min(0.95, mixed))
            pcm[i] = Int16(clamped * Double(Int16.max))
        }
        return encodeWAV(samples: pcm, sampleRate: sampleRate)
    }

    static func makeBellChimeWAV(frequency: Double) -> Data {
        let sampleRate = 22050
        let totalSamples = sampleRate * 2
        var pcm = [Int16](repeating: 0, count: totalSamples)

        for i in 0..<totalSamples {
            let t = Double(i) / Double(sampleRate)
            let decay = exp(-2.4 * t)
            let tone1 = sin(2.0 * .pi * frequency * t)
            let tone2 = 0.5 * sin(2.0 * .pi * (frequency * 2.0) * t)
            let sample = (tone1 + tone2) * 0.45 * decay
            pcm[i] = Int16(max(-0.95, min(0.95, sample)) * Double(Int16.max))
        }
        return encodeWAV(samples: pcm, sampleRate: sampleRate)
    }

    private static func encodeWAV(samples: [Int16], sampleRate: Int) -> Data {
        let dataSize = samples.count * 2
        let fileSize = 36 + dataSize
        var data = Data()
        data.append(contentsOf: Array("RIFF".utf8))
        data.append(uint32LE(UInt32(fileSize)))
        data.append(contentsOf: Array("WAVEfmt ".utf8))
        data.append(uint32LE(16))
        data.append(uint16LE(1))
        data.append(uint16LE(1))
        data.append(uint32LE(UInt32(sampleRate)))
        data.append(uint32LE(UInt32(sampleRate * 2)))
        data.append(uint16LE(2))
        data.append(uint16LE(16))
        data.append(contentsOf: Array("data".utf8))
        data.append(uint32LE(UInt32(dataSize)))
        samples.withUnsafeBufferPointer { buffer in
            data.append(UnsafeBufferPointer(
                start: UnsafeRawPointer(buffer.baseAddress)?.assumingMemoryBound(to: UInt8.self),
                count: dataSize
            ))
        }
        return data
    }

    private static func uint32LE(_ value: UInt32) -> Data {
        var le = value.littleEndian
        return Data(bytes: &le, count: 4)
    }

    private static func uint16LE(_ value: UInt16) -> Data {
        var le = value.littleEndian
        return Data(bytes: &le, count: 2)
    }
}
