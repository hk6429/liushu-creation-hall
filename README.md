# 六書造字堂

面向國中學生的原生 SwiftUI 六書學習 App，由「六書造字堂」網頁版完整移植。教材、學習遊戲、課堂共學、家庭陪學與進度備份皆以原生 iPhone／iPad 介面重建，不使用 `WKWebView`。

## 目前功能

- 一日一印：每日 5 個不重複字例、一字開卷、七日入堂與三印成週；答錯仍保留練習進度，但不灌高掌握度。
- 低壓復歸：缺席 3–6 天用一字重新落筆，7 天以上用三字暖身，所有歷史進度永久保留。
- 墨乾時刻：前景使用 15 分鐘提醒、20 分鐘停止開新題，可完成手上題目後安心收卷。
- 六書導讀：18 篇概念內容與 9 篇造字故事。
- 220 字完整字庫：支援搜尋、六書分類、難度篩選與字例詳情。
- 自適應判字闖關：弱點字優先，加入分類與造字證據雙重判斷。
- 三級適性挑戰：辨六書、找逐字證據、比較近似字；連錯會恢復鷹架。
- Leitner 五盒閃卡、每日固定 12 題、每日五題與八卷故事試煉。
- 八位文字學人物 PvE 對戰，以辨形、尋聲、析義形成證據連鎖；拜帖可先開練習戰。
- 有效精熟採跨日證據：同字至少答對 3 次、分布 2 天、包含延宕答對與理由辨認。
- 課堂共學：匿名初答、理由討論、修正作答、證據牆與中途續接。
- 學習統計、弱點複習、六書印記、家長 10 分鐘陪學與大字模式。
- 故事／證據／跨日保留三軌、個人上週能力圖、證據收藏冊與永久節氣展覽館。
- 經教師及複核者標記的本機 JSON 內容包；家長可縮短健康停點、關閉分享與特效。
- 與網頁版相容的 JSON 匯出／匯入、每日成果分享與問題回報。
- 全程離線可用，不收集學生個資。
- iPhone 與 iPad 自適應版面、Dynamic Type 與 VoiceOver 標籤。

## 開發環境

- Xcode 26.6
- SwiftUI
- iOS / iPadOS 17+
- XcodeGen 2.46+

## 啟動

```sh
xcodegen
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
- `Features/`：首頁、導讀、字庫、闖關、旅程、閃卡、對戰、教室、家長與統計。
- `Resources/WebContent/`：從網頁版匯入的 JSON 與教學圖片。
- `Scripts/import-web-content.mjs`：可重複執行的網頁內容匯入工具。
- `project.yml`：XcodeGen 單一專案來源。

## 資料與隱私

App 沒有帳號或分析 SDK。學習進度僅儲存在 App 的 Application Support 目錄；跨裝置使用由使用者主動匯出／匯入 JSON，App 不會自行上傳學生資料。問題回報只有在使用者按下送出後才連線，且畫面明示不填姓名或個資。

## 網頁版功能移植範圍

第二階段已完成網頁版核心功能的原生移植，包括 Leitner 複習、旅程、每日挑戰、大師對戰、課堂共學、家長陪學、學習統計、問題回報與網頁版 JSON 備份相容。詳細契約見 `docs/content-contract.md`。

五位專家提出的 50 項設計評審已逐項實作並建立證據矩陣，見 `docs/review-implementation-matrix.md`；無障礙回歸見 `docs/accessibility-checklist.md`，教師內容包格式見 `docs/teacher-content-pack.md`。

## 發布前待辦

- 真機測試、簽章、Archive、TestFlight 與 App Store 審核。
- 轉注與假借在學界與教材中有不同釋例；本版使用常見國中教材說法，並在解析標示語境與傳統通例。
