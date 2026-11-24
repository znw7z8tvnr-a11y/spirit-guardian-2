# Lab 整合版｜2026-11-24

這是近期修改的單一整合交付，不是將各個 HTML 模組重新拼接，也沒有覆蓋原版或合併到 main。

## 整合內容

1. 保留既有 Lab 戰鬥、血肉城牆、倍速、獎勵刷新、背包篩選與安全波間存檔。
2. 翻頁使候選離開當前頁時取消預選；隱藏物品不能透過殘留確認裝上。
3. 關閉背包取消預選，拒絕延遲確認；重開顯示實際裝備。
4. 返回、確認、分類與換頁操作位於上方；物品區獨立捲動，換頁回頂端。極小畫面保留外層捲動備援。
5. 物品區支援垂直觸控拖曳，超過 12 邏輯像素才成立；拖曳取消卡片按壓，避免滑動誤選；第二指不接管既有拖曳。
6. 保留分層驗收流程，沒有把完整戰局測試重新加回每次小修改。

## 來源與驗收

整合前來源 HEAD `be2d166`，遊戲內容與受測 `edeefc7cc02f72487832f45e07b395ec79550bc2` 相同（`git diff edeefc7 -- godot` 為空）。所有近期修正在同一 Godot 分支，沒有互相覆寫。

本次 Godot 4.6.3 匯入、Lab 解析及六組整合檢查通過：刷新 14、獎勵 26、分類 27、背包 25、連鎖樹 59、存檔 32，共 183 項，零失敗。這是本輪執行結果，不和之前 209 項相加冒充新的測試總量。

沿用相同遊戲程式的 Web 證據：docs/inventory-fixed-header/browser-fixed-header.json，橫向 1180×820、直向 820×1180，以及短橫向 1180×600 的 Chromium 觸控拖曳、固定操作列、翻頁、取消、替換與施法。[GitHub Actions 45335803108](https://github.com/znw7z8tvnr-a11y/spirit-guardian-2/actions/runs/45335803108) 已成功。本輪未重跑相同瀏覽器測試或完整 20 波／全部技能。

## 單一下載包

- `SpiritGuardian-Godot-ChainLab-Integrated-2026-11-24.zip`：完整 Godot 專案，解壓後匯入 project.godot，主場景已設為 Lab。
- `SpiritGuardian-Web-ChainLab-Integrated-2026-11-24.zip`：獨立 Web 匯出，須放在 HTTP／HTTPS 主機，不能直接以本機檔案 URL 遊玩。

兩個 ZIP 放在 dist/，來源、大小及 SHA256 見 delivery.json。新專案包的程式與資源逐檔對照已驗證的 FixedHeader 專案包，只增加整合說明與驗收資料；未引入另一份遊戲程式。Web 包沿用同一受測的 Lab 匯出並同步字型授權資訊。

## 限制

整合版尚未發布到線上試玩站，也未替換 main、原 HTML 或穩定 M2 入口。iPad Safari／Godot Web Editor 實機未測，美術仍為暫用。雙魔杖、擴格、完整共振／成就等尚未完成項目，未因這次整合被標成完成。
