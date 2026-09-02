import SwiftUI

struct EvidenceCheckView: View {
    let prompt: EvidencePrompt
    @Binding var selectedID: String?
    let onAnswer: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(prompt.question)
                .font(.headline)
            ForEach(prompt.choices) { option in
                Button {
                    guard selectedID == nil else { return }
                    selectedID = option.id
                    onAnswer(option.id == prompt.correctChoiceID)
                } label: {
                    HStack {
                        Text(option.text)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        if selectedID != nil, option.id == prompt.correctChoiceID {
                            Label("正確證據", systemImage: "checkmark.circle.fill")
                                .labelStyle(.iconOnly)
                                .accessibilityLabel("正確證據")
                        } else if selectedID == option.id {
                            Label("你的選擇不正確", systemImage: "xmark.circle.fill")
                                .labelStyle(.iconOnly)
                                .accessibilityLabel("你的選擇不正確")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
                .tint(tint(for: option.id))
                .disabled(selectedID != nil)
                .accessibilityIdentifier("evidence-choice-\(option.id)")
            }
            if let selectedID {
                Text(selectedID == prompt.correctChoiceID ? "證據判斷正確。" : "請比較紅色錯選與綠色正確證據。")
                    .font(.subheadline.bold())
                    .foregroundStyle(selectedID == prompt.correctChoiceID ? AppTheme.jade : AppTheme.cinnabar)
                    .accessibilityFocused($resultFocused)
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .onChange(of: selectedID) { _, value in
            if value != nil { resultFocused = true }
        }
    }

    @AccessibilityFocusState private var resultFocused: Bool

    private func tint(for optionID: String) -> Color {
        guard let selectedID else { return AppTheme.cinnabar }
        if optionID == prompt.correctChoiceID { return AppTheme.jade }
        if optionID == selectedID { return AppTheme.cinnabar }
        return .primary
    }
}
