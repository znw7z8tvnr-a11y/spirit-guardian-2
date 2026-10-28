extends RefCounted
const Catalog = preload("res://modules/spell/catalog.gd")
func evaluate(previous: String, current: String, elements: Array, finisher_used: bool) -> Dictionary:
 var pair := [previous,current]
 pair.sort()
 var fusion: Array = Catalog.data.FUSIONS.get("+".join(pair), [])
 var result := {"multiplier":1.0,"fusion":"","finisher":""}
 if not fusion.is_empty():
  result.multiplier *= float(fusion[1])
  result.fusion = str(fusion[0])
 if not finisher_used:
  for key in Catalog.data.FINISHERS:
   var matches := true
   for element in str(key).split("+"):
    if element not in elements:
     matches = false
   if matches:
    var finisher: Array = Catalog.data.FINISHERS[key]
    result.multiplier *= float(finisher[1])
    result.finisher = str(finisher[0])
    break
 return result
