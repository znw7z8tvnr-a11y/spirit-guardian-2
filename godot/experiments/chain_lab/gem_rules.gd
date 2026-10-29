extends RefCounted
## First source-backed gem batch; relay remains a separate lab tuning item.
const KEYS=["relay","chance","hit","kill"]
const NAMES={"relay":"接續寶石","chance":"機率觸發","hit":"命中觸發","kill":"擊殺觸發"}
const RATES={"relay":[0.85,0.93,1.0],"chance":[0.25,0.45,0.65],"hit":[0.30,0.45,0.60],"kill":[0.40,0.70,1.0]}
const COLORS={"relay":Color("ffffff"),"chance":Color("b6a5ff"),"hit":Color("80e8ff"),"kill":Color("ff937b")}
static func tint(key: String) -> Color:return COLORS.get(key,Color.WHITE)
static func title(key: String) -> String:return NAMES.get(key,"未支援寶石")
static func description(key: String,level: int) -> String:
 if not RATES.has(key):return "尚未實作，不會觸發"
 var condition: String={"relay":"施放後判定，落空也可接續","chance":"施放後判定，落空也可接續","hit":"實際命中後才判定","kill":"實際擊殺後才判定"}[key]
 return "%s｜觸發率 %d%%｜最多接續 %d 條線" % [condition,roundi(RATES[key][clampi(level,1,3)-1]*100),2 if level==3 else 1]
static func succeeds(key: String,level: int,source: Dictionary,rng: RandomNumberGenerator) -> bool:
 if not RATES.has(key):return false
 if key in ["hit","kill"] and not source.get("hit",false):return false
 if key=="kill" and not source.get("killed",false):return false
 return rng.randf()<float(RATES[key][clampi(level,1,3)-1])
