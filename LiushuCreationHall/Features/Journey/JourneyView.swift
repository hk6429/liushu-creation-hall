import SwiftUI

struct JourneyView: View {
    @EnvironmentObject private var model: AppModel

    private var completedCount: Int { model.progress.journey.completed.count }
    private var today: DailyActivity { model.progress.days[LearningClock.dateKey(), default: DailyActivity()] }
    private var weeklyDays: Int { model.progress.completedDaysThisWeek() }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("今日主線").font(.largeTitle.bold())
                    Text("從故事開始，讀完一卷再接受三題短試煉。達到 2／3 才會開啟下一卷。")
                    ProgressView(value: Double(completedCount), total: 8).tint(AppTheme.cinnabar)
                    Text("故事 \(completedCount)／8 卷　・　今日有效任務 \(today.effective)／5")
                        .font(.subheadline)
                    Text("本週完成 \(weeklyDays)／\(model.progress.journey.weeklyGoal) 天")
                        .font(.subheadline.bold())
                    NavigationLink("進行今日五題") {
                        JourneyTrialView(chapter: nil)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(.background, in: RoundedRectangle(cornerRadius: 22))

                if let boundary = model.learningLibrary?.story.first(where: { $0.id == "story-00" }) {
                    DisclosureGroup("故事與史實的閱讀界線") {
                        Text(boundary.body).lineSpacing(6).padding(.top, 8)
                    }
                    .padding()
                    .background(.background, in: RoundedRectangle(cornerRadius: 18))
                }

                    Text("八卷旅程").font(.title2.bold())
                    ForEach(JourneyChapter.all) { chapter in
                        let isDone = model.progress.journey.completed[chapter.id] != nil
                        let isAvailable = chapter.id <= model.progress.journey.currentChapter || isDone
                        NavigationLink {
                            JourneyChapterView(chapter: chapter)
                        } label: {
                            HStack(spacing: 14) {
                                Text(isDone ? "✓" : "\(chapter.id + 1)")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(width: 42, height: 42)
                                    .background(isDone ? AppTheme.jade : AppTheme.cinnabar, in: Circle())
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(chapter.title).font(.headline)
                                    Text(isDone ? "故事、試煉與印記已完成" : isAvailable ? chapter.hook : "開啟條件：完成前卷 2／3 題")
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                        .lineLimit(2)
                                }
                                Spacer()
                                Image(systemName: isAvailable ? "chevron.right" : "lock.fill")
                            }
                            .foregroundStyle(.primary)
                            .padding()
                            .background(.background, in: RoundedRectangle(cornerRadius: 18))
                        }
                        .buttonStyle(.plain)
                        .disabled(!isAvailable)
                        .id("chapter-\(chapter.id)")
                    }
                }
                .padding()
                .frame(maxWidth: 800)
                .frame(maxWidth: .infinity)
            }
            .background(InkBackground())
            .onAppear {
                DispatchQueue.main.async {
                    proxy.scrollTo("chapter-\(model.progress.journey.currentChapter)", anchor: .center)
                }
            }
        }
        .navigationTitle("八卷旅程")
    }
}

private struct JourneyChapterView: View {
    @EnvironmentObject private var model: AppModel
    let chapter: JourneyChapter
    @State private var evidenceDecision: String?

