import Foundation

enum PracticeMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case quiz
    case daily
    case flash
    case journey
    case battle

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quiz: "一般自測"
        case .daily: "每日字陣"
        case .flash: "閃卡複習"
        case .journey: "故事試煉"
        case .battle: "大師對戰"
        }
    }
}

struct ScoreBucket: Codable, Equatable, Sendable {
    var right = 0
    var wrong = 0

    var total: Int { right + wrong }
    var accuracy: Double { total == 0 ? 0 : Double(right) / Double(total) }
}

struct CardProgress: Codable, Equatable, Sendable {
    var box = 1
    var dueDay = LearningClock.dayNumber()
    var seen = 0
    var right = 0
    var wrong = 0
    var streak = 0

    var stageTitle: String {
        switch box {
        case 1: "初識"
        case 2: "練習"
        case 3...4: "鞏固"
        default: "熟練"
        }
    }
}

struct SkillEvidence: Codable, Equatable, Sendable {
    var category: String?
    var objectiveRight = 0
    var objectiveWrong = 0
    var distinctDays: Set<String> = []
    var delayedPasses = 0
    var rationalePasses = 0
    var lastCorrectDay: String?

    var isMastered: Bool {
        objectiveRight >= 3 && distinctDays.count >= 2 && delayedPasses >= 1 && rationalePasses >= 1
    }

    init(
        category: String? = nil,
        objectiveRight: Int = 0,
        objectiveWrong: Int = 0,
        distinctDays: Set<String> = [],
        delayedPasses: Int = 0,
        rationalePasses: Int = 0,
        lastCorrectDay: String? = nil
    ) {
        self.category = category
        self.objectiveRight = objectiveRight
        self.objectiveWrong = objectiveWrong
        self.distinctDays = distinctDays
        self.delayedPasses = delayedPasses
        self.rationalePasses = rationalePasses
        self.lastCorrectDay = lastCorrectDay
    }

    private enum CodingKeys: String, CodingKey {
        case category, objectiveRight, objectiveWrong, distinctDays, delayedPasses, rationalePasses, lastCorrectDay
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        objectiveRight = try container.decodeIfPresent(Int.self, forKey: .objectiveRight) ?? 0
        objectiveWrong = try container.decodeIfPresent(Int.self, forKey: .objectiveWrong) ?? 0
        distinctDays = try container.decodeIfPresent(Set<String>.self, forKey: .distinctDays) ?? []
        delayedPasses = try container.decodeIfPresent(Int.self, forKey: .delayedPasses) ?? 0
        rationalePasses = try container.decodeIfPresent(Int.self, forKey: .rationalePasses) ?? 0
        lastCorrectDay = try container.decodeIfPresent(String.self, forKey: .lastCorrectDay)
    }
}

struct JourneyProgress: Codable, Equatable, Sendable {
    var currentChapter = 0
    var completed: [Int: Date] = [:]
    var read: [Int: Date] = [:]
    var pendingChapter: Int?
    var weeklyGoal = 3
}

struct BattleProgress: Codable, Equatable, Sendable {
    var beaten: [String: Int] = [:]
    var losses: [String: Int] = [:]
    var best: [String: Int] = [:]
}

struct DailyActivity: Codable, Equatable, Sendable {
    var flash = 0
    var quiz = 0
    var battle = 0
    var effective = 0

    var total: Int { flash + quiz + battle }
    var isComplete: Bool { effective >= 5 }
}

struct DailyChallengeResult: Codable, Equatable, Sendable {
    var attempts = 0
    var first: Int?
    var best = 0
    var total = 12
}

struct ClassroomSession: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let promptID: String
    let title: String
    let groups: Int
    let changed: Int
    let confidenceUp: Int
    let initialCounts: [String: Int]
    let revisedCounts: [String: Int]
    let evidenceCounts: [String: Int]
    let completedAt: Date
}

struct ActiveClassroomSession: Codable, Equatable, Sendable {
    let promptID: String
    var groups: Int
    var changed: Int
    var confidenceUp: Int
    var initialCounts: [String: Int]
    var revisedCounts: [String: Int]
    var evidenceCounts: [String: Int]
}

enum LearningClock {
    static let taipeiTimeZone = TimeZone(identifier: "Asia/Taipei")!

    static func dateKey(_ date: Date = .now) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = taipeiTimeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func dayNumber(_ date: Date = .now) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = taipeiTimeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let midnight = calendar.date(from: components) ?? date
        return Int(midnight.timeIntervalSince1970 / 86_400)
    }

    static func date(from key: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = taipeiTimeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: key)
    }
}

