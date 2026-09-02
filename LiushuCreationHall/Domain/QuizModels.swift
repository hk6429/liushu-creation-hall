import Foundation

struct EvidenceChoice: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let text: String
}

struct EvidencePrompt: Codable, Equatable, Sendable {
    let question: String
    let choices: [EvidenceChoice]
    let correctChoiceID: String
}

struct CharacterQuestion: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let display: String
    let prompt: String
    let correctMethod: CreationMethod
    let clue: String
    let explanation: String
    let evidencePrompt: EvidencePrompt?

    init(
        id: String,
        display: String,
        prompt: String,
        correctMethod: CreationMethod,
        clue: String,
        explanation: String,
        evidencePrompt: EvidencePrompt? = nil
    ) {
        self.id = id
        self.display = display
        self.prompt = prompt
        self.correctMethod = correctMethod
        self.clue = clue
        self.explanation = explanation
        self.evidencePrompt = evidencePrompt
    }
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
