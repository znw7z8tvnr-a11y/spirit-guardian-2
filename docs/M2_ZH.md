# M2 繁體中文化

分支：`godot/m2-zh-hant`。沿用原 M2 試玩網址，原 HTML、原 GitHub Pages 入口與 main 均不替換。

已翻譯戰鬥介面、8種可操作法術名稱、19種寶石名稱與說明、自由連鎖圖、品質、匯入錯誤、暫停／速度／音效狀態、Boss名稱與階段、三選一獎勵／稀有度／鎖定／重抽及敗北訊息。法術及寶石名稱優先沿用附件資料。

資料儲存仍使用原有英文 ID；下拉選項顯示中文但透過 metadata 取得 ID。Godot 專案 config/name 維持原值，避免改變本機 user:// 存檔位置。只保存連鎖配置，尚不保存完整戰局。

內嵌 Noto Sans CJK TC 衍生的 Spirit Guardian TC 字型（206,152 bytes、419個所需字元），更名並按 SIL OFL 1.1 發布；授權與來源位於 godot/assets/fonts/。新增中文時需執行 tools/subset_zh_font.py 更新子集，--check 可驗證涵蓋率。

## 驗證

Godot 4.6.3 Compatibility：匯入、18項戰鬥、39項模組與21項中文化檢查均通過（78項）。檢查涵蓋實際字型指派／字元、中文動態狀態、下拉選項 ID、JSON 匯出匯入相容性、Boss、獎勵及敗北。

單執行緒 Web 匯出成功；Linux Chromium 軟體 WebGL、觸控模擬的橫向1180×820、直向820×1180測試：啟動、出怪、暫停／繼續、速度、選法術、連鎖新增／復原／重做、儲存配置與重新開始。紀錄與**實際遊戲截圖**見 docs/m2-zh/，不是概念圖。美術仍為暫用素材。

尚未驗證實機 iPad Safari、長時間效能、App Store 匯出；線上 Chromium 受執行環境憑證鏈限制，部署後以原生部署狀態與 TLS 驗證的資產雜湊核對確認。未宣稱線上 Safari 已通過。

新增的全新匯入檢查發現全域主題會在字型匯入前載入；現改在 HUD 建立時載入主題，連鎖與獎勵視窗繼承同一主題。以不含 .godot 快取的乾淨專案重新驗證，避免依賴開發環境快取。

## 下一階段

依 iPad 實機回報調整字級、觸控目標與連鎖圖操作；再逐一補齊完整法術／共振行為、Boss招式與完整戰局存檔。原功能缺口仍見 M2_MODULES.md，中文化不代表已完成全部移植。

GitHub Actions 已通過： https://github.com/znw7z8tvnr-a11y/spirit-guardian-2/actions/runs/40733196340 。此流程從乾淨 checkout 完成目錄匯入、78項引擎檢查、Web匯出、雙方向觸控測試與ZIP封裝；Artifact 名稱 godot-m2-delivery。試玩站使用同源碼的本機測試匯出。
