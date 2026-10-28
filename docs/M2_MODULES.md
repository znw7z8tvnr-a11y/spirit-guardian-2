# M2：11 個補充檔案接入紀錄

2026-10-28，延續 M1 提交 `9fbb589`，獨立本地分支 `godot/m2-module-supplement`。所有 11 個附件已**原樣**收錄於 `reference_modules/`；原本根目錄 27 個 HTML 未修改。雜湊、大小、標題、腳本重複比對見 `supplement-manifest.json`。檔名含 final / complete / integrated 不作為整合成功證據。

## 逐附件處理

| 附件 | 實際發現 | M2 Godot 接入狀態 |
|---|---|---|
| enemy_ai_final | 核心 API `SGEnemyAI10.version=14.final`，標題仍寫 v11；6 類策略、74px 空間格、最多7鄰居、護盾／鼓舞預警 | 已接衝刺、迂迴、裝甲護盾、巫師遠攻／治療、精英繞側／鼓舞、空間格分離。未逐一接齊80 id／16 trait／精英詞綴 |
| gem_chain_module_v9_integrated | 真正 V9，含 undo/redo、JSON、6 融合、4 終結；V32 只含其部分 patch，不是整個 V9 | 已接自由 DAG、19 寶石條件／數值、8 可執行技能、分支排程、6雙元素融合／4終結、圖編輯與 undo/redo、Godot JSON。原 V9 樹 JSON 轉換尚未支援 |
| ui_final_integrated | 完整主遊戲加 UI 多層包裝；後續12段腳本與 V32 相同 | 已重製8法術選擇、圖編輯 modal、增刪／連線／undo/redo／JSON、三選一 modal。尚未等價重製所有圖鑑、設定、縮放／鍵盤焦點細節 |
| boss_v5_playable | 獨立 host 範例＋Boss engine；engine 第1段與 V32 同文 | 已接3型選招、70%/35%三階、25/45護盾、弱點、失衡、預警、真正傷塔與最多8存活召喚物。招式幾何、封印／重力狀態、完整自適應仍待移植，不能稱 Boss v5 完整等價 |
| module11_performance_audio_v10 | 單獨版本有正確 DOM，短測正常；V32 是拼接時缺 DOM | 已取8 voices與90ms節流策略，預設靜音／觸控開啟的暫用合成 SFX、debug FPS與傷害／連鎖計數。原場景音樂、完整音效曲線、P95面板／節能設定尚未移植 |
| v31_16_skills_final | **仍實測報 `sg7Resonance is not defined`**；核心有配方去重與 lastId，外部擴充依然跨 IIFE 直接取用 | 已抽出50不重複配方＋50領域 profile JSON；目前執行的是V9的6融合／4終結，50持續領域／圖鑑尚未執行 |
| v31_30_combat_vfx_final | 完整主遊戲＋多套 FX hook，單獨短測正常 | 由統一命中事件觸發 Sprite 命中／融合特效與狀態、數量上限。尚未逐項重製22技能的全套FX、警示形狀與粒子 |
| background_preview_v31_18 | 純 Canvas 背景 API＋展示 host | M1 已使用同系統地形快取；M2 保留原背景完整來源供分層重製。沒有假裝這次已換成正式浮空島素材 |
| growth_rewards_v32_00_complete | **所有8段 script 均與 V32 相同**，是可對照的獨立完整來源，非額外一套疊加系統 | 已接三選一、稀有度、pity7傳說、鎖定／一次重抽、領取去重、可執行技能等級增傷。永久碎片、進化／協同／4融合成長、完整歷史尚未移植 |
| v1_8_optimized_interactive | 標題實際為 V1.7；獨立互動展示，不是主遊戲升級包 | 原樣保存為視覺／互動參考，未把展示UI和遊戲核心疊加 |
| v31_10_enemy_ai_10passes | AI 較早版本，沒有 final 版完整空間格／tactical 內容 | 原樣保存供回歸，實作以 `14.final` 為優先，不同時執行兩個AI控制器 |

所有原檔都可在參考 ZIP 中取得。來源收錄、資料抽取、功能執行、美術完成是四種不同狀態，本表刻意分開記錄。

## 實際可玩新增

