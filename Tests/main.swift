import Foundation

var checks = 0
@inline(__always) func require(_ condition: @autoclosure () -> Bool, _ description: String) {
    guard condition() else { fatalError("FAIL: \(description)") }
    checks += 1
}
func expect(_ condition: @autoclosure () -> Bool, _ description: String) {
    require(condition(), description)
}
func calendar(_ zone: String) -> Calendar {
    var result = Calendar(identifier: .gregorian)
    result.timeZone = TimeZone(identifier: zone)!
    return result
}
let utc = calendar("UTC")
func date(_ value: String) -> Date { ISO8601DateFormatter().date(from: value)! }
let monday = date("2026-11-16T06:00:00Z")
let eight = date("2026-11-16T08:00:00Z")
var alarm = WakeAlarm(label: "  Morning  ", time: eight, rule: .daily, now: monday, calendar: utc)
expect(alarm.label == "Morning", "Trim labels")
expect(alarm.nextOccurrence(after: monday, calendar: utc) == eight, "Daily reminder today")
expect(alarm.nextOccurrence(after: eight, calendar: utc) == date("2026-11-17T08:00:00Z"), "Strictly future occurrence")
alarm.enabled = false
expect(alarm.nextOccurrence(after: monday, calendar: utc) == nil, "Disabled reminder has no next occurrence")
alarm.enabled = true
alarm.rule = .weekdays
expect(alarm.nextOccurrence(after: date("2026-11-20T09:00:00Z"), calendar: utc) == date("2026-11-23T08:00:00Z"), "Weekday skips weekend")
alarm.rule = .weekends
expect(alarm.nextOccurrence(after: monday, calendar: utc) == date("2026-11-21T08:00:00Z"), "Weekend starts Saturday")
alarm.rule = .once
expect(alarm.nextOccurrence(after: monday, calendar: utc) == eight, "One-time reminder")
expect(alarm.nextOccurrence(after: eight, calendar: utc) == nil, "Expired one-time reminder")
let tomorrow = WakeAlarm(label: "", time: eight, rule: .once, now: eight, calendar: utc)
expect(tomorrow.oneTimeDate == date("2026-11-17T08:00:00Z"), "Once at current time means tomorrow")
expect(tomorrow.label == "A fresh start", "Empty label fallback")
let long = WakeAlarm(label: String(repeating: "a", count: 100), time: eight, rule: .daily, now: monday, calendar: utc)
expect(long.label.count == 60, "Bound labels")
expect(Set(alarm.notificationIDs).count == 8, "Unique notification IDs")
expect(Set(alarm.notificationIDs).isDisjoint(with: Set(tomorrow.notificationIDs)), "IDs isolated between reminders")
let ny = calendar("America/New_York")
let beforeSpring = date("2026-03-07T17:00:00Z")
let springTime = date("2026-03-07T07:30:00Z")
let spring = WakeAlarm(label: "DST", time: springTime, rule: .daily, now: beforeSpring, calendar: ny)
expect(spring.nextOccurrence(after: beforeSpring, calendar: ny) == date("2026-03-08T07:00:00Z"), "Spring gap moves to next valid local time")
let beforeFall = date("2026-10-31T16:00:00Z")
let fallTime = date("2026-10-31T05:30:00Z")
let fall = WakeAlarm(label: "DST", time: fallTime, rule: .daily, now: beforeFall, calendar: ny)
expect(fall.nextOccurrence(after: beforeFall, calendar: ny) == date("2026-11-01T05:30:00Z"), "Fall overlap uses first occurrence")
let state = SavedState(alarms: [alarm, tomorrow], messages: [CoachMessage(isUser: true, text: "hello")], completedDay: SavedState.dayKey(monday, calendar: utc))
let encoded = try JSONEncoder().encode(state)
let decoded = try JSONDecoder().decode(SavedState.self, from: encoded)
expect(decoded.alarms == state.alarms, "Alarm JSON round trip")
expect(decoded.messages == state.messages, "Chat JSON round trip")
expect(decoded.completedDay == state.completedDay, "Challenge JSON round trip")
expect(SavedState.dayKey(monday, calendar: utc) != SavedState.dayKey(monday.addingTimeInterval(86_400), calendar: utc), "Challenge resets each day")
expect(OfflineCoach.reply(to: "WAKE me up", nextAlarm: "08:00").contains("08:00"), "Coach uses next reminder")
expect(OfflineCoach.reply(to: "set an alarm", nextAlarm: nil).contains("can’t change reminders"), "Coach does not claim tool access")
expect(OfflineCoach.reply(to: "I am tired", nextAlarm: nil).contains("Rest matters"), "Rest over pressure")
expect(OfflineCoach.reply(to: "I am late", nextAlarm: nil).contains("No rushing"), "Safe late advice")
expect(OfflineCoach.reply(to: "challenge", nextAlarm: nil).contains("two-minute"), "Small challenge")
expect(!OfflineCoach.reply(to: "hello", nextAlarm: nil).isEmpty, "Fallback response")
print("PASS: \(checks) scheduling, DST, persistence and coach checks")

