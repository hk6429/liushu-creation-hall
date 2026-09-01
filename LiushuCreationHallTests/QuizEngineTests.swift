import XCTest
@testable import LiushuCreationHall

final class QuizEngineTests: XCTestCase {
    func testCorrectAnswerProducesCorrectFeedback() {
        let question = CharacterQuestion(
            id: "test-sun",
            display: "日",
            prompt: "這個字屬於哪一類？",
            correctMethod: .pictograph,
            clue: "像圖畫",
            explanation: "日像太陽。"
        )

        let feedback = QuizEngine.evaluate(question: question, answer: .pictograph)

        XCTAssertTrue(feedback.isCorrect)
        XCTAssertEqual(feedback.correctMethod, .pictograph)
    }

    func testWrongAnswerResetsCurrentStreakButKeepsBestStreak() {
        var progress = LearningProgress.empty
        let correct = AnswerFeedback(
            questionID: "1",
            selectedMethod: .pictograph,
            correctMethod: .pictograph,
            explanation: ""
        )
        let wrong = AnswerFeedback(
            questionID: "2",
            selectedMethod: .indicative,
            correctMethod: .associative,
            explanation: ""
        )

        progress.record(correct)
        progress.record(correct)
        progress.record(wrong)

        XCTAssertEqual(progress.totalAttempts, 3)
        XCTAssertEqual(progress.totalCorrect, 2)
        XCTAssertEqual(progress.currentStreak, 0)
        XCTAssertEqual(progress.bestStreak, 2)
    }

    func testFileProgressStoreRestoresSavedProgress() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("progress.json")
        let store = FileProgressStore(fileURL: fileURL)
        var progress = LearningProgress.empty
        progress.record(
            AnswerFeedback(
                questionID: "saved-question",
                selectedMethod: .associative,
                correctMethod: .associative,
                explanation: ""
            )
        )

        try store.save(progress)
        let restored = try store.load()

        XCTAssertEqual(restored.totalAttempts, 1)
        XCTAssertEqual(restored.completedQuestionIDs, ["saved-question"])
    }
}
