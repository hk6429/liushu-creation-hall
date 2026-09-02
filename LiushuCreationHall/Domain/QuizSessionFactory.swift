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

    static func makeJourneyQuestions(
        from characters: [CharacterEntry],
        blueprint: [String]
    ) -> [CharacterQuestion] {
        guard blueprint.count == 3 else { return [] }
        let byCharacter = Dictionary(uniqueKeysWithValues: characters.map { ($0.char, $0) })
        let entries = blueprint.compactMap { byCharacter[$0] }
        guard entries.count == 3, entries.allSatisfy({ !$0.disputed && $0.method != nil }) else { return [] }
        return entries.compactMap(makeQuestion)
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
                ? usageContext(for: entry)
                : "這題問字形如何構成，請找可驗證的部件或古字形線索。",
            explanation: entry.explain,
            evidencePrompt: makeEvidencePrompt(for: entry, correctMethod: method)
        )
    }

    private static func makeEvidencePrompt(
        for entry: CharacterEntry,
        correctMethod: CreationMethod
    ) -> EvidencePrompt {
        let distractors = CreationMethod.allCases
            .filter { $0 != correctMethod }
            .sorted { stableHash("\(entry.id)|\($0.rawValue)") < stableHash("\(entry.id)|\($1.rawValue)") }
            .prefix(2)
        let methods = ([correctMethod] + distractors).sorted {
            stableHash("evidence|\(entry.id)|\($0.rawValue)") < stableHash("evidence|\(entry.id)|\($1.rawValue)")
        }
        let choices = methods.map { method in
            EvidenceChoice(
                id: method.rawValue,
                text: method == correctMethod
                    ? specificEvidence(from: entry.explain)
                    : distractorEvidence(for: method, character: entry.char)
            )
        }
        return EvidencePrompt(
            question: "哪一項才是「\(entry.char)」在本題中的具體證據？",
            choices: choices,
            correctChoiceID: correctMethod.rawValue
        )
    }

    private static func specificEvidence(from explanation: String) -> String {
        let sentences = explanation
            .split(separator: "。", omittingEmptySubsequences: true)
            .prefix(2)
            .map(String.init)
        let text = sentences.joined(separator: "；")
        return text.isEmpty ? explanation : text + "。"
    }

    private static func distractorEvidence(for method: CreationMethod, character: String) -> String {
        switch method {
        case .pictograph: "早期「\(character)」只是在描畫一個具體物體的外形。"
        case .indicative: "「\(character)」只靠附加記號指出抽象概念或關鍵部位。"
        case .associative: "「\(character)」由兩個有獨立意義的部件共同表意。"
        case .phonoSemantic: "「\(character)」可明確拆成表義形符與提示讀音的聲符。"
        case .derivative: "「\(character)」必須和另一個同類近義字彼此訓釋。"
        case .phoneticLoan: "「\(character)」原有本義，後來借來記錄同音或音近的另一個詞。"
        }
    }

    private static func usageContext(for entry: CharacterEntry) -> String {
        let context = specificEvidence(from: entry.explain)
            .replacingOccurrences(of: entry.category, with: "這種關係")
        let related = entry.usageRelations.flatMap(\.relatedChars)
        let relationText = related.isEmpty ? "" : " 關係字：\(related.joined(separator: "、"))。"
        return "本題問用字關係，不問單字構形。\(context)\(relationText)"
    }
}
