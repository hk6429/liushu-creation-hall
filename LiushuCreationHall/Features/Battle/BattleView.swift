import SwiftUI

struct BattleView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("大師對戰").font(.largeTitle.bold())
                Text("答對造成傷害並累積連擊；答錯會承受大師攻擊。有效精通字數會開啟新的對手。")
                Text("人物插畫是 AI 輔助的教學想像圖；對戰台詞是戲劇化創作，不是史料原句。")
                    .font(.footnote).foregroundStyle(.primary)
                Text("目前有效精通：\(model.progress.masteredIDs.count) 字").font(.headline)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 14)], spacing: 14) {
                    ForEach(MasterDefinition.all) { master in
                        masterCard(master)
                    }
                }
            }
            .padding()
            .frame(maxWidth: 1000)
            .frame(maxWidth: .infinity)
        }
        .background(InkBackground())
        .navigationTitle("翰墨對決")
    }

    private func masterCard(_ master: MasterDefinition) -> some View {
        let masteredCategories = Set(model.progress.skillEvidence.compactMap { id, evidence in
            model.progress.masteredIDs.contains(id) ? evidence.category : nil
        })
        let focusBreadth = masteredCategories.intersection(master.focus).count
        let locked = model.progress.masteredIDs.count < master.unlock || focusBreadth < master.requiredBreadth
        let focusIDs = model.characters.filter { master.focus.contains($0.category) }.map(\.id)
        let focusEvidence = model.progress.skillEvidence.values.filter { evidence in
            evidence.unpromptedRationalePasses > 0 && evidence.category.map(master.focus.contains) == true
        }.count
        let delayed = model.progress.skillEvidence.values.filter { $0.delayedPasses > 0 }.count
        let invitationReady = focusEvidence >= 3 && delayed >= 5
        return VStack(spacing: 10) {
            BundledImageView(resourceName: master.imageName, contentMode: .fill)
                .frame(height: 170)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .accessibilityLabel("\(master.name)人物教學想像圖")
            Text(master.name).font(.title2.bold())
            Text(master.title).font(.subheadline)
            Text("攻擊 \(master.attack)・主題 \(master.focus.sorted().joined(separator: "／"))")
                .font(.caption).multilineTextAlignment(.center)
            if let wins = model.progress.battle.beaten[master.id], wins > 0 {
                Text("已擊敗 ×\(wins)　最佳 \(model.progress.battle.best[master.id, default: 0])／10")
                    .font(.caption.bold()).foregroundStyle(AppTheme.jade)
            }
            if locked {
                Label("拜帖進度", systemImage: "lock.fill").font(.headline)
                Text("有效精通 \(model.progress.masteredIDs.count)／\(master.unlock) 字；主題廣度 \(focusBreadth)／\(master.requiredBreadth)")
                    .font(.caption).multilineTextAlignment(.center)
                Label("三個主題證據 \(focusEvidence)／3", systemImage: focusEvidence >= 3 ? "checkmark.circle.fill" : "circle")
                    .font(.caption)
                Label("隔日答對五字 \(delayed)／5", systemImage: delayed >= 5 ? "checkmark.circle.fill" : "circle")
                    .font(.caption)
                if invitationReady {
                    NavigationLink("拜帖練習戰") { BattleFightView(master: master, practiceOnly: true) }
                        .buttonStyle(.borderedProminent)
                }
                NavigationLink("去練此主題") { FlashcardView(focusIDs: focusIDs) }
                    .buttonStyle(.bordered)
            } else {
                NavigationLink("挑戰") { BattleFightView(master: master) }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.background, in: RoundedRectangle(cornerRadius: 22))
    }
}

private struct BattleFightView: View {
    private enum Tactic: String, CaseIterable, Identifiable {
        case inspectForm = "辨形"
        case seekSound = "尋聲"
        case analyzeMeaning = "析義"

