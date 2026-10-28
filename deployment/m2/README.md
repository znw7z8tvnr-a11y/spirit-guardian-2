# M2 獨立網頁試玩部署

試玩網址：https://spirit-guardian-m2-play.trylook.chatgpt.site

此站為 Sites 私人網站，使用擁有者的 ChatGPT 帳號登入。原遊戲網址 https://znw7z8tvnr-a11y.github.io/spirit-guardian-2/ 保持不變；其 Pages 設定仍為 main 分支根目錄、legacy build，未切換來源、覆蓋 index.html 或合併 main。

遊戲來源：GitHub commit `831d14318f02e526d3bb174fa83abfc8b01ed2a3`，Actions run `40721247540` 成功（57 引擎檢查及 WebGL 觸控 smoke），artifact `12830312750`。下載的原 artifact SHA-256 已比對官方 digest：`e76c6d80c66151960334aa250c651b2b16e8c74841529ce87e6cdb87cf955232`。

## 部署方式

`prepare_site.py <artifact.zip> <site-directory>` 取出 CI 的 `dist/SpiritGuardian-Web-M2.zip`。為符合靜態主機單檔限制，37,700,666 bytes 的 wasm 分成3個最多12MiB的檔案，由 `wasm-stream.js` 還原成串流 Response 供原 Godot loader 使用。串流後SHA-256與原wasm完全相同；index.pck、引擎JS與遊戲GDScript不改動。只修改HTML語言／標題及新增串流載入器。

發布成功的 Site／version／deployment ID及來源SHA見 `site.json`。這些是識別資料，不含任何憑證。沿用相同 Site ID 更新，不要再建立另一個同名Site。

本執行環境未提供 Sites skill 指定的 source helper，使用等價的 Git 準備、推送及 `git archive` 備援流程：Git認證只從停用回顯的stdin進入子程序環境，不存檔、不寫入Git config；以遠端HEAD確認來源SHA後，從同一HEAD封裝 `.openai/hosting.json` 與 `dist/`。再由原生 Sites save/deploy API 發布。後續若官方 helper 可用，優先使用官方流程。

## 驗證

- `test_static.py --directory <dist> --report <report.json>`：實際部署包的Linux Chromium軟體WebGL，橫1180×820及豎820×1180通過出怪、觸控暫停／恢復、速度、法術選擇、連鎖增刪復原、配置儲存／重開、音效開關；0 pageerror／Godot runtime ERROR，3個wasm分段皆200。
- `qa/local.json` 為本地部署包測試，`qa/landscape-game.png` 是本地實際Godot WebGL截圖，非概念圖、非正式站遠端截圖、非iPad實機截圖。
- 正式站以現有owner-private測試授權及TLS驗證讀取：HTML200、三段wasm200且逐段與合併hash一致、PCK與CI原檔一致，證據 `qa/live-assets.json`。憑證未寫入報告。
- 正式站瀏覽器自動化遇到測試環境的 `ERR_CERT_AUTHORITY_INVALID`。已嘗試臨時匯入環境CA，仍未通過；沒有停用TLS驗證或宣稱遠端互動已通過。本地部署包互動與正式站檔案完整性各自通過。
- iPad Safari真機操作、長跑記憶體、瀏覽器儲存／音訊仍需擁有者實測。開啟網址若要求登入，使用建立本專案的ChatGPT帳號。

此版本仍為M2功能接入版，保留8可執行法術、配置存檔及暫用美術的既有限制；完整機制範圍見 `docs/M2_MODULES.md`。
