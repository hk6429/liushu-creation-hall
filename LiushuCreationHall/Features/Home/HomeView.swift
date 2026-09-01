import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var model: AppModel

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 14)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                hero
                progressSection
                methodGrid
            }
            .padding()
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .background(InkBackground())
        .navigationTitle("六書造字堂")
    }

    private var hero: some View {
        HStack(spacing: 18) {
            Text("字")
                .font(.system(size: 56, weight: .black, design: .serif))
                .foregroundStyle(.white)
                .frame(width: 92, height: 92)
                .background(AppTheme.cinnabar, in: RoundedRectangle(cornerRadius: 24))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 7) {
                Text("看懂漢字，像看見古人留下的密碼。")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                Text("從字形、字音到字義，一起走進六書的世界。")
                    .font(.body)
                    .foregroundStyle(.primary)
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28))
        .accessibilityElement(children: .combine)
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("我的學習卷")
                .font(.title2.bold())

            LazyVGrid(columns: columns, spacing: 12) {
                ProgressTile(
                    title: "已探索",
                    value: "\(model.progress.completedQuestionIDs.count) 題",
                    symbol: "checkmark.seal.fill"
                )
                ProgressTile(
                    title: "正確率",
                    value: model.progress.totalAttempts == 0
                        ? "尚未開始"
                        : model.progress.accuracy.formatted(.percent.precision(.fractionLength(0))),
                    symbol: "scope"
                )
                ProgressTile(
                    title: "最佳連續",
                    value: "\(model.progress.bestStreak) 題",
                    symbol: "flame.fill"
                )
            }
        }
    }

    private var methodGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("六書六扇門")
                .font(.title2.bold())

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(CreationMethod.allCases) { method in
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: method.systemImage)
                            .font(.title2.bold())
                            .foregroundStyle(AppTheme.color(for: method))
                        Text(method.rawValue)
                            .font(.headline)
                        Text(method.shortDefinition)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
                    .padding()
                    .background(.background, in: RoundedRectangle(cornerRadius: 18))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(AppTheme.color(for: method), lineWidth: 2)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}

private struct ProgressTile: View {
    let title: String
    let value: String
    let symbol: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(AppTheme.cinnabar)
                .accessibilityHidden(true)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption.bold())
                Text(value)
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }
}
