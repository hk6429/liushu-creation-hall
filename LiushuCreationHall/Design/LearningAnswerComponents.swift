import SwiftUI

struct MethodAnswerGrid<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ViewBuilder let content: () -> Content

    var body: some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(), spacing: 12),
                count: horizontalSizeClass == .regular ? 3 : 2
            ),
            spacing: 12,
            content: content
        )
    }
}

struct LearningFeedbackCard: View {
    let feedback: AnswerFeedback
    var evidenceCorrect: Bool? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(
                feedback.isCorrect ? "判得好！" : "漏看的線索：\(feedback.correctMethod.evidenceLens)",
                systemImage: feedback.isCorrect ? "checkmark.seal.fill" : "lightbulb.fill"
            )
            .font(.title3.bold())
            .foregroundStyle(feedback.isCorrect ? AppTheme.jade : AppTheme.cinnabar)

            Text("字形標註：\(feedback.correctMethod.annotationGuide)")
                .font(.headline)
            if let evidenceCorrect {
                Text(evidenceCorrect ? "證據判斷正確" : "證據尚未成立；這次算補救，不算未提示精熟")
                    .font(.subheadline.bold())
            }
            Text("本題答案：\(feedback.correctMethod.rawValue)")
                .font(.headline)
            Text(feedback.explanation)
                .lineSpacing(5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(feedback.isCorrect ? AppTheme.jade : AppTheme.cinnabar, lineWidth: 2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("learning-feedback")
    }
}

private extension CreationMethod {
    var evidenceLens: String {
        switch self {
        case .pictograph: "古字形是否描出物體輪廓"
        case .indicative: "指示符號落在哪個位置"
        case .associative: "各部件如何共同表意"
        case .phonoSemantic: "哪邊表義、哪邊提示讀音"
        case .derivative: "兩個近義字如何彼此訓釋"
        case .phoneticLoan: "本義與借義是否因聲音相連"
        }
    }

    var annotationGuide: String {
        switch self {
        case .pictograph: "沿外形找輪廓，不只看今天的楷書筆畫。"
        case .indicative: "圈出基礎形體，再找額外的短畫或位置記號。"
        case .associative: "分開圈出兩個表意部件，再合讀整體意思。"
        case .phonoSemantic: "以形符標義、聲符標音，兩者都要指出。"
        case .derivative: "把關係字並列，畫出近義互訓的雙向箭頭。"
        case .phoneticLoan: "把本義詞例與借義詞例分列，用讀音連線。"
        }
    }
}
