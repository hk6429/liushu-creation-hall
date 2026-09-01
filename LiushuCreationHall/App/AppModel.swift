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
            progress = try progressStore.load()
        } catch {
            loadError = "內容載入失敗，請重新開啟 App。"
        }
    }

    func startNewQuiz() {
        questions = QuizSessionFactory.makeQuestions(from: characters)
    }

    func record(_ feedback: AnswerFeedback) {
        progress.record(feedback)
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
