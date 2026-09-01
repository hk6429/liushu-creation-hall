import Foundation

protocol QuestionLoading {
    func load() throws -> [CharacterQuestion]
}

struct BundleQuestionLoader: QuestionLoading {
    func load() throws -> [CharacterQuestion] {
        guard let url = Bundle.main.url(forResource: "questions", withExtension: "json") else {
            throw QuestionLoadingError.missingResource
        }

        let data = try Data(contentsOf: url)
        let questions = try JSONDecoder().decode([CharacterQuestion].self, from: data)

        guard !questions.isEmpty, Set(questions.map(\.id)).count == questions.count else {
            throw QuestionLoadingError.invalidContent
        }

        return questions
    }
}

enum QuestionLoadingError: Error {
    case missingResource
    case invalidContent
}
