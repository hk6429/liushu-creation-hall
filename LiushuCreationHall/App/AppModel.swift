import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var questions: [CharacterQuestion] = []
    @Published private(set) var characters: [CharacterEntry] = []
    @Published private(set) var learningLibrary: LearningLibrary?
    @Published private(set) var progress: LearningProgress = .empty
    @Published private(set) var loadError: String?

    private let progressStore: ProgressStoring

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
        persistProgress()
    }

    func resetProgress() {
        progress = .empty
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
