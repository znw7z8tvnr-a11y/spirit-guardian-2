# M1 測試與交付紀錄

> 此文件保留M1當時狀態；M2實際接入與最新限制見 [M2_MODULES.md](M2_MODULES.md) 與 [M2_TESTING.md](M2_TESTING.md)。

日期 2026-10-28。環境：Linux、官方 Godot 4.6.3.stable.official.7d41c59c4、GDScript、Compatibility；Web 使用同版本官方 single-thread / no GDExtension export template，Chromium headless（軟體 WebGL）。這不是 iPad Safari 真機測試。

## 已通過

- 全 27 個原 HTML 的所有 inline scripts 以 Node vm.Script 編譯，0 語法錯誤；此項不等於執行成功。
- Chromium 原 HTML 啟動／出怪／暫停：index、V31.7.1、V31.9、V31.10 通過，無 pageerror；V32／V33／V34 的核心可動但各有兩個模組初始化錯誤，見 AUDIT。
- Godot clean import：GDScript、主場景、preload 圖檔與引用正常；檢查 stderr，不只依賴退出碼。
- 18 項引擎整合測試通過，實際物理 tick 執行，不是只呼叫相同公式比較：塔初始生命、波次排程／生怪、AI 移動、暫停凍結、2× 時間、四種彈體逐一命中擊殺、冰減速、怪物傷塔、提前波保留待生怪與存活怪、死亡暫停、重開重置、一般場景 60 模擬秒、entity 上限。
- 固定 seed 3201 的一般 60 模擬秒：第 3 波、31 kills、塔 64 HP、7 enemies、1 projectile、未 GameOver。這不是 60 FPS 的效能認證。
- 官方 Web release 匯出成功，沒有 GDScript／資源錯誤。
- **實際匯出的 WebGL 遊戲**在 Chromium 1180×820 與 820×1180 觸控模擬通過：啟動／出怪、點擊暫停與恢復、速度 2×、選冰與奧術、重開清回火元素／1×／100 HP；0 pageerror、0 Godot runtime ERROR。詳見 `web-smoke.json`。
- `godot-web-landscape.png`、`godot-web-portrait.png` 是這次實際 Web 匯出遊戲截圖，**不是概念圖、不是 iPad 實機截圖**。美術仍是暫用素材。
- 專案 ZIP 包含根目錄 project.godot、主場景、腳本與資源，排除 `.godot`、匯出快取。交付時另外驗證 ZIP 內容與乾淨解壓匯入。

## 本次實測修正

1. 原內嵌資料實際為 WebP，錯用 .png 會讓 Godot importer 標記 invalid；已按真實格式使用 `.webp`，保留原 byte hash。
2. `JavaScriptBridge.eval` 在 Web 將 JS 布林傳回整數；改以 `bool(...)` 轉換，避免網頁版 _ready 中斷。原生測試不會走到這段，必須測實際 Web。
3. UI pressed 回呼立即 reload 會在輸入樹走訪期間移除節點；改 `call_deferred("reload_current_scene")`，實際 Web 重開回歸通過。
4. 最初整合測試把已被彈體擊殺的敵人當作移動觀察對象，修正為該步驟給觀察敵人足夠 HP；一般 soak 仍使用未修改的遊戲數值。

## 未測／限制

- iPad Safari、Godot Web Editor 在 iPad 匯入及長期穩定性；iOS 原生匯出／簽章／App Store。
- 真機記憶體、電量、熱降頻、10–30 分鐘效能、P95／60 FPS、背景恢復、Safari 音訊／儲存清理；M1 本身無完整存檔與音效。
- 完整 Boss、Roguelite、掉落、保底、全法術／連鎖／共振及舊存檔相容性：尚未移植，不能宣稱通過。
- 正式 2.5D／分層美術、攻擊動畫、光影與粒子效果未完成；原版城堡烘焙在背景中，30% 視覺縮放尚未做同鏡頭比對。
- 背景目前固定 1280×720，較高畫面上下為底色；UI 暫用英文、預設 Godot theme。iPad 安全區／可讀性待真機調整。
- 新引擎流程使用固定 seed 以便重現，後續 roguelite 才會提供隨機 run seed 與存檔重現。
- GitHub Actions 工作流已建立，但遠端是否執行成功必須以實際 run 為準。本次 GitHub API 建立遠端分支回 403 `Resource not accessible by integration`；不能把本地測試當作 Actions 已通過。

## 重現

```sh
python3 tools/inventory_sources.py
python3 tools/check_godot.py
mkdir -p godot/export/web
godot --headless --path godot --export-release Web
python3 tools/test_web.py
python3 tools/package_project.py
```

Godot、Web templates 必須同為 4.6.3；browser test 需 Playwright（本次 1.62.0）與 Chromium。HTML audit 需完整原 HTML；資產抽取需 Pillow。程式與執行時檢查會寫出 JSON／log。HTML tests 是短時間功能 smoke，不是所有敵人／獎勵／Boss 的自動通關。

## GitHub 寫入阻礙

現有 GitHub 連接雖能讀取儲存庫，建立分支 API 仍回 403。這是連接的實際寫入權限限制，不是請求使用者再次同意原本已授權的工作。工作保存在本地 `godot/phase-1-minimum` 分支；另交付 Git bundle 以免提交遺失。需要具 Contents write（若含 workflow，亦需 Workflows write）的連接才能將提交寫到原庫；未修改 main，也未部署網站。另以 Git CLI 推送同一分支亦回 HTTP 403（Permission denied）。本次沒有遠端分支或 Actions run；本地提交與 bundle 已保存。
