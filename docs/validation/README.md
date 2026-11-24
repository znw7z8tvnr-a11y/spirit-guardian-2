# 分層驗收流程

本輪只修改開發流程，不變更遊戲規則或發布試玩網站。

- **focused（推送預設）**：匯入、場景解析及四項基礎引擎測試；另依變更路徑選擇相關測試。已建立刷新、背包篩選／介面、怪物呈現的局部依賴規則。
- **integration（手動整合批次）**：增加短戰鬥、Boss、獎勵、背包及存檔測試，瀏覽器檢查保持短流程。
- **full（重要版本）**：保留全部原生及瀏覽器測試，包括 20 波、22 技能。共用核心、未知遊戲資源或未知工具依賴改動也自動提升到此層級；自動推送缺少可靠比較基準時同樣如此。手動明確選 integration 可執行固定的局部整合清單，報告會註明未建立變更範圍比對；手動 focused 缺少基準仍擴大為 full。

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


## 後續修正：省略不必要的網頁建置

規劃輸出增加 `web_required`。沒有選到瀏覽器測試的局部流程，略過 Web 模板安裝、兩個入口匯出及 Web 建置檔上傳；Godot 匯入與選中的原生測試仍執行。這不是略過選中的驗收，也不將局部結果標成完整通過。

實際驗證：選測／錯誤處理共 19 項 Python 測試通過，包含手動 integration 入口、未知基準安全回退、未知子目錄同名檔案不套用局部規則，以及 GitHub 輸出格式。另檢查 YAML、Shell 語法及四處 Web 建置條件。未修改遊戲程式，因此本地未重跑上一輪已通過的 98 項引擎檢查。

上一版 GitHub run 45331566745 的 plan 與 validate-build 均已成功；瀏覽器矩陣仍執行時推送後續修正，可能被既有 concurrency 規則取消。這不代表完整瀏覽器驗收通過。

後續修正的遠端實測已完成：[GitHub Actions 45331914486](https://github.com/znw7z8tvnr-a11y/spirit-guardian-2/actions/runs/45331914486)，來源 `f580a4d97a5da0c7e0aa7de951c233214e1e7460`，結果 success。plan 與 validate-build 成功；Web 模板安裝、兩個 Web 匯出、Web artifact、候選封裝及整個瀏覽器工作均按規劃略過。這證實純原生驗證路徑可用，並不代表瀏覽器或完整遊戲回歸通過。
