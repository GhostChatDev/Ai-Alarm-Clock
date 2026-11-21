import SwiftUI
import CoreMotion
#if canImport(HealthKit)
import HealthKit
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
            (.awake, 12), (.core, 28), (.deep, 38), (.core, 14), (.rem, 12),
            (.core, 26), (.deep, 32), (.core, 16), (.rem, 22),
            (.core, 30), (.deep, 18), (.core, 20), (.rem, 28),
            (.awake, 6),  (.core, 34), (.rem, 32),
            (.core, 42), (.rem, 36), (.awake, 8)
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
