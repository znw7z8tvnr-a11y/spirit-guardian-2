# 靈境守衛 Spirit Guardian — Godot M2.1 觸控版

[2026-10-29 完整設計統整與開發順序](docs/design/MASTER_PLAN_2026-10-29.md) · [開發計畫書文字檔（TXT）](docs/design/SpiritGuardian_Project_Plan_2026-10-29.txt)

[最新：血肉城牆與1／2／4／8倍速](docs/FLESH_WALL.md)

[P1第一批進度：跳怪與空放](docs/CHAIN_FLOW.md) · [來源盤點與移植差距](docs/design/SOURCE_INVENTORY_2026-10-29.md)

[獨立連鎖戰鬥試驗室](https://spirit-guardian-m2-play.trylook.chatgpt.site/lab/) · [試驗規則與限制](docs/CHAIN_LAB.md)

[開啟 M2 網頁試玩（需以擁有者 ChatGPT 帳號登入）](https://spirit-guardian-m2-play.trylook.chatgpt.site) · [部署與驗證紀錄](deployment/m2/README.md)

原來27個HTML全部保留；本次11個補充附件原樣存於 `reference_modules/`。Godot在 `godot/`，分支 `godot/m2-1-ipad`，延續M1而不覆蓋原遊戲入口。

- [M2.1觸控優化與驗證](docs/M2_1.md)
- [繁中化範圍與驗證](docs/M2_ZH.md)
- [M2逐附件接入、可玩功能與未完成清單](docs/M2_MODULES.md)
- [M2測試與限制](docs/M2_TESTING.md)
- [Godot匯入及操作](godot/README.md)
- [原始補充檔案manifest](docs/supplement-manifest.json)
- [M1原庫盤點（歷史）](docs/AUDIT.md)、[M1功能清單（歷史）](docs/FEATURES.md)、[架構規劃](docs/ARCHITECTURE.md)

Godot 4.6.3：`python3 tools/check_godot.py` 執行18項戰鬥、39項模組整合、21項中文化及20項觸控測試。安裝相同版本官方 Web templates 後，建立 `godot/export/web` 再執行 `godot --headless --path godot --export-release Web`。`python3 tools/test_web.py` 測實際WebGL匯出及觸控模擬，需Playwright 1.62.0與Chromium，可用 `CHROMIUM_PATH` 指定執行檔。

`python3 tools/build_supplement_catalog.py` 從附件再生資料／圖檔（需Node.js）。`python3 tools/audit_supplements.py` 逐頁短測原附件。`python3 tools/package_project.py` 產出 Godot M2、Web M2及原模組來源ZIP。

Actions流程僅驗證／匯出／提供artifact，不部署、不覆蓋原HTML。實際遠端是否推送成功以交付訊息為準；原GitHub連接曾回403。新移植程式碼MIT，原HTML及抽取圖像不被重新授權，詳見 [LICENSE-GODOT-CODE.md](LICENSE-GODOT-CODE.md)。
