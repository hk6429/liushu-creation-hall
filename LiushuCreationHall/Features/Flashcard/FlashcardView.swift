import SwiftUI

struct FlashcardView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let focusIDs: [String]
    @State private var selectedLevel = "全部"
    @State private var deck: [CharacterEntry] = []
    @State private var index = 0
    @State private var isFlipped = false
    @State private var feedback = ""
    @State private var predictedMethod: CreationMethod?
    @State private var predictionFeedback = ""
    @State private var lastGradedID: String?
    @State private var lastCardProgress: CardProgress?

    init(focusIDs: [String] = []) {
        self.focusIDs = focusIDs
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("Leitner 五盒間隔複習：到期卡與弱點字優先，每輪最多 20 張，並保留最多 4 個新字。")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.background, in: RoundedRectangle(cornerRadius: 18))

                Picker("複習難度", selection: $selectedLevel) {
                    ForEach(["全部", "基礎", "進階", "挑戰"], id: \.self) { Text($0) }
                }
                .pickerStyle(.segmented)

                if deck.isEmpty {
                    Button("開始複習") { start() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                } else if index >= deck.count {
                    completion
                } else {
                    card(deck[index])
                }
            }
            .padding()
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .background(InkBackground())
        .navigationTitle("閃卡複習")
    }

    @ViewBuilder
    private func card(_ entry: CharacterEntry) -> some View {
        let cardProgress = model.progress.cards[entry.id, default: CardProgress()]
        VStack(spacing: 16) {
            Text("第 \(index + 1)／\(deck.count) 張　・　\(cardProgress.stageTitle)（第 \(cardProgress.box) 盒）")
                .font(.headline.monospacedDigit())
            Label(cardMode(for: entry), systemImage: cardModeSymbol(for: entry))
                .font(.headline).foregroundStyle(AppTheme.cinnabar)
            if !feedback.isEmpty {
                HStack {
                    Text(feedback)
                    Spacer()
                    if lastGradedID != nil {
                        Button("撤銷上次評級") { undoLastGrade() }.buttonStyle(.bordered)
                    }
                }
                .padding().frame(maxWidth: .infinity)
                .background(AppTheme.parchment, in: RoundedRectangle(cornerRadius: 14))
            }
            Button {
                if predictedMethod != nil { reveal(entry) }
            } label: {
                VStack(spacing: 12) {
                    Text(entry.char)
                        .font(.system(size: isFlipped ? 64 : 104, weight: .black, design: .serif))
                    if index % 3 == 1 {
                        BundledImageView(resourceName: entry.id, contentMode: .fit)
                            .frame(maxHeight: 120)
                            .accessibilityLabel("\(entry.char)的字形資料")
                    }
                    if isFlipped || entry.method != .phonoSemantic {
                        Text(entry.zhuyin).font(.title3)
                    } else {
                        Text("注音將在翻面後顯示").font(.subheadline.bold())
                    }
                    if isFlipped {
                        Label(entry.category + (entry.sub.map { "・\($0)" } ?? ""), systemImage: entry.method?.systemImage ?? "character.book.closed")
                            .font(.headline)
                        Text(entry.explain)
                            .multilineTextAlignment(.leading)
                            .lineSpacing(5)
                        if entry.disputed, !entry.disputeNote.isEmpty {
                            Text("爭議提醒：\(entry.disputeNote)")
                                .font(.footnote)
                                .multilineTextAlignment(.leading)
                        }
                    } else {
                        Text(predictedMethod == nil ? "先預測六書分類" : "點卡片核對答案")
                            .foregroundStyle(.primary)
                    }
                }
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, minHeight: 330)
                .padding(24)
                .background(.background, in: RoundedRectangle(cornerRadius: 28))
                .overlay { RoundedRectangle(cornerRadius: 28).stroke(AppTheme.cinnabar, lineWidth: 3) }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isFlipped ? "\(entry.char)，\(entry.category)，\(entry.explain)" : "\(entry.char)，點兩下翻面")

            if !isFlipped {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: 10) {
                    ForEach(CreationMethod.allCases) { method in
                        Button(method.rawValue) { predictedMethod = method }
                            .buttonStyle(.bordered)
                            .tint(predictedMethod == method ? AppTheme.cinnabar : AppTheme.color(for: method))
                            .disabled(predictedMethod != nil)
                    }
                }
            }

            if !predictionFeedback.isEmpty {
                Text(predictionFeedback)
                    .font(.headline)
                    .foregroundStyle(predictedMethod == entry.method ? AppTheme.jade : AppTheme.cinnabar)
            }

            if isFlipped {
                HStack {
                    gradeButton("忘了", schedule: scheduleText(grade: 0, progress: cardProgress), grade: 0, tint: AppTheme.cinnabar)
                    gradeButton("模糊", schedule: scheduleText(grade: 1, progress: cardProgress), grade: 1, tint: .orange)
                    gradeButton("熟！", schedule: scheduleText(grade: 2, progress: cardProgress), grade: 2, tint: AppTheme.jade)
                }
            }
        }
    }

    private func gradeButton(_ title: String, schedule: String, grade value: Int, tint: Color) -> some View {
        Button { grade(value) } label: {
            VStack(spacing: 3) {
                Text(title).bold()
                Text(schedule).font(.caption2)
            }
        }
            .buttonStyle(.borderedProminent)
            .tint(tint)
            .frame(maxWidth: .infinity)
    }

    private var completion: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill").font(.system(size: 60)).foregroundStyle(AppTheme.jade)
            Text("本回合完成！").font(.largeTitle.bold())
            Text("共複習 \(deck.count) 張。到期字會依五盒排程再次出現。")
            Button("今日收功") { dismiss() }.buttonStyle(.borderedProminent)
            if model.canStartNewTask {
                Button("再複習一輪") { start() }.buttonStyle(.bordered)
            }
        }
        .padding(28)
        .background(.background, in: RoundedRectangle(cornerRadius: 24))
    }

    private func start() {
        deck = model.flashDeck(
            level: selectedLevel == "全部" ? nil : selectedLevel,
            focusIDs: focusIDs
        )
        index = 0
        isFlipped = false
        feedback = ""
        predictedMethod = nil
        predictionFeedback = ""
        lastGradedID = nil
        lastCardProgress = nil
    }

    private func grade(_ grade: Int) {
        let entry = deck[index]
        lastGradedID = entry.id
        lastCardProgress = model.progress.cards[entry.id]
        let before = model.progress.cards[entry.id]?.box ?? 1
        model.gradeCard(id: entry.id, grade: grade)
        let after = model.progress.cards[entry.id]?.box ?? 1
        let due = model.progress.cards[entry.id]?.dueDay ?? LearningClock.dayNumber()
        feedback = (before == after ? "保留在第 \(after) 盒" : "第 \(before) 盒 → 第 \(after) 盒") + "；\(dueLabel(day: due))"
        index += 1
        isFlipped = false
        predictedMethod = nil
        predictionFeedback = ""
    }

    private func reveal(_ entry: CharacterEntry) {
        guard !isFlipped, let predictedMethod,
              let question = QuizSessionFactory.makeQuestion(from: entry) else { return }
        let result = QuizEngine.evaluate(question: question, answer: predictedMethod)
        model.record(result, mode: .flash)
        predictionFeedback = result.isCorrect
            ? "預測正確；自評只調整下次出現時間。"
            : "預測未命中；正確分類是 \(result.correctMethod.rawValue)。"
        isFlipped = true
    }

    private func undoLastGrade() {
        guard let id = lastGradedID else { return }
        model.restoreCardProgress(id: id, previous: lastCardProgress)
        feedback = "已撤銷上次評級。"
        lastGradedID = nil
        lastCardProgress = nil
    }

    private func scheduleText(grade: Int, progress: CardProgress) -> String {
        switch grade {
        case 0: return "今天再見"
        case 1: return "明天再見"
        default:
            let nextBox = min(5, progress.box + 1)
            let days = [0, 0, 1, 2, 4, 8][nextBox]
            return days == 1 ? "明天再見" : "\(days) 天後再見"
        }
    }

    private func dueLabel(day: Int) -> String {
        let distance = max(0, day - LearningClock.dayNumber())
        if distance == 0 { return "排在今天再次出現" }
        if distance == 1 { return "排在明天再次出現" }
        return "排在 \(distance) 天後再次出現"
    }

    private func cardMode(for entry: CharacterEntry) -> String {
        if entry.isUsageRelation { return "詞例判用字：先分本義與借義／互訓" }
        switch index % 3 {
        case 1: return "古字形找部件：先找可見線索"
        case 2: return "證據校準：先判類，再核對理由"
        default: return "看字判構形：翻面前先預測"
        }
    }

    private func cardModeSymbol(for entry: CharacterEntry) -> String {
        if entry.isUsageRelation { return "text.quote" }
        return index % 3 == 1 ? "viewfinder" : index % 3 == 2 ? "scope" : "character.cursor.ibeam"
    }
}
