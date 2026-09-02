# 一日一印實作計畫

## 目標

依已核可的設計規格，在既有 local-first SwiftUI App 中加入可重開、可測試、向下相容的一日一印完整流程。

## 切片

1. **Domain 與相容性**
   - 新增習慣進度、每日印記、七日入堂與使用時間模型。
   - `LearningProgress` schema 升為 3，舊 schema 仍能解碼。
   - 建立台北日期／曆週工具與可重現的 `DailySealPlanner`。
   - 先以單元測試驗證唯一題、復歸門檻、週進度及錯題判定。

2. **AppModel 場次控制**
   - 建立或恢復今日方案。
   - 首次提交才記錄作答，錯題不增加掌握度。
   - 完成後更新日印、七日與每週進度。
   - 實作前景計時、15 分鐘提醒與 20 分鐘作答鎖定。

3. **SwiftUI 垂直切片**
   - 首頁新增最高優先的 `DailySealCard` 與 `WeeklySealStrip`。
   - 新增 `DailySealSessionView`、題目、完成、七日引導與墨乾收尾畫面。
   - 支援復歸一字／三字路徑、Dynamic Type、VoiceOver 與減少動態效果。

4. **匯出、匯入與驗收**
   - Web 備份加入 `nativeHabit`，維持沒有該欄位的舊備份相容。
   - 增補單元測試與 UI smoke 路徑。
   - 產生 Xcode 專案、執行 build／tests，修正後再做模擬器試玩驗收。

## 完成定義

- 已核可設計規格的 12 項資料測試與主要 UI 路徑通過。
- iPhone 與 iPad 均可建置，App 可在同日關閉再開後繼續場次。
- 20 分鐘後不能開始新題，但可以完成手上題目。
- Git 工作樹只包含本功能必要修改，README 補上玩法與測試方式，提交並推送 GitHub。
