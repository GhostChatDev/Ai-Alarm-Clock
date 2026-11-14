import Foundation

var checks = 0
func expect(_ condition: @autoclosure () -> Bool, _ description: String) {
    guard condition() else { fatalError("FAIL: \(description)") }
    checks += 1
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
