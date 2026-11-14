# 本輪驗收資料

最終狀態看 release.json（完成發布後產生）與 docs/CHECKPOINT.md。

- godot-*.json：38 組原生測試，合計 1,300 項。
- browser-synchronous.json：同步儲存、近即時重載與故障提示。
- browser-staged.json：最終部署分塊載入包的同等觸控測試。
- fullrun-checkpoint-observations.json：三局 60 個安全波間的補充資料驗證，不混入正式測試計數。
- spell-reload/：修改測試重開流程後的直向 22 技能完整本機回歸。
- 倉庫中的 browser-web.json 與 *-web-*.png 是未發布的非同步原型歷史；CI 使用預設標籤時亦可能產生同名檔，須連同對應執行提交判讀。最終狀態以 release.json 與同步儲存報告為準。
- live-assets.json：發布後 HTTPS 資源、來源與下載 ZIP 核對；不是遠端 Safari 畫面驗收。

所有 PNG 均為實際測試遊戲畫面，使用暫用美術。
