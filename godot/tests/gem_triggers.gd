extends SceneTree
const Rules=preload("res://experiments/chain_lab/gem_rules.gd")
var checks: Array=[]
var failures: Array=[]
func check(ok: bool,message: String) -> void:
 if ok:checks.append(message)
 else:failures.append(message)
func _initialize() -> void:
 var rng:=RandomNumberGenerator.new();rng.seed=101
 for key in ["hit","kill"]:
  for i in range(100):
   if Rules.succeeds(key,3,{"hit":false,"killed":true},rng):failures.append("phantom hit passed")
  check(true,key+" rejects misses including stale kill flags")
 check(not Rules.succeeds("kill",3,{"hit":true,"killed":false},rng),"nonlethal hit cannot satisfy kill")
 check(Rules.succeeds("kill",3,{"hit":true,"killed":true},rng),"level three kill guarantees continuation after actual kill")
 check(not Rules.succeeds("unknown",3,{"hit":true,"killed":true},rng),"unimplemented gems fail closed")
 for key in Rules.KEYS:
  for level in range(1,4):
   var passed:=0;var source: Dictionary={"hit":true,"killed":true}
   for i in range(10000):
    if Rules.succeeds(key,level,source,rng):passed+=1
   check(absf(passed/10000.0-float(Rules.RATES[key][level-1]))<0.025,"%s level %d source probability" % [key,level])
 check(Rules.succeeds("relay",3,{"hit":false},rng),"relay continues over empty ground")
 var rewards:=preload("res://experiments/chain_lab/rewards.gd").new();rewards.rng.seed=555
 rewards.complete_wave(3,false)
 check(rewards.offers.filter(func(o):return o.kind=="gem")[0].key=="relay","first reward keeps beginner relay")
 rewards.granted_count=1
 var seen: Array=[]
 for i in range(100):
  rewards.roll()
  var key: String=rewards.offers.filter(func(o):return o.kind=="gem")[0].key
  if key not in seen:seen.append(key)
 check(seen.size()==Rules.KEYS.size(),"later rewards offer all supported gem kinds")
 rewards.free()
 print("GEMTRIGGERS_RESULT "+JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
