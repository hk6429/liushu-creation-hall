# 六書造字堂

面向國中學生的原生 SwiftUI 六書學習 App，由「六書造字堂」網頁版移植。學生可閱讀六書觀念與造字故事、瀏覽完整字庫，並透過「看字判六書」闖關獲得即時解析。

## 目前功能

- 六書導讀：18 篇概念內容與 9 篇造字故事。
- 220 字完整字庫：支援搜尋、六書分類、難度篩選與字例詳情。
- 每回 10 題平衡判字闖關，涵蓋六類並排除有爭議、無法唯一作答的字例。
- 答題數、正確數、連續答對與已完成題目的本機保存。
- 全程離線可用，不收集學生個資。
- iPhone 與 iPad 自適應版面、Dynamic Type 與 VoiceOver 標籤。

## 開發環境

- Xcode 26.6
- SwiftUI
- iOS / iPadOS 17+
- XcodeGen 2.46+

## 啟動

```sh
xcodegen generate
open LiushuCreationHall.xcodeproj
```

或先列出目前可用的 Simulator，再用明確 UDID 建置：

```sh
xcrun simctl list devices available
xcodebuild -project LiushuCreationHall.xcodeproj \
  -scheme LiushuCreationHall \
  -destination 'platform=iOS Simulator,id=<SIMULATOR_UDID>' \
  build
```

## 專案結構

- `Domain/`：六書、字例、答題判定與進度模型。
- `Data/`：移植內容載入與 Application Support JSON 持久化。
- `Features/`：首頁、導讀、字庫與闖關畫面。
- `Resources/WebContent/`：從網頁版匯入的 JSON 與教學圖片。
- `Scripts/import-web-content.mjs`：可重複執行的網頁內容匯入工具。
- `project.yml`：XcodeGen 單一專案來源。

## 資料與隱私

第一版沒有帳號、分析 SDK 或雲端同步。學習進度僅儲存在 App 的 Application Support 目錄。

## 網頁版功能移植範圍

第一階段完成核心教學內容與可玩的原生學習流程。Leitner 複習排程、對戰、旅程、班級、家長檢視、資料匯出入與學習報告，列入後續階段；詳細契約見 `docs/content-contract.md`。

## 發布前待辦

- 真機測試、簽章、Archive、TestFlight 與 App Store 審核。
- 轉注與假借在學界與教材中有不同釋例；本版使用常見國中教材說法，並在解析標示語境與傳統通例。