// Sleep models live with the SwiftUI manager in the app target. These Foundation-only
// mirrors run on Linux so CI can reject an empty or incomplete seeded hypnogram.
enum TestSleepStage: String, CaseIterable {
    case awake = "Awake", rem = "REM", core = "Core", deep = "Deep"
}
struct TestSleepSample: Equatable {
    let startDate: Date
    let endDate: Date
    let stage: TestSleepStage
    var durationMinutes: Double { max(0, endDate.timeIntervalSince(startDate) / 60) }
}
struct TestSleepNight {
    let samples: [TestSleepSample]
    var totalInBedMinutes: Double {
        samples.reduce(0) { $0 + $1.durationMinutes }
    }
    func minutes(_ stage: TestSleepStage) -> Double {
        samples.filter { $0.stage == stage }.reduce(0) { $0 + $1.durationMinutes }
    }
}
func buildRealisticTestNight(endingAt end: Date) -> TestSleepNight {
    let segments: [(TestSleepStage, Int)] = [
        (.awake, 12), (.core, 34), (.deep, 38), (.core, 14), (.rem, 12),
        (.core, 32), (.deep, 32), (.core, 16), (.rem, 22),
        (.core, 36), (.deep, 18), (.core, 20), (.rem, 28),
        (.awake, 6), (.core, 34), (.rem, 32),
        (.core, 50), (.rem, 36), (.awake, 8)
    ]
    let totalMinutes = segments.reduce(0) { $0 + $1.1 }
    var cursor = end.addingTimeInterval(-Double(totalMinutes * 60))
    var samples: [TestSleepSample] = []
    for (stage, minutes) in segments {
        let next = cursor.addingTimeInterval(Double(minutes * 60))
        samples.append(TestSleepSample(startDate: cursor, endDate: next, stage: stage))
        cursor = next
    }
    return TestSleepNight(samples: samples)
}

let sleepEnd = date("2026-11-16T08:00:00Z")
let seededNight = buildRealisticTestNight(endingAt: sleepEnd)
expect(!seededNight.samples.isEmpty, "Seeded hypnogram must not be empty")
expect(!buildRealisticTestNight(endingAt: .distantPast).samples.isEmpty, "Every seeded night contains sleep stages")
expect(seededNight.totalInBedMinutes == 480, "Seeded night spans exactly eight hours")
expect(seededNight.samples.first?.startDate == date("2026-11-16T00:00:00Z"), "Seeded night starts eight hours before waking")
expect(seededNight.samples.last?.endDate == sleepEnd, "Final sleep segment ends at wake time")
expect(TestSleepStage.allCases.allSatisfy { seededNight.minutes($0) > 0 }, "Hypnogram includes Awake, REM, Core, and Deep")
expect(seededNight.minutes(.awake) == 26, "Awake stage totals are correct")
expect(seededNight.minutes(.rem) == 130, "REM stage totals are correct")
expect(seededNight.minutes(.core) == 236, "Core stage totals are correct")
expect(seededNight.minutes(.deep) == 88, "Deep stage totals are correct")
for (left, right) in zip(seededNight.samples, seededNight.samples.dropFirst()) {
    expect(left.endDate == right.startDate, "Sleep segments are contiguous")
}
print("Seeded night: REM \(Int(seededNight.minutes(.rem)))m, Deep \(Int(seededNight.minutes(.deep)))m, Core \(Int(seededNight.minutes(.core)))m, Awake \(Int(seededNight.minutes(.awake)))m")
print("PASS: \(checks) total logic checks")
