# 靈境守衛 Godot M1

Godot **4.6.3**、GDScript、Compatibility。開啟 `project.godot`，執行主場景（Play）。此 ZIP 的根目錄即專案根目錄，可直接匯入；第一次需要等待圖像匯入。

目前可玩：中央水晶、暫用祭壇地圖、三類怪物、四種可選單體彈體（冰含緩速）、近戰傷塔、波次、提前開波、暫停、1×／2×與重開。法術按鈕選擇目前主攻元素，沒有學習或多法術裝配。Next wave 會在當波怪物已全部生成後開放，可保留存活怪直接開下一波。

目前無完整存檔、無聲音、無 Boss／連鎖／成長。暫用美術取自原 HTML；地形是 Canvas 快取，沒有達到最終分層 2.5D 目標。UI 暫用英文避免未附 CJK 字體時缺字，完整繁中介面待後續。

iPad：可先嘗試 Godot Web Editor 匯入 ZIP；其 iPad Safari 操作／可用記憶體未經真機驗證。Web Editor 能否匯入與執行、能否匯出是不同能力，不依賴它完成正式匯出。本次直接交付專案 ZIP 與 Web ZIP；目前 GitHub 寫入被 403 拒絕，遠端分支及 Actions artifact 尚未建立。修復連接寫入權限並推送後，工作流才可產生 `godot-m1-delivery` artifact（下載需 GitHub 登入）。Web 匯出需以 HTTP(S) 服務提供所有檔案，不能在「檔案」App 直接點 index.html 當正式遊戲。尚未部署公開遊戲網址。

Web 預設關閉 threads，降低 SharedArrayBuffer／跨來源隔離需求；仍需 WebAssembly、WebGL 2 及足夠記憶體，不能據此保證所有 iPad 相容。若開 `?debug=1`，只讀診斷可從 `window.SG_M1_STATE` 取得。

詳細盤點與未完成清單見原始庫 `docs/` 或 ZIP 的 `migration_docs/`。素材授權未確認，不能以本 ZIP 當作已取得全部商用授權的正式發行包。
