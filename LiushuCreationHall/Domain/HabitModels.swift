import Foundation

enum StudyAnchor: Codable, Equatable, Sendable {
    case afterSchool
    case afterDinner
    case beforeBath
    case custom(String)

    var title: String {
        switch self {
        case .afterSchool: "放學後"
        case .afterDinner: "晚餐後"
        case .beforeBath: "洗澡前"
        case let .custom(label): label.isEmpty ? "自訂時段" : label
        }
    }
}

enum SealKind: String, Codable, Equatable, Sendable {
    case normal
    case recoveryOne
    case recoveryThree

    var targetCount: Int {
        switch self {
        case .normal: 5
        case .recoveryOne: 1
        case .recoveryThree: 3
        }
    }

    var title: String {
        switch self {
        case .normal: "今日一印"
        case .recoveryOne: "重新落筆"
        case .recoveryThree: "三字暖身"
        }
    }
}

struct DailySealRecord: Codable, Equatable, Sendable {
    var dateKey: String
    var plannedCharacterIDs: [String]
    var attemptedCharacterIDs: [String]
    var correctCharacterIDs: [String]
    var kind: SealKind
    var startedAt: Date
    var completedAt: Date? = nil
    var closedAt: Date? = nil

    var targetCount: Int { min(kind.targetCount, plannedCharacterIDs.count) }
    var attemptedCount: Int { Set(attemptedCharacterIDs).intersection(plannedCharacterIDs).count }
    var correctCount: Int { Set(correctCharacterIDs).intersection(plannedCharacterIDs).count }
    var isComplete: Bool { completedAt != nil }
    var nextCharacterID: String? {
        let attempted = Set(attemptedCharacterIDs)
        return plannedCharacterIDs.first { !attempted.contains($0) }
    }
}

struct SevenDayProgress: Codable, Equatable, Sendable {
    var completedStages: Set<Int> = []
    var completedAt: [Int: Date] = [:]

    var nextStage: Int? {
        (1...7).first { !completedStages.contains($0) }
    }

    mutating func completeNext(at date: Date, dateKey: String) {
        guard let stage = nextStage else { return }
        let alreadyAdvancedToday = completedAt.values.contains { LearningClock.dateKey($0) == dateKey }
        guard !alreadyAdvancedToday else { return }
        completedStages.insert(stage)
        completedAt[stage] = date
    }
}

struct UsageClockState: Codable, Equatable, Sendable {
    static let warningSeconds: TimeInterval = 15 * 60
    static let stopSeconds: TimeInterval = 20 * 60

    var dateKey = LearningClock.dateKey()
    var foregroundSeconds: TimeInterval = 0
    var didShowWarning = false
    var didReachStop = false

    var hasReachedWarning: Bool { foregroundSeconds >= Self.warningSeconds }
    var hasReachedStop: Bool { foregroundSeconds >= Self.stopSeconds || didReachStop }

    mutating func rollOverIfNeeded(now: Date) {
        let currentKey = LearningClock.dateKey(now)
        guard currentKey != dateKey else { return }
        self = UsageClockState(dateKey: currentKey)
    }

    mutating func addForegroundTime(_ seconds: TimeInterval, now: Date) {
        rollOverIfNeeded(now: now)
        foregroundSeconds = min(Self.stopSeconds, foregroundSeconds + max(0, seconds))
        if hasReachedWarning { didShowWarning = true }
        if foregroundSeconds >= Self.stopSeconds { didReachStop = true }
    }
}

struct HabitProgress: Codable, Equatable, Sendable {
    var anchor: StudyAnchor?
    var preferredCategory: CreationMethod?
    var dailyRecords: [String: DailySealRecord]
    var sevenDay: SevenDayProgress
    var usageClock: UsageClockState

    init(
        anchor: StudyAnchor? = nil,
        preferredCategory: CreationMethod? = nil,
        dailyRecords: [String: DailySealRecord] = [:],
        sevenDay: SevenDayProgress = SevenDayProgress(),
        usageClock: UsageClockState = UsageClockState()
    ) {
        self.anchor = anchor
        self.preferredCategory = preferredCategory
        self.dailyRecords = dailyRecords
        self.sevenDay = sevenDay
        self.usageClock = usageClock
    }

    var completedRecords: [DailySealRecord] {
        dailyRecords.values.filter(\.isComplete)
    }

    func lastCompletedDate(before now: Date = .now) -> Date? {
        completedRecords.compactMap(\.completedAt).filter { $0 < now }.max()
    }