struct LearningProgress: Codable, Equatable, Sendable {
    var totalAttempts: Int
    var totalCorrect: Int
    var currentStreak: Int
    var bestStreak: Int
    var completedQuestionIDs: Set<String>
    var lastPlayedAt: Date?
    var cards: [String: CardProgress]
    var byCategory: [String: ScoreBucket]
    var byMode: [PracticeMode: ScoreBucket]
    var skillEvidence: [String: SkillEvidence]
    var journey: JourneyProgress
    var battle: BattleProgress
    var days: [String: DailyActivity]
    var dailyChallenges: [String: DailyChallengeResult]
    var quizSessions: Int
    var lastQuizScore: Int?
    var lastQuizTotal: Int?
    var badges: [String: Date]
    var classroomSessions: [ClassroomSession]
    var activeClassroom: ActiveClassroomSession?
    var evidenceWall: [String: Int]
    var onboardingStep: Int
    var schemaVersion: Int

    static let empty = LearningProgress(
        totalAttempts: 0,
        totalCorrect: 0,
        currentStreak: 0,
        bestStreak: 0,
        completedQuestionIDs: [],
        lastPlayedAt: nil,
        cards: [:],
        byCategory: [:],
        byMode: [:],
        skillEvidence: [:],
        journey: JourneyProgress(),
        battle: BattleProgress(),
        days: [:],
        dailyChallenges: [:],
        quizSessions: 0,
        lastQuizScore: nil,
        lastQuizTotal: nil,
        badges: [:],
        classroomSessions: [],
        activeClassroom: nil,
        evidenceWall: [:],
        onboardingStep: 0,
        schemaVersion: 2
    )

    var accuracy: Double {
        totalAttempts == 0 ? 0 : Double(totalCorrect) / Double(totalAttempts)
    }

    var masteredIDs: Set<String> {
        Set(skillEvidence.filter { $0.value.isMastered }.map(\.key))
    }

    var weakIDs: [String] {
        cards.filter { _, card in
            card.wrong > 0 && (Double(card.wrong) / Double(max(1, card.right + card.wrong)) >= 0.34 || card.box <= 2)
        }
        .sorted {
            let lhsRate = Double($0.value.wrong) / Double(max(1, $0.value.right + $0.value.wrong))
            let rhsRate = Double($1.value.wrong) / Double(max(1, $1.value.right + $1.value.wrong))
            return lhsRate == rhsRate ? $0.value.wrong > $1.value.wrong : lhsRate > rhsRate
        }
        .map(\.key)
    }

