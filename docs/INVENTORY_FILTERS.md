# 背包分類與可裝配篩選（Lab）

加入全部、技能、寶石、可裝配四個分類與數量；依本局取得的實體物品順序顯示，不將同名不同件合併。全部的數量不包含清空操作。分類只瀏覽本局持有物品，不揭露未知共振或贈送物品。

可裝配分類沿用實際裝備驗證，排除目前這格、其他格使用中的同一件，以及不能維持目前交替連線與分岔的物品。不是自動更改連線或降低寶石品質。若沒有結果，明確顯示空分類並停用翻頁、確認。

候選在新分類仍存在時保留預覽並移到所在頁；不在新分類時取消候選，不能誤按確認。確認前再次驗證實體物品與所有權。關閉再開回到全部第一頁，保留原操作慣例。篩選不改配置、持有物、傷害、獎勵或亂數狀態，關閉預覽不消耗物品。

獨立 inventory_filter.gd 負責純篩選；inventory_view.gd 負責分頁、預覽與確認。原生測試包含正常奧彈開局、空分類、32件演練背包、非連續實體ID分頁、候選切換、所有權改變、實際裝備及返回背包、三級分岔限制。Web 使用實際觸控操作正常背包與明確標記的技能演練背包；不注入遊戲物品或強制戰鬥狀態。

測試及實際遊戲截圖見 docs/inventory-filters，最終發布狀態以 release.json 為準。原版 HTML 與穩定 M2 入口不變。美術仍為暫用；iPad Safari 實機未測。雙魔杖、擴格、完整共振與正式美術依主計畫繼續處理，未因背包分類宣稱完成。

## 已完成交付

40組原生測試共1,352項（新增23項）通過。原始Web包與部署分塊包均通過橫直向實際觸控、分類分頁、空分類與隱藏候選防誤裝、物品返回及確認後施法；截圖為實際遊戲。完整 [GitHub Actions 44473417541](https://github.com/znw7z8tvnr-a11y/spirit-guardian-2/actions/runs/44473417541) 成功，含提前開波、續玩、20波與22技能兩類守衛回歸。

受測程式 b66fa0bac02e17f4c7c5d3be71ec9a71b751d360 已發布至既有私人 [Lab](https://spirit-guardian-m2-play.trylook.chatgpt.site/lab/)。[Godot專案ZIP](https://spirit-guardian-m2-play.trylook.chatgpt.site/lab/SpiritGuardian-Godot-ChainLab.zip) 為4,982,992 bytes，乾淨解壓後Godot匯入及600幀真實生成／施法通過。HTTPS核對HTML、PCK、WASM、來源、700字中文字型資訊與下載ZIP檢查碼／CRC一致；原版入口18檔案保持不變。

本機匯出後需同步FONT-INFO.json與FONT-LICENSE.txt；此批已對照目前來源字型檢查碼校正，遊戲PCK內容未因此改動。詳細版本與限制見 docs/inventory-filters/release.json；沒有宣稱Safari、Web Editor實機或最終美術驗收。
