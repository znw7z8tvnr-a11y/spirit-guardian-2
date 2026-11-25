# 獨立優化批次：怪物預警候選索引

enemy_presentation.gd 的候選建立改用 Dictionary 記錄已列入預警的怪物 ID。原本反覆以陣列尋找 ID、對每個怪物再次掃描 urgent，改成各掃一次搭配查找。只針對候選收集減少重複掃描；預警排序本身與其他顯示步驟沒有因此變成常數時間，也未宣稱已量測 FPS 提升。

保留緊急預警優先、同一怪物第一個有效預警、閒置怪物原始順序、每種提示數量上限、最多六個 Label、避讓與安全區域、文字寫入快取。沒有變更怪物 AI、能力、傷害、預警秒數或鎖定目標。

Godot 4.6.3 匯入與 Lab 解析通過。readability 84、enemytactics 41 共 125 項檢查通過；新增四項涵蓋與凍結舊演算法的順序對照、同怪重複預警、1280 個實際怪物參照加一個無效參照的候選內容對照，以及空場無殘留 ID。1280 參照是重複使用既有 40 隻怪物的測試資料，不是 1280 隻實體怪物的效能驗收。Python 選測與錯誤處理 23 項通過。

修改 enemy_presentation.gd、enemy_readability.gd 及這份測試的局部驗收依賴，不啟動完整 20 波與全部技能回歸。

Web 以兩份敵人專用 JSON 報告 為準，未產生時不能視為通過：enemy-readability 和 enemy-tactics 的兩組橫直向實際 WebGL 操作，順序執行避免同機 WebGL 爭用。截圖若提供均為實際遊戲；怪物演練明確標示為測試。

本批獨立保存，不移動既有版本標記或更新線上站。iPad Safari 真機、長時間效能、正式美術未驗收。

本地 Web 已通過：readability 與 tactics 各自的 Chromium WebGL 橫向 1180×820、直向 820×1180，共四次方向驗收。40 隻實體怪物的標籤邊界、避讓、文字寫入與觸控，以及治療／護盾／鼓舞／靈彈警示均正常；無 pageerror 或引擎錯誤。兩份結果分別位於 readability/enemy-readability-indexed.json 與 tactics/enemy-tactics-indexed.json。來源 c1e9513。

上一批存檔清除確認的遠端 [GitHub Actions 45533712889](https://github.com/znw7z8tvnr-a11y/spirit-guardian-2/actions/runs/45533712889) 已 success，與本批效能驗收分開記錄。

獨立交付：`dist/SpiritGuardian-Godot-EnemyWarningIndex-2026-11-25.zip`，9,137,704 bytes，來源 `c1e9513115723c711aeedb18895cbd3be745e966`；SHA256 見 project-zip.json。已測 CRC、乾淨解壓匯入與啟動 600 幀；這些檢查不當成完整戰局或裝置 FPS 驗收。

本批遠端局部 [GitHub Actions 45534671893](https://github.com/znw7z8tvnr-a11y/spirit-guardian-2/actions/runs/45534671893) 已啟動，編寫本段時仍執行中，不能視為已通過。本地結果與遠端狀態分開記錄。
