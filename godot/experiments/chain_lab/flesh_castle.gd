extends "res://modules/tower/tower.gd"
# Source growth module: drops 4/16/48; cost 6+7*level; atk +50%, HP +65,
# armor +2 (7% each, capped at 70%), regeneration +2 per simulation second.
# Lab adds a 360-HP wall before the original 100-HP core and optional autobuy.
signal growth_changed
const BASE_WALL:=360.0
const ORDER: Array[String]=["atk","hp","armor","regen"]
var wall_max:=BASE_WALL
var wall_hp:=BASE_WALL
var wall_active:=true
var flesh:=0
var total_absorbed:=0
var levels: Dictionary={"atk":0,"hp":0,"armor":0,"regen":0}
var auto_upgrade:=true
var auto_cursor:=0
var max_hp:=100.0
func cost(stat: String) -> int:
 return 6+int(levels.get(stat,0))*7 if stat in levels else -1
func attack_multiplier() -> float:return 1.0+0.5*int(levels.atk)
func reduction() -> float:return minf(0.70,0.14*int(levels.armor))
func regeneration() -> float:return 2.0*int(levels.regen)
func upgrade(stat: String) -> bool:
 if stat not in levels or flesh<cost(stat) or hp<=0:return false
 flesh-=cost(stat);levels[stat]=int(levels[stat])+1
 if stat=="hp":wall_max+=65;wall_hp=minf(wall_max,wall_hp+65);check_wall_recovery()
 growth_changed.emit();return true
func absorb(amount: int) -> void:
 if amount<=0:return
 flesh+=amount;total_absorbed+=amount
 if auto_upgrade and hp>0:
  for i in 128:
   var stat: String=ORDER[auto_cursor%ORDER.size()]
   if not upgrade(stat):break
   auto_cursor+=1
 growth_changed.emit()
func set_auto(value: bool) -> void:
 auto_upgrade=value
 if value:spend_available()
 growth_changed.emit()
func spend_available() -> void:
 if not auto_upgrade or hp<=0:return
 for i in 128:
  if not upgrade(ORDER[auto_cursor%ORDER.size()]):break
  auto_cursor+=1
func check_wall_recovery() -> void:
 if not wall_active and wall_hp>=wall_max*0.2:wall_active=true
func recover(delta: float) -> void:
 if hp<=0 or delta<=0:return
 var budget:=regeneration()*delta
 if budget<=0:return
 var repair:=minf(wall_max-wall_hp,budget);wall_hp+=repair;budget-=repair
 check_wall_recovery()
 hp=minf(max_hp,hp+budget)
 health_changed.emit(hp,max_hp)
func take_damage(amount: float) -> void:
 if hp<=0 or not is_finite(amount) or amount<=0:return
 var damage:=maxf(1.0,amount*(1.0-reduction()))
 if wall_active:
  var stopped:=minf(wall_hp,damage);wall_hp-=stopped;damage-=stopped
  if wall_hp<=0:wall_hp=0;wall_active=false
 hp=maxf(0,hp-damage)
 health_changed.emit(hp,max_hp);growth_changed.emit()
 if hp<=0:destroyed.emit()
func reset() -> void:
 hp=100;max_hp=100;wall_max=BASE_WALL;wall_hp=BASE_WALL;wall_active=true
 flesh=0;total_absorbed=0;levels={"atk":0,"hp":0,"armor":0,"regen":0};auto_cursor=0;auto_upgrade=true
 health_changed.emit(hp,max_hp);growth_changed.emit()
