# M1 實際變更

- 新增 `godot/project.godot`、`scenes/main.tscn`、`export_presets.cfg`：Godot 4.6.3 Compatibility，單執行緒 Web 輸出。
- 新增 Arena／Tower／Enemy／Spell／CombatFX／UI 腳本：地形、獨立中央塔、三種圖集怪、移動近戰、四種單體彈體與冰緩速、48 特效／64 彈體／100 怪上限、可觸控波次／暫停／速度／重開。
- `scripts/main.gd` 組裝模組與唯一狀態／時間控制；可選 `?debug=1` 只讀狀態供網頁測試。
- `godot/assets/legacy` 抽取原 HTML 的 WebP 與 terrain Canvas 快取，出處及雜湊記錄於 manifest；暫用且授權待確認。
- Boss／Resonance／ChainGraph／Progression／SaveSystem／Audio 只有明示未實作的計畫目錄；不計為已移植。
- `docs/` 新增 27 個 HTML 盤點、版本選擇、逐項功能表、架構契約、測試紀錄／JSON 與真實遊戲截圖。
- `tools/` 新增讀取原版的 smoke、資產抽取、引擎整合檢查、WebGL 觸控 smoke、乾淨 ZIP 打包。
- `.github/workflows/godot-m1.yml` 建立未部署的驗證與 Web artifact 流程；遠端寫入受 403 阻擋，沒有宣稱 Actions 已跑過。
- 新移植程式碼使用 MIT；原始 HTML、既有圖像等不被重新授權。

全部原始 27 個 HTML 未修改；main 未被覆蓋。ZIP 解壓至新目錄後再匯入並重跑 18 項引擎整合測試通過，證據為 `zip-clean-*.log`。
