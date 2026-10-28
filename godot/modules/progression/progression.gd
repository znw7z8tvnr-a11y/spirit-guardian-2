extends RefCounted
const Catalog = preload("res://modules/spell/catalog.gd")
var rng := RandomNumberGenerator.new()
var levels := {"fire":1,"ice":1,"lightning":1,"arcane":1}
var pity := 0
var rerolls := 1
var locked := -1
var options: Array = []
var claimed := true
func _init() -> void:
 rng.seed = 3200
func generate() -> Array:
 var tier := "legendary" if pity>=7 or rng.randf()<0.055 else "epic" if pity>=4 or rng.randf()<0.19 else "rare"
 var keys: Array = Catalog.PLAYABLE.duplicate()
 var held: Dictionary = options[locked].duplicate() if locked>=0 and locked<options.size() else {}
 if not held.is_empty():keys.erase(held.key)
 options=[]
 for i in 3:
  var index:=rng.randi_range(0,keys.size()-1)
  var key: String=keys.pop_at(index)
  options.append({"key":key,"tier":tier if i==0 else "common","power":3 if tier=="legendary" and i==0 else 2 if tier=="epic" and i==0 else 1})
 if not held.is_empty():
  if tier=="legendary" and held.tier!="legendary":options[(locked+1)%3].merge({"tier":"legendary","power":3},true)
  options[locked]=held
 claimed=false
 return options
func reroll() -> bool:
 if claimed or rerolls<=0:return false
 rerolls-=1
 generate()
 return true
func claim(index: int) -> bool:
 if claimed or index<0 or index>=options.size():return false
 var reward: Dictionary=options[index]
 levels[reward.key]=int(levels.get(reward.key,0))+int(reward.power)
 pity=0 if reward.tier=="legendary" else mini(7,pity+1)
 claimed=true
 locked=-1
 rerolls=1
 return true
func multiplier(key: String) -> float:
 return 1.0 + maxf(0,float(levels.get(key,1))-1)*0.12
