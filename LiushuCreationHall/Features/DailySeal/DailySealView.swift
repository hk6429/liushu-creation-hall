import SwiftUI

struct DailySealCard: View {
    @EnvironmentObject private var model: AppModel

    private var record: DailySealRecord? { model.todaySealRecord }
    private var attempted: Int { record?.attemptedCount ?? 0 }
    private var target: Int { record?.targetCount ?? model.progress.habit.sealKind().targetCount }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(record?.kind.title ?? model.progress.habit.sealKind().title)
                        .font(.title2.bold())
                    Text(statusText)
                        .font(.body)
                        .foregroundStyle(.primary)
                }
                Spacer()
                Image(systemName: record?.isComplete == true ? "checkmark.seal.fill" : "seal.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(record?.isComplete == true ? AppTheme.jade : AppTheme.cinnabar)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("七日入堂").font(.subheadline.bold())
                    Spacer()
                    Text("\(model.progress.habit.sevenDay.completedStages.count)／7")
                        .font(.subheadline.bold().monospacedDigit())
                }
                ProgressView(
                    value: Double(model.progress.habit.sevenDay.completedStages.count),
                    total: 7
                )
                .tint(AppTheme.cinnabar)
                .accessibilityLabel("七日入堂進度")
                .accessibilityValue("已完成 \(model.progress.habit.sevenDay.completedStages.count) 印，共 7 印")
            }

            WeeklySealStrip(completed: model.weeklySealCount)

            if record?.isComplete == true {
                NavigationLink("自由探索") { CharacterCatalogView() }
                    .buttonStyle(.bordered)
                    .accessibilityHint("今日任務已完成，閱讀字例不再增加獎勵")
            } else if model.canStartNewTask {
                NavigationLink(attempted == 0 ? "今日一印" : "繼續修行") {
                    DailySealSessionView()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityHint("進入今日短場次，約五到十五分鐘")
            } else {
                Label("今日墨已乾，不再開新題", systemImage: "moon.stars.fill")
                    .font(.headline).foregroundStyle(.primary)
                NavigationLink("自由閱讀字庫") { CharacterCatalogView() }
                    .buttonStyle(.bordered)
            }
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppTheme.cinnabar, lineWidth: 3)
        }
        .accessibilityElement(children: .contain)
    }

    private var statusText: String {
        if let record, record.isComplete {
            return "已落印・答對 \(record.correctCount)／\(record.targetCount) 題"
        }
        if attempted > 0 { return "已完成 \(attempted)／\(target) 題，下一字正在等你。" }
        return target == 1 ? "用一個熟悉的字，輕輕重新落筆。" : "先用一個字開卷，再決定要不要繼續。"
    }
}

struct WeeklySealStrip: View {
    let completed: Int

    private let titles = ["開卷", "磨字", "試鋒"]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(titles.enumerated()), id: \.offset) { index, title in
                Label(title, systemImage: index < min(completed, 3) ? "seal.fill" : "seal")
                    .font(.subheadline.bold())
                    .foregroundStyle(index < min(completed, 3) ? AppTheme.cinnabar : .primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(AppTheme.parchment, in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityLabel("本週\(title)，\(index < min(completed, 3) ? "已完成" : "未完成")")
            }
        }
    }
}

