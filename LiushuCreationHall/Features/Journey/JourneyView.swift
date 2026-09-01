import SwiftUI

struct JourneyView: View {
    @EnvironmentObject private var model: AppModel

    private var completedCount: Int { model.progress.journey.completed.count }
    private var today: DailyActivity { model.progress.days[LearningClock.dateKey(), default: DailyActivity()] }
    private var weeklyDays: Int { model.progress.completedDaysThisWeek() }

    var body: some View {
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
                                Text(isDone ? "已通過" : isAvailable ? chapter.hook : "完成前卷後開啟")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
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
                }
            }
            .padding()
            .frame(maxWidth: 800)
            .frame(maxWidth: .infinity)
        }
        .background(InkBackground())
        .navigationTitle("八卷旅程")
    }
}

private struct JourneyChapterView: View {
    @EnvironmentObject private var model: AppModel
    let chapter: JourneyChapter

    private var story: LessonSection? {
        guard let sections = model.learningLibrary?.story, sections.indices.contains(chapter.storyIndex) else { return nil }
        return sections[chapter.storyIndex]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let story {
                    if let imageName = story.imageName {
                        BundledImageView(resourceName: imageName)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                    }
                    Text(story.body).lineSpacing(7)
                } else {
                    Text(chapter.hook).font(.title3)
                }
                NavigationLink("開始本卷三題試煉") {
                    JourneyTrialView(chapter: chapter)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
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

struct JourneyTrialView: View {
    @EnvironmentObject private var model: AppModel
    let chapter: JourneyChapter?
    let dailyCount: Int
    @State private var questions: [CharacterQuestion] = []
    @State private var index = 0
    @State private var score = 0
    @State private var feedback: AnswerFeedback?
    @State private var selectedEvidence: CreationMethod?
    @State private var isComplete = false
    @State private var passed = false

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
            ForEach(CreationMethod.allCases) { method in
                Button(method.rawValue) { answer(method, item: item) }
                    .buttonStyle(.bordered)
                    .tint(method == feedback?.correctMethod ? AppTheme.jade : AppTheme.color(for: method))
                    .disabled(feedback != nil)
                    .frame(maxWidth: .infinity)
            }
            if let feedback {
                Text((feedback.isCorrect ? "答對了。" : "再看一次證據。") + feedback.explanation)
                    .padding().frame(maxWidth: .infinity, alignment: .leading)
                    .background(.background, in: RoundedRectangle(cornerRadius: 16))
                EvidenceCheckView(method: feedback.correctMethod, selected: $selectedEvidence) { correct in
                    model.recordRationale(questionID: feedback.questionID, method: feedback.correctMethod, correct: correct)
                }
                Button(index == questions.count - 1 ? "看學習摘要" : "下一題") { next() }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedEvidence == nil)
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
            if chapter == nil {
                ShareLink(item: "我在六書造字堂完成今日挑戰，答對 \(score)／\(questions.count) 題。") {
                    Label("分享今日成果", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
            }
            if !passed, chapter != nil {
                Button("重試本卷") { reset() }.buttonStyle(.borderedProminent)
            }
        }
        .padding(28)
        .background(.background, in: RoundedRectangle(cornerRadius: 24))
    }

    private func makeQuestions() {
        questions = if let chapter {
            QuizSessionFactory.makeQuestions(from: model.characters, preferredCharacters: chapter.characters, count: 3)
        } else {
            Array(QuizSessionFactory.makeDailyQuestions(from: model.characters, dateKey: LearningClock.dateKey(), count: dailyCount).prefix(dailyCount))
        }
    }

    private func answer(_ method: CreationMethod, item: CharacterQuestion) {
        let result = QuizEngine.evaluate(question: item, answer: method)
        feedback = result
        if result.isCorrect { score += 1 }
        model.record(result, mode: chapter == nil ? .daily : .journey)
    }

    private func next() {
        if index < questions.count - 1 {
            index += 1
            feedback = nil
            selectedEvidence = nil
        } else {
            if let chapter { passed = model.completeJourney(chapter: chapter.id, score: score, total: questions.count) }
            else { model.recordDaily(score: score, total: questions.count); passed = true }
            isComplete = true
        }
    }

    private func reset() {
        index = 0; score = 0; feedback = nil; selectedEvidence = nil; isComplete = false; passed = false
        makeQuestions()
    }
}
