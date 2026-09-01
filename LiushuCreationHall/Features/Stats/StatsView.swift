import SwiftUI
import UniformTypeIdentifiers

struct StatsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var exportDocument = ProgressDocument()
    @State private var status = ""
    @State private var showResetConfirmation = false

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                LazyVGrid(columns: columns, spacing: 12) {
                    metric("有效精通", "\(model.progress.masteredIDs.count)／220", "seal.fill")
                    metric("累計答題", "\(model.progress.totalAttempts)", "list.number")
                    metric("總正確率", model.progress.totalAttempts == 0 ? "—" : model.progress.accuracy.formatted(.percent.precision(.fractionLength(0))), "scope")
                    metric("擊敗大師", "\(model.progress.battle.beaten.values.reduce(0, +)) 次", "trophy.fill")
                }

                section("各模式正確率") {
                    ForEach(PracticeMode.allCases) { mode in
                        let bucket = model.progress.byMode[mode, default: ScoreBucket()]
                        scoreRow(mode.title, bucket: bucket)
                    }
                }

                section("六書分類正確率") {
                    ForEach(CreationMethod.allCases) { method in
                        scoreRow(method.rawValue, bucket: model.progress.byCategory[method.rawValue, default: ScoreBucket()])
                    }
                }

                section("弱點字・優先複習") {
                    if model.progress.weakIDs.isEmpty {
                        Text("目前沒有弱點字。完成自測、旅程或對戰後，系統會自動整理。")
                    } else {
                        Text(model.progress.weakIDs.prefix(30).compactMap { id in model.characters.first(where: { $0.id == id })?.char }.joined(separator: "　"))
                            .font(.title2.bold())
                    }
                    NavigationLink("立即開啟閃卡複習") { FlashcardView() }.buttonStyle(.borderedProminent)
                }

                section("六書印譜") {
                    if model.progress.badges.isEmpty { Text("完成真實學習成果後，印記會出現在這裡。") }
                    else { Text(model.progress.badges.keys.sorted().map { "🏮 \(badgeTitle($0))" }.joined(separator: "　")) }
                }

                section("家庭與支援") {
                    NavigationLink("家長陪學指南") { ParentGuideView() }.buttonStyle(.bordered)
                    NavigationLink("問題回報") { ProblemReportView(contextTitle: "學習紀錄") }.buttonStyle(.bordered)
                }

                section("進度備份") {
                    Text("進度只存在本機。換裝置前請匯出 JSON，到新裝置再安全匯入。")
                    if !status.isEmpty { Text(status).font(.footnote).foregroundStyle(AppTheme.jade) }
                    HStack {
                        Button("匯出 JSON") { prepareExport() }.buttonStyle(.borderedProminent)
                        Button("匯入 JSON") { isImporting = true }.buttonStyle(.bordered)
                    }
                    Button("全部重置", role: .destructive) { showResetConfirmation = true }
                }
            }
            .padding()
            .frame(maxWidth: 850)
            .frame(maxWidth: .infinity)
        }
        .background(InkBackground())
        .navigationTitle("學習紀錄")
        .fileExporter(isPresented: $isExporting, document: exportDocument, contentType: .json, defaultFilename: "liushu-quest-\(LearningClock.dateKey())") { result in
            status = result.isSuccess ? "JSON 備份已匯出。" : "匯出失敗。"
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) { result in
            importFile(result)
        }
        .confirmationDialog("確定清空所有學習進度？", isPresented: $showResetConfirmation, titleVisibility: .visible) {
            Button("清空所有進度", role: .destructive) { model.resetProgress(); status = "進度已重置。" }
        }
    }

    private func metric(_ title: String, _ value: String, _ symbol: String) -> some View {
        VStack(spacing: 7) {
            Image(systemName: symbol).font(.title2).foregroundStyle(AppTheme.cinnabar)
            Text(value).font(.title2.bold())
            Text(title).font(.caption)
        }
        .frame(maxWidth: .infinity, minHeight: 110)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.title2.bold())
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }

    private func scoreRow(_ title: String, bucket: ScoreBucket) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(bucket.total == 0 ? "—" : "\(bucket.accuracy.formatted(.percent.precision(.fractionLength(0))))（\(bucket.total) 題）")
                .font(.subheadline.bold())
        }
    }

    private func prepareExport() {
        do { exportDocument = ProgressDocument(data: try model.exportProgress()); isExporting = true }
        catch { status = "無法建立備份：\(error.localizedDescription)" }
    }

    private func importFile(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            try model.importProgress(from: Data(contentsOf: url))
            status = "進度已安全匯入。"
        } catch { status = "匯入失敗：\(error.localizedDescription)" }
    }

    private func badgeTitle(_ id: String) -> String {
        if id == "first-quiz" { return "初試啼聲" }
        if id == "perfect-ten" { return "十連精準" }
        if id.hasPrefix("cat-") { return "\(id.dropFirst(4))印記" }
        if id.hasPrefix("master-") {
            let masterID = String(id.dropFirst(7))
            return MasterDefinition.all.first(where: { $0.id == masterID }).map { "擊敗\($0.name)" } ?? "大師認可"
        }
        if id == "all-chars" { return "六書宗師" }
        return id
    }
}

private extension Result {
    var isSuccess: Bool { if case .success = self { true } else { false } }
}
