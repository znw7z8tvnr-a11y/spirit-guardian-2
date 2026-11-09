extends RefCounted
## Lab spell rules, separated from projectile timing and chain traversal.
const Catalog=preload("res://modules/spell/catalog.gd")
const PLAYABLE=["fire","ice","lightning","arcane","poison","meteor","nova","beam","pierce","earth","wind","sword","spark","storm","blizzard","lava","swamp","gravity","orbit","thorn","summon","skeleton"]
const Art=preload("res://modules/spell/projectile.gd")
const SKELETON_ART=preload("res://experiments/chain_lab/assets/skeleton_guardian.svg")
const BONE_SEAL=preload("res://experiments/chain_lab/assets/bone_seal.svg")
const SUMMON_ART=preload("res://experiments/chain_lab/assets/summon.svg")
const GHOST_ART=preload("res://experiments/chain_lab/assets/ghost_guardian.svg")
const THORN_ART=preload("res://experiments/chain_lab/assets/thorn.svg")
const THORN_SPIKE=preload("res://experiments/chain_lab/assets/thorn_spike.svg")
const ORBIT_ART=preload("res://experiments/chain_lab/assets/orbit.svg")
const ORBIT_ORB=preload("res://experiments/chain_lab/assets/orbit_orb.svg")
const GRAVITY_ART=preload("res://experiments/chain_lab/assets/gravity.svg")
const GRAVITY_SHARD=preload("res://experiments/chain_lab/assets/gravity_shard.svg")
const SWAMP_ART=preload("res://experiments/chain_lab/assets/swamp.svg")
const SWAMP_HAZE=preload("res://experiments/chain_lab/assets/swamp_haze.svg")
const LAVA_ART=preload("res://experiments/chain_lab/assets/lava.svg")
const LAVA_FLAME=preload("res://experiments/chain_lab/assets/lava_flame.svg")
const BLIZZARD_ART=preload("res://experiments/chain_lab/assets/blizzard.svg")
const BLIZZARD_SHARD=preload("res://experiments/chain_lab/assets/blizzard_shard.svg")
const STORM_ART=preload("res://experiments/chain_lab/assets/storm.svg")
const STORM_BOLT=preload("res://experiments/chain_lab/assets/storm_bolt.svg")
const GROUND_RULES={"earth":{"radius":75.0,"limit":24},"wind":{"radius":125.0,"limit":24},"sword":{"radius":110.0,"limit":24},"spark":{"radius":165.0,"limit":6},"storm":{"radius":155.0,"limit":24},"blizzard":{"radius":155.0,"limit":24},"lava":{"radius":75.0,"limit":24},"swamp":{"radius":75.0,"limit":24},"gravity":{"radius":125.0,"limit":24},"orbit":{"radius":75.0,"limit":24},"thorn":{"radius":75.0,"limit":24}}
const SPARK_ART=preload("res://experiments/chain_lab/assets/spark.svg")
const SWORD_ART=preload("res://experiments/chain_lab/assets/sword.svg")
const WIND_ART=preload("res://experiments/chain_lab/assets/wind.svg")
const EARTH_ART=preload("res://experiments/chain_lab/assets/earth.svg")
const BEAM_ART=preload("res://experiments/chain_lab/assets/beam.svg")
const ATLAS_REGIONS={"pierce":[&"lightning",Rect2(0,30,300,61)],"fire":[&"fire",Rect2(0,0,300,94)],"ice":[&"ice",Rect2(0,0,300,78)],"lightning":[&"lightning",Rect2(0,30,300,61)],"arcane":[&"arcane",Rect2(0,14,108,65)],"poison":[&"arcane",Rect2(110,13,190,75)],"meteor":[&"fire",Rect2(0,0,300,94)],"nova":[&"nova",Rect2(102,33,174,136)]}
static var textures: Dictionary={}
static func texture(key: String) -> Texture2D:
 if key=="skeleton":return SKELETON_ART
 if key=="summon":return GHOST_ART
 if key=="thorn":return THORN_ART
 if key=="orbit":return ORBIT_ART
 if key=="gravity":return GRAVITY_ART
 if key=="swamp":return SWAMP_ART
 if key=="lava":return LAVA_ART
 if key=="blizzard":return BLIZZARD_ART
 if key=="storm":return STORM_ART
 if key=="spark":return SPARK_ART
 if key=="sword":return SWORD_ART
 if key=="wind":return WIND_ART
 if key=="earth":return EARTH_ART
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
const DESCRIPTIONS={"skeleton":"骷髏召喚：單體直擊後召喚 8 秒骷髏；索敵 400、近戰 48、每 0.8 秒揮砍，基礎 11；與幽靈共用等級加一上限","summon":"幽靈守衛：單體直擊後召喚 8 秒幽靈；索敵 400、近身 65、每 0.55 秒雷擊，基礎 9；上限為技能等級加一","thorn":"荊棘護城：半徑 75 內最多 24 個目標；刺叢只結算一次，非永久城牆或反傷","orbit":"旋轉法球：半徑 75 內最多 24 個目標；五顆法球只結算一次，非永久環繞","gravity":"引力漩渦：風系，半徑 125 內最多 24 個目標；向內旋轉只結算一次，無吸怪位移","swamp":"毒沼：毒系，半徑 75 內最多 24 個目標；中毒 2.5 秒，每 0.5 秒 3 傷害","lava":"熔岩裂隙：火系，半徑 75 內最多 24 個目標；裂焰只結算一次","blizzard":"暴風雪：冰系，半徑 155 內最多 24 個目標，緩速 1.8 秒；冰晶只結算一次","storm":"雷電風暴：雷系，落點半徑 155 內，最多 24 個目標；落雷只結算一次","spark":"火花術：雷系，落點半徑 165 內，最多 6 個目標，每個目標完整傷害","sword":"迴旋月刃：火系，落點半徑 110 內，最多 24 個目標；旋轉只結算一次","wind":"颶風：落點半徑 125 內風系爆發，最多 24 個目標","earth":"土刺：落點半徑 75 內地面爆發，最多 24 個目標","pierce":"雷系水平掃射｜目標橫向帶半寬 38，最多 8 個目標","arcane":"單體奧術攻擊","fire":"爆裂：最多波及兩個鄰近目標","ice":"單體寒冰攻擊，附加緩速","lightning":"雷擊：最多波及兩個鄰近目標","poison":"附毒 2.5 秒，每 0.5 秒造成 3 傷害","meteor":"延遲落擊，半徑 145，最多 24 個目標","nova":"冰霜擴散，半徑 75，最多 24 個目標並緩速","beam":"沿本段施法方向穿透，最多 8 個目標"}
static func description(key: String) -> String:return DESCRIPTIONS.get(key,"尚未實作")
static func power(key: String, level: int, boost: float) -> float:
 return Catalog.power(key)*(1+0.55*(clampi(level,1,3)-1))*boost
