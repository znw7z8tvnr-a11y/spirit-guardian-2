# 背包翻頁防誤裝

本輪修正 Lab 背包：選中候選物品後，翻頁使該物品離開當前頁時，取消候選、清除高亮並停用確認。返回原頁後需重新點選，才可確認替換。選擇與確認入口都檢查當前頁物品，不接受殘留的跨頁操作。

切換分類時，若候選仍在該分類，沿用原本跳到候選所在頁的行為。取得順序、實體物品 ID、連線、獎勵與亂數不變；未新增文字或變動字型資源。

修改檔案：`godot/experiments/chain_lab/inventory_view.gd`、`godot/tests/inventory_filters.gd`、`tools/test_inventory_filters_web.py`；另在 `tools/plan_validation.py` 與對應測試補上背包原生測試的局部依賴，避免只增加相關驗收就誤跑完整遊戲。

本地 Godot 4.6.3：匯入、Lab 場景解析及 integration／modules／localization／touch／inventoryfilters／inventory／tree 共 197 項檢查通過（新增 4 項翻頁防誤裝檢查）。Python 選測流程 20 項通過。Web 驗收結果另見 browser-page-guard.json；不存在該檔時不得視為已通過。

驗收範圍是局部背包與觸控，不包含完整 20 波、全部技能或 iPad Safari 實機。本輪美術仍是既有暫用素材。此目錄截圖若有提供，均來自實際 Godot WebGL 遊戲。

尚未更新線上試玩站；不將本地修改冒充已發布版本。

本地 Web 實測已完成：Chromium WebGL 橫向 1180×820、直向 820×1180 均通過。以實際觸控選取末頁技能、翻回前頁、嘗試確認、返回末頁重新選取，再驗證分類／可裝配／替換後施法；未注入遊戲狀態。兩種方向無 pageerror 或引擎錯誤，報告見 browser-page-guard.json。技能演練背包仍明確標示為演練。

交付來源：`f31efd3912ac8e2623adf15cb980a11cafb8f41b`（獨立 Godot 分支，原 HTML 保留）。`dist/SpiritGuardian-Godot-ChainLab-PageGuard.zip` 是該來源的獨立 Lab 專案，已將主場景設為 Lab，附本輪局部驗收證據；大小與 SHA256 見 project-zip.json。ZIP CRC、乾淨解壓匯入，以及解壓版啟動 600 幀引擎冒煙檢查通過；此冒煙不代表畫面或完整戰局驗收。

遠端 [GitHub Actions 45332830994](https://github.com/znw7z8tvnr-a11y/spirit-guardian-2/actions/runs/45332830994) 已啟動；編寫本段時仍執行中，不能視為通過。本地 Web 與原生結果如上。測試來源未變，因此僅補交付文件不再重跑測試。
