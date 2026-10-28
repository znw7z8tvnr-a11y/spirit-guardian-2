# 靈境守衛 Godot M2 — 補充模組版

使用官方 Godot **4.6.3**、GDScript、Compatibility。匯入 ZIP 根目錄的 `project.godot`，等圖檔匯入後 Play。原 HTML 不被替換。

新增自由分支連鎖圖、8種可執行法術、雙元素／三元素共振、敵人AI策略、三階Boss、三選一／保底／鎖定重抽、連鎖配置存檔與暫用合成音效。

- 底部按鈕選主攻法術；Pause、1×／2×、Next wave、Restart 維持可用。
- Chain：Add 新節點、拖 OUT → IN 連線；選節點 Remove；支援 Undo／Redo、Demo與JSON。圖不限制4格，循環會拒絕。
- Done：保存配置並返回；Restart 會讀回配置。只存配置，**不保存本局戰鬥**。
- Audio: off：預設靜音，點擊開啟暫用合成音效。不是原版完整配樂。
- 每3波清完會暫停並顯示三選一，支援鎖定及一次重抽；每4波有Boss。

全部22法術與50共鳴配方資料已保存，但目前只有8法術與6雙元素／4終結共振實際執行。其他機制、完整Boss招式幾何、成長進化／永久碎片、原HTML V9樹JSON轉換及完整存檔仍未完成。暫用英文UI、原圖集與地形快取，不代表最終2.5D品質；素材商用授權待確認。

iPad 可嘗試 Godot Web Editor 匯入 ZIP，但未真機驗證。Web Editor 不被當作正式匯出工具；已提供桌面引擎的單執行緒 Web 匯出與 GitHub Actions 腳本。Web ZIP 需透過 HTTP(S) 提供所有檔案，不能直接在「檔案」App 開 index.html。GitHub寫入前次回403，遠端保存狀態見交付訊息，不能假設已有Actions artifact。

詳細範圍及測試見專案內 `migration_docs/M2_MODULES.md`、`migration_docs/M2_TESTING.md`，或原始庫的 `docs/`。`?debug=1` 提供只讀 `window.SG_M1_STATE`（為維持測試相容保留名稱，包含M2欄位）。
