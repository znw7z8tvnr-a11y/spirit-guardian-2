# 靈境守衛 Spirit Guardian

原 HTML 遊戲全部保留。Godot 移植在 `godot/`，本次分支為 `godot/phase-1-minimum`，不替換 `index.html`。

- [Godot 匯入與操作](godot/README.md)
- [原版盤點、版本選擇與整合風險](docs/AUDIT.md)
- [逐項功能移植表](docs/FEATURES.md)
- [架構、資料介面與後續階段](docs/ARCHITECTURE.md)
- [實際測試與限制](docs/TESTING.md)
- [素材出處／雜湊／授權狀態](docs/asset-manifest.json)

可玩回歸基線為 V31.10；V32/V33/V34 有已重現的初始化錯誤，保留為功能／視覺參考。Godot M1 是最小戰鬥版，尚非完整遊戲重製。

Godot 4.6.3 安裝後：`python3 tools/check_godot.py`；安裝相同版官方 Web export templates 後：`godot --headless --path godot --export-release Web`（先建立 godot/export/web）。`python3 tools/package_project.py` 產出乾淨可匯入 ZIP。Actions 會完成引擎測試、Web 匯出及觸控模擬測試並提供 artifact；沒有自動部署到 Pages 或覆蓋原 HTML。

HTML／Web 測試需 Python Playwright；`python3 -m playwright install chromium` 後可執行 `tools/audit_html.py`、`tools/audit_older.py`、`tools/test_web.py`。若使用已有 Chromium，可設 `CHROMIUM_PATH`。素材抽取需 Pillow；`tools/extract_assets.py` 抽 WebP，`audit_html.py` 另存 terrain Canvas 快取。

新移植程式碼採 MIT；原 HTML 與抽取美術不在這次授權範圍。詳見 [LICENSE-GODOT-CODE.md](LICENSE-GODOT-CODE.md)。
