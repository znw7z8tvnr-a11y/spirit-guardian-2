extends RefCounted
## Lab spell rules, separated from projectile timing and chain traversal.
const Catalog=preload("res://modules/spell/catalog.gd")
const Art=preload("res://modules/spell/projectile.gd")
const BEAM_ART=preload("res://experiments/chain_lab/assets/beam.svg")
const ATLAS_REGIONS={"fire":[&"fire",Rect2(0,0,300,94)],"ice":[&"ice",Rect2(0,0,300,78)],"lightning":[&"lightning",Rect2(0,30,300,61)],"arcane":[&"arcane",Rect2(0,14,108,65)],"poison":[&"arcane",Rect2(110,13,190,75)],"meteor":[&"fire",Rect2(0,0,300,94)],"nova":[&"nova",Rect2(102,33,174,136)]}
static var textures: Dictionary={}
static func texture(key: String) -> Texture2D:
 if key=="beam":return BEAM_ART
 if textures.has(key):return textures[key]
 if key not in ATLAS_REGIONS:key="arcane"
 var atlas:=AtlasTexture.new();atlas.atlas=Art.TEXTURES[ATLAS_REGIONS[key][0]];atlas.region=ATLAS_REGIONS[key][1]
 textures[key]=atlas;return atlas
static func impact_texture(key: String) -> Texture2D:
 if key!="meteor":return texture(key)
 if not textures.has("meteor_impact"):
  var atlas:=AtlasTexture.new();atlas.atlas=Art.TEXTURES[&"meteor"];atlas.region=Rect2(0,31,147,60);textures.meteor_impact=atlas
 return textures.meteor_impact
const DESCRIPTIONS={"arcane":"單體奧術攻擊","fire":"爆裂：最多波及兩個鄰近目標","ice":"單體寒冰攻擊，附加緩速","lightning":"雷擊：最多波及兩個鄰近目標","poison":"附毒 2.5 秒，每 0.5 秒造成 3 傷害","meteor":"延遲落擊，半徑 145，最多 24 個目標","nova":"冰霜擴散，半徑 75，最多 24 個目標並緩速","beam":"沿本段施法方向穿透，最多 8 個目標"}
static func description(key: String) -> String:return DESCRIPTIONS.get(key,"尚未實作")
static func power(key: String, level: int, boost: float) -> float:
 return Catalog.power(key)*(1+0.55*(clampi(level,1,3)-1))*boost
static func living(enemy: Node2D) -> bool:return is_instance_valid(enemy) and not enemy.dead
static func impact(key: String, primary: Node2D, origin: Vector2, at: Vector2, level: int, boost: float, enemies: Array, resolver: Node) -> Dictionary:
 var outcome: Dictionary={"hit":false,"killed":false,"critical":false,"position":at,"element":Catalog.element(key),"damage":0.0,"hit_count":0,"target_id":0,"slowed_hit":false}
 if key not in Catalog.PLAYABLE:return outcome
 var victims: Array=[]
 var all: Array=enemies.filter(func(enemy):return living(enemy))
 if key in ["meteor","nova"]:
  var radius:=145.0 if key=="meteor" else 75.0
  victims=all.filter(func(enemy):return enemy.position.distance_to(at)<=radius)
  victims.sort_custom(func(a,b):return a.position.distance_squared_to(at)<b.position.distance_squared_to(at));victims=victims.slice(0,24)
 elif key=="beam":
  var axis: Vector2=(at-origin).normalized()
  if axis==Vector2.ZERO:axis=Vector2.RIGHT
  var length:=clampf(origin.distance_to(at)+160,120,1000)
  victims=all.filter(func(enemy):
   var offset: Vector2=enemy.position-origin
   return axis.dot(offset)>=0 and axis.dot(offset)<=length and absf(axis.cross(offset))<=28
  )
  victims.sort_custom(func(a,b):return axis.dot(a.position-origin)<axis.dot(b.position-origin));
  if living(primary) and primary in victims:victims.erase(primary);victims.push_front(primary)
  victims=victims.slice(0,8)
 else:
  if living(primary):victims.append(primary)
  if key in ["fire","lightning"]:
   var neighbors: Array=all.filter(func(enemy):return enemy!=primary and enemy.position.distance_to(at)<150)
   neighbors.sort_custom(func(a,b):return a.position.distance_squared_to(at)<b.position.distance_squared_to(at));victims.append_array(neighbors.slice(0,2))
 for enemy in victims:
  if not living(enemy):continue
  var multiplier:=0.45 if key in ["fire","lightning"] and enemy!=primary else 1.0
  var result: Dictionary=resolver.resolve(enemy,power(key,level,boost)*multiplier,Catalog.element(key),{"critical":false,"spell_key":key})
  if result.is_empty():continue
  if int(outcome.target_id)==0 or enemy==primary:outcome.target_id=enemy.get_instance_id();outcome.position=enemy.position
  outcome.slowed_hit=bool(outcome.slowed_hit) or enemy.slow_time>0
  outcome.hit=true;outcome.hit_count+=1;outcome.damage+=float(result.get("damage",0))
  outcome.killed=bool(outcome.killed) or bool(result.get("killed",false))
 return outcome
