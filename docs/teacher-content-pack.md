# 教師 JSON 內容包

內容包由教師透過「紀錄→教師內容包」從檔案匯入，只存本機。App 不提供公開上架、市集、留言或學生身分追蹤。

## 驗證規則

- `schemaVersion` 必須為 `1`。
- `teacher`、`reviewedBy` 必須填寫，落實雙人複核責任；這不是網路身分憑證。
- 每筆 ID 必須以 `teacher-` 開頭，且不可與內建或同包內容重複。
- 不接受與內建字例重複的字、未知六書分類或 `disputed: true` 的定論題。
- 檔案上限 2 MB；JSON 不執行任何程式碼。

完整 `entries` 欄位沿用 `characters.json` 的 `CharacterEntry` 格式。內容責任仍由製作者與複核者承擔；App 的檢查只能保證結構與基本教學安全條件，不能取代文字學審訂。

