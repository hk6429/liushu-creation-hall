import Foundation

@MainActor
final class AppModel: ObservableObject {
    enum UsageNotice: Identifiable, Equatable {
        case warning
        case stop

        var id: String { self == .warning ? "warning" : "stop" }
    }

    @Published private(set) var questions: [CharacterQuestion] = []
    @Published private(set) var characters: [CharacterEntry] = []
    @Published private(set) var learningLibrary: LearningLibrary?
    @Published private(set) var progress: LearningProgress = .empty
    @Published private(set) var loadError: String?
    @Published private(set) var activeSealDateKey: String?
    @Published var usageNotice: UsageNotice?

    private let progressStore: ProgressStoring
    private var foregroundCheckpoint: Date?
    private var lastClockSaveSecond = 0

    init(
        progressStore: ProgressStoring = FileProgressStore(),
        contentLoader: WebContentLoading = BundleWebContentLoader()
    ) {
        self.progressStore = progressStore

        do {
            characters = try contentLoader.loadCharacters()
            learningLibrary = try contentLoader.loadLearningLibrary()
            questions = QuizSessionFactory.makeQuestions(from: characters)
        } catch {
            loadError = "內容載入失敗，請重新開啟 App。"
            return
        }

        do {
            progress = try progressStore.load()
            progress.schemaVersion = 3
            if CommandLine.arguments.contains("-ui-test-reset") {
                progress = .empty
                try? progressStore.save(progress)
            }
        } catch {
            progress = .empty
            loadError = "舊進度無法讀取，教材內容仍可正常使用。請從「紀錄」匯入備份或重新開始。"
        }
    }

    func startNewQuiz() {
        let weakCharacters = progress.weakIDs.compactMap { id in characters.first(where: { $0.id == id })?.char }
        questions = weakCharacters.isEmpty
            ? QuizSessionFactory.makeQuestions(from: characters)
            : QuizSessionFactory.makeQuestions(from: characters, preferredCharacters: weakCharacters, count: 10)
    }

    var activeSealRecord: DailySealRecord? {
        guard let activeSealDateKey else { return nil }
        return progress.habit.dailyRecords[activeSealDateKey]
    }

    var todaySealRecord: DailySealRecord? {
        progress.habit.dailyRecords[LearningClock.dateKey()]
    }

    var weeklySealCount: Int {
        progress.habit.completedDaysThisWeek()
    }

    var canStartNewTask: Bool {
        !progress.habit.usageClock.hasReachedStop
    }

    @discardableResult
    func prepareDailySeal(now: Date = .now) -> DailySealRecord? {
        progress.habit.usageClock.rollOverIfNeeded(now: now)
        let today = LearningClock.dateKey(now)
        if let existing = progress.habit.dailyRecords[today] {
            activeSealDateKey = today
            return existing
        }

        if let unfinished = resumableSeal(now: now) {
            activeSealDateKey = unfinished.dateKey
            return unfinished
        }

        guard canStartNewTask else { return nil }
        let plan = DailySealPlanner.makePlan(characters: characters, progress: progress, now: now)
        guard plan.characterIDs.count == plan.kind.targetCount else {
            loadError = "目前沒有足夠的可用字例，請稍後再試。"
            return nil
        }
        let record = DailySealRecord(
            dateKey: plan.dateKey,
            plannedCharacterIDs: plan.characterIDs,
            attemptedCharacterIDs: [],
            correctCharacterIDs: [],
            kind: plan.kind,
            startedAt: now,
            completedAt: nil,
            closedAt: nil
        )
        progress.habit.dailyRecords[plan.dateKey] = record
        activeSealDateKey = plan.dateKey
        persistProgress()
        return record
    }

    func activeSealQuestions() -> [CharacterQuestion] {
        guard let record = activeSealRecord else { return [] }
        let byID = Dictionary(uniqueKeysWithValues: characters.map { ($0.id, $0) })
        return record.plannedCharacterIDs.compactMap { id in
            byID[id].flatMap(QuizSessionFactory.makeQuestion)
        }
    }

