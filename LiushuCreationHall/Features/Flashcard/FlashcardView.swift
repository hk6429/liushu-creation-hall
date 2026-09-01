import SwiftUI

struct FlashcardView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selectedLevel = "全部"
    @State private var deck: [CharacterEntry] = []
    @State private var index = 0
    @State private var isFlipped = false
    @State private var feedback = ""

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
            if !feedback.isEmpty {
                Text(feedback).padding().frame(maxWidth: .infinity).background(AppTheme.parchment, in: RoundedRectangle(cornerRadius: 14))
            }
            Button {
                isFlipped = true
            } label: {
                VStack(spacing: 12) {
                    Text(entry.char)
                        .font(.system(size: isFlipped ? 64 : 104, weight: .black, design: .serif))
                    Text(entry.zhuyin).font(.title3)
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
                        Text("點卡片翻面").foregroundStyle(.secondary)
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

            if isFlipped {
                HStack {
                    gradeButton("忘了", grade: 0, tint: AppTheme.cinnabar)
                    gradeButton("模糊", grade: 1, tint: .orange)
                    gradeButton("熟！", grade: 2, tint: AppTheme.jade)
                }
            }
        }
    }

    private func gradeButton(_ title: String, grade value: Int, tint: Color) -> some View {
        Button(title) { grade(value) }
            .buttonStyle(.borderedProminent)
            .tint(tint)
            .frame(maxWidth: .infinity)
    }

    private var completion: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill").font(.system(size: 60)).foregroundStyle(AppTheme.jade)
            Text("本回合完成！").font(.largeTitle.bold())
            Text("共複習 \(deck.count) 張。到期字會依五盒排程再次出現。")
            Button("再複習一輪") { start() }.buttonStyle(.borderedProminent)
        }
        .padding(28)
        .background(.background, in: RoundedRectangle(cornerRadius: 24))
    }

    private func start() {
        deck = model.flashDeck(level: selectedLevel == "全部" ? nil : selectedLevel)
        index = 0
        isFlipped = false
        feedback = ""
    }

    private func grade(_ grade: Int) {
        let entry = deck[index]
        let before = model.progress.cards[entry.id]?.box ?? 1
        model.gradeCard(id: entry.id, grade: grade)
        let after = model.progress.cards[entry.id]?.box ?? 1
        feedback = before == after ? "保留在第 \(after) 盒" : "第 \(before) 盒 → 第 \(after) 盒"
        index += 1
        isFlipped = false
    }
}
