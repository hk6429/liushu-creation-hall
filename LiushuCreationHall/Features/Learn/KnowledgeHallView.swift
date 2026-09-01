import SwiftUI

struct KnowledgeHallView: View {
    private let columns = [GridItem(.adaptive(minimum: 280), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(CreationMethod.allCases) { method in
                    NavigationLink(value: method) {
                        MethodCard(method: method)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .frame(maxWidth: 1000)
            .frame(maxWidth: .infinity)
        }
        .background(InkBackground())
        .navigationTitle("六書知識館")
        .navigationDestination(for: CreationMethod.self) { method in
            MethodDetailView(method: method)
        }
    }
}

private struct MethodCard: View {
    let method: CreationMethod

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: method.systemImage)
                .font(.title.bold())
                .foregroundStyle(.white)
                .frame(width: 62, height: 62)
                .background(AppTheme.color(for: method), in: RoundedRectangle(cornerRadius: 18))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(method.rawValue)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                Text(method.shortDefinition)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.primary)
                .accessibilityHidden(true)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 104)
        .background(.background, in: RoundedRectangle(cornerRadius: 22))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppTheme.color(for: method))
                .frame(height: 5)
                .clipShape(.rect(bottomLeadingRadius: 22, bottomTrailingRadius: 22))
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("點入查看完整說明")
    }
}

private struct MethodDetailView: View {
    let method: CreationMethod

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 18) {
                    Image(systemName: method.systemImage)
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                        .frame(width: 86, height: 86)
                        .background(AppTheme.color(for: method), in: RoundedRectangle(cornerRadius: 24))
                    VStack(alignment: .leading, spacing: 6) {
                        Text(method.rawValue)
                            .font(.largeTitle.bold())
                        Text(method.shortDefinition)
                            .font(.headline)
                    }
                }

                Text(method.detail)
                    .font(.title3)
                    .lineSpacing(7)

                Text("常見例子")
                    .font(.title2.bold())

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 14) {
                    ForEach(method.examples, id: \.self) { example in
                        Text(example)
                            .font(.system(size: 32, weight: .bold, design: .serif))
                            .frame(maxWidth: .infinity, minHeight: 76)
                            .background(AppTheme.color(for: method).opacity(0.14), in: RoundedRectangle(cornerRadius: 16))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppTheme.color(for: method), lineWidth: 2)
                            }
                    }
                }
            }
            .padding()
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .background(InkBackground())
        .navigationTitle(method.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }
}
