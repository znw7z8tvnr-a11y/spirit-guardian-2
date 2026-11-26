extends SceneTree
class CountingRewardView extends "res://experiments/chain_lab/reward_view.gd":
 var description_calls:=0
 func description(item: Dictionary) -> String:
  description_calls+=1
  return super.description(item)
var checks: Array=[]
var failures: Array=[]
func check(ok: bool,message: String) -> void:
 if ok:checks.append(message)
 else:failures.append(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var rewards=load("res://experiments/chain_lab/rewards.gd").new();root.add_child(rewards);rewards.rng.seed=12032
 var view=CountingRewardView.new();root.add_child(view);view.bind(rewards)
 check(not view.activate(0),"hidden reward panel rejects stale input")
 rewards.complete_wave(15,true)
 if rewards.pending<2:rewards.pending=2
 var initial_calls: int=view.description_calls
 var before_rng: int=rewards.rng.state
 var before_offers: Array=rewards.offers.duplicate(true)
 var initial_texts: Array=view.choices.map(func(b):return b.text)
 for repeat_index in range(25):rewards.changed.emit()
 check(initial_calls==3 and view.description_calls==initial_calls and view.choices.map(func(b):return b.text)==initial_texts,"25 unchanged reward signals reuse three card descriptions without rewriting content")
 check(rewards.rng.state==before_rng and rewards.offers==before_offers,"presentation refresh does not consume RNG or change offers")
 # Mutate the existing offer dictionary: cached references must not hide a change.
 var skill_index: int=rewards.offers.find_custom(func(item):return item.kind=="skill")
 var original_level: int=rewards.offers[skill_index].level
 rewards.offers[skill_index].level=original_level%3+1;rewards.changed.emit()
 check(view.description_calls==initial_calls+1 and view.choices[skill_index].text==view.description(rewards.offers[skill_index]),"in-place skill level change refreshes only its own card")
 rewards.offers[skill_index].level=original_level;rewards.changed.emit()
 check(view.choices.map(func(b):return b.text)==initial_texts,"restoring an offer restores its exact description")
 var before_copy: int=view.description_calls
 rewards.offers=rewards.offers.duplicate(true);rewards.changed.emit()
 check(view.description_calls==before_copy,"equal copied offers reuse cached text rather than dictionary identity")
 var first: Dictionary=rewards.offers[0];rewards.offers[0]=rewards.offers[1];rewards.offers[1]=first;rewards.changed.emit()
 check(view.description_calls==before_copy+2 and view.choices[0].text==initial_texts[1] and view.choices[1].text==initial_texts[0],"reordered reward cards refresh their displayed positions")
 rewards.offers=before_offers.duplicate(true);rewards.changed.emit()
 var pending: int=rewards.pending
 check(view.activate(0) and rewards.pending==pending-1,"first visible reward choice consumes exactly one pending reward")
 var history: Array=rewards.history.duplicate(true);var state: int=rewards.rng.state
 check(view.input_locked and view.choices.all(func(b):return b.disabled) and view.refresh.disabled,"new offer is visible with controls briefly disabled")
 check(not view.activate(1) and not view.activate(-1) and rewards.history==history and rewards.rng.state==state,"rapid choice and refresh cannot consume another offer or RNG")
 await create_timer(0.30,true,false,true).timeout
 check(not view.input_locked and view.choices.all(func(b):return not b.disabled),"controls recover after the real-time input guard")
 check(view.activate(-1),"a deliberate later refresh remains available")
 var budget: int=rewards.refreshes;var granted: int=rewards.granted_count;var offers: Array=rewards.offers.duplicate(true)
 check(not view.activate(0) and not view.activate(-1) and rewards.refreshes==budget and rewards.granted_count==granted and rewards.offers==offers,"refresh then immediate choice leaves new offer and remaining charges unchanged")
 await create_timer(0.30,true,false,true).timeout
 rewards.refreshes=0;rewards.changed.emit()
 check(not view.activate(-1) and not view.input_locked,"rejected refresh does not leave controls stuck")
 check(not view.activate(99) and not view.input_locked,"invalid card index is rejected without locking input")
 while rewards.pending>1:rewards.choose(0)
 check(view.activate(0),"reward remains selectable after rejected input")
 await create_timer(0.30,true,false,true).timeout
 check(not view.input_locked and not view.visible,"guard releases even if the last choice hides the panel")
 view.queue_free();rewards.queue_free();await process_frame
 print("REWARDINPUT_RESULT "+JSON.stringify({"checks":checks,"failures":failures}));quit(1 if failures.size() else 0)
