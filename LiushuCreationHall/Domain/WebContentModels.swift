import Foundation

struct CharacterEntry: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let char: String
    let zhuyin: String
    let category: String
    let classificationScope: String
    let sub: String?
    let subScope: String?
    let level: String
    let explain: String
    let shuowen: String
    let shuowenStatus: String
    let disputed: Bool
    let disputeNote: String
    let formationCategory: String
    let usageRelations: [UsageRelation]

    var method: CreationMethod? { CreationMethod(rawValue: category) }
    var isUsageRelation: Bool { classificationScope == "用字關係" }

    enum CodingKeys: String, CodingKey {
        case id, char, zhuyin, category, sub, level, explain, shuowen, disputed
        case classificationScope = "classification_scope"
        case subScope = "sub_scope"
        case shuowenStatus = "shuowen_status"
        case disputeNote = "dispute_note"
        case formationCategory = "formation_category"
        case usageRelations = "usage_relations"
    }
}

struct UsageRelation: Codable, Hashable, Sendable {
    let type: String
    let sub: String?
    let relatedChars: [String]
    let relationBasis: String
    let relationStatus: String
    let note: String

    enum CodingKeys: String, CodingKey {
        case type, sub, note
        case relatedChars = "related_chars"
        case relationBasis = "relation_basis"
        case relationStatus = "relation_status"
    }
}

struct LearningLibrary: Codable, Equatable, Sendable {
    let schemaVersion: Int
    let sourceRepository: String
    let sourceVersion: String
    let importedAt: String
    let concept: [LessonSection]
    let story: [LessonSection]
}

struct LessonSection: Codable, Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let title: String
    let body: String
    let imageName: String?
}