- **五種普通／特殊怪＋Boss**：grunt、swift、armored、shaman、elite、boss；移動圖集、近戰／遠攻、緩速、毒素、護盾、治療、鼓舞與策略分離。
- **八種可選／可連鎖法術**：火、冰、雷、奧術、毒、隕石、新星、光束。支援 AoE、雷多目標、毒 tick、冰減速、光束直線命中。22種法術名稱／數值均保留在來源資料，但其餘14種未完成執行，編輯器會拒絕它們，避免用通用彈體冒充完成。
- **自由 DAG**：預設5節點、4連線，可以加第6個以上節點並自行拖曳插座連線、移除節點；允許分支／匯合，拒絕環路。上限500 nodes／2000 edges、16下游層、240 events/run、400 pending、24 events/tick。這些是安全預算，沒有固定四格。
- **19種寶石**：品質1–3，命中／機率／暴擊／擊殺／緩速／火命中／低血量／時序等條件與增幅，攻擊寶石施於本節點、條件增幅延續下游。大範圍／多重等仍沿原版增傷數值工作，不宣稱已做新機制。
- **六融合／四終結**：讀取原V9資料，實際改變連鎖命中傷害與觸發特效；共用單一 CombatResolver，不覆寫原傷害函式。每個run終結最多一次，避免同一AoE多目標重複推進圖。
- **每4波Boss**：選取3型，具三階、護盾、弱點、失衡與倒數預警；目前預警統一以守護水晶為目標，尚未等價實作各線／環／圈幾何。
- **每3波清完獎勵**：追蹤各波存活數，三選一時暫停；等級增傷會作用於主攻和下游法術。保底／重抽／鎖定可測，尚無永久成長。
- **配置存檔**：按 Chain → Done 保存 `user://sg_m2_build.json`，重開／重載後載入；只有配置，沒有本局續玩。Godot schema 1 可在編輯器底部 JSON 區匯入匯出，與原 HTML V9 樹形 JSON 不互通，後者暫明確拒絕。

圖編輯操作：Chain → 選法術、寶石與品質 → Add；拖曳黃色 OUT 到藍色 IN 連結。選中節點後 Remove；Undo／Redo、Demo、Export JSON／Import JSON 可用。Done 返回戰鬥並存配置。若要暫停後編輯，關閉會保持原本暫停狀態。

## 新架構與實際檔案

- `modules/enemy/steering.gd`：共用空間格與意圖；`enemy.gd`：生命、狀態、AI及戰術。
- `modules/spell/combat_resolver.gd`：唯一護盾／傷害／暴擊結算入口；`main.execute_spell` 為8技能目標策略；Projectile 僅負責飛行與請求命中。
- `modules/chain_graph/chain_graph.gd`：圖、驗證、事件預算；`resonance/resonance.gd`：融合倍率。
- `modules/boss/boss.gd`：Enemy 子類與Boss狀態；main確認實際召喚數量。
- `modules/progression/progression.gd`、`ui/chain_editor.gd`、`save_system/save_system.gd`、`audio/audio.gd`：已從M1占位變為實作。
- `data/supplement_catalog.json`、`data/resonance_profiles.json`：可重現資料抽取；`tools/build_supplement_catalog.py` 可從原樣參考檔再生資料與11張新增圖集／技能圖。
- `tests/modules.gd`：39項新測試；原18項戰鬥回歸亦保留。M1證據仍放原 `docs/`；M2證據放 `docs/m2/`。

## 未完成與下一步

下一步優先補14種未執行法術及 summon／orbit／gravity 等獨特行為、50共鳴領域的作用域安全接入、Boss線／環／圈幾何與封印／重力、完整怪物trait、原V9配置轉換、成長進化／永久強化及本局存檔。再處理分層場景、正式攻擊／受擊／死亡動畫與觸控細節。

圖像仍為原HTML暫用素材，授權未確認；地形仍是快取圖。M2是可測試功能接入版，不是最終美術、平衡或全部模組等價完成版。iPad Safari／Godot Web Editor 的實機匯入、音訊解鎖、儲存可靠性與長跑效能仍未測。原生整合測試與Chromium觸控模擬不能替代這些驗收。
