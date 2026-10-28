# 靈境守衛 Spirit Guardian — Godot M2

原來27個HTML全部保留；本次11個補充附件原樣存於 `reference_modules/`。Godot在 `godot/`，分支 `godot/m2-module-supplement`，延續M1而不覆蓋原遊戲入口。

- [M2逐附件接入、可玩功能與未完成清單](docs/M2_MODULES.md)
- [M2測試與限制](docs/M2_TESTING.md)
- [Godot匯入及操作](godot/README.md)
- [原始補充檔案manifest](docs/supplement-manifest.json)
- [M1原庫盤點（歷史）](docs/AUDIT.md)、[M1功能清單（歷史）](docs/FEATURES.md)、[架構規劃](docs/ARCHITECTURE.md)

Godot 4.6.3：`python3 tools/check_godot.py` 執行18項戰鬥與39項模組整合測試。安裝相同版本官方 Web templates 後，建立 `godot/export/web` 再執行 `godot --headless --path godot --export-release Web`。`python3 tools/test_web.py` 測實際WebGL匯出及觸控模擬，需Playwright 1.62.0與Chromium，可用 `CHROMIUM_PATH` 指定執行檔。

`python3 tools/build_supplement_catalog.py` 從附件再生資料／圖檔（需Node.js）。`python3 tools/audit_supplements.py` 逐頁短測原附件。`python3 tools/package_project.py` 產出 Godot M2、Web M2及原模組來源ZIP。

Actions流程僅驗證／匯出／提供artifact，不部署、不覆蓋原HTML。實際遠端是否推送成功以交付訊息為準；原GitHub連接曾回403。新移植程式碼MIT，原HTML及抽取圖像不被重新授權，詳見 [LICENSE-GODOT-CODE.md](LICENSE-GODOT-CODE.md)。