    @discardableResult
    func submitDailySealAnswer(
        question: CharacterQuestion,
        answer: CreationMethod,
        now: Date = .now
    ) -> AnswerFeedback? {
        guard let key = activeSealDateKey,
              var record = progress.habit.dailyRecords[key],
              record.plannedCharacterIDs.contains(question.id),
              !record.attemptedCharacterIDs.contains(question.id) else { return nil }

        let feedback = QuizEngine.evaluate(question: question, answer: answer)
        progress.record(feedback, mode: .daily, rationale: false, now: now)
        record.attemptedCharacterIDs.append(question.id)
        if feedback.isCorrect { record.correctCharacterIDs.append(question.id) }

        if progress.habit.sevenDay.completedStages.isEmpty, progress.habit.anchor != nil {
            progress.habit.sevenDay.completeNext(at: now, dateKey: record.dateKey)
        }
        if record.attemptedCount >= record.targetCount {
            record.completedAt = record.completedAt ?? now
            progress.habit.sevenDay.completeNext(at: now, dateKey: record.dateKey)
        }
        progress.habit.dailyRecords[key] = record
        persistProgress()
        return feedback
    }

    func closeActiveSeal(now: Date = .now) {
        guard let key = activeSealDateKey, var record = progress.habit.dailyRecords[key] else { return }
        record.closedAt = now
        progress.habit.dailyRecords[key] = record
        persistProgress()
    }

    func setStudyAnchor(_ anchor: StudyAnchor) {
        progress.habit.anchor = anchor
        persistProgress()
    }

    func setPreferredCategory(_ method: CreationMethod) {
        progress.habit.preferredCategory = method
        persistProgress()
    }

    func beginForegroundUsage(now: Date = .now) {
        progress.habit.usageClock.rollOverIfNeeded(now: now)
        foregroundCheckpoint = now
    }

    func updateForegroundUsage(now: Date = .now) {
        guard let checkpoint = foregroundCheckpoint else {
            foregroundCheckpoint = now
            return
        }
        let elapsed = max(0, now.timeIntervalSince(checkpoint))
        foregroundCheckpoint = now
        let wasWarning = progress.habit.usageClock.hasReachedWarning
        let wasStopped = progress.habit.usageClock.hasReachedStop
        progress.habit.usageClock.addForegroundTime(elapsed, now: now)
        if !wasWarning, progress.habit.usageClock.hasReachedWarning { usageNotice = .warning }
        if !wasStopped, progress.habit.usageClock.hasReachedStop { usageNotice = .stop }

        let currentSecond = Int(progress.habit.usageClock.foregroundSeconds)
        if currentSecond / 30 > lastClockSaveSecond / 30 || usageNotice != nil {
            lastClockSaveSecond = currentSecond
            persistProgress()
        }
    }

    func endForegroundUsage(now: Date = .now) {
        updateForegroundUsage(now: now)
        foregroundCheckpoint = nil
        persistProgress()
    }

    func dismissUsageNotice() {
        usageNotice = nil
    }

    func record(
        _ feedback: AnswerFeedback,
        mode: PracticeMode = .quiz,
        rationale: Bool = false
    ) {
        progress.record(feedback, mode: mode, rationale: rationale)
        if mode == .quiz, progress.onboardingStep == 2 { progress.onboardingStep = 3 }
        persistProgress()
    }

    func gradeCard(id: String, grade: Int) {
        progress.gradeCard(id: id, grade: grade)
        if progress.onboardingStep == 1 { progress.onboardingStep = 2 }
        persistProgress()
    }

    func recordRationale(questionID: String, method: CreationMethod, correct: Bool) {
        progress.recordRationale(questionID: questionID, method: method, correct: correct)
        persistProgress()
    }

    func flashDeck(level: String? = nil, focusIDs: [String] = []) -> [CharacterEntry] {
        let pool = characters.filter { level == nil || $0.level == level }
        let allowed = Set(pool.map(\.id))
        let focus = focusIDs.filter { allowed.contains($0) }
        let weak = progress.weakIDs.filter { allowed.contains($0) && !focus.contains($0) }
        let due = progress.dueIDs(from: pool.map(\.id)).filter { !focus.contains($0) && !weak.contains($0) }
        let fresh = pool.map(\.id).filter { progress.cards[$0]?.seen ?? 0 == 0 }
        let reviewLimit = focus.isEmpty ? 16 : 20
        var ids = Array((focus + Array(weak.prefix(10)) + due).prefix(reviewLimit))
        for id in fresh.shuffled().prefix(max(0, 20 - ids.count)) where !ids.contains(id) {
            ids.append(id)
        }
        if ids.isEmpty { ids = Array(pool.shuffled().prefix(20).map(\.id)) }
        let byID = Dictionary(uniqueKeysWithValues: pool.map { ($0.id, $0) })
        return ids.compactMap { byID[$0] }
    }

