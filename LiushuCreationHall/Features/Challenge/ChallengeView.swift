import SwiftUI

struct ChallengeView: View {
    @EnvironmentObject private var model: AppModel
    @State private var currentIndex = 0
    @State private var selectedMethod: CreationMethod?
    @State private var selectedEvidence: CreationMethod?
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
                Text(question.prompt)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                Text("線索：\(question.clue)")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130))], spacing: 12) {
                ForEach(CreationMethod.allCases) { method in
                    answerButton(method, question: question)
                }
            }

            if let feedback {
                FeedbackCard(feedback: feedback)
                    .transition(.move(edge: .bottom).combined(with: .opacity))

                EvidenceCheckView(method: feedback.correctMethod, selected: $selectedEvidence) { correct in
                    model.recordRationale(questionID: feedback.questionID, method: feedback.correctMethod, correct: correct)
                }

                Button(currentIndex == model.questions.count - 1 ? "查看成績" : "下一題") {
                    moveToNextQuestion()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(selectedEvidence == nil)
                .accessibilityHint("繼續判斷下一個字")
            }
        }
        .animation(.snappy, value: feedback)
    }

    private func answerButton(
        _ method: CreationMethod,
        question: CharacterQuestion
    ) -> some View {
        Button {
            guard feedback == nil else { return }
            selectedMethod = method
            let result = QuizEngine.evaluate(question: question, answer: method)
            feedback = result
            if result.isCorrect { sessionCorrect += 1 }
            model.record(result)
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
        .disabled(feedback != nil)
        .accessibilityHint(feedback == nil ? "選擇\(method.rawValue)" : "")
    }

    private func buttonTint(for method: CreationMethod) -> Color {
        guard let feedback else { return AppTheme.color(for: method) }
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
        selectedEvidence = nil
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
            Button("再闖一輪") {
                model.startNewQuiz()
                currentIndex = 0
                selectedMethod = nil
                selectedEvidence = nil
                feedback = nil
                sessionCorrect = 0
                isComplete = false
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(28)
        .background(.background, in: RoundedRectangle(cornerRadius: 28))
        .accessibilityElement(children: .combine)
    }
}

private struct FeedbackCard: View {
    let feedback: AnswerFeedback

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(
                feedback.isCorrect ? "判得好！" : "再看一眼字的線索",
                systemImage: feedback.isCorrect ? "checkmark.seal.fill" : "lightbulb.fill"
            )
            .font(.title3.bold())
            .foregroundStyle(feedback.isCorrect ? AppTheme.jade : AppTheme.cinnabar)

            Text("正確答案：\(feedback.correctMethod.rawValue)")
                .font(.headline)
            Text(feedback.explanation)
                .font(.body)
                .lineSpacing(5)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(feedback.isCorrect ? AppTheme.jade : AppTheme.cinnabar, lineWidth: 2)
        }
        .accessibilityElement(children: .combine)
    }
}