    func missedDayCount(now: Date = .now) -> Int {
        guard let last = lastCompletedDate(before: now) else { return 0 }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = LearningClock.taipeiTimeZone
        let lastStart = calendar.startOfDay(for: last)
        let todayStart = calendar.startOfDay(for: now)
        let distance = calendar.dateComponents([.day], from: lastStart, to: todayStart).day ?? 0
        return max(0, distance - 1)
    }

    func sealKind(now: Date = .now) -> SealKind {
        switch missedDayCount(now: now) {
        case 7...: .recoveryThree
        case 3...6: .recoveryOne
        default: .normal
        }
    }

    func completedDaysThisWeek(now: Date = .now) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = LearningClock.taipeiTimeZone
        calendar.firstWeekday = 2
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: now) else { return 0 }
        return Set(completedRecords.compactMap { record -> String? in
            guard let date = LearningClock.date(from: record.dateKey), interval.contains(date) else { return nil }
            return record.dateKey
        }).count
    }
}

struct DailySealPlan: Equatable, Sendable {
    let dateKey: String
    let kind: SealKind
    let characterIDs: [String]
}

enum DailySealPlanner {
    static func makePlan(
        characters: [CharacterEntry],
        progress: LearningProgress,
        now: Date = .now
    ) -> DailySealPlan {
        let dateKey = LearningClock.dateKey(now)
        let kind = progress.habit.sealKind(now: now)
        let target = kind.targetCount
        let eligible = characters.filter { !$0.disputed && $0.method != nil }
        let byID = Dictionary(uniqueKeysWithValues: eligible.map { ($0.id, $0) })
        let stableEligible = eligible.sorted { stableRank(dateKey, $0.id) < stableRank(dateKey, $1.id) }
        var selected: [String] = []

        func append(_ ids: [String]) {
            for id in ids where selected.count < target && byID[id] != nil && !selected.contains(id) {
                selected.append(id)
            }
        }

        if kind == .recoveryOne {
            let familiar = stableEligible.filter { (progress.cards[$0.id]?.right ?? 0) > 0 }.map(\.id)
            append(familiar)
        } else if kind == .recoveryThree {
            let familiar = stableEligible.filter { (progress.cards[$0.id]?.right ?? 0) > 0 }.map(\.id)
            append(Array(familiar.prefix(1)))
            append(Array(progress.weakIDs.prefix(1)))
            if let preferred = progress.habit.preferredCategory {
                append(stableEligible.filter { $0.method == preferred }.map(\.id))
            }
        } else {
            if progress.habit.sevenDay.nextStage == 2 {
                append(Array(yesterdayForeshadowIDs(progress: progress, now: now).prefix(1)))
                append(Array(stableEligible.filter { (progress.cards[$0.id]?.seen ?? 0) == 0 }.prefix(2).map(\.id)))
            } else {
                append(yesterdayForeshadowIDs(progress: progress, now: now))
            }
            append(Array(progress.dueIDs(from: stableEligible.map(\.id), now: now).prefix(2)))
            append(Array(progress.weakIDs.prefix(2)))
            if let preferred = progress.habit.preferredCategory {
                append(Array(stableEligible.filter { $0.method == preferred && (progress.cards[$0.id]?.seen ?? 0) == 0 }.prefix(1).map(\.id)))
            }
        }

        let selectedCategories = Set(selected.compactMap { byID[$0]?.category })
        let balanced = CreationMethod.allCases
            .filter { !selectedCategories.contains($0.rawValue) }
            .compactMap { method in stableEligible.first { $0.method == method }?.id }
        append(balanced)
        if kind == .normal {
            append(stableEligible.filter { (progress.cards[$0.id]?.seen ?? 0) == 0 }.map(\.id))
        }
        append(stableEligible.map(\.id))

        return DailySealPlan(dateKey: dateKey, kind: kind, characterIDs: Array(selected.prefix(target)))
    }

    private static func yesterdayForeshadowIDs(progress: LearningProgress, now: Date) -> [String] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = LearningClock.taipeiTimeZone
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
              let record = progress.habit.dailyRecords[LearningClock.dateKey(yesterday)] else { return [] }
        let wrong = record.attemptedCharacterIDs.filter { !record.correctCharacterIDs.contains($0) }
        return wrong.isEmpty ? Array(record.plannedCharacterIDs.suffix(1)) : wrong
    }

    private static func stableRank(_ dateKey: String, _ id: String) -> UInt64 {
        "\(dateKey)|\(id)".utf8.reduce(14_695_981_039_346_656_037) { value, byte in
            (value ^ UInt64(byte)) &* 1_099_511_628_211
        }
    }
}
