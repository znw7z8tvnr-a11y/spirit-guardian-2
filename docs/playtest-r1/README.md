# 整合試玩版 R1｜2026-11-26

本次一次完成三項交付：整合近期獨立優化、修正中斷操作、驗收並發布獨立試玩站。不是完整正式遊戲驗收。

整合：獎勵卡說明重用、背包與連鎖樹小數拖曳／手勢清理、存檔確認失焦取消、敵人預警標籤、Lab 音效快取、召喚物共用圖集／動畫分流、旋轉法球共用旋轉及荊棘高度分組。沒有合併到 main 或覆蓋原 HTML。

新增 FocusPauseController 場景子節點：只有原本正在運作的戰鬥／一般波間才在視窗失焦、App 失焦或暫停時呼叫既有 toggle_pause；重複中斷不反向切換，返回焦點不自動恢復。已暫停、配置、成長、領獎、續玩提示與結算不額外改變手動暫停狀態。使用原有「繼續」按鈕，不變更存檔格式、傷害或難度數值。

獨立發行分支 godot/playtest-r1-2026-11-26；完整原生、遠端完整瀏覽器矩陣，以及實際部署包中斷／續玩／20 波主流程均通過。詳細來源與發布結果見 release.json，不以匯入／語法通過代替實際遊玩驗收。

素材與音色仍有暫用內容；iPad Safari／Godot Web Editor 真機未測，全球命名／成就、雙魔杖、擴格及完整原版功能對帳仍待後續，未因整合變成已完成。獨立新網址的儲存空間不同，不自動搬移舊站進度。舊版網址和進度保留。

本機完整原生驗收：Godot 4.6.3 的 45 組／1,554 項檢查通過，另含匯入與場景解析；Python 規則 31 項通過。原生三種策略均完成 20 波，核心最低 100、城牆最低約 94%；這組樣本防守壓力偏低，未宣稱正式難度定案。逐波與全程最低資料分別見 native/godot-fullrun.json、balance-observations.json。

實際部署包的自動暫停橫直向各六項通過（focus-browser/）。完整專案 ZIP 通過 CRC、來源逐檔比對、乾淨匯入與 600 幀啟動；專案入口為 Lab，根 README 已改為 R1 使用說明，舊穩定 M2 說明留在 M2_README.md，避免匯入後看錯入口。檔名與雜湊見 delivery.json。整合包含的獨立提交皆確認為遊戲來源祖先。

完整 [CI 45753870081](https://github.com/znw7z8tvnr-a11y/spirit-guardian-2/actions/runs/45753870081) 已 completed/success：plan、validate-build 及全部 20 組瀏覽器工作均成功，沒有失敗、取消或略過。遊戲來源 c7142b9a368137215f82119e7cf5c361e49eaa66；後續提交僅保存驗收／發布紀錄。

實際部署包驗收全部通過：自動暫停每方向六項、一般開局完整 20 波／四首領／最終領獎／勝敗結算與重開每方向六項、續玩／備份／儲存故障／清除確認每方向九項；均為 Chromium 橫向 1180×820、直向 820×1180。沒有頁面或引擎錯誤。一般通關使用當局取得的獎勵與觸控排列，敗北另用明確標示的演練局；未注入戰鬥狀態。截圖為實際遊戲，報告分別在 focus-browser、battle-browser、checkpoint-browser。

最終發布：透過 Sites 發布獨立、僅擁有者可訪問的 [R1 試玩站](https://spirit-guardian-playtest-r1-20261126.trylook.chatgpt.site)，原生發布結果 succeeded。hosting source 2427e6bbacd03c1020b86b615c69b8b8a2587503、部署與版本 ID 詳見 release.json。舊 HTML、舊 M2 站與先前 preview 站均未修改，沒有搬移舊進度或改變觀眾權限。

完整專案 ZIP 亦隨站提供於 /SpiritGuardian-Godot-Playtest-R1.zip；本機交付檔位於 dist/，大小及 SHA256 見 delivery.json。完整 Web ZIP 是原始獨立匯出；實際 Sites 包以既有分段串流重組相同引擎，部署前已逐檔核對 WASM、PCK 與專案下載檔。發布成功不是 Safari 真機驗收。

本環境沒有安裝 Sites source helper，因此沿用已驗證的隱藏 stdin 憑證與 Git 推送方法；憑證只留在程序記憶體、不寫入來源。原生發布使用已推送來源的精確 SHA 與相同 archive，未另外改動發行檔。
