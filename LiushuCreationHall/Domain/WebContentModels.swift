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
    var verifiedShuowen: String? {
        shuowenStatus == "已核對" && !shuowen.isEmpty ? shuowen : nil
    }

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

struct TeacherContentPack: Codable, Sendable {
    let schemaVersion: Int
    let title: String
    let teacher: String
    let reviewedBy: String
    let entries: [CharacterEntry]
}

enum TeacherContentPackError: LocalizedError {
    case fileTooLarge
    case invalidSchema
    case missingReview
    case invalidEntries

    var errorDescription: String? {
        switch self {
        case .fileTooLarge: "內容包超過 2 MB。"
        case .invalidSchema: "內容包版本不支援。"
        case .missingReview: "內容包缺少教師與複核者欄位。"
        case .invalidEntries: "字例重複、含爭議定論，或缺少可辨識的六書分類。"
        }
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
