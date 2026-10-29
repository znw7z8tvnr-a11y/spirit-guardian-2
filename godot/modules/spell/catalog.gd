extends RefCounted
static var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/supplement_catalog.json"))
const PLAYABLE := ["fire", "ice", "lightning", "arcane", "poison", "meteor", "nova", "beam"]
static func power(key: String) -> float:
 return float(data.SK[key][3])
static func element(key: String) -> String:
 if key=="pierce":return "lightning"
 if key in ["nova"]:
  return "ice"
 if key in ["beam", "arcane"]:
  return "arcane"
 return data.ELEMENT.get(key, key)
