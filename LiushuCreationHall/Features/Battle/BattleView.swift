import SwiftUI

struct BattleView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("大師對戰").font(.largeTitle.bold())
                Text("答對造成傷害並累積連擊；答錯會承受大師攻擊。有效精通字數會開啟新的對手。")
                Text("人物插畫是 AI 輔助的教學想像圖；對戰台詞是戲劇化創作，不是史料原句。")
                    .font(.footnote).foregroundStyle(.secondary)
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
        let locked = model.progress.masteredIDs.count < master.unlock
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
                Label("有效精通 \(master.unlock) 字解鎖", systemImage: "lock.fill").font(.caption)
            } else {
                NavigationLink("挑戰") { BattleFightView(master: master) }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.background, in: RoundedRectangle(cornerRadius: 22))
        .opacity(locked ? 0.65 : 1)
    }
}

private struct BattleFightView: View {
    @EnvironmentObject private var model: AppModel
    let master: MasterDefinition
    @State private var questions: [CharacterQuestion] = []
    @State private var index = 0
    @State private var score = 0
    @State private var focusRight = 0
    @State private var combo = 0
    @State private var playerHP = 100
    @State private var masterHP = 100
    @State private var feedback: AnswerFeedback?
    @State private var selectedEvidence: CreationMethod?
    @State private var result: Bool?
    @State private var didRecord = false

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
            Text("氣力 \(hp)／100").font(.caption.monospacedDigit())
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
            ForEach(CreationMethod.allCases) { method in
                Button(method.rawValue) { answer(method, item: item) }
                    .buttonStyle(.bordered)
                    .tint(method == feedback?.correctMethod ? AppTheme.jade : AppTheme.color(for: method))
                    .disabled(feedback != nil)
                    .frame(maxWidth: .infinity)
            }
            if let feedback {
                Text(feedback.explanation).padding().frame(maxWidth: .infinity, alignment: .leading)
                    .background(.background, in: RoundedRectangle(cornerRadius: 16))
                EvidenceCheckView(method: feedback.correctMethod, selected: $selectedEvidence) { correct in
                    model.recordRationale(questionID: feedback.questionID, method: feedback.correctMethod, correct: correct)
                }
                Button("下一回合") { next() }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedEvidence == nil)
            }
        }
    }

    private func summary(win: Bool) -> some View {
        VStack(spacing: 14) {
            Image(systemName: win ? "trophy.fill" : "shield.lefthalf.filled")
                .font(.system(size: 60)).foregroundStyle(win ? .orange : AppTheme.cinnabar)
            Text(win ? "勝出！" : "修煉後再戰").font(.largeTitle.bold())
            Text("本次答對 \(score)／10；\(win ? "大師留下認可印記。" : "錯字已排入弱點複習。")")
            Button("再戰一次") { start() }.buttonStyle(.borderedProminent)
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
        feedback = nil; selectedEvidence = nil; result = nil; didRecord = false
    }

    private func answer(_ method: CreationMethod, item: CharacterQuestion) {
        let answer = QuizEngine.evaluate(question: item, answer: method)
        feedback = answer
        if answer.isCorrect {
            score += 1; combo += 1
            if master.focus.contains(item.correctMethod.rawValue) { focusRight += 1 }
            masterHP = max(0, masterHP - (10 + combo * 3 + (playerHP <= 30 ? 5 : 0)))
        } else {
            combo = 0
            playerHP = max(0, playerHP - master.attack)
        }
        model.record(answer, mode: .battle)
    }

    private func next() {
        feedback = nil
        selectedEvidence = nil
        index += 1
        if masterHP == 0 || playerHP == 0 || index >= 10 {
            let win = masterHP == 0 || (score >= 7 && focusRight >= 3)
            result = win
            if !didRecord { model.recordBattle(masterID: master.id, win: win, score: score); didRecord = true }
        }
    }
}
