import SwiftUI

enum AppTheme {
    static let cinnabar = Color(red: 0.72, green: 0.12, blue: 0.10)
    static let ink = Color(red: 0.10, green: 0.09, blue: 0.08)
    static let parchment = Color(red: 0.97, green: 0.92, blue: 0.80)
    static let jade = Color(red: 0.06, green: 0.46, blue: 0.34)

    static func color(for method: CreationMethod) -> Color {
        switch method {
        case .pictograph: Color(red: 0.74, green: 0.22, blue: 0.16)
        case .indicative: Color(red: 0.84, green: 0.48, blue: 0.08)
        case .associative: Color(red: 0.08, green: 0.50, blue: 0.36)
        case .phonoSemantic: Color(red: 0.08, green: 0.38, blue: 0.68)
        case .derivative: Color(red: 0.45, green: 0.24, blue: 0.67)
        case .phoneticLoan: Color(red: 0.66, green: 0.18, blue: 0.43)
        }
    }
}

struct InkBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                AppTheme.parchment.opacity(0.82),
                Color(uiColor: .systemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
