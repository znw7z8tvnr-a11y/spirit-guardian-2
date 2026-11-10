extends RefCounted
## First source-backed gem batch; relay remains a separate lab tuning item.
const ATTACK_BONUSES={"blast":[0.15,0.30,0.50],"bolt":[0.12,0.25,0.45],"venom":[0.10,0.22,0.40],"frostatk":[0.10,0.20,0.35],"critical":[0.20,0.40,0.70],"piercing":[0.12,0.25,0.45],"range":[0.10,0.20,0.35],"multi":[0.15,0.30,0.50]}
const ATTACK_ART=preload("res://experiments/chain_lab/assets/attack_gem.svg")
const RELAY_ART=preload("res://experiments/chain_lab/assets/relay_gem.svg")
const KEYS=["relay","chance","hit","kill","split","echo","burn","freeze","lowhp","delay","blast","bolt","venom","frostatk","critical","piercing","range","multi","rapid","crit"]
const NAMES={"rapid":"迅捷寶石","crit":"暴擊條件","blast":"爆破攻擊","bolt":"雷擊攻擊","venom":"毒蝕攻擊","frostatk":"寒霜攻擊","critical":"致命攻擊","piercing":"穿刺攻擊","range":"廣域攻擊","multi":"多重攻擊","relay":"接續寶石","chance":"機率觸發","hit":"命中觸發","kill":"擊殺觸發","split":"法術增幅","echo":"迴響寶石","burn":"灼燒觸發","freeze":"冰凍觸發","lowhp":"殘血追擊","delay":"時序寶石"}
const RATES={"rapid":[1.0,1.0,1.0],"crit":[0.20,0.35,0.50],"blast":[1.0,1.0,1.0],"bolt":[1.0,1.0,1.0],"venom":[1.0,1.0,1.0],"frostatk":[1.0,1.0,1.0],"critical":[1.0,1.0,1.0],"piercing":[1.0,1.0,1.0],"range":[1.0,1.0,1.0],"multi":[1.0,1.0,1.0],"relay":[0.85,0.93,1.0],"chance":[0.25,0.45,0.65],"hit":[0.30,0.45,0.60],"kill":[0.40,0.70,1.0],"split":[1.0,1.0,1.0],"echo":[1.0,1.0,1.0],"burn":[0.4,0.65,0.9],"freeze":[0.4,0.65,0.9],"lowhp":[1.0,1.0,1.0],"delay":[1.0,1.0,1.0]}
const COLORS={"rapid":Color("a4edb1"),"crit":Color("ffe58c"),"blast":Color("ff9e64"),"bolt":Color("d8c3ff"),"venom":Color("93de99"),"frostatk":Color("9dddf2"),"critical":Color("ffadb8"),"piercing":Color("b4d2e1"),"range":Color("dac181"),"multi":Color("ffd9a0"),"relay":Color("ffffff"),"chance":Color("b6a5ff"),"hit":Color("80e8ff"),"kill":Color("ff937b"),"split":Color("ffd36e"),"echo":Color("e9a6ff"),"burn":Color("ff9559"),"freeze":Color("91c5ff"),"lowhp":Color("ff89ad"),"delay":Color("d7b1ff")}
static func tint(key: String) -> Color:return COLORS.get(key,Color.WHITE)
static func title(key: String) -> String:return NAMES.get(key,"未支援寶石")
static func description(key: String,level: int) -> String:
 if not RATES.has(key):return "尚未實作，不會觸發"
 if key in ATTACK_BONUSES:return "前一個技能直擊 +%d%%｜保證接續｜固定 1 條線｜不增加暴擊、範圍或攻擊次數" % roundi((preceding_multiplier(key,level)-1)*100)
 if key=="delay":return "每 %d 秒可接續一次｜首次可用｜冷卻中結束支線｜落空可判定｜最多 %d 條線" % [int(delay_seconds(level)),2 if level==3 else 1]
 if key=="lowhp":return "本次命中後任一受擊敵人生命不高於 %d%% 即接續｜含擊殺｜最多 %d 條線" % [roundi(lowhp_threshold(level)*100),2 if level==3 else 1]
 if key=="echo":return "保證接續｜下一個技能 %d%% 機率追加一次，不延伸後續節點｜最多 %d 條線" % [roundi(echo_chance(key,level)*100),2 if level==3 else 1]
 if key in ["split","rapid"]:return "保證接續｜下一個技能直擊傷害 +%d%%｜最多接續 %d 條線" % [roundi((next_multiplier(key,level)-1)*100),2 if level==3 else 1]
 var condition: String={"relay":"施放後判定，落空也可接續","chance":"施放後判定，落空也可接續","hit":"實際命中後才判定","crit":"本次直擊至少一個目標暴擊後判定","kill":"實際擊殺後才判定","burn":"火焰實際命中後判定，不附加持續灼燒","freeze":"冰系命中或命中正在緩速的敵人後判定"}[key]
 return "%s｜觸發率 %d%%｜最多接續 %d 條線" % [condition,roundi(RATES[key][clampi(level,1,3)-1]*100),2 if level==3 else 1]
static func succeeds(key: String,level: int,source: Dictionary,rng: RandomNumberGenerator) -> bool:
 if not eligible(key,source,level):return false
 var roll:=rng.randf()
 var rate:=float(RATES[key][clampi(level,1,3)-1])
 return rate>=1.0 or roll<rate

static func eligible(key: String,source: Dictionary,level: int=1) -> bool:
 if not RATES.has(key):return false
 if key in ["hit","kill","burn","freeze","lowhp","crit"] and not source.get("hit",false):return false
 if key=="crit" and not source.get("critical",false):return false
 if key=="kill" and not source.get("killed",false):return false
 if key=="burn" and source.get("element","")!="fire":return false
 if key=="freeze" and source.get("element","")!="ice" and not source.get("slowed_hit",false):return false
 if key=="lowhp":
  var ratio:=float(source.get("lowest_hp_ratio",INF))
  return is_finite(ratio) and ratio>=0 and ratio<=lowhp_threshold(level)
 return true

static func next_multiplier(key: String,level: int) -> float:
 return 1.0+float([0.10,0.20,0.35][clampi(level,1,3)-1]) if key in ["split","rapid"] else 1.0

static func echo_chance(key: String,level: int) -> float:
 return float([0.20,0.35,0.50][clampi(level,1,3)-1]) if key=="echo" else 0.0

static func may_follow(key: String,element: String) -> bool:
 # Auto-arrangement must not assume a target was slowed by an unrelated attack.
 if key=="burn":return element=="fire"
 if key=="freeze":return element=="ice"
 return key in KEYS

static func lowhp_threshold(level: int) -> float:return float([0.25,0.40,0.55][clampi(level,1,3)-1])
static func preferred_starter(key: String) -> bool:return key in ["relay","split","echo","rapid"]

static func delay_seconds(level: int) -> float:return float([3.0,2.0,1.0][clampi(level,1,3)-1])

static func preceding_multiplier(key: String,level: int) -> float:
 return 1.0+float(ATTACK_BONUSES[key][clampi(level,1,3)-1]) if key in ATTACK_BONUSES else 1.0
static func branch_limit(key: String,level: int) -> int:
 return 1 if key in ATTACK_BONUSES or level<3 else 2
static func texture(key: String) -> Texture2D:return ATTACK_ART if key in ATTACK_BONUSES else RELAY_ART
