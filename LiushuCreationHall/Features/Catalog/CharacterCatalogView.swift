import SwiftUI

struct CharacterCatalogView: View {
    @EnvironmentObject private var model: AppModel
    @State private var query = ""
    @State private var selectedMethod: CreationMethod?
    @State private var selectedLevel: String?

    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 12)]

    private var filteredCharacters: [CharacterEntry] {
        model.characters.filter { entry in
            (selectedMethod == nil || entry.category == selectedMethod?.rawValue)
                && (selectedLevel == nil || entry.level == selectedLevel)
                && (query.isEmpty || entry.char.contains(query) || entry.zhuyin.contains(query))
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                filters
                Text("找到 \(filteredCharacters.count) 字")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(filteredCharacters) { entry in
                        NavigationLink {
                            CharacterDetailView(entry: entry)
                        } label: {
                            CharacterTile(entry: entry)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
            .frame(maxWidth: 1000)
            .frame(maxWidth: .infinity)
        }
        .background(InkBackground())
        .navigationTitle("字例總覽・220 字")
        .searchable(text: $query, prompt: "搜尋單字或注音")
    }

    private var filters: some View {
        HStack {
            Menu {
                Button("全部書類") { selectedMethod = nil }
                ForEach(CreationMethod.allCases) { method in
                    Button(method.rawValue) { selectedMethod = method }
                }
            } label: {
                Label(selectedMethod?.rawValue ?? "全部書類", systemImage: "line.3.horizontal.decrease.circle")
            }
            .buttonStyle(.bordered)

            Menu {
                Button("全部難度") { selectedLevel = nil }
                ForEach(["基礎", "進階", "挑戰"], id: \.self) { level in
                    Button(level) { selectedLevel = level }
                }
            } label: {
                Label(selectedLevel ?? "全部難度", systemImage: "gauge.with.dots.needle.33percent")
            }
            .buttonStyle(.bordered)
            Spacer()
        }
    }
}

private struct CharacterTile: View {
    let entry: CharacterEntry

    var body: some View {
        VStack(spacing: 7) {
            Text(entry.char)
                .font(.system(size: 42, weight: .bold, design: .serif))
            Text(entry.zhuyin)
                .font(.caption)
            Text(entry.category)
                .font(.caption2.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((entry.method.map { AppTheme.color(for: $0) } ?? AppTheme.cinnabar).opacity(0.16), in: Capsule())
        }
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity, minHeight: 116)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(entry.method.map { AppTheme.color(for: $0) } ?? AppTheme.cinnabar, lineWidth: 2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.char)，\(entry.zhuyin)，\(entry.category)")
        .accessibilityHint("點入查看字例解說")
    }
}

private struct CharacterDetailView: View {
    let entry: CharacterEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                BundledImageView(resourceName: entry.id)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .accessibilityLabel("\(entry.char)的字形與本義教學情境圖")

                HStack(alignment: .firstTextBaseline, spacing: 14) {
                    Text(entry.char)
                        .font(.system(size: 64, weight: .black, design: .serif))
                    VStack(alignment: .leading) {
                        Text(entry.zhuyin).font(.title3)
                        Text("\(entry.category) ・ \(entry.level)")
                            .font(.headline)
                    }
                }

                if entry.disputed {
                    Label("歸類有爭議", systemImage: "bolt.trianglebadge.exclamationmark.fill")
                        .font(.headline)
                        .foregroundStyle(AppTheme.cinnabar)
                    Text(entry.disputeNote)
                        .font(.body)
                }

                ContentBlock(title: "教學解說", body: entry.explain)

                if !entry.shuowen.isEmpty {
                    ContentBlock(
                        title: "《說文解字》節錄・\(entry.shuowenStatus)",
                        body: entry.shuowen
                    )
                }

                ContentBlock(
                    title: "分類軸線",
                    body: "主類：\(entry.category)（\(entry.classificationScope)）\n構形軸：\(entry.formationCategory)"
                )

                ForEach(Array(entry.usageRelations.enumerated()), id: \.offset) { _, relation in
                    ContentBlock(
                        title: "\(relation.type)用字關係",
                        body: relation.note
                    )
                }
            }
            .padding()
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .background(InkBackground())
        .navigationTitle(entry.char)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ContentBlock: View {
    let title: String
    let text: String

    init(title: String, body: String) {
        self.title = title
        self.text = body
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Text(text)
                .font(.body)
                .lineSpacing(6)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
    }
}
