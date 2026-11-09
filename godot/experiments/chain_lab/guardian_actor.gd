extends Node2D
## Data and bounded Sprite presentation; manager owns AI and damage.
const GHOST=preload("res://experiments/chain_lab/assets/ghost_guardian.svg")
const SEAL=preload("res://experiments/chain_lab/assets/summon.svg")
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
 var seal:=Sprite2D.new();seal.texture=SEAL;seal.scale=Vector2(0.24,0.15);seal.modulate.a=0.35;add_child(seal)
 spirit=Sprite2D.new();spirit.texture=GHOST;spirit.scale=Vector2.ONE*0.5;spirit.position.y=-30;add_child(spirit)
 bolt=Sprite2D.new();var atlas:=AtlasTexture.new();atlas.atlas=Art.TEXTURES[&"lightning"];atlas.region=Rect2(0,30,300,61);bolt.texture=atlas;bolt.hide();add_child(bolt)
func present(delta: float) -> void:
 flash=maxf(0.0,flash-delta)
 spirit.position.y=-30+sin(age*3.5)*4
 spirit.modulate=Color(1.3,1.6,1.8) if flash>0 else Color.WHITE
 bolt.visible=flash>0
 if bolt.visible:
  var offset:=strike_point-position
  bolt.position=offset*0.5+Vector2(0,-16);bolt.rotation=offset.angle();bolt.scale=Vector2(maxf(12,offset.length())/300.0,0.20)
 modulate.a=clampf(remaining/0.65,0.0,1.0)