struct DailySealSessionView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentQuestion: CharacterQuestion?
    @State private var selectedMethod: CreationMethod?
    @State private var selectedEvidenceID: String?
    @State private var feedback: AnswerFeedback?
    @State private var customAnchor = ""

    private var record: DailySealRecord? { model.activeSealRecord }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let record, record.isComplete, feedback == nil {
                    SealCompletionView(record: record) {
                        model.closeActiveSeal()
                        dismiss()
                    }
                } else if !model.canStartNewTask, currentQuestion == nil {
                    InkDryView { dismiss() }
                } else if let question = currentQuestion, let record {
                    coreRoundHeader(question)
                    stageGuidance
                    taskCard(question, record: record)
                } else {
                    ProgressView("展開今日字卷……")
                        .padding(40)
                }
            }
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
            .padding()
        }
        .background(InkBackground())
        .navigationTitle(record?.kind.title ?? "今日一印")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: startOrResume)
    }

    private func coreRoundHeader(_ question: CharacterQuestion) -> some View {
        let chapter = JourneyChapter.all[min(model.progress.journey.currentChapter, JourneyChapter.all.count - 1)]
        let card = model.progress.cards[question.id]
        let stage = (card?.dueDay ?? Int.max) <= LearningClock.dayNumber() ? "到期複習" : model.progress.weakIDs.contains(question.id) ? "弱點修補" : "新字探索"
        return VStack(alignment: .leading, spacing: 7) {
            Text("有限回合：到期複習 → 弱點修補 → 新字探索 → 落印收功")
                .font(.subheadline.bold())
            Text("本題階段：\(stage)　・　故事節點：\(chapter.title)")
                .font(.caption).foregroundStyle(.primary)
            Text("今日保底只要完成五字；12 題字陣是自由進階，不是第二份作業。")
                .font(.caption).foregroundStyle(.primary)
        }
        .padding().frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var stageGuidance: some View {
        if model.progress.habit.sevenDay.completedStages.isEmpty, model.progress.habit.anchor == nil {
            SevenDayEntryView(customAnchor: $customAnchor) { model.setStudyAnchor($0) }
        } else if model.progress.habit.sevenDay.nextStage == 3,
                  model.progress.habit.preferredCategory == nil {
            VStack(alignment: .leading, spacing: 10) {
                Text("第 3 印・擇路").font(.headline)
                Text("選一扇最近想優先修行的門。")
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))]) {
                    ForEach(CreationMethod.allCases) { method in
                        Button(method.rawValue) { model.setPreferredCategory(method) }
                            .buttonStyle(.bordered)
                    }
                }
            }
            .padding()
            .background(.background, in: RoundedRectangle(cornerRadius: 18))
        } else if model.progress.habit.sevenDay.nextStage == 6 {
            Label("第 6 印・立證：選答案前，先在心中說一句判斷理由。", systemImage: "quote.bubble.fill")
                .font(.headline)
                .padding()
                .background(.background, in: RoundedRectangle(cornerRadius: 18))
        } else if model.progress.habit.sevenDay.nextStage == 7 {
            VStack(alignment: .leading, spacing: 10) {
                Text("第 7 印・入堂").font(.headline)
                Text("已走過六次修行。選一扇門，作為下週最想磨亮的目標。")
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))]) {
                    ForEach(CreationMethod.allCases) { method in
                        Button(method.rawValue) { model.setPreferredCategory(method) }
                            .buttonStyle(.bordered)
                            .tint(model.progress.habit.preferredCategory == method ? AppTheme.cinnabar : .primary)
                    }
                }
            }
            .padding()
            .background(.background, in: RoundedRectangle(cornerRadius: 18))
        }
    }

    private func taskCard(_ question: CharacterQuestion, record: DailySealRecord) -> some View {
        VStack(spacing: 20) {
            ProgressView(value: Double(record.attemptedCount), total: Double(max(1, record.targetCount)))
                .tint(AppTheme.cinnabar)
                .accessibilityLabel("今日進度 \(record.attemptedCount)／\(record.targetCount)")

            Text(question.display)
                .font(.system(size: question.display.count > 2 ? 46 : 82, weight: .black, design: .serif))
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, minHeight: 130)
                .foregroundStyle(AppTheme.ink)
                .background(AppTheme.parchment, in: RoundedRectangle(cornerRadius: 28))
                .overlay { RoundedRectangle(cornerRadius: 28).stroke(AppTheme.cinnabar, lineWidth: 3) }
                .accessibilityLabel("題目：\(question.display)")

            Text(question.prompt)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
            Text("線索：\(question.clue)")
                .foregroundStyle(.primary)

            MethodAnswerGrid {
                ForEach(CreationMethod.allCases) { method in
                    answerButton(method, question: question)
                }
            }

            if feedback == nil, selectedMethod != nil, let prompt = question.evidencePrompt {
                EvidenceCheckView(prompt: prompt, selectedID: $selectedEvidenceID) { correct in
                    revealAnswer(question: question, evidenceCorrect: correct)
                }
            }

            if let feedback {
                LearningFeedbackCard(feedback: feedback, evidenceCorrect: selectedEvidenceID == question.evidencePrompt?.correctChoiceID)

                Button(nextButtonTitle(record: self.record)) { advanceAfterFeedback() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                if record.attemptedCount == 1, !record.isComplete {
                    Button("一字開卷完成，今天先收筆") {
                        model.closeActiveSeal()
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .animation(reduceMotion ? nil : .snappy, value: feedback)
    }

    private func answerButton(_ method: CreationMethod, question: CharacterQuestion) -> some View {
        Button {
            guard feedback == nil, selectedMethod == nil, anchorRequirementMet else { return }
            selectedMethod = method
            if question.evidencePrompt == nil { revealAnswer(question: question, evidenceCorrect: false) }
        } label: {
            HStack {
                Image(systemName: method.systemImage).accessibilityHidden(true)
                Text(method.rawValue).font(.headline)
                Spacer(minLength: 0)
                if let feedback, method == feedback.correctMethod {
                    Image(systemName: "checkmark.circle.fill").accessibilityLabel("正確答案")
                } else if let feedback, method == selectedMethod, !feedback.isCorrect {
                    Image(systemName: "xmark.circle.fill").accessibilityLabel("你的答案不正確")
                }
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .padding(.horizontal, 14)
        }
        .buttonStyle(.bordered)
        .tint(tint(for: method))
        .disabled(selectedMethod != nil || !anchorRequirementMet)
    }

    private var anchorRequirementMet: Bool {
        !model.progress.habit.sevenDay.completedStages.isEmpty || model.progress.habit.anchor != nil
    }

    private func tint(for method: CreationMethod) -> Color {
        guard let feedback else {
            return method == selectedMethod ? AppTheme.cinnabar : AppTheme.color(for: method)
        }
        if method == feedback.correctMethod { return AppTheme.jade }
        if method == selectedMethod { return AppTheme.cinnabar }
        return .primary
    }

    private func nextButtonTitle(record: DailySealRecord?) -> String {
        if record?.isComplete == true { return "查看今日落印" }
        if !model.canStartNewTask { return "墨已乾，完成今日收尾" }
        return "下一字"
    }

    private func startOrResume() {
        guard model.canStartNewTask || model.todaySealRecord?.isComplete == true else { return }
        _ = model.prepareDailySeal()
        loadNextQuestion()
    }

    private func loadNextQuestion() {
        guard let record = model.activeSealRecord, !record.isComplete else {
            currentQuestion = nil
            return
        }
        let attempted = Set(record.attemptedCharacterIDs)
        currentQuestion = model.activeSealQuestions().first { !attempted.contains($0.id) }
    }

    private func advanceAfterFeedback() {
        selectedMethod = nil
        selectedEvidenceID = nil
        feedback = nil
        if !model.canStartNewTask, model.activeSealRecord?.isComplete != true {
            currentQuestion = nil
            model.closeActiveSeal()
            return
        }
        loadNextQuestion()
    }

    private func revealAnswer(question: CharacterQuestion, evidenceCorrect: Bool) {
        guard let selectedMethod, feedback == nil else { return }
        feedback = model.submitDailySealAnswer(
            question: question,
            answer: selectedMethod,
            rationale: evidenceCorrect
        )
    }
}

private struct SevenDayEntryView: View {
    @Binding var customAnchor: String
    let select: (StudyAnchor) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("第 1 印・定錨").font(.title3.bold())
            Text("你最容易在什麼時候打開這本字卷？先選一個生活中的固定時刻。")
            HStack {
                Button("放學後") { select(.afterSchool) }
                Button("晚餐後") { select(.afterDinner) }
                Button("洗澡前") { select(.beforeBath) }
            }
            .buttonStyle(.bordered)
            HStack {
                TextField("例如：寫完功課後", text: $customAnchor)
                    .textFieldStyle(.roundedBorder)
                Button("使用") { select(.custom(customAnchor.trimmingCharacters(in: .whitespacesAndNewlines))) }
                    .buttonStyle(.bordered)
                    .disabled(customAnchor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct SealCompletionView: View {
    @EnvironmentObject private var model: AppModel
    @AppStorage("parent-sharing-enabled") private var sharingEnabled = true
    let record: DailySealRecord
    let finish: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.cinnabar)
                .accessibilityHidden(true)
            Text("今日已落印").font(.largeTitle.bold())
            Text("完成 \(record.targetCount) 個字，答對 \(record.correctCount) 個。")
                .font(.title3)
            Text(record.correctCount == record.targetCount
                 ? "墨跡已成，今天可以安心收卷。"
                 : "不熟的字已留下記號，下次會再回來。今天可以安心收卷。")
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 6) {
                Text("今天記住的證據：\(rememberedEvidence)")
                Text("下次會回來的字：\(returningCharacter)")
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)
            if sharingEnabled {
                ShareLink(item: "我今天在六書造字堂破解了 \(record.plannedCharacterIDs.compactMap(character).joined(separator: "、"))，練習用具體證據判斷漢字。分享內容不含姓名、班級與分數。") {
                    Label("分享今天的新發現", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
            }
            Button("收卷離開", action: finish)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(28)
        .background(.background, in: RoundedRectangle(cornerRadius: 28))
        .accessibilityElement(children: .contain)
    }

    private var rememberedEvidence: String {
        guard let id = record.correctCharacterIDs.first,
              let entry = model.characters.first(where: { $0.id == id }) else { return "錯題已標記，下一次會再找線索。" }
        return entry.explain.split(separator: "。").first.map(String.init) ?? entry.explain
    }

    private var returningCharacter: String {
        let missed = record.plannedCharacterIDs.first { !record.correctCharacterIDs.contains($0) }
        return missed.flatMap(character) ?? record.plannedCharacterIDs.last.flatMap(character) ?? "依排程再見"
    }

    private func character(_ id: String) -> String? { model.characters.first { $0.id == id }?.char }
}

struct InkDryView: View {
    @EnvironmentObject private var model: AppModel
    let finish: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.cinnabar)
                .accessibilityHidden(true)
            Text("墨乾時刻").font(.largeTitle.bold())
            Text("今天已到 \(Int(model.usageStopSeconds / 60)) 分鐘健康停點。手上的字可以寫完，接著讓記憶慢慢沉澱。")
                .multilineTextAlignment(.center)
            Button("今日收卷", action: finish)
                .buttonStyle(.borderedProminent)
        }
        .padding(28)
        .background(.background, in: RoundedRectangle(cornerRadius: 28))
    }
}
