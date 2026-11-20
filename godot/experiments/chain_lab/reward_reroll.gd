extends RefCounted
## Content identity ignores display order. No inventory, grade or charge mutation.
static func signature(offers: Array) -> Array:
 var rows: Array=[]
 for item in offers:rows.append("%s:%s:%d" % [item.kind,item.key,int(item.level)])
 rows.sort()
 return rows
static func replace_skill(offers: Array,keys: Array,rng: RandomNumberGenerator) -> bool:
 for item in offers:
  if item.kind!="skill":continue
  var alternatives: Array=keys.filter(func(key):return key!=item.key)
  if alternatives.is_empty():return false
  item.key=alternatives[rng.randi_range(0,alternatives.size()-1)]
  return true
 return false
