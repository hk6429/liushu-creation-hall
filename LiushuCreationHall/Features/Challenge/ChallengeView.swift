import SwiftUI

struct ChallengeView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentIndex = 0
    @State private var selectedMethod: CreationMethod?
    @State private var selectedEvidenceID: String?
    @State private var feedback: AnswerFeedback?
    @State private var sessionCorrect = 0
    @State private var isComplete = false

    private var currentQuestion: CharacterQuestion? {
        guard model.questions.indices.contains(currentIndex) else { return nil }
        return model.questions[currentIndex]
    }

    var body: some View {
        ScrollView {
            Group {
                if model.questions.isEmpty {
                    ContentUnavailableView(
                        "題庫準備中",
                        systemImage: "character.book.closed",
                        description: Text("請稍後再試。")
                    )
                } else if isComplete {
                    completionCard
                } else if let question = currentQuestion {
                    questionCard(question)
                }
            }
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
            .padding()
        }
        .background(InkBackground())
        .navigationTitle("判字闖關")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Text("\(min(currentIndex + 1, model.questions.count)) / \(model.questions.count)")
                    .font(.headline.monospacedDigit())
                    .accessibilityLabel("第 \(min(currentIndex + 1, model.questions.count)) 題，共 \(model.questions.count) 題")
            }
        }
    }

    @ViewBuilder
    private func questionCard(_ question: CharacterQuestion) -> some View {
        let level = AdaptiveChallengeLevel.level(for: model.progress.skillEvidence[question.id])
        VStack(spacing: 20) {
            ProgressView(value: Double(currentIndex), total: Double(model.questions.count))
                .tint(AppTheme.cinnabar)

            Text(question.display)
                .font(.system(size: question.display.count > 2 ? 46 : 82, weight: .black, design: .serif))
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, minHeight: 130)
                .foregroundStyle(AppTheme.ink)
                .background(AppTheme.parchment, in: RoundedRectangle(cornerRadius: 28))
                .overlay {
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(AppTheme.cinnabar, lineWidth: 3)
                }
                .accessibilityLabel("題目：\(question.display)")

            VStack(spacing: 6) {
                Label(level.title, systemImage: level == .transfer ? "arrow.triangle.branch" : "scope")
                    .font(.headline)
                    .foregroundStyle(AppTheme.cinnabar)
                Text(question.prompt)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                if level == .classify {
                    Text("鷹架線索：\(question.clue)")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                } else if level == .transfer {
                    Text(transferPrompt(for: question))
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                }
            }

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
                    .transition(.move(edge: .bottom).combined(with: .opacity))

                Button(currentIndex == model.questions.count - 1 ? "查看成績" : "下一題") {
                    moveToNextQuestion()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityHint("繼續判斷下一個字")
            }
        }
        .animation(reduceMotion ? nil : .snappy, value: feedback)
    }

    private func transferPrompt(for question: CharacterQuestion) -> String {
        let partner = model.characters.first {
            $0.id != question.id && $0.category == question.correctMethod.rawValue && !$0.disputed
        }?.char ?? "另一個同類字"
        return "遷移比較：先想「\(question.display)」和「\(partner)」共用哪種證據，再作答。"
    }

    private func answerButton(
        _ method: CreationMethod,
        question: CharacterQuestion
    ) -> some View {
        Button {
            guard feedback == nil, selectedMethod == nil else { return }
            selectedMethod = method
            if question.evidencePrompt == nil { revealAnswer(question: question, evidenceCorrect: false) }
        } label: {
            HStack {
                Image(systemName: method.systemImage)
                    .accessibilityHidden(true)
                Text(method.rawValue)
                    .font(.headline)
                Spacer(minLength: 0)
                if let feedback, method == feedback.correctMethod {
                    Image(systemName: "checkmark.circle.fill")
                        .accessibilityLabel("正確答案")
                } else if let feedback, method == selectedMethod, !feedback.isCorrect {
                    Image(systemName: "xmark.circle.fill")
                        .accessibilityLabel("你選擇的答案不正確")
                }
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .padding(.horizontal, 14)
        }
        .buttonStyle(.bordered)
        .tint(buttonTint(for: method))
        .disabled(selectedMethod != nil)
        .accessibilityHint(feedback == nil ? "選擇\(method.rawValue)" : "")
    }

    private func buttonTint(for method: CreationMethod) -> Color {
        guard let feedback else {
            return method == selectedMethod ? AppTheme.cinnabar : AppTheme.color(for: method)
        }
        if method == feedback.correctMethod { return AppTheme.jade }
        if method == selectedMethod { return AppTheme.cinnabar }
        return .primary
    }

    private func moveToNextQuestion() {
        guard currentIndex < model.questions.count - 1 else {
            model.recordQuizSession(score: sessionCorrect, total: model.questions.count)
            isComplete = true
            return
        }
        currentIndex += 1
        selectedMethod = nil
        selectedEvidenceID = nil
        feedback = nil
    }

    private var completionCard: some View {
        VStack(spacing: 22) {
            Image(systemName: "scroll.fill")
                .font(.system(size: 58))
                .foregroundStyle(AppTheme.cinnabar)
                .accessibilityHidden(true)
            Text("字堂修業！")
                .font(.largeTitle.bold())
            Text("這一輪答對 \(sessionCorrect) / \(model.questions.count) 題")
                .font(.title2)
            Text("每一個字，都是古人留給我們的小小時光膠囊。")
                .font(.body)
                .multilineTextAlignment(.center)
            Button("今日收功") { dismiss() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            if model.canStartNewTask {
                Button("再闖一輪") {
                    model.startNewQuiz()
                    currentIndex = 0
                    selectedMethod = nil
                    selectedEvidenceID = nil
                    feedback = nil
                    sessionCorrect = 0
                    isComplete = false
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(28)
        .background(.background, in: RoundedRectangle(cornerRadius: 28))
        .accessibilityElement(children: .combine)
    }

    private func revealAnswer(question: CharacterQuestion, evidenceCorrect: Bool) {
        guard let selectedMethod, feedback == nil else { return }
        let result = QuizEngine.evaluate(question: question, answer: selectedMethod)
        feedback = result
        if result.isCorrect { sessionCorrect += 1 }
        model.record(result, rationale: evidenceCorrect && result.isCorrect)
    }
}
