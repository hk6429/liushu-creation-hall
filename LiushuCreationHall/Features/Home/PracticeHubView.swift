import SwiftUI

struct PracticeHubView: View {
    @EnvironmentObject private var model: AppModel

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                DailySealCard()

                Text("選一條修行路線").font(.title2.bold())
                LazyVGrid(columns: columns, spacing: 12) {
                    route("主線旅程", "讀故事、過三題試煉", "map.fill") { JourneyView() }
                    route("弱點複習", weaknessText, "scope") {
                        FlashcardView(focusIDs: Array(model.progress.weakIDs.prefix(12)))
                    }
                    route("自主字陣", "今日固定 12 題進階挑戰", "square.grid.3x3.fill") {
                        JourneyTrialView(chapter: nil, dailyCount: 12)
                    }
                    route("大師對戰", "用辨形、尋聲、析義破招", "figure.fencing") { BattleView() }
                }

                NavigationLink {
                    ExhibitionHallView()
                } label: {
                    Label("走進永久展覽館", systemImage: "building.columns.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .frame(maxWidth: 850)
            .frame(maxWidth: .infinity)
        }
        .background(InkBackground())
        .navigationTitle("修行")
    }

    private var weaknessText: String {
        model.progress.weakIDs.isEmpty ? "從到期字開始穩固記憶" : "有 \(model.progress.weakIDs.count) 字適合再看"
    }

    private func route<Destination: View>(
        _ title: String,
        _ subtitle: String,
        _ symbol: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink(destination: destination()) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: symbol).font(.title2).foregroundStyle(AppTheme.cinnabar)
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
            .padding()
            .background(.background, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}

struct ExhibitionHallView: View {
    @EnvironmentObject private var model: AppModel

    private let exhibits: [(String, String, [String])] = [
        ("月字家族", "從月的輪廓出發，比較明、望等字的部件證據。特展永久保留，不必趕在節日前完成。", ["月", "明", "望"]),
        ("校園草木", "觀察木、林、森，以及帶木形符的字如何提示意義。", ["木", "林", "森"]),
        ("水邊尋聲", "比較江、河等形聲字的形符與聲符。", ["江", "河", "湖"])
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("所有特展結束後仍會留在這裡；沒有倒數、絕版或錯過懲罰。")
                    .padding().background(.background, in: RoundedRectangle(cornerRadius: 16))
                ForEach(exhibits, id: \.0) { exhibit in
                    let ids = model.characters.filter { exhibit.2.contains($0.char) }.map(\.id)
                    VStack(alignment: .leading, spacing: 10) {
                        Text(exhibit.0).font(.title2.bold())
                        Text(exhibit.2.joined(separator: "　")).font(.largeTitle.bold())
                        Text(exhibit.1)
                        NavigationLink("考察這組字") { FlashcardView(focusIDs: ids) }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding().frame(maxWidth: .infinity, alignment: .leading)
                    .background(.background, in: RoundedRectangle(cornerRadius: 20))
                }
            }
            .padding().frame(maxWidth: 800).frame(maxWidth: .infinity)
        }
        .background(InkBackground())
        .navigationTitle("永久展覽館")
    }
}
