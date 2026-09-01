import SwiftUI

struct ParentGuideView: View {
    @EnvironmentObject private var model: AppModel
    @AppStorage("parent-reading-large") private var useLargeReading = false
    @State private var timerEnd: Date?

    private var summary: String {
        let seen = model.progress.cards.values.filter { $0.seen > 0 }.count
        let mastered = model.progress.masteredIDs.count
        let weak = model.progress.weakIDs.count
        if seen == 0 { return "尚未開始；全站共有 220 字，不需要一次學完。先共讀一段故事就很好。" }
        if weak > 0 { return "已接觸 \(seen) 字、有效精通 \(mastered) 字；有 \(weak) 字適合再看一次。" }
        return "已接觸 \(seen) 字、有效精通 \(mastered) 字；今天維持短時間練習即可。"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                guideSection("今天怎麼陪？") { Text(summary) }
                guideSection("10 分鐘三步驟") {
                    Text("1. 共讀一小段，不急著講答案。\n2. 請孩子挑 3–5 個字，說出『怎麼看出來』。\n3. 最後只問：『哪個地方想明天再試一次？』")
                }
                guideSection("可以這樣問") {
                    Text("• 你先看到了哪個部件？\n• 這是字形構造，還是後來的用字關係？\n• 如果分類有爭議，兩種說法各根據什麼？")
                }
                guideSection("低壓力回饋") {
                    Text("先描述策略，例如：『你有找到聲符線索。』再談答案。App 不做公開排名；答錯只用來安排下次複習。")
                }
                guideSection("閱讀與休息工具") {
                    Toggle("放大閱讀字級", isOn: $useLargeReading)
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Text(timerText(now: context.date)).font(.headline.monospacedDigit())
                    }
                    Button(timerEnd == nil ? "開始 10 分鐘陪學" : "重新計時") { timerEnd = .now.addingTimeInterval(600) }
                        .buttonStyle(.borderedProminent)
                }
                guideSection("資料界線") {
                    Text("進度預設只存在這台裝置，不輸入姓名，也沒有公開排名。換裝置時由使用者主動匯出與匯入 JSON 備份。")
                }
            }
            .padding()
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .background(InkBackground())
        .navigationTitle("家長陪學")
    }

    private func guideSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) { Text(title).font(.title2.bold()); content() }
            .padding().frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }

    private func timerText(now: Date) -> String {
        guard let timerEnd else { return "尚未計時" }
        let seconds = max(0, Int(ceil(timerEnd.timeIntervalSince(now))))
        if seconds == 0 { return "10 分鐘到了：看看遠方、喝口水，今天學到這裡也很好。" }
        return "剩下 \(seconds / 60):\(String(format: "%02d", seconds % 60))"
    }
}
