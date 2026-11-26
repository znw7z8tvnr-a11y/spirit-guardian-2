# 獨立網頁試玩版｜2026-11-26

網址：https://spirit-guardian-preview-20261126.trylook.chatgpt.site

透過 Sites 建立獨立、僅擁有者可訪問的試玩站，沒有更改原站／舊 Lab。遊戲來源 559c84f，包括已累積的背包、連鎖樹、觸控、音效及預警標籤優化。Sites 原生發布結果為 succeeded；詳細來源、版本與部署 ID 見 release.json。這是發布成功證據，不等同 Safari 真機操作驗收。

Godot 4.6.3 Compatibility、單執行緒 Web 匯出；沿用已驗證的 WASM 分段串流，重組雜湊與原始檔一致，PCK 未改。最終部署包在 Linux Chromium 橫直向各六項觸控音效檢查通過，無引擎或頁面錯誤（browser/）。遊戲來源的局部 CI 45745775671 已 success；本輪未重跑完整 20 波。音色與部分美術仍為暫用，iPad Safari 未測。

環境沒有安裝 Sites source helper，沿用專案已有的隱藏 stdin 憑證／Git 推送方法；憑證只在程序記憶體使用，不寫入來源。發布 archive 來自已推送的 hosting_source，包含 .openai/hosting.json 與 dist/。

使用 Safari 開網址即可試玩。新網址與舊站儲存空間不同，舊進度不會自動帶入；不更動舊站進度。音效預設關閉，需觸控開啟。
