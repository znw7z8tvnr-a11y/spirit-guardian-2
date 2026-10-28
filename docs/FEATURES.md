# 功能移植追蹤（M1）

「原版有」表示讀到具體程式，不代表每條分支均已實玩。沒有功能被核准刪除；未移植項保留在本表。M1 僅是第二階段的最小戰鬥循環。原始碼行號參考 V32；V31.10 作可玩回歸基線。

| 功能 | HTML 證據／整合狀態 | Godot M1 | 後續驗收 |
|---|---|---|---|
| 中央單塔 | C、sg7WallHP／p3WallDamage | 已實作、實測傷塔與死亡 | 與原生命／護甲公式對照 |
| 城堡縮小約 30% | 原大背景烘焙城堡 | 獨立塔使用 nominal 200×210 的 70%，原版尺寸比未驗收 | 同鏡頭前後截圖對比 |
| 地圖、鏡頭 | SG61_ARENA、zoom、shake | 暫用 SGBackground 地形、Camera2D | 分層島嶼／峽谷／瀑布／遠景；碰撞與路徑 |
| 普通怪 | grunt、swift、armored | 三種速率／HP、圖集移動、近戰，實測 | 抗性／步幅／攻擊動畫 |
| 特殊／精英 | shaman、elite、4 精英詞綴 | 未移植 | 治療、遠攻、迅捷、荊棘、護盾、吸血 |
| 怪物家族與特性 | 8 family、16 trait 標籤，sg7Id %16 行為 | 未移植 | 逐條對照，不能將 80 id 算 80 獨特 AI |
| 敵人護盾／重生／瞬避 | damage() 與 trait 處理 | 未移植 | 吸收、復活、瞬移各驗一次 |
| 波次、每 4 波 Boss | spawn()／wave%4 | 一般波次已實作；Boss 尚無 | 對照數量與節奏 |
| 提前開波 | 原版控制項 | 新增安全提前開波；不丟棄待生怪，實測 | 與獎勵／Boss 邊界整合 |
| 自動選敵／鎖定目標 | nearest／lockedId | 自動最近目標；鎖定未移植 | 觸控鎖定、死亡轉移 |
| 火球 | shoot fire、split、pierce | 單體追蹤火球、實測命中 | 爆破、燃燒、分裂／貫穿 |
| 冰 | ice slow、脈衝 | 單體冰彈＋1.8 秒緩速，實測 | 冰凍與範圍控制 |
| 雷 | lightningLinks／chain arcs | 雷 Sprite 單體彈；連鎖未移植 | 多目標跳躍、上限與距離 |
| 奧術 | chain SK.arcane | 單體 Sprite 彈、實測 | 原版連鎖裡映射 lightning，重製需明確元素 |
| 毒／持續傷害 | poison | 未移植 | tick 時鐘與疊層規則 |
| 主動脈衝／月刃／護盾／新星／隕石瞄準 | pulse/swords/shield/nova/castMeteor | 未移植 | 冷卻、範圍、指示器與取消操作 |
| 分裂／貫穿／環繞／攻速／召喚 | skills 與 sg7Summon | 未移植 | 每種修飾獨立測試 |
| 22 連鎖法術節點 | SK（完整清單見下） | 未移植圖系統 | 每節點實際行為與數值 |
| 19 寶石條件／攻擊增幅 | GEM、ATTACK_GEMS | 未移植 | 條件、品質 1–3、傷害套用時序 |
| 多層分支 | 最深 16、240 events/run、400 pending、24/frame | 未移植 | DAG／自由節點、環路、預算、刪節點 |
| 連鎖編輯、替換／刪除／示範／清空／縮放 | chain editor、sg_chain_v4 | 未移植 | 觸控可編輯任意連結，不限四格 |
| 6 種連鎖複合反應 | reactionTable | 未移植 | 火冰／冰雷／火毒／雷毒／火風／冰風 |
| 50 三重共鳴、圖鑑 | SG7_RESONANCES、sg7Discovered | 未移植 | 核心觸發、永久收錄、配方可取得 |
| 50 差異化持續領域 | SGResonanceZones 擴充初始化失敗 | 未移植，不算原版成功整合 | 補橋接或重建後逐型測 |
| 升級經驗、三選一 | xp／level／choose／SGGrowth | 未移植 | 抽取／選取／暫停／返回 |
| 稀有度、保底、重抽、鎖定、歷史 | SGGrowth.generate／claim 等 | 未移植 | seed 固定重現及極端亂數測試 |
| 進化、協同、4 配方融合 | evolutionLinks／fusionRecipes | 未移植 | 實際技能變動，不只提示 |
| 永久碎片、rank 0–10 | sg_growth_meta_v1 | 未移植 | 結算僅付一次、消費與上限 |
| 血肉城牆 HP／攻擊／回血／防禦 | sg7WallScreen | 未移植 | 資源扣款與全傷害共享增益 |
| 任務／遺物／精英獎勵 | missionGoal／chooseRelic／relics | 未移植 | 完成、領取與重開重置 |
| 暴擊、擊退、連擊、得分、最佳 | damage／combo／score／sg_best_v2 | 僅 kills，其他未移植 | 統計與傷害結果一致 |
| 核心舊 Boss 三種、多階段 | spawn/update 中舊邏輯 | 未移植 | 預警、階段、召喚、掉落 |
| Boss v5 適應／失衡／護盾／招式 | SG_BOSS 只有定義、沒有 host 接入 | 未移植 | 明確選用一個 Boss 結算器 |
| 暫停／繼續／1×2×／重開 | state／speedMode | 已實測 | 暫停 UI 與所有時鐘一致 |
| 觸控／鍵盤快捷鍵 | pointer、Space/Q/E/Escape | 48px 以上按鈕；快捷鍵未移植 | 真機橫豎屏、缺口／安全區、多指 |
| 設定、音量、畫質、震動、傷害數字、鏡頭模式 | prefs／settings | 未移植 | 儲存／無障礙／節能 |
| 本局續玩、12 秒／pagehide 快照 | sgP4Snapshot／Restore | 未移植，UI 明示無完整存檔 | 版本、壞檔備份、Safari 清理儲存、續玩不重複傷害 |
| 圖鑑、最佳、連鎖、永久成長存檔 | 多個 localStorage key | 未移植 | 舊存檔遷移／匯入匯出策略 |
| 多套 FX、品質／數量上限 | SGV30FX／SGV24FX／SG314FX／SG315／SGCombatFinal | Sprite 命中淡出，48 FX、64 shots、100 enemies 上限 | 粒子、層級、低畫質與效能量測 |
| 原 WebAudio 音樂／音效 | initAudio／sound／music | 無聲；Audio 未移植 | 點擊後解鎖音訊、背景暫停 |
| Module11 音樂場景／效能面板 | 缺 DOM 初始化失敗 | 未移植 | 補 UI／接 Audio 與 metrics |
| FPS／P95／錯誤面板／診斷 | SG311Diagnostics／SG312Report | headless JSON 測試；遊戲內面板未移植 | 真機指標、錯誤可讀與重試 |
| 背景 A/B 與塔景深試驗 | V32 background、V33、V34 分歧 | 只取可獨立塔的 terrain cache | 合併前決定取用版本及視覺驗收 |

22 節點：fire、ice、lightning、poison、meteor、arcane、sword、pierce、earth、wind、beam、orbit、lava、gravity、summon、thorn、spark、storm、blizzard、nova、swamp、skeleton。

19 寶石：hit、chance、kill、split、freeze、burn、echo、crit、lowhp、rapid、delay、blast、bolt、venom、frostatk、critical、piercing、range、multi。

M1 四個可選元素只是最小測試彈體；玩家學習、多法術同時裝配、完整法術特性、自由寶石圖、Roguelite 都還沒完成，不可當作第三階段完成。新增模組必須更新此表並附測試證據。
