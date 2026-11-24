# 分層驗收流程

本輪只修改開發流程，不變更遊戲規則或發布試玩網站。

- **focused（推送預設）**：匯入、場景解析及四項基礎引擎測試；另依變更路徑選擇相關測試。已建立刷新、背包篩選／介面、怪物呈現的局部依賴規則。
- **integration（手動整合批次）**：增加短戰鬥、Boss、獎勵、背包及存檔測試，瀏覽器檢查保持短流程。
- **full（重要版本）**：保留全部原生及瀏覽器測試，包括 20 波、22 技能。共用核心、未知遊戲資源或未知工具依賴改動也自動提升到此層級；缺少可靠比較基準時同樣如此。

GitHub Actions → Godot M2 validation and Web build → Run workflow，選 profile。瀏覽器測試拆成各別工作，最多同時四項；失敗後使用 GitHub 的 Re-run failed jobs。單機本地瀏覽器測試仍逐項執行，避免 WebGL 資源競爭。

局部原生測試範例：

```sh
python3 tools/check_godot.py --suites reroll,rewards,checkpoint --report-dir /tmp/sg-validation
python3 tools/check_godot.py  # 保留原先「全部原生測試」行為
python3 tools/plan_validation.py --profile focused --files godot/experiments/chain_lab/reward_reroll.gd
python3 tools/test_validation_plan.py
```

報告 `validation-selection/selection.json` 記錄來源提交、變更、選擇原因和測試範圍；`native-validation/selection.json` 明列已選及略過的原生套件。瀏覽器在乾淨報告目錄產生本輪證據，失敗也上傳已產生的紀錄。局部通過不代表完整遊戲驗收；所有矩陣工作通過前，完整模式產出的 ZIP 只是候選檔。

快取固定 Godot 4.6.3、對應 Web 模板與 Playwright 1.62.0 Chromium；首次執行仍需下載。尚未量測遠端端到端省時幅度，也未聲稱已在 iPad Safari 驗證。

本輪實測：Godot 4.6.3 匯入、Lab 場景解析、integration／modules／localization／touch 共 98 項檢查通過；11 項 Python 選測及錯誤處理測試通過；工作流程 YAML 與內嵌 Shell 語法通過。未執行完整戰鬥回歸、瀏覽器矩陣與 iPad 實機測試。遠端 Actions 狀態需另查，不能以本地語法檢查替代。
