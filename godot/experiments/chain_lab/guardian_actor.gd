extends Node2D
## Data and bounded Sprite presentation; manager owns AI and damage.
const GHOST=preload("res://experiments/chain_lab/assets/ghost_guardian.svg")
const SEAL=preload("res://experiments/chain_lab/assets/summon.svg")
const BONE=preload("res://experiments/chain_lab/assets/skeleton_guardian.svg")
const BONE_SEAL=preload("res://experiments/chain_lab/assets/bone_seal.svg")
const SLASH=preload("res://experiments/chain_lab/assets/bone_slash.svg")
var species:="summon"
var facing_left:=false
const Art=preload("res://modules/spell/projectile.gd")
var remaining:=8.0
var age:=0.0
var cooldown:=0.0
var power:=9.0
var strikes:=0
var target_id:=0
var intent:="待命"
var flash:=0.0
var strike_point:=Vector2.ZERO
var spirit: Sprite2D
var bolt: Sprite2D
func _ready() -> void:
 var seal:=Sprite2D.new();seal.texture=BONE_SEAL if species=="skeleton" else SEAL;seal.scale=Vector2(0.24,0.15);seal.modulate.a=0.35;add_child(seal)
 spirit=Sprite2D.new();spirit.texture=BONE if species=="skeleton" else GHOST;spirit.scale=Vector2.ONE*0.5;spirit.position.y=-30;add_child(spirit)
 bolt=Sprite2D.new();var atlas:=AtlasTexture.new();atlas.atlas=Art.TEXTURES[&"lightning"];atlas.region=Rect2(0,30,300,61);bolt.texture=SLASH if species=="skeleton" else atlas;bolt.hide();add_child(bolt)
func present(delta: float) -> void:
 flash=maxf(0.0,flash-delta)
 spirit.flip_h=facing_left
 spirit.position.y=-30+(sin(age*9.0)*1.5 if species=="skeleton" and intent=="追擊" else sin(age*3.5)*(1.0 if species=="skeleton" else 4.0))
 spirit.rotation=sin(flash*22)*0.12 if species=="skeleton" and flash>0 else 0.0
 spirit.modulate=Color(1.3,1.6,1.8) if flash>0 else Color.WHITE
 bolt.visible=flash>0
 if bolt.visible:
  var offset:=strike_point-position
  bolt.position=offset*0.5+Vector2(0,-16);bolt.rotation=offset.angle();bolt.scale=Vector2(maxf(12,offset.length())/300.0,0.20)
  if species=="skeleton":bolt.position=Vector2(-18 if facing_left else 18,-22);bolt.rotation=(-0.8+flash/0.14*1.6)*(-1 if facing_left else 1);bolt.scale=Vector2.ONE*0.65
 modulate.a=clampf(remaining/0.65,0.0,1.0)
