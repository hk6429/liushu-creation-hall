import SwiftUI
import UniformTypeIdentifiers

struct StatsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var isImportingTeacherPack = false
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

                section("三軌成長") {
                    progressTrack("故事進度", value: model.progress.journey.completed.count, total: 8, note: "通過八卷故事試煉")
                    progressTrack("證據能力", value: model.progress.skillEvidence.values.filter { $0.unpromptedRationalePasses > 0 }.count, total: max(1, model.progress.completedQuestionIDs.count), note: "能在未提示時找出逐字證據")
                    progressTrack("跨日保留", value: model.progress.skillEvidence.values.filter { $0.delayedPasses > 0 }.count, total: max(1, model.progress.completedQuestionIDs.count), note: "至少隔 24 小時、換情境再答對")
                }

                section("我的能力圖・只和自己比") {
                    let current = model.progress.currentAbility
                    let previous = model.progress.previousWeekAbility()
                    abilityRow("判類", current.classification, previous?.classification)
                    abilityRow("證據", current.evidence, previous?.evidence)
                    abilityRow("軸線", current.axis, previous?.axis)
                    abilityRow("延宕", current.delayed, previous?.delayed)
                    abilityRow("修正", current.revision, previous?.revision)
                    Text(previous == nil ? "累積到下週後，這裡會顯示與自己上週的差異；不建立全班或全球排行榜。" : "箭頭只比較自己的上週快照。")
                        .font(.footnote)
                }

                section("各模式正確率") {
                    ForEach(PracticeMode.allCases) { mode in
                        let bucket = model.progress.byMode[mode, default: ScoreBucket()]
                        scoreRow(mode.title, bucket: bucket)
                    }
                }

                section("構形四類正確率") {
                    ForEach([CreationMethod.pictograph, .indicative, .associative, .phonoSemantic]) { method in
                        scoreRow(method.rawValue, bucket: model.progress.byCategory[method.rawValue, default: ScoreBucket()])
                    }
                }

                section("用字關係正確率") {
                    ForEach([CreationMethod.derivative, .phoneticLoan]) { method in
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
                    ForEach(CreationMethod.allCases) { method in
                        let count = model.progress.skillEvidence.filter { id, evidence in
                            evidence.category == method.rawValue && model.progress.masteredIDs.contains(id)
                        }.count
                        HStack {
                            Label("\(method.rawValue)印", systemImage: count >= 5 ? "checkmark.seal.fill" : "seal")
                            Spacer()
                            Text(count >= 5 ? "已取得" : "\(count)／5 字・再練 \(5 - count) 字")
                                .font(.subheadline.bold())
                        }
                        .foregroundStyle(count >= 5 ? AppTheme.jade : .primary)
                    }
                    NavigationLink("從弱點字開始磨印") {
                        FlashcardView(focusIDs: Array(model.progress.weakIDs.prefix(10)))
                    }
                    .buttonStyle(.bordered)
                }

                section("證據收藏冊") {
                    ForEach(JourneyChapter.all) { chapter in
                        let collected = model.progress.journey.completed[chapter.id] != nil
                        HStack {
                            Label(chapterArtifact(chapter.id), systemImage: collected ? "checkmark.seal.fill" : "seal")
                            Spacer()
                            Text(collected ? "可重看・\(chapter.characters.joined(separator: "、"))" : "通過〈\(chapter.title)〉取得")
                                .font(.caption)
                        }
                        .foregroundStyle(collected ? AppTheme.jade : .primary)
                    }
                    NavigationLink("前往旅程取得證據收藏") { JourneyView() }.buttonStyle(.bordered)
                }

                section("家庭與支援") {
                    NavigationLink("家長陪學指南") { ParentGuideView() }.buttonStyle(.bordered)
                    NavigationLink("問題回報") { ProblemReportView(contextTitle: "學習紀錄") }.buttonStyle(.bordered)
                }

                section("教師內容包") {
                    Text("只接受本機檔案匯入、具教師與複核者欄位的 JSON；不開放公開內容市場、按讚或陌生人留言。")
                    if let title = model.teacherPackTitle {
                        Text("已載入：\(title)").font(.headline).foregroundStyle(AppTheme.jade)
                        Button("移除內容包") { model.removeTeacherContentPack(); status = "教師內容包已移除。" }
                            .buttonStyle(.bordered)
                    }
                    Button("從檔案匯入教師內容包") { isImportingTeacherPack = true }
                        .buttonStyle(.borderedProminent)
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
        .fileImporter(isPresented: $isImportingTeacherPack, allowedContentTypes: [.json]) { result in
            importTeacherPack(result)
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
            Text(bucket.total == 0 ? "尚無資料" : bucket.total < 5 ? "累積 \(bucket.total) 題" : "\(bucket.accuracy.formatted(.percent.precision(.fractionLength(0))))（\(bucket.total) 題）")
                .font(.subheadline.bold())
        }
    }

    private func progressTrack(_ title: String, value: Int, total: Int, note: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack { Text(title).bold(); Spacer(); Text("\(value)／\(total)").monospacedDigit() }
            ProgressView(value: Double(value), total: Double(max(1, total))).tint(AppTheme.cinnabar)
            Text(note).font(.caption).foregroundStyle(.primary)
        }
    }

    private func abilityRow(_ title: String, _ current: Double, _ previous: Double?) -> some View {
        let delta = previous.map { current - $0 }
        return HStack {
            Text(title).frame(width: 54, alignment: .leading)
            ProgressView(value: min(1, current)).tint(AppTheme.cinnabar)
            Text(current.formatted(.percent.precision(.fractionLength(0))))
                .font(.subheadline.monospacedDigit()).frame(width: 45, alignment: .trailing)
            Text(delta.map { $0 > 0.005 ? "↑" : $0 < -0.005 ? "↓" : "＝" } ?? "—")
                .font(.headline).accessibilityLabel(delta == nil ? "尚無上週資料" : "與上週比較")
        }
    }

    private func chapterArtifact(_ chapter: Int) -> String {
        ["結繩札", "甲骨碎片", "指事墨點", "會意部件牌", "借音簡", "聲符牌", "互訓箋", "辨證卷"][chapter]
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

    private func importTeacherPack(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            try model.importTeacherContentPack(from: Data(contentsOf: url))
            status = "教師內容包已驗證並載入。"
        } catch { status = "內容包未載入：\(error.localizedDescription)" }
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
