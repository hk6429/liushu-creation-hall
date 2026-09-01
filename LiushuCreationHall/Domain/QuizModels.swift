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
