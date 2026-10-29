extends RefCounted
## First source-backed gem batch; relay remains a separate lab tuning item.
const KEYS=["relay","chance","hit","kill","split","echo","burn","freeze","lowhp","delay"]
const NAMES={"relay":"接續寶石","chance":"機率觸發","hit":"命中觸發","kill":"擊殺觸發","split":"法術增幅","echo":"迴響寶石","burn":"灼燒觸發","freeze":"冰凍觸發","lowhp":"殘血追擊","delay":"時序寶石"}
const RATES={"relay":[0.85,0.93,1.0],"chance":[0.25,0.45,0.65],"hit":[0.30,0.45,0.60],"kill":[0.40,0.70,1.0],"split":[1.0,1.0,1.0],"echo":[1.0,1.0,1.0],"burn":[0.4,0.65,0.9],"freeze":[0.4,0.65,0.9],"lowhp":[1.0,1.0,1.0],"delay":[1.0,1.0,1.0]}
const COLORS={"relay":Color("ffffff"),"chance":Color("b6a5ff"),"hit":Color("80e8ff"),"kill":Color("ff937b"),"split":Color("ffd36e"),"echo":Color("e9a6ff"),"burn":Color("ff9559"),"freeze":Color("91c5ff"),"lowhp":Color("ff89ad"),"delay":Color("d7b1ff")}
static func tint(key: String) -> Color:return COLORS.get(key,Color.WHITE)
static func title(key: String) -> String:return NAMES.get(key,"未支援寶石")
static func description(key: String,level: int) -> String:
 if not RATES.has(key):return "尚未實作，不會觸發"
 if key=="delay":return "每 %d 秒可接續一次｜首次可用｜冷卻中結束支線｜落空可判定｜最多 %d 條線" % [int(delay_seconds(level)),2 if level==3 else 1]
 if key=="lowhp":return "本次命中後任一受擊敵人生命不高於 %d%% 即接續｜含擊殺｜最多 %d 條線" % [roundi(lowhp_threshold(level)*100),2 if level==3 else 1]
 if key=="echo":return "保證接續｜下一個技能 %d%% 機率追加一次，不延伸後續節點｜最多 %d 條線" % [roundi(echo_chance(key,level)*100),2 if level==3 else 1]
 if key=="split":return "保證接續｜下一個技能直擊傷害 +%d%%｜最多接續 %d 條線" % [roundi((next_multiplier(key,level)-1)*100),2 if level==3 else 1]
 var condition: String={"relay":"施放後判定，落空也可接續","chance":"施放後判定，落空也可接續","hit":"實際命中後才判定","kill":"實際擊殺後才判定","burn":"火焰實際命中後判定，不附加持續灼燒","freeze":"冰系命中或命中正在緩速的敵人後判定"}[key]
 return "%s｜觸發率 %d%%｜最多接續 %d 條線" % [condition,roundi(RATES[key][clampi(level,1,3)-1]*100),2 if level==3 else 1]
static func succeeds(key: String,level: int,source: Dictionary,rng: RandomNumberGenerator) -> bool:
 if not eligible(key,source,level):return false
 var roll:=rng.randf()
 var rate:=float(RATES[key][clampi(level,1,3)-1])
 return rate>=1.0 or roll<rate

static func eligible(key: String,source: Dictionary,level: int=1) -> bool:
 if not RATES.has(key):return false
 if key in ["hit","kill","burn","freeze","lowhp"] and not source.get("hit",false):return false
 if key=="kill" and not source.get("killed",false):return false
 if key=="burn" and source.get("element","")!="fire":return false
 if key=="freeze" and source.get("element","")!="ice" and not source.get("slowed_hit",false):return false
 if key=="lowhp":
  var ratio:=float(source.get("lowest_hp_ratio",INF))
  return is_finite(ratio) and ratio>=0 and ratio<=lowhp_threshold(level)
 return true

static func next_multiplier(key: String,level: int) -> float:
 return 1.0+float([0.10,0.20,0.35][clampi(level,1,3)-1]) if key=="split" else 1.0

static func echo_chance(key: String,level: int) -> float:
 return float([0.20,0.35,0.50][clampi(level,1,3)-1]) if key=="echo" else 0.0

static func may_follow(key: String,element: String) -> bool:
 # Auto-arrangement must not assume a target was slowed by an unrelated attack.
 if key=="burn":return element=="fire"
 if key=="freeze":return element=="ice"
 return key in KEYS

static func lowhp_threshold(level: int) -> float:return float([0.25,0.40,0.55][clampi(level,1,3)-1])
static func preferred_starter(key: String) -> bool:return key in ["relay","split","echo"]

static func delay_seconds(level: int) -> float:return float([3.0,2.0,1.0][clampi(level,1,3)-1])
