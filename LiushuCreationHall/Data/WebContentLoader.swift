import Foundation

protocol WebContentLoading {
    func loadCharacters() throws -> [CharacterEntry]
    func loadLearningLibrary() throws -> LearningLibrary
}

struct BundleWebContentLoader: WebContentLoading {
    func loadCharacters() throws -> [CharacterEntry] {
        let data = try resourceData(named: "characters")
        let characters = try JSONDecoder().decode([CharacterEntry].self, from: data)
        guard characters.count == 220,
              Set(characters.map(\.id)).count == characters.count,
              Set(characters.map(\.char)).count == characters.count
        else {
            throw WebContentLoadingError.invalidCharacterContract
        }
        return characters
    }

    func loadLearningLibrary() throws -> LearningLibrary {
        let data = try resourceData(named: "learning-library")
        let library = try JSONDecoder().decode(LearningLibrary.self, from: data)
        guard !library.concept.isEmpty, !library.story.isEmpty else {
            throw WebContentLoadingError.invalidLearningLibrary
        }
        return library
    }

    private func resourceData(named name: String) throws -> Data {
        let url = Bundle.main.url(
            forResource: name,
            withExtension: "json",
            subdirectory: "WebContent"
        ) ?? Bundle.main.url(forResource: name, withExtension: "json")

        guard let url else { throw WebContentLoadingError.missingResource(name) }
        return try Data(contentsOf: url)
    }
}

enum WebContentLoadingError: Error {
    case missingResource(String)
    case invalidCharacterContract
    case invalidLearningLibrary
}
