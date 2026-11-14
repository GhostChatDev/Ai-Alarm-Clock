import Foundation

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
