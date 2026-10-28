# Godot 4 架構與下一階段介面

> 此文件保留M1當時狀態；M2實際接入與最新限制見 [M2_MODULES.md](M2_MODULES.md) 與 [M2_TESTING.md](M2_TESTING.md)。

使用 GDScript、Compatibility（gl_compatibility）、單執行緒 Web 匯出。M1 沒有外掛、C#、付費依賴或伺服器依賴。

```text
godot/
  project.godot
  export_presets.cfg
  scenes/main.tscn
  scripts/main.gd              # 組裝、波次、選敵、遊戲狀態
  assets/legacy/               # 暫用抽取圖及 terrain cache
  modules/
    arena/arena.gd             # 地形 Sprite、Camera2D
    tower/tower.gd             # 生命／死亡、獨立塔 Sprite
    enemy/enemy.gd             # 移動／近戰、三種圖集
    boss/                     # 計畫，尚未實作
    spell/projectile.gd        # 彈體追蹤與命中
    resonance/                # 計畫
    chain_graph/              # 計畫
    combat_fx/combat_fx.gd     # 有上限的命中 Sprite
    progression/              # 計畫
    ui/hud.gd                 # 暫停／速度／開波／重開／法術按鈕
    save_system/              # 計畫
    audio/                    # 計畫
  tests/integration.gd
```

`README.md` 目錄占位不構成已實作模組。M1 是一個主 `.tscn` 配上獨立腳本元件，由 main 組裝；後續會將可重用的敵人／Boss／塔拆為 PackedScene，資料改用 Resource。避免空殼 API 偽裝完成。

## 已執行的訊號

- Enemy `attacked(amount)` → Tower.take_damage；Enemy `died(enemy)` → main 擊殺統計。
- Tower `health_changed(current,maximum)` → HUD；`destroyed` → GameOver。
- Projectile 目前直接呼叫 target.take_damage，再送 `impacted(at,element)` → main → CombatFX。
- HUD 僅送 pause／speed／wave／restart／element_selected；不改戰鬥函式。
- main 是波次與狀態唯一擁有者。`SceneTree.paused` 暫停戰鬥子樹，HUD `PROCESS_MODE_ALWAYS` 保持可操作；`Engine.time_scale` 控制 1×／2×，restart 清回 1×。

## 第三階段要先落地的資料契約（尚未實作）

`SpellDefinition(Resource)`：id、element、base_damage、cooldown、range、target_mode、projectile_scene、status_effects。`HitContext(RefCounted)`：event_id、source_id、target_id、spell_id、element、amount、critical、chain_run_id、depth。`HitResult`：actual_damage、absorbed、killed、status_applied、target_id、position。穩定 ID 不使用 Node instance id 當存檔鍵。

先加單一 CombatResolver，負責護盾／抗性／暴擊／HP／死亡；發出 `hit_resolved(result,context)`。Spell、ChainGraph、Resonance 都請求 resolver 結算；FX／Audio／Progression 訂閱結果，不能重算或覆寫 damage。M1 的直接命中會在這一步替換。

ChainGraph 圖資料：node_id、kind、definition_id、quality、position；edge：from、to、condition。支援任意多節點與 DAG；若要容許環，必須用 run_id 去重、深度與事件預算、每 tick budget、最大 pending、cooldown 截斷。暫停與速度使用遊戲時間。編輯器預覽與執行器共享驗證器。驗收包含：多分支、四格以上、16 層、刪除在途節點、目標死亡轉移、無限環、壞存檔、同一事件 FX／傷害各一次。

Resonance：配方 Resource＋元素狀態堆疊、共享 hit_resolved，區分六種連鎖反應與 50 三技能共鳴；不能用圖鑑名稱數量代替實際差異。

Boss：Enemy 共用 CombatResolver，階段機器發出 telegraph_started／phase_changed／summon_requested／defeated；Arena 顯示預警；召喚由 wave/spawner 確認數量；死亡獎勵去重。

Progression：獨立 seeded RNG、reward_requested／reward_selected；保底與重抽可序列化；UI 不呼叫隨機函式。SaveSystem：schema_version、run_seed、RNG state、tower、wave/spawn、enemy IDs、skills、graph、pity、meta；版本遷移與原子／備份寫入。暫存 FX 不存檔，pending chain 在存／載策略中明確定義。Web 採 `user://`（瀏覽器持久層），加匯出／匯入 JSON 備份並顯示寫入失敗，不能保證 Safari 永久保留。

Audio：獨立 Music/SFX bus、上限／冷卻、首次點擊啟用，跟隨暫停／分頁背景事件。

## 交付階段

1. 本次：原始盤點、可追蹤功能、M1 戰鬥、引擎測試、匯出工作流。
2. 下一次：CombatResolver＋Resource、完整火冰雷毒奧術／修飾技能、ChainGraph 資料與執行器、觸控節點編輯器、共振；每個機制附事件與預算測試。
3. 再下一次：特殊／精英、Boss、Roguelite、遺物／掉落、完整存檔與舊資料遷移。
4. 視覺與效能：拆遠景／地形／瀑布／前景、正式塔及怪物動畫、分階 Boss、粒子預警；iPad Safari 真機橫豎屏、熱機長跑、P95／記憶體／觸控驗收。
5. iOS 原生上架：Mac/Xcode 簽章／provisioning、Apple 帳號與商店素材；Godot 免費，Apple 發佈及 macOS runner 等仍可能收費。Web CI 不等於 App Store 可上架包。