    func completedDaysThisWeek(now: Date = .now) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = LearningClock.taipeiTimeZone
        calendar.firstWeekday = 2
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: now) else { return 0 }
        return days.filter { key, activity in
            guard activity.isComplete, let date = LearningClock.date(from: key) else { return false }
            return interval.contains(date)
        }.count
    }

    func dueIDs(from ids: [String], now: Date = .now) -> [String] {
        let today = LearningClock.dayNumber(now)
        return ids.filter { id in
            guard let card = cards[id] else { return false }
            return card.seen > 0 && card.dueDay <= today
        }
    }

    mutating func record(
        _ feedback: AnswerFeedback,
        mode: PracticeMode = .quiz,
        rationale: Bool = false,
        now: Date = .now
    ) {
        totalAttempts += 1
        completedQuestionIDs.insert(feedback.questionID)
        lastPlayedAt = now

        var category = byCategory[feedback.correctMethod.rawValue, default: ScoreBucket()]
        var modeScore = byMode[mode, default: ScoreBucket()]
        var card = cards[feedback.questionID, default: CardProgress()]
        var evidence = skillEvidence[feedback.questionID, default: SkillEvidence()]
        evidence.category = feedback.correctMethod.rawValue
        card.seen += 1

        if feedback.isCorrect {
            totalCorrect += 1
            currentStreak += 1
            bestStreak = max(bestStreak, currentStreak)
            category.right += 1
            modeScore.right += 1
            card.right += 1
            card.streak += 1
            if card.streak >= 2 && card.box < 5 { card.box += 1 }
            card.dueDay = LearningClock.dayNumber(now) + [0, 0, 1, 2, 4, 8][card.box]
            evidence.objectiveRight += 1
            let day = LearningClock.dateKey(now)
            if let last = evidence.lastCorrectDay, last != day { evidence.delayedPasses += 1 }
            evidence.distinctDays.insert(day)
            evidence.lastCorrectDay = day
            if rationale { evidence.rationalePasses += 1 }
        } else {
            currentStreak = 0
            category.wrong += 1
            modeScore.wrong += 1
            card.wrong += 1
            card.streak = 0
            card.box = 1
            card.dueDay = LearningClock.dayNumber(now)
            evidence.objectiveWrong += 1
        }

        cards[feedback.questionID] = card
        byCategory[feedback.correctMethod.rawValue] = category
        byMode[mode] = modeScore
        skillEvidence[feedback.questionID] = evidence
        noteActivity(mode: mode, effective: feedback.isCorrect ? 1 : 0, now: now)
        evaluateBadges()
    }

    mutating func recordRationale(questionID: String, method: CreationMethod, correct: Bool, now: Date = .now) {
        var evidence = skillEvidence[questionID, default: SkillEvidence()]
        evidence.category = method.rawValue
        if correct { evidence.rationalePasses += 1 }
        skillEvidence[questionID] = evidence
        evaluateBadges(now: now)
    }

    mutating func gradeCard(id: String, grade: Int, now: Date = .now) {
        var card = cards[id, default: CardProgress()]
        card.seen += 1
        switch grade {
        case 0:
            card.box = 1
            card.streak = 0
            card.wrong += 1
            card.dueDay = LearningClock.dayNumber(now)
        case 1:
            card.streak = 0
            card.wrong += 1
            card.dueDay = LearningClock.dayNumber(now) + 1
        default:
            card.box = min(5, card.box + 1)
            card.streak += 1
            card.right += 1
            card.dueDay = LearningClock.dayNumber(now) + [0, 0, 1, 2, 4, 8][card.box]
        }
        cards[id] = card
        noteActivity(mode: .flash, effective: 0, now: now)
    }

    mutating func noteActivity(mode: PracticeMode, effective: Int, now: Date = .now) {
        let key = LearningClock.dateKey(now)
        var day = days[key, default: DailyActivity()]
        switch mode {
        case .flash: day.flash += 1
        case .battle: day.battle += 1
        default: day.quiz += 1
        }
        day.effective += max(0, effective)
        days[key] = day
    }

    mutating func recordBattle(masterID: String, win: Bool, score: Int) {
        if win { battle.beaten[masterID, default: 0] += 1 }
        else { battle.losses[masterID, default: 0] += 1 }
        battle.best[masterID] = max(battle.best[masterID, default: 0], score)
        evaluateBadges()
    }

    mutating func completeJourney(chapter: Int, score: Int, total: Int, now: Date = .now) -> Bool {
        let passed = score >= Int(ceil(Double(total) * 2 / 3))
        if passed {
            journey.completed[chapter] = now
            journey.currentChapter = min(7, max(journey.currentChapter, chapter + 1))
            journey.pendingChapter = nil
        } else if journey.completed[chapter] == nil {
            journey.pendingChapter = chapter
        }
        return passed
    }

    mutating func recordDaily(score: Int, total: Int, now: Date = .now) {
        let key = LearningClock.dateKey(now)
        var result = dailyChallenges[key, default: DailyChallengeResult()]
        result.attempts += 1
        result.first = result.first ?? score
        result.best = max(result.best, score)
        result.total = total
        dailyChallenges[key] = result
    }

    mutating func recordQuizSession(score: Int, total: Int, now: Date = .now) {
        quizSessions += 1
        lastQuizScore = score
        lastQuizTotal = total
        evaluateBadges(now: now)
    }

    mutating func addClassroomSession(_ session: ClassroomSession) {
        classroomSessions.append(session)
        classroomSessions = Array(classroomSessions.suffix(20))
        for (label, count) in session.evidenceCounts {
            evidenceWall[label, default: 0] += count
        }
    }

    mutating func evaluateBadges(now: Date = .now) {
        if quizSessions > 0 { badges["first-quiz"] = badges["first-quiz"] ?? now }
        if lastQuizTotal == 10, lastQuizScore == 10 { badges["perfect-ten"] = badges["perfect-ten"] ?? now }
        for method in CreationMethod.allCases {
            let count = skillEvidence.filter { id, evidence in
                evidence.category == method.rawValue && evidence.isMastered && completedQuestionIDs.contains(id)
            }.count
            if count >= 5 { badges["cat-\(method.rawValue)"] = badges["cat-\(method.rawValue)"] ?? now }
        }
        for (master, wins) in battle.beaten where wins > 0 {
            badges["master-\(master)"] = badges["master-\(master)"] ?? now
        }
        if masteredIDs.count >= 220 { badges["all-chars"] = badges["all-chars"] ?? now }
    }

    private enum CodingKeys: String, CodingKey {
        case totalAttempts, totalCorrect, currentStreak, bestStreak, completedQuestionIDs, lastPlayedAt
        case cards, byCategory, byMode, skillEvidence, journey, battle, days, dailyChallenges
        case quizSessions, lastQuizScore, lastQuizTotal
        case badges, classroomSessions, activeClassroom, evidenceWall, onboardingStep, schemaVersion
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalAttempts = try container.decodeIfPresent(Int.self, forKey: .totalAttempts) ?? 0
        totalCorrect = try container.decodeIfPresent(Int.self, forKey: .totalCorrect) ?? 0
        currentStreak = try container.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 0
        bestStreak = try container.decodeIfPresent(Int.self, forKey: .bestStreak) ?? 0
        completedQuestionIDs = try container.decodeIfPresent(Set<String>.self, forKey: .completedQuestionIDs) ?? []
        lastPlayedAt = try container.decodeIfPresent(Date.self, forKey: .lastPlayedAt)
        cards = try container.decodeIfPresent([String: CardProgress].self, forKey: .cards) ?? [:]
        byCategory = try container.decodeIfPresent([String: ScoreBucket].self, forKey: .byCategory) ?? [:]
        byMode = try container.decodeIfPresent([PracticeMode: ScoreBucket].self, forKey: .byMode) ?? [:]
        skillEvidence = try container.decodeIfPresent([String: SkillEvidence].self, forKey: .skillEvidence) ?? [:]
        journey = try container.decodeIfPresent(JourneyProgress.self, forKey: .journey) ?? JourneyProgress()
        battle = try container.decodeIfPresent(BattleProgress.self, forKey: .battle) ?? BattleProgress()
        days = try container.decodeIfPresent([String: DailyActivity].self, forKey: .days) ?? [:]
        dailyChallenges = try container.decodeIfPresent([String: DailyChallengeResult].self, forKey: .dailyChallenges) ?? [:]
        quizSessions = try container.decodeIfPresent(Int.self, forKey: .quizSessions) ?? 0
        lastQuizScore = try container.decodeIfPresent(Int.self, forKey: .lastQuizScore)
        lastQuizTotal = try container.decodeIfPresent(Int.self, forKey: .lastQuizTotal)
        badges = try container.decodeIfPresent([String: Date].self, forKey: .badges) ?? [:]
        classroomSessions = try container.decodeIfPresent([ClassroomSession].self, forKey: .classroomSessions) ?? []
        activeClassroom = try container.decodeIfPresent(ActiveClassroomSession.self, forKey: .activeClassroom)
        evidenceWall = try container.decodeIfPresent([String: Int].self, forKey: .evidenceWall) ?? [:]
        onboardingStep = try container.decodeIfPresent(Int.self, forKey: .onboardingStep) ?? 0
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
    }

    init(
        totalAttempts: Int,
        totalCorrect: Int,
        currentStreak: Int,
        bestStreak: Int,
        completedQuestionIDs: Set<String>,
        lastPlayedAt: Date?,
        cards: [String: CardProgress],
        byCategory: [String: ScoreBucket],
        byMode: [PracticeMode: ScoreBucket],
        skillEvidence: [String: SkillEvidence],
        journey: JourneyProgress,
        battle: BattleProgress,
        days: [String: DailyActivity],
        dailyChallenges: [String: DailyChallengeResult],
        quizSessions: Int,
        lastQuizScore: Int?,
        lastQuizTotal: Int?,
        badges: [String: Date],
        classroomSessions: [ClassroomSession],
        activeClassroom: ActiveClassroomSession?,
        evidenceWall: [String: Int],
        onboardingStep: Int,
        schemaVersion: Int
    ) {
        self.totalAttempts = totalAttempts
        self.totalCorrect = totalCorrect
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.completedQuestionIDs = completedQuestionIDs
        self.lastPlayedAt = lastPlayedAt
        self.cards = cards
        self.byCategory = byCategory
        self.byMode = byMode
        self.skillEvidence = skillEvidence
        self.journey = journey
        self.battle = battle
        self.days = days
        self.dailyChallenges = dailyChallenges
        self.quizSessions = quizSessions
        self.lastQuizScore = lastQuizScore
        self.lastQuizTotal = lastQuizTotal
        self.badges = badges
        self.classroomSessions = classroomSessions
        self.activeClassroom = activeClassroom
        self.evidenceWall = evidenceWall
        self.onboardingStep = onboardingStep
        self.schemaVersion = schemaVersion
    }
}