static func living(enemy: Node2D) -> bool:return is_instance_valid(enemy) and not enemy.dead
static func impact(key: String, primary: Node2D, origin: Vector2, at: Vector2, level: int, boost: float, enemies: Array, resolver: Node) -> Dictionary:
 var outcome: Dictionary={"hit":false,"killed":false,"critical":false,"position":at,"element":Catalog.element(key),"damage":0.0,"hit_count":0,"target_id":0,"hit_positions":[],"slowed_hit":false,"lowest_hp_ratio":1.0}
 if key not in PLAYABLE:return outcome
 var victims: Array=[]
 var all: Array=enemies.filter(func(enemy):return living(enemy))
 if GROUND_RULES.has(key):
  var rule: Dictionary=GROUND_RULES[key]
  victims=all.filter(func(enemy):return enemy.position.distance_to(at)<float(rule.radius))
  victims.sort_custom(func(a,b):return a.position.distance_squared_to(at)<b.position.distance_squared_to(at))
  if living(primary) and primary in victims:victims.erase(primary);victims.push_front(primary)
  victims=victims.slice(0,int(rule.limit))
 elif key in ["meteor","nova"]:
  var radius:=145.0 if key=="meteor" else 75.0
  victims=all.filter(func(enemy):return enemy.position.distance_to(at)<=radius)
  victims.sort_custom(func(a,b):return a.position.distance_squared_to(at)<b.position.distance_squared_to(at));victims=victims.slice(0,24)
 elif key=="pierce":
  victims=all.filter(func(enemy):return absf(enemy.position.y-at.y)<38.0)
  victims.sort_custom(func(a,b):
   var da: float=a.position.distance_squared_to(at);var db: float=b.position.distance_squared_to(at)
   return a.get_instance_id()<b.get_instance_id() if is_equal_approx(da,db) else da<db
  )
  if living(primary) and primary in victims:victims.erase(primary);victims.push_front(primary)
  victims=victims.slice(0,8)
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
  outcome.lowest_hp_ratio=minf(float(outcome.lowest_hp_ratio),clampf(enemy.hp/maxf(enemy.max_hp,0.001),0.0,1.0))
  outcome.slowed_hit=bool(outcome.slowed_hit) or enemy.slow_time>0
  outcome.hit_positions.append(enemy.position)
  outcome.hit=true;outcome.hit_count+=1;outcome.damage+=float(result.get("damage",0))
  outcome.killed=bool(outcome.killed) or bool(result.get("killed",false))
 return outcome