    @discardableResult
    func completeJourney(chapter: Int, score: Int, total: Int) -> Bool {
        let passed = progress.completeJourney(chapter: chapter, score: score, total: total)
        persistProgress()
        return passed
    }

    func markChapterRead(_ chapter: Int) {
        progress.journey.read[chapter] = .now
        persistProgress()
    }

    func recordDaily(score: Int, total: Int) {
        progress.recordDaily(score: score, total: total)
        persistProgress()
    }

    func recordQuizSession(score: Int, total: Int) {
        progress.recordQuizSession(score: score, total: total)
        persistProgress()
    }

    func recordBattle(masterID: String, win: Bool, score: Int) {
        progress.recordBattle(masterID: masterID, win: win, score: score)
        persistProgress()
    }

    func addClassroomSession(_ session: ClassroomSession) {
        progress.addClassroomSession(session)
        progress.activeClassroom = nil
        persistProgress()
    }

    func saveActiveClassroom(_ session: ActiveClassroomSession) {
        progress.activeClassroom = session
        persistProgress()
    }

    func clearEvidenceWall() {
        progress.evidenceWall = [:]
        persistProgress()
    }

    func advanceOnboarding() {
        progress.onboardingStep = min(3, progress.onboardingStep + 1)
        persistProgress()
    }

    func skipOnboarding() {
        progress.onboardingStep = 3
        persistProgress()
    }

    func exportProgress() throws -> Data {
        try WebProgressBridge.export(progress)
    }

    func importProgress(from data: Data) throws {
        guard data.count <= 2_000_000 else { throw ProgressImportError.fileTooLarge }
        var imported: LearningProgress
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let native = try? decoder.decode(LearningProgress.self, from: data),
           !native.cards.isEmpty || data.range(of: Data("\"totalAttempts\"".utf8)) != nil {
            imported = native
        } else {
            imported = try WebProgressBridge.importWebBackup(data)
        }
        guard imported.totalAttempts >= 0, imported.totalCorrect >= 0,
              imported.totalCorrect <= imported.totalAttempts else {
            throw ProgressImportError.invalidData
        }
        let categories = Dictionary(uniqueKeysWithValues: characters.map { ($0.id, $0.category) })
        for id in imported.skillEvidence.keys where imported.skillEvidence[id]?.category == nil {
            imported.skillEvidence[id]?.category = categories[id]
        }
        progress = imported
        progress.schemaVersion = 3
        persistProgress()
    }

    func resetProgress() {
        progress = .empty
        activeSealDateKey = nil
        persistProgress()
    }

    func dismissError() {
        loadError = nil
    }

    private func persistProgress() {
        do {
            try progressStore.save(progress)
        } catch {
            loadError = "學習進度暫時無法儲存。"
        }
    }

    private func resumableSeal(now: Date) -> DailySealRecord? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = LearningClock.taipeiTimeZone
        return progress.habit.dailyRecords.values
            .filter { record in
                guard !record.isComplete, record.nextCharacterID != nil,
                      let date = LearningClock.date(from: record.dateKey) else { return false }
                let distance = calendar.dateComponents(
                    [.day],
                    from: calendar.startOfDay(for: date),
                    to: calendar.startOfDay(for: now)
                ).day ?? 99
                return (0...1).contains(distance)
            }
            .max { $0.startedAt < $1.startedAt }
    }
}

enum ProgressImportError: LocalizedError {
    case fileTooLarge
    case invalidData

    var errorDescription: String? {
        switch self {
        case .fileTooLarge: "備份檔超過 2 MB。"
        case .invalidData: "備份內容不符合六書造字堂格式。"
        }
    }
}
