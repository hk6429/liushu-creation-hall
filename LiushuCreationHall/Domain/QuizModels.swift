import Foundation

struct CharacterQuestion: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let display: String
    let prompt: String
    let correctMethod: CreationMethod
    let clue: String
    let explanation: String
}

struct AnswerFeedback: Equatable, Sendable {
    let questionID: String
    let selectedMethod: CreationMethod
    let correctMethod: CreationMethod
    let explanation: String

    var isCorrect: Bool { selectedMethod == correctMethod }
}

enum QuizEngine {
    static func evaluate(
        question: CharacterQuestion,
        answer: CreationMethod
    ) -> AnswerFeedback {
        AnswerFeedback(
            questionID: question.id,
            selectedMethod: answer,
            correctMethod: question.correctMethod,
            explanation: question.explanation
        )
    }
}

struct LearningProgress: Codable, Equatable, Sendable {
    var totalAttempts: Int
    var totalCorrect: Int
    var currentStreak: Int
    var bestStreak: Int
    var completedQuestionIDs: Set<String>
    var lastPlayedAt: Date?

    static let empty = LearningProgress(
        totalAttempts: 0,
        totalCorrect: 0,
        currentStreak: 0,
        bestStreak: 0,
        completedQuestionIDs: [],
        lastPlayedAt: nil
    )

    var accuracy: Double {
        guard totalAttempts > 0 else { return 0 }
        return Double(totalCorrect) / Double(totalAttempts)
    }

    mutating func record(_ feedback: AnswerFeedback, now: Date = .now) {
        totalAttempts += 1
        completedQuestionIDs.insert(feedback.questionID)
        lastPlayedAt = now

        if feedback.isCorrect {
            totalCorrect += 1
            currentStreak += 1
            bestStreak = max(bestStreak, currentStreak)
        } else {
            currentStreak = 0
        }
    }
}
