# 原始專案盤點與基線決策

檢查日期：2026-10-28。儲存庫 `znw7z8tvnr-a11y/spirit-guardian-2`，原始 main commit `8de3a066e90c256a5b6339f6d1719325cca0b3be`（V34 上傳）。附件 V32 與庫內 V32 byte-for-byte 相同。全部原 HTML 保持不變。

## 實際結構

根目錄 27 個 HTML，沒有 README、授權檔、獨立圖片／音訊資產資料夾、測試或 Godot 專案。逐檔大小、SHA-256、Git blob SHA、標題、inline script 與語法檢查結果見 `source-inventory.json`。檔名不能代表發佈順序或整合完成度；`index.html` 標題仍為 P5，V34 標題仍為 V32。

- `index.html`、`index_attack_test.html`：較早期完整遊戲入口／攻擊測試。
- `attacks.html`、`attacks-v3.html`、`attacks-v8.html`、`attacks_v14.html`、`attacks-v20.html`：獨立攻擊展示／測試候選；未把它們的效果算作主遊戲已整合。
- `spirit_guardian_web25d_v1.html`、`spirit_guardian_v24.html`、`v26_effect_preview.html`、V28／V28.1／V29：早期或獨立測試版本。
- V30、V31、V31.3、V31.4、V31.6、V31.7.1、V31.9、V31.10：主遊戲逐版擴充。
- V32 fusion／V32 background A/B、V33 tower depth、V34 altar A/B：最新實驗分支，以複製整個單檔方式保存。
- `v28.html` 與 `spirit_guardian_v28_1_fixed.html` 同 blob；V31.3 test 與 vfx 亦同 blob，不是額外兩套系統。

## 建議使用版本

**可玩移植基線：`spirit_guardian_v31_10_crisp_controls.html`。** 是已完成瀏覽器回測候選中最新、啟動沒有 pageerror 且可出怪及暫停的版本。不是宣稱它已通過完整遊戲／長時間／iPad 驗收。

**功能與資料參考：`spirit_guardian_v32_fusion_test.html`。** 附件確實可載入核心戰鬥並有擊殺，但共振及音效擴充初始化失敗。V32 包含比 V31.10 更新的融合／成長資料，應逐項移入，不能當作一套已驗證完整系統照搬。

**最新檔案：V34**，增加背景 A/B 的真正呼叫，仍有 V32 的兩個錯誤；V33 另加塔底座景深。實際 diff 顯示 V34 是基於 V32 的背景改動，沒有 V33 的 `sgV33TowerFoundation`，不是 V33 的全面升級。

## 實測發現

`html-smoke.json` 與 `html-older-smoke.json` 是 Linux Chromium 的短時間原檔測試。沒有修改受測 JS。

| 候選 | 啟動／出怪／暫停 | pageerror | 結論 |
|---|---|---|---|
| index | 通過 | 0 | 較早期基線 |
| V31.7.1、V31.9、V31.10 | 通過 | 0 | 優先 V31.10 |
| V32、V33、V34 | 核心可動；錯誤面板會擋操作 | 各 2 | 不可稱完整整合成功 |

V32 實際錯誤：
1. line 1330 `const original=sg7Resonance`，但核心函式封裝於第一個 IIFE，外部腳本無法直接存取。連帶 `update/state/enemies/damage/SG7_RESONANCES` 等依賴也沒有橋接；50 個差異化持續領域擴充沒有成功初始化。核心內的三重共鳴函式仍存在，須與失敗擴充分開。
2. line 1391 `$('sgM11Music').value=...`，DOM 中沒有該控制項；音效／效能模組初始化中斷。
3. `SG_BOSS` v5 定義存在（line 1783），未搜尋到主戰鬥的 `.create`／`.update`／`.hit` 接入。核心已有舊 Boss，不能將 v5 預警、適應、護盾、失衡當作已整合。
4. `SGBackground` 在 V32 已定義，但主 `draw` 仍畫 SG61_ARENA；V34 才透過 A/B 選擇接入。V33 只改 `drawTowerArt`，主繪製路徑以 `drawAssetTower` 為主，新增景深不代表畫面必定用到。
5. `SGChain` 透過 `SGBridge` 接核心，與未橋接的擴充不同；`SGChain.debug()` 才是排程診斷 API，最初 smoke 的 `stats` 欄為 null 不能當作連鎖不存在。

## 依賴與風險

| 系統 | 原始依賴 | Godot 處理 |
|---|---|---|
| 核心戰鬥 | IIFE 內 C、state、enemies、skills、damage、update | 明確物件參照；模組訊號；main 負責組裝 |
| SGChain | SGBridge、stable enemy id、命中結果、時間、localStorage | 獨立圖資料與事件佇列；先定義 HitResult 再移植 |
| SGGrowth | skills、wave、獎勵 UI、seed、meta localStorage | 資料 Resource、獨立 RNG、持久版本格式 |
| 共振 | skills、命中／狀態、SG7_RESONANCES | 核心三重配方與擴充分開移植驗收 |
| Boss v5 | hooks host 結算傷害、召喚確認、舊 Boss 更新 | 必須單一結算擁有者，避免兩套攻擊同時執行 |
| 特效 | 多個 Canvas／rAF、SG314FX 包裝、座標投影 | CombatFX 接事件；不覆寫命中函式 |
| 背景／塔 | 大背景已烘焙城堡；Image 非同步載入 | 獨立 Sprite／地形層，30% 比對另驗收 |
| 儲存 | 多個 localStorage key、頁面離開／12 秒快照 | schema、遷移、備份及 Safari 寫入失敗提示 |
| 音效／效能 | WebAudio、缺失 DOM、visibility、rAF | Audio bus + 唯一 pause/time source |

其他風險：chain lowhp 判斷用 `target.maxHp`，核心敵人用 `max`；延遲條件用真實時間，主戰鬥用速度縮放時間；部分連鎖技能共用 AoE／重映射元素，不能只按 22 個名稱視為 22 套獨特機制。舊註解仍稱兩層，但常數已是 16 層。讀檔允許 12 roots、編輯新增限制 8 roots，需定義一致資料規則。自由圖需額外環路偵測與觸發預算，不能繼承樹形限制當作最終自由圖。

## 可重用素材與缺件

V32 有 47 個 `data:image` 出現位置，包括 JSON 內塔、怪物、Boss、技能、UI、8 幀行走圖集與 SG61 背景。已抽出最小版所需及參考圖，見 `asset-manifest.json`。原內嵌圖實際多為 WebP；已按真實格式使用 `.webp`，不是依副檔名猜測。`terrain.png` 來自 SGBackground 的 Canvas 快取，工具可重現抽取。

原大圖漂亮但城堡烘焙其中，不適合獨立縮塔；M1 使用平面地形快取與獨立塔／怪物 Sprite。這是暫用美術，不是完成的分層 2.5D。缺少可編輯地形層、正式怪物攻擊／受擊／死亡動畫、完整 Boss 分階素材、音訊成品，以及所有圖像／音訊的作者及再散布／商用授權證明。現有檔案足夠建立 M1，不要求使用者補程式碼。正式上架前仍需補素材或替換為具明確授權的免費開源素材。
