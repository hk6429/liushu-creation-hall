import SwiftUI

struct EvidenceCheckView: View {
    let method: CreationMethod
    @Binding var selected: CreationMethod?
    let onAnswer: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("證據確認：為什麼屬於\(method.rawValue)？")
                .font(.headline)
            ForEach(CreationMethod.allCases) { option in
                Button {
                    guard selected == nil else { return }
                    selected = option
                    onAnswer(option == method)
                } label: {
                    HStack {
                        Text(option.evidenceLabel)
                        Spacer()
                        if selected != nil, option == method {
                            Image(systemName: "checkmark.circle.fill")
                        } else if selected == option {
                            Image(systemName: "xmark.circle.fill")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
                .tint(tint(for: option))
                .disabled(selected != nil)
            }
            if let selected {
                Text(selected == method ? "證據判斷正確。" : "正確證據：\(method.evidenceLabel)")
                    .font(.subheadline.bold())
                    .foregroundStyle(selected == method ? AppTheme.jade : AppTheme.cinnabar)
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }

    private func tint(for option: CreationMethod) -> Color {
        guard let selected else { return AppTheme.color(for: option) }
        if option == method { return AppTheme.jade }
        if option == selected { return AppTheme.cinnabar }
        return .secondary
    }
}