    private var story: LessonSection? {
        model.learningLibrary?.story.first { $0.id == chapter.storyID }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let story {
                    Label("教學創作", systemImage: "book.closed.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.cinnabar)
                    if let imageName = story.imageName {
                        BundledImageView(resourceName: imageName)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                    }
                    Text(story.body).lineSpacing(7)
                } else {
                    Text(chapter.hook).font(.title3)
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("證據決策").font(.title2.bold())
                    Text("故事情節不改寫史實；你只決定解題時先檢查哪一類證據。")
                    ForEach(["先辨字形與部件", "先尋讀音與聲符", "先析本義、借義或互訓"], id: \.self) { choice in
                        Button(choice) { evidenceDecision = choice }
                            .buttonStyle(.bordered)
                            .tint(evidenceDecision == choice ? AppTheme.cinnabar : .primary)
                    }
                    if let evidenceDecision {
                        Label("本卷採用：\(evidenceDecision)", systemImage: "checkmark.seal.fill")
                            .font(.headline).foregroundStyle(AppTheme.jade)
                    }
                }
                .padding().background(.background, in: RoundedRectangle(cornerRadius: 18))
                NavigationLink("開始本卷三題試煉") {
                    JourneyTrialView(chapter: chapter)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(evidenceDecision == nil)
                Text("永久支線").font(.title2.bold())
                ForEach(JourneySideQuest.all) { quest in
                    NavigationLink {
                        JourneySideQuestView(quest: quest, chapter: chapter)
                    } label: {
                        Label(quest.title, systemImage: quest.symbol)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .background(InkBackground())
        .navigationTitle(chapter.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { model.markChapterRead(chapter.id) }
    }
}

private struct JourneySideQuest: Identifiable {
    let id: String
    let title: String
    let symbol: String
    let instruction: String

    static let all = [
        JourneySideQuest(id: "glyph", title: "古字形考察", symbol: "fossil.shell.fill", instruction: "先找輪廓、指示符號或表意部件，再核對今天的楷書。"),
        JourneySideQuest(id: "loan", title: "借字事件", symbol: "arrow.left.arrow.right", instruction: "把字的本義與借義分開，確認題目問的是構形還是用字關係。"),
        JourneySideQuest(id: "parts", title: "部件合成謎題", symbol: "square.3.layers.3d", instruction: "拆出每個部件的工作：表義、表音或共同會意。")
    ]
}

private struct JourneySideQuestView: View {
    @EnvironmentObject private var model: AppModel
    let quest: JourneySideQuest
    let chapter: JourneyChapter

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: quest.symbol).font(.system(size: 56)).foregroundStyle(AppTheme.cinnabar)
            Text(quest.title).font(.largeTitle.bold())
            Text(quest.instruction).multilineTextAlignment(.center)
            Text("這條支線永久可補玩；完成後仍回到本卷相同的六書核心。")
                .font(.subheadline)
            NavigationLink("開始考察") {
                FlashcardView(focusIDs: model.characters.filter { chapter.characters.contains($0.char) }.map(\.id))
            }
            .buttonStyle(.borderedProminent)
        }
        .padding().frame(maxWidth: 680).frame(maxWidth: .infinity)
        .navigationTitle("支線考察")
    }
}

struct JourneyTrialView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let chapter: JourneyChapter?
    let dailyCount: Int
    @State private var questions: [CharacterQuestion] = []
    @State private var index = 0
    @State private var score = 0
    @State private var selectedMethod: CreationMethod?
    @State private var feedback: AnswerFeedback?
    @State private var selectedEvidenceID: String?
    @State private var isComplete = false
    @State private var passed = false
    @AppStorage("parent-sharing-enabled") private var sharingEnabled = true

    init(chapter: JourneyChapter?, dailyCount: Int = 5) {
        self.chapter = chapter
        self.dailyCount = dailyCount
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if questions.isEmpty {
                    ProgressView("正在備題……")
                } else if isComplete {
                    summary
                } else {
                    question(questions[index])
                }
            }
            .padding()
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .background(InkBackground())
        .navigationTitle(chapter == nil ? (dailyCount == 12 ? "每日字陣" : "今日五題") : "本卷試煉")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if questions.isEmpty { makeQuestions() } }
    }

    private func question(_ item: CharacterQuestion) -> some View {
        VStack(spacing: 16) {
            Text("第 \(index + 1)／\(questions.count) 題").font(.headline.monospacedDigit())
            Text(item.display).font(.system(size: 82, weight: .black, design: .serif))
            Text(item.prompt).font(.title3.bold()).multilineTextAlignment(.center)
            Text(item.clue).font(.subheadline)
            MethodAnswerGrid {
                ForEach(CreationMethod.allCases) { method in
                    Button(method.rawValue) { select(method, item: item) }
                        .buttonStyle(.bordered)
                        .tint(answerTint(method))
                        .disabled(selectedMethod != nil)
                        .frame(maxWidth: .infinity)
                }
            }
            if feedback == nil, selectedMethod != nil, let prompt = item.evidencePrompt {
                EvidenceCheckView(prompt: prompt, selectedID: $selectedEvidenceID) { correct in
                    reveal(item: item, evidenceCorrect: correct)
                }
            }
            if let feedback {
                LearningFeedbackCard(feedback: feedback, evidenceCorrect: selectedEvidenceID == item.evidencePrompt?.correctChoiceID)
                Button(index == questions.count - 1 ? "看學習摘要" : "下一題") { next() }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private var summary: some View {
        VStack(spacing: 16) {
            Image(systemName: passed ? "checkmark.seal.fill" : "arrow.counterclockwise.circle.fill")
                .font(.system(size: 58)).foregroundStyle(passed ? AppTheme.jade : AppTheme.cinnabar)
            Text("\(score)／\(questions.count) 題答對").font(.largeTitle.bold())
            Text(chapter == nil ? "今日有效進度已更新；錯題會排入弱點複習。" : passed ? "已留下本卷通關印記，下一卷開啟。" : "尚未達到 2／3，先複習再重試。")
                .multilineTextAlignment(.center)
            if chapter == nil, sharingEnabled {
                ShareLink(item: shareSummary) {
                    Label("分享今日成果", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
            } else if chapter == nil {
                Label("分享已由家長關閉；學習功能不受影響", systemImage: "hand.raised.fill")
                    .font(.subheadline)
            }
            if !passed, chapter != nil {
                Button("今日收功") { dismiss() }.buttonStyle(.borderedProminent)
                if model.canStartNewTask {
                    Button("重試本卷") { reset() }.buttonStyle(.bordered)
                }
            } else {
                Button("今日收功") { dismiss() }.buttonStyle(.borderedProminent)
            }
        }
        .padding(28)
        .background(.background, in: RoundedRectangle(cornerRadius: 24))
    }

    private var shareSummary: String {
        let characters = questions.map(\.display).joined(separator: "、")
        return "我今天在六書造字堂破解了：\(characters)。我練習先判斷六書，再找字形、字音或用字關係的證據。分享內容不含姓名、班級與分數。"
    }

    private func makeQuestions() {
        questions = if let chapter {
            QuizSessionFactory.makeJourneyQuestions(from: model.characters, blueprint: chapter.characters)
        } else {
            Array(QuizSessionFactory.makeDailyQuestions(from: model.characters, dateKey: LearningClock.dateKey(), count: dailyCount).prefix(dailyCount))
        }
    }

    private func select(_ method: CreationMethod, item: CharacterQuestion) {
        guard selectedMethod == nil else { return }
        selectedMethod = method
        if item.evidencePrompt == nil { reveal(item: item, evidenceCorrect: false) }
    }

    private func reveal(item: CharacterQuestion, evidenceCorrect: Bool) {
        guard let selectedMethod, feedback == nil else { return }
        let result = QuizEngine.evaluate(question: item, answer: selectedMethod)
        feedback = result
        if result.isCorrect { score += 1 }
        model.record(
            result,
            mode: chapter == nil ? .daily : .journey,
            rationale: evidenceCorrect && result.isCorrect
        )
    }

    private func answerTint(_ method: CreationMethod) -> Color {
        if let feedback, method == feedback.correctMethod { return AppTheme.jade }
        if method == selectedMethod { return AppTheme.cinnabar }
        return AppTheme.color(for: method)
    }

    private func next() {
        if index < questions.count - 1 {
            index += 1
            selectedMethod = nil
            feedback = nil
            selectedEvidenceID = nil
        } else {
            if let chapter { passed = model.completeJourney(chapter: chapter.id, score: score, total: questions.count) }
            else { model.recordDaily(score: score, total: questions.count); passed = true }
            isComplete = true
        }
    }

    private func reset() {
        index = 0; score = 0; selectedMethod = nil; feedback = nil; selectedEvidenceID = nil; isComplete = false; passed = false
        makeQuestions()
    }
}
