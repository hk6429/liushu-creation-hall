# Web → iOS 內容與行為契約

## 來源

- Web repository：`/Users/naichengchen/projects/liushu-quest`
- 唯一字例來源：`data/chars.json`（由 shards 建立）
- 概念導讀：`js/concept.js`
- 造字故事：`js/story.js`
- 字例與教學圖片：`img/`

`Scripts/import-web-content.mjs` 會將來源 commit SHA 寫入 App bundle 的 `learning-library.json`，使每次移植可追溯。

## 必須保留的學術契約

1. 精確包含 220 個穩定 ID 字例，不由 iOS 端重新推斷分類。
2. `formation_category` 是構形軸；`usage_relations` 是用字關係軸，不得壓成單一無條件標籤。
3. 轉注與假借問題必須明說「用字關係」；象形、指事、會意、形聲問「構形方式」。
4. `disputed: true` 必須顯示爭議說明，且一般模式不把它當作無條件唯一正解。
5. 保留注音、難度、次分類、《說文》核對狀態、來源與教學解說。
6. 學生前台不將「待核」文字假裝成已核對直接引文。

## 原生交互契約

- 字庫：可依六書、難度與單字搜尋 220 字，點開後顯示移植的圖像與完整解說。
- 概念與故事：以 SwiftUI 原生導覽呈現，不使用 `WKWebView`。
- 自測：第一個原生版本每輪 10 題，至少覆蓋六書各一題，並用移植的字例解說作即時回饋。
- 離線：教材、題庫、圖片與進度全部保留本機。
- 進度：本機保存，終止 App 再開後恢復。

## 分期邊界

第一個可試玩版先完成全部內容、字庫與均衡自測。Web 版 Leitner 5 盒、八卷通關、大師對戰、課堂共學、家長模式、匯出匯入與問題回報列為後續原生功能，不以靜態畫面假裝已完成。
