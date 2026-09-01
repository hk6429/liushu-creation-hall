import Foundation

enum QuizSessionFactory {
    static func makeQuestions(
        from characters: [CharacterEntry],
        count: Int = 10,
        categories: Set<String>? = nil,
        level: String? = nil
    ) -> [CharacterQuestion] {
        let eligible = characters.filter {
            !$0.disputed && $0.method != nil
                && (categories == nil || categories!.contains($0.category))
                && (level == nil || $0.level == level)
        }
        var selected: [CharacterEntry] = []

        let methods = CreationMethod.allCases.filter { categories == nil || categories!.contains($0.rawValue) }
        for method in methods {
            if let entry = eligible.filter({ $0.category == method.rawValue }).randomElement() {
                selected.append(entry)
            }
        }

        let selectedIDs = Set(selected.map(\.id))
        selected.append(contentsOf: eligible
            .filter { !selectedIDs.contains($0.id) }
            .shuffled()
            .prefix(max(0, count - selected.count)))

        return selected.shuffled().compactMap(makeQuestion)
    }

    static func makeQuestions(
        from characters: [CharacterEntry],
        preferredCharacters: [String],
        count: Int
    ) -> [CharacterQuestion] {
        let preferred = Set(preferredCharacters)
        let first = characters.filter { preferred.contains($0.char) && !$0.disputed && $0.method != nil }
        let fallback = characters.filter { !preferred.contains($0.char) && !$0.disputed && $0.method != nil }
        return Array((first.shuffled() + fallback.shuffled()).prefix(count)).compactMap(makeQuestion)
    }

    static func makeDailyQuestions(from characters: [CharacterEntry], dateKey: String, count: Int = 12) -> [CharacterQuestion] {
        let eligible = characters.filter { !$0.disputed && $0.method != nil }
        let ordered = eligible.sorted {
            stableHash("\(dateKey)|\($0.id)") < stableHash("\(dateKey)|\($1.id)")
        }
        var selected: [CharacterEntry] = []
        for method in CreationMethod.allCases {
            if let entry = ordered.first(where: { $0.category == method.rawValue }) { selected.append(entry) }
        }
        for entry in ordered where selected.count < count && !selected.contains(where: { $0.id == entry.id }) {
            selected.append(entry)
        }
        return selected.compactMap(makeQuestion)
    }

    private static func stableHash(_ text: String) -> UInt64 {
        text.utf8.reduce(14_695_981_039_346_656_037) { value, byte in
            (value ^ UInt64(byte)) &* 1_099_511_628_211
        }
    }

    static func makeQuestion(from entry: CharacterEntry) -> CharacterQuestion? {
        guard let method = entry.method else { return nil }
        let axis = entry.isUsageRelation ? "用字關係" : "構形方式"
        return CharacterQuestion(
            id: entry.id,
            display: entry.char,
            prompt: "\(entry.char)（\(entry.zhuyin)）在本題的\(axis)應判為哪一類？",
            correctMethod: method,
            clue: entry.isUsageRelation
                ? "這題問字與字、字與詞義的使用關係。"
                : "這題問字形如何構成，請找可驗證的部件或古字形線索。",
            explanation: entry.explain
        )
    }
}
