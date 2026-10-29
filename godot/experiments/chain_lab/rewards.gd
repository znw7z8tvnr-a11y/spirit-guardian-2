extends Node
## Run-local progression. No inventory mutation while browsing or refreshing.
signal changed
signal granted(reward: Dictionary)
const SKILLS=preload("res://modules/spell/catalog.gd").PLAYABLE
var rng:=RandomNumberGenerator.new()
var pending:=0
var offers: Array=[]
var completed: Dictionary={}
var refreshes:=0
var extra_refresh:=0
var attack_stacks:=0
var granted_count:=0
var history: Array=[]
func _init() -> void:rng.randomize()
func complete_wave(wave: int, boss_defeated: bool) -> int:
 if wave<=0 or wave>20 or completed.has(wave):return 0
 completed[wave]=true
 var count:=1 if wave%3==0 else 0
 if boss_defeated:count+=rng.randi_range(1,5)
 var was_empty:=pending==0
 pending+=count
 if was_empty and pending>0:new_offer()
 changed.emit();return count
func new_offer() -> void:
 refreshes=1+extra_refresh;roll()
func roll() -> void:
 var level_roll:=rng.randf()
 var level:=1 if level_roll<0.70 else 2 if level_roll<0.95 else 3
 offers=[{"kind":"skill","key":SKILLS[rng.randi_range(0,SKILLS.size()-1)],"level":level},{"kind":"gem","key":("relay" if granted_count==0 else preload("res://experiments/chain_lab/gem_rules.gd").KEYS[rng.randi_range(0,preload("res://experiments/chain_lab/gem_rules.gd").KEYS.size()-1)]),"level":1 if rng.randf()<0.70 else (2 if rng.randf()<0.75 else 3)},{"kind":"affix","key":"refresh" if rng.randf()<0.5 else "power","level":1}]
 for i in range(offers.size()-1,0,-1):
  var j:=rng.randi_range(0,i);var value: Dictionary=offers[i];offers[i]=offers[j];offers[j]=value
func refresh_offer() -> bool:
 if pending<=0 or refreshes<=0:return false
 refreshes-=1;roll();changed.emit();return true
func choose(index: int) -> bool:
 if pending<=0 or index<0 or index>=offers.size():return false
 var reward: Dictionary=offers[index].duplicate(true)
 if reward.kind=="affix":
  if reward.key=="refresh":extra_refresh+=1
  elif reward.key=="power":attack_stacks+=1
 granted_count+=1;history.append(reward);pending-=1
 if pending>0:new_offer()
 else:offers=[];refreshes=0
 granted.emit(reward);changed.emit();return true
func attack_multiplier() -> float:return 1.0+0.10*attack_stacks
