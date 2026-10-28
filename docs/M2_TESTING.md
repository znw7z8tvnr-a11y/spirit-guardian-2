# M2 測試與驗收

日期：2026-10-28。Linux／官方Godot 4.6.3／Compatibility、官方同版單執行緒Web template、Playwright 1.62.0與Chromium軟體WebGL。沒有iPad或Safari實機。本頁是M2結果；原 `TESTING.md` 為M1歷史記錄。

## 原附件

11個附件已原樣保存並記錄SHA-256；所有inline scripts都能編譯，0語法錯誤。以原頁面啟動／出怪或點擊示範控制項，短測約4秒：10頁無pageerror；`spirit_guardian_v31_16_skills_final.html` 有 `sg7Resonance is not defined`。這只是短smoke，沒有宣稱原模組所有分支、Boss／成長都完整通關。詳見 `supplement-html-smoke.json`。

重複比對採script內容完全相同，並非只看檔名：成長獎勵附件8段script與V32完全相同；Boss附件engine相同而host新增；敵人final的核心與舊10passes不同。完整比對索引見manifest。

## 引擎實際執行

`python3 tools/check_godot.py` 通過 **18項戰鬥回歸＋39項新增模組測試，共57項**，並檢查Godot輸出中的SCRIPT ERROR／ERROR，而非只看exit code。

- 戰鬥回歸：塔生命、波次排程／實際生怪、敵人移動、暫停凍結、速度、四元素飛行命中、冰緩速、近戰傷塔、提前開波、死亡暫停與重開、正常場景及實體數上限。
- 圖與傷害：超過四節點、增加第六節點、有效連線、拒絕環、壞JSON交易性拒絕、bool schema／無效座標拒絕、JSON round trip、分支排程造成實際HP傷害、六融合／三元素終結、刪除在途節點、暫停凍結clock與傷害、240每run／400pending、最多16下游層。
- 技能與AI：毒tick持續造成HP減少、隕石命中第二目標、巫師近距離撤退、迅捷衝刺冷卻、裝甲預警後才得護盾。
- Boss：70%／35%階段、25／45護盾、真實生成召喚物、存活上限8、預警未到不能傷塔、倒數結束只出手一次。
- 成長與UI：pity7保證傳說、鎖定重抽、token不可重複花、獎勵不可重領、GraphEdit Add／Undo影響實際模型、Done寫配置、fresh graph重載、三選一暫停／選取後恢復。

固定seed的一般場景跑3600個physics frames；測試遇到正常成長選擇會領取第1項繼續，不改戰鬥數值。結果第4波、54 kills、塔66 HP、2 enemies、2 projectiles、未GameOver。這是功能模擬，不是60FPS／真機效能認證。完整輸出：`m2/godot-integration.json`、`m2/godot-modules.json`。

## 實際Web匯出

以正式匯出的WebGL版本執行，不是HTML仿製頁。橫向1180×820與縱向820×1180測試：啟動／出怪、觸控暫停／恢復、速度、冰／奧術選擇、Chain開關、Add／Undo／Redo、Done儲存、重開後配置保留與主攻／速度／HP重置。0 pageerror、0 Godot runtime ERROR。資料在 `m2/web-smoke.json`。

`m2/graph-landscape.png`、`m2/graph-portrait.png` 與 `m2/godot-web-*.png` 是**實際Godot WebGL截圖**，不是概念圖，也不是iPad截圖。圖編輯時暫停，透過HUD常駐處理更新診斷座標；遊戲clock／傷害仍凍結。觸控拖曳插座由Godot GraphEdit處理，本次自動化驗證了模型連線與觸控新增／復原操作，沒有把iPad上的插座拖曳宣稱已實測。

乾淨ZIP：排除 `.godot/` 與 `export/`；解壓到新目錄後重新匯入、執行18＋39項測試，證據存於 `m2/zip-clean-*.log`。原27個根HTML及11個新附件的hash另檢查不變。

## 未測與已知限制

- iPad Safari、Godot Web Editor真機匯入、缺口／安全區、多指拖圖、瀏覽器長期儲存、音訊解鎖／實際聲音品質、背景恢復與30分鐘長跑尚未測。
- 圖存檔只有Godot schema1配置，原V9樹JSON不互通；尚未提供本局續玩與舊存檔遷移。匯入不支援的14法術會明確拒絕，不悄悄替換。
- 已錄入22法術／50共鳴資料不代表已執行：目前8法術、6雙元素、4終結；50領域及圖鑑未接入。
- Boss預警目前以水晶為目標統一圈形；原招式線／環／圈幾何與封印／重力等狀態、完整adaptation未等價實作。Nightmare弱點仍保留原資料的light，目前8法術中沒有light。
- 永久碎片、進化／協同融合成長、完整trait／精英詞綴、原場景配樂／P95面板及正式粒子動畫未完成。
- 地形仍為原Canvas快取、Sprite圖集為暫用美術，UI暫用英文、原版城堡30%視覺比對／正式2.5D品質未驗收。程式執行通過不等於美術達標。
- Actions腳本已更新為M2並包含來源資料再生驗證與57項檢查；若遠端寫入仍403，不能宣稱Actions已執行。

重現：`python3 tools/build_supplement_catalog.py` → `python3 tools/check_godot.py` → 安裝4.6.3 Web templates並匯出 → `python3 tools/test_web.py` → `python3 tools/package_project.py`。來源smoke使用 `tools/audit_supplements.py`。`CHROMIUM_PATH` 可指定已有瀏覽器；需要可用localhost網路與瀏覽器啟動權限。
