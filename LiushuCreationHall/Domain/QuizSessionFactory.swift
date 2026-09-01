import Foundation

enum QuizSessionFactory {
    static func makeQuestions(
        from characters: [CharacterEntry],
        count: Int = 10
    ) -> [CharacterQuestion] {
        let eligible = characters.filter { !$0.disputed && $0.method != nil }
        var selected: [CharacterEntry] = []

        for method in CreationMethod.allCases {
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
