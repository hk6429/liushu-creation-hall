import SwiftUI

struct ProblemReportView: View {
    let contextTitle: String
    @State private var issueType = "classification"
    @State private var note = ""
    @State private var status = ""
    @State private var isSending = false

    private let types = [
        ("classification", "字例分類或文字學內容"), ("pronunciation", "注音或讀音"),
        ("question", "題目、選項或答案"), ("story", "故事或教學說明"),
        ("interface", "介面或功能異常"), ("accessibility", "閱讀或無障礙問題"), ("other", "其他問題")
    ]

    var body: some View {
        Form {
            Section("直接送給大乃老師") {
                Text("系統只會附上目前功能名稱。請勿填寫姓名、班級或其他個人資料。")
                Picker("問題類型", selection: $issueType) {
                    ForEach(types, id: \.0) { Text($0.1).tag($0.0) }
                }
                TextField("請描述問題（5–800 字）", text: $note, axis: .vertical)
                    .lineLimit(5...12)
            }
            Section {
                Button(isSending ? "傳送中……" : "送出回報") {
                    Task { await send() }
                }
                .disabled(isSending || note.trimmingCharacters(in: .whitespacesAndNewlines).count < 5 || note.count > 800)
                if !status.isEmpty { Text(status) }
            }
        }
        .navigationTitle("問題回報")
    }

    @MainActor
    private func send() async {
        isSending = true
        defer { isSending = false }
        do {
            var request = URLRequest(url: URL(string: "https://liushu-quest.pages.dev/api/report")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "issueType": issueType,
                "note": note.trimmingCharacters(in: .whitespacesAndNewlines),
                "website": "",
                "context": ["view": "ios", "title": contextTitle, "path": "native-ios"],
                "reportId": "liushu-ios-\(UUID().uuidString.lowercased())"
            ])
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw URLError(.badServerResponse) }
            status = "已送出，謝謝你幫忙把六書造字堂變得更好。"
            note = ""
        } catch {
            status = "暫時無法送出，請確認網路後再試。"
        }
    }
}
