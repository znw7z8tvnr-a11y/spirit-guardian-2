extends "res://modules/enemy/enemy.gd"
## Lab-only tactical overrides; movement, status and hit resolution stay shared.
signal tactic_resolved(enemy: Node2D, skill: String, affected: int)
var wave_level:=1
var tactic_name:=""
var tactical_casts:=0
var support_targets:=0
var ranged_warning:=0.0
var ranged_attacks:=0
func advance_attack(delta: float,distance: float) -> void:
 if kind!=3:super.advance_attack(delta,distance);return
 attack_clock=maxf(0,attack_clock-delta)
 if ranged_warning>0:
  ranged_warning=maxf(0,ranged_warning-delta)
  if distance>=330:ranged_warning=0;attack_clock=0.8
  elif ranged_warning<=0:
   attacked.emit(damage);ranged_attacks+=1;attack_clock=2.8;tactic_resolved.emit(self,"靈彈",1)
 elif distance<330 and attack_clock<=0:ranged_warning=0.75
func advance_tactics(delta: float,distance: float) -> void:
 if kind not in [2,3,4]:return
 tactical_clock=maxf(0,tactical_clock-delta)
 if telegraph>0:
  telegraph=maxf(0,telegraph-delta)
  if telegraph<=0:
   var affected:=0
   if kind==2:shield=maxf(shield,maxf(8,max_hp*0.12));affected=1
   else:
    # Exact radius + nearest four. Never heal/haste bosses or dead entities.
    var radius:=120.0 if kind==3 else 145.0
    var nearby: Array=get_parent().get_children().filter(func(e):return e!=self and is_instance_valid(e) and not e.dead and e.kind!=5 and e.position.distance_to(position)<radius)
    nearby.sort_custom(func(a,b):return a.position.distance_squared_to(position)<b.position.distance_squared_to(position))
    for other in nearby.slice(0,4):
     if kind==3:
      var before: float=other.hp;other.hp=minf(other.max_hp,other.hp+9+wave_level*2)
      if other.hp>before:affected+=1
     else:other.haste=maxf(other.haste,1.2);affected+=1
   tactical_casts+=1;support_targets+=affected;tactic_resolved.emit(self,tactic_name,affected)
 elif tactical_clock<=0 and distance<(320 if kind==2 else 370):
  tactic_name="護盾蓄力" if kind==2 else "治療蓄力" if kind==3 else "鼓舞蓄力"
  telegraph=0.55;tactical_clock=11.0 if kind==2 else 9.0
