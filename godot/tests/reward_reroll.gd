extends SceneTree
const Rewards=preload("res://experiments/chain_lab/rewards.gd")
const Policy=preload("res://experiments/chain_lab/reward_reroll.gd")
class RepeatingRewards:
 extends "res://experiments/chain_lab/rewards.gd"
 var fixed: Array=[]
 var calls:=0
 func roll() -> void:
  calls+=1;rng.randi();offers=fixed.duplicate(true);offers.reverse()
var checks: Array=[]
var failures: Array=[]
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 if ok:checks.append(message)
 else:failures.append(message)
func run() -> void:
 var original: Array=[{"kind":"skill","key":"arcane","level":1},{"kind":"gem","key":"relay","level":1},{"kind":"affix","key":"power","level":1}]
 var reversed: Array=original.duplicate(true);reversed.reverse()
 check(Policy.signature(original)==Policy.signature(reversed),"display-order changes alone are not a new reward offer")
 var changed: Array=original.duplicate(true);changed[0].level=2
 check(Policy.signature(original)!=Policy.signature(changed),"an actual grade change counts as changed content")
 var repeat:=RepeatingRewards.new();repeat.fixed=original.duplicate(true);repeat.offers=original.duplicate(true);repeat.pending=1;repeat.refreshes=1
 check(repeat.refresh_offer() and repeat.calls==8,"repeated identical rolls take a bounded eight attempts then finish")
 check(Policy.signature(repeat.offers)!=Policy.signature(original) and repeat.refreshes==0,"fallback changes content while consuming exactly one refresh charge")
 var skill: Dictionary=repeat.offers.filter(func(i):return i.kind=="skill")[0]
 check(skill.key!="arcane" and skill.key in Rewards.SKILLS and skill.level==1,"fallback selects a different supported skill without upgrading its grade")
 check(repeat.offers.filter(func(i):return i.kind=="gem")[0].key=="relay" and repeat.pending==1 and repeat.granted_count==0 and repeat.history.is_empty(),"fallback preserves first-gem guarantee, pending choice and empty ownership history")
 var state_before: int=repeat.rng.state;var current:=Policy.signature(repeat.offers)
 check(not repeat.refresh_offer() and repeat.rng.state==state_before and Policy.signature(repeat.offers)==current,"spent refresh budget cannot advance RNG or alter offers")
 var no_alternative: Array=original.duplicate(true)
 check(not Policy.replace_skill(no_alternative,["arcane"],repeat.rng) and no_alternative==original,"unavailable alternative pool returns failure without altering the offer")
 repeat.free()
 var unique:=true;var categories:=true;var guaranteed:=true;var one_charge:=true;var no_grants:=true
 for seed_value in range(1000):
  var r:=Rewards.new();r.rng.seed=seed_value;r.complete_wave(3,false)
  var before:=Policy.signature(r.offers);var budget: int=r.refreshes
  if not r.refresh_offer() or Policy.signature(r.offers)==before:unique=false
  var kinds: Array=r.offers.map(func(i):return str(i.kind));kinds.sort()
  if kinds!=["affix","gem","skill"]:categories=false
  if r.offers.filter(func(i):return i.kind=="gem")[0].key!="relay":guaranteed=false
  if r.refreshes!=budget-1:one_charge=false
  if r.pending!=1 or r.granted_count!=0 or not r.history.is_empty():no_grants=false
  r.free()
 check(unique,"1000 seeded real refreshes all change at least one content item")
 check(categories,"1000 refreshes retain exactly one skill, gem and affix")
 check(guaranteed,"1000 first selections retain the relay-gem guarantee")
 check(one_charge and no_grants,"1000 refreshes spend one charge and grant no inventory, history or choices")
 var bonus:=Rewards.new();bonus.rng.seed=12032;bonus.complete_wave(3,false)
 for i in bonus.offers.size():
  if bonus.offers[i].kind=="affix":bonus.offers[i].key="refresh";bonus.choose(i);break
 bonus.complete_wave(6,false)
 check(bonus.extra_refresh==1 and bonus.refreshes==2,"existing earned refresh trait still gives two attempts on the next reward")
 var first:=Policy.signature(bonus.offers);bonus.refresh_offer();var second:=Policy.signature(bonus.offers);bonus.refresh_offer()
 check(first!=second and second!=Policy.signature(bonus.offers) and bonus.refreshes==0 and bonus.granted_count==1,"both trait-funded refreshes change content and spend their own budget once")
 bonus.free()
 print("REROLL_RESULT "+JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
