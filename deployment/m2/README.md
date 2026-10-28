# M2／M2.1 獨立網頁試玩部署

目前試玩版本為 **M2.1 觸控優化版**： https://spirit-guardian-m2-play.trylook.chatgpt.site

沿用同一個私人 Site，使用擁有者的 ChatGPT 帳號登入。原遊戲 https://znw7z8tvnr-a11y.github.io/spirit-guardian-2/ 、main、原 HTML 入口及 Pages 設定不變。

目前遊戲／部署來源SHA、版本、CI與artifact識別資料見 `site.json`，不含憑證。修改與驗證詳見 `docs/M2_1.md`、`docs/m2-1/`。

## 部署方式

`prepare_site.py <web.zip> <site-directory> --source-commit <完整SHA> --web-zip` 使用已驗證的M2.1 Web ZIP；省略 `--web-zip` 時讀取 Actions artifact 內的 `dist/SpiritGuardian-Web-M2.1-zh-Hant.zip`。

為符合主機單檔限制，原 Godot wasm 分成3個最多12MiB的檔案，由 wasm-stream.js 還原串流 Response。合併雜湊與原wasm相同，PCK不改動。HTML只調整語言、標題及串流載入器。此版串流機制未修改。

本環境未提供 Sites skill 指定的 source helper，沿用等價 Git＋git archive 備援：停用回顯的stdin接收短期認證，僅用於子程序環境，不存入檔案或Git設定；推送後核對遠端HEAD，以同一HEAD封裝 `.openai/hosting.json` 與 `dist/`，再由原生 Sites API發布。沿用既有Site及私人閱覽權限。

## 驗證

- M2.1：98項引擎檢查通過，實際單執行緒Web匯出於Linux Chromium軟體WebGL的橫／直向觸控模擬通過；包括兩次點選連接／移除、循環拒絕、復原重做、視圖移動及44 CSS px主要戰鬥按鈕尺寸。`docs/m2-1/`為當前測試與實際遊戲截圖。
- GitHub Actions同源碼乾淨checkout亦全部成功，ZIP位於run 40735480303的godot-m2-delivery artifact。
- 正式站以既有私人驗證授權及TLS驗證讀取：HTML200、三段wasm逐段與合併雜湊一致、PCK與本機原匯出一致。當前記錄 `qa/live-assets.json`。
- 正式站瀏覽器自動化受環境憑證鏈限制，未停用TLS驗證，未宣稱正式站遠端互動或Safari已通過。
- `qa/local.json`及其中截圖為早期M2分段wasm包測試的歷史紀錄。本次M2.1重新測試原始Web匯出；分段載入器未改，另核對正式站資源完整性。
- iPad Safari真機、長跑效能、瀏覽器儲存／音訊仍待實測。美術仍為暫用素材；只保存配置，未保存完整戰局。