        var id: String { rawValue }
        var symbol: String {
            switch self {
            case .inspectForm: "viewfinder"
            case .seekSound: "waveform"
            case .analyzeMeaning: "text.magnifyingglass"
            }
        }
    }

    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let master: MasterDefinition
    var practiceOnly = false
    @State private var questions: [CharacterQuestion] = []
    @State private var index = 0
    @State private var score = 0
    @State private var focusRight = 0
    @State private var combo = 0
    @State private var playerHP = 100
    @State private var masterHP = 100
    @State private var selectedMethod: CreationMethod?
    @State private var selectedTactic: Tactic?
    @State private var feedback: AnswerFeedback?
    @State private var selectedEvidenceID: String?
    @State private var evidenceWasCorrect = false
    @State private var result: Bool?
    @State private var didRecord = false
    @State private var missedIDs: [String] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                combatants
                if let result { summary(win: result) }
                else if questions.indices.contains(index) { question(questions[index]) }
                else { ProgressView("大師正在出題……") }
            }
            .padding()
            .frame(maxWidth: 800)
            .frame(maxWidth: .infinity)
        }
        .background(InkBackground())
        .navigationTitle("阿滿 對 \(master.name)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if questions.isEmpty { start() } }
    }

    private var combatants: some View {
        HStack(spacing: 18) {
            fighter(name: "阿滿", image: "character-aman", hp: playerHP, tint: AppTheme.jade)
            Text("對").font(.title.bold()).foregroundStyle(AppTheme.cinnabar)
            fighter(name: master.name, image: master.imageName, hp: masterHP, tint: AppTheme.cinnabar)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 22))
    }

    private func fighter(name: String, image: String, hp: Int, tint: Color) -> some View {
        VStack(spacing: 8) {
            BundledImageView(resourceName: image, contentMode: .fill)
                .frame(height: 120).clipShape(RoundedRectangle(cornerRadius: 14))
            Text(name).font(.headline)
            ProgressView(value: Double(hp), total: 100).tint(tint)
            Text("氣力 \(hp)／100")
                .font(.caption.monospacedDigit())
                .contentTransition(.numericText())
                .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: hp)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func question(_ item: CharacterQuestion) -> some View {
        VStack(spacing: 14) {
            Text("第 \(index + 1)／10 題・答對 \(score)・連擊 \(combo)").font(.headline.monospacedDigit())
            if index == 0 { Text("\(master.name)：『\(master.taunt)』").font(.subheadline).italic() }
            Text(item.display).font(.system(size: 76, weight: .black, design: .serif))
            Text(item.prompt).font(.title3.bold()).multilineTextAlignment(.center)
            Text("先選這題要用的招式").font(.headline)
            HStack {
                ForEach(Tactic.allCases) { tactic in
                    Button {
                        selectedTactic = tactic
                    } label: {
                        Label(tactic.rawValue, systemImage: tactic.symbol)
                    }
                    .buttonStyle(.bordered)
                    .tint(selectedTactic == tactic ? AppTheme.cinnabar : .primary)
                    .disabled(selectedMethod != nil)
                }
            }
            MethodAnswerGrid {
                ForEach(CreationMethod.allCases) { method in
                    Button(method.rawValue) { select(method, item: item) }
                        .buttonStyle(.bordered)
                        .tint(answerTint(method))
                        .disabled(selectedMethod != nil || selectedTactic == nil)
                        .frame(maxWidth: .infinity)
                }
            }
            if feedback == nil, selectedMethod != nil, let prompt = item.evidencePrompt {
                EvidenceCheckView(prompt: prompt, selectedID: $selectedEvidenceID) { correct in
                    reveal(item: item, evidenceCorrect: correct)
                }
            }
            if let feedback {
                Text(chainEstablished(for: item) ? "證據連鎖成立：招式、判類與找證都正確。" : "證據連鎖未成立：招式、判類或證據仍有一環要補。")
                    .font(.headline)
                    .foregroundStyle(chainEstablished(for: item) ? AppTheme.jade : AppTheme.cinnabar)
                LearningFeedbackCard(feedback: feedback, evidenceCorrect: evidenceWasCorrect)
                Button("下一回合") { next() }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private func summary(win: Bool) -> some View {
        VStack(spacing: 14) {
            Image(systemName: win ? "trophy.fill" : "shield.lefthalf.filled")
                .font(.system(size: 60)).foregroundStyle(win ? .orange : AppTheme.cinnabar)
            Text(practiceOnly ? "拜帖試鋒完成" : win ? "勝出！" : "修煉後再戰").font(.largeTitle.bold())
            Text("本次判類答對 \(score)／10；\(win ? "大師留下認可印記。" : "大師手札已整理本局弱點，先完成補救再戰。")")
            Button("今日收功") { dismiss() }.buttonStyle(.borderedProminent)
            if practiceOnly {
                Text("練習戰不取代正式的總量與六書廣度門檻。")
                    .font(.subheadline)
            } else if win, model.canStartNewTask {
                Button("再戰一次") { start() }.buttonStyle(.bordered)
            } else {
                Text("大師手札：本局容易漏掉 \(missedCharacters)。建議回到〈\(remediationStory)〉，再用兩字短練習找一次證據。")
                    .font(.subheadline)
                NavigationLink("研讀大師手札") {
                    FlashcardView(focusIDs: Array(missedIDs.prefix(2)))
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(28)
        .background(.background, in: RoundedRectangle(cornerRadius: 24))
    }

    private func start() {
        questions = QuizSessionFactory.makeQuestions(from: model.characters, count: 10, categories: master.focus, level: master.level)
        if questions.count < 10 {
            questions += QuizSessionFactory.makeQuestions(from: model.characters, count: 10 - questions.count)
        }
        questions = Array(questions.prefix(10))
        index = 0; score = 0; focusRight = 0; combo = 0; playerHP = 100; masterHP = 100
        selectedMethod = nil; selectedTactic = nil; feedback = nil; selectedEvidenceID = nil; evidenceWasCorrect = false
        result = nil; didRecord = false
        missedIDs = []
    }

    private func select(_ method: CreationMethod, item: CharacterQuestion) {
        guard selectedMethod == nil else { return }
        selectedMethod = method
        if item.evidencePrompt == nil { reveal(item: item, evidenceCorrect: false) }
    }

    private func reveal(item: CharacterQuestion, evidenceCorrect: Bool) {
        guard let selectedMethod, feedback == nil else { return }
        let answer = QuizEngine.evaluate(question: item, answer: selectedMethod)
        feedback = answer
        evidenceWasCorrect = evidenceCorrect
        if answer.isCorrect {
            score += 1
            if evidenceCorrect && selectedTactic == tactic(for: item.correctMethod) {
                combo += 1
                if master.focus.contains(item.correctMethod.rawValue) { focusRight += 1 }
                masterHP = max(0, masterHP - (10 + combo * 3 + (playerHP <= 30 ? 5 : 0)))
            } else {
                combo = 0
                masterHP = max(0, masterHP - 4)
            }
        } else {
            combo = 0
            playerHP = max(0, playerHP - master.attack)
        }
        if !chainEstablished(for: item), !missedIDs.contains(item.id) { missedIDs.append(item.id) }
        model.record(answer, mode: .battle, rationale: evidenceCorrect && answer.isCorrect)
    }

    private func answerTint(_ method: CreationMethod) -> Color {
        if let feedback, method == feedback.correctMethod { return AppTheme.jade }
        if method == selectedMethod { return AppTheme.cinnabar }
        return AppTheme.color(for: method)
    }

    private func next() {
        feedback = nil
        selectedMethod = nil
        selectedTactic = nil
        selectedEvidenceID = nil
        evidenceWasCorrect = false
        index += 1
        if masterHP == 0 || playerHP == 0 || index >= 10 {
            let win = masterHP == 0 || (score >= 7 && focusRight >= 3)
            result = win
            if !practiceOnly, !didRecord { model.recordBattle(masterID: master.id, win: win, score: score); didRecord = true }
        }
    }

    private func tactic(for method: CreationMethod) -> Tactic {
        switch method {
        case .pictograph, .indicative, .associative: .inspectForm
        case .phonoSemantic: .seekSound
        case .derivative, .phoneticLoan: .analyzeMeaning
        }
    }

    private func chainEstablished(for item: CharacterQuestion) -> Bool {
        feedback?.isCorrect == true && evidenceWasCorrect && selectedTactic == tactic(for: item.correctMethod)
    }

    private var missedCharacters: String {
        let text = missedIDs.prefix(2).compactMap { id in model.characters.first { $0.id == id }?.char }.joined(separator: "、")
        return text.isEmpty ? "招式與證據的配合" : text
    }

    private var remediationStory: String {
        let method = missedIDs.first.flatMap { id in model.characters.first { $0.id == id }?.category }
        return JourneyChapter.all.first { chapter in
            chapter.characters.contains { char in model.characters.first { $0.char == char }?.category == method }
        }?.title ?? "八卷旅程"
    }
}
