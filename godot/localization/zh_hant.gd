extends RefCounted
# Stable engine/save/test IDs remain English; only player-facing text changes.
const Catalog = preload("res://modules/spell/catalog.gd")
const LABELS := {
 "Chain":"寶石連鎖", "Audio: off":"音效：關", "Audio: on":"音效：開",
 "Pause":"暫停", "Resume":"繼續", "1x":"1×", "Next wave":"提前開波", "Restart":"重新開始",
 "Add":"新增", "Remove":"移除", "Done":"完成並返回", "Demo":"示範配置", "Undo":"復原", "Redo":"重做",
 "Export JSON":"匯出配置", "Import JSON":"匯入配置", "Cancel link":"取消連線", "Link mode":"連線模式：新增"
}
const RARITIES := {"common":"普通", "rare":"稀有", "epic":"史詩", "legendary":"傳說"}
const BOSS_NAMES := ["深淵領主・裂晶王", "虛空暴君・夜魘", "星骸巨像・終幕"]
static func spell(key: String) -> String:
 return str(Catalog.data.SK[key][1]) if Catalog.data.SK.has(key) else key
static func gem(key: String) -> String:
 return str(Catalog.data.GEM[key][1]) if Catalog.data.GEM.has(key) else key
static func rarity(key: String) -> String:
 return RARITIES.get(key,key)
static func ui(key: String) -> String:
 if key.to_lower() in Catalog.PLAYABLE:
  return spell(key.to_lower())
 return LABELS.get(key,key)
