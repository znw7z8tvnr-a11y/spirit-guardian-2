extends SceneTree
const Rewards=preload("res://experiments/chain_lab/rewards.gd")
var checks: Array=[]
var failures: Array=[]
func check(ok: bool,message: String) -> void:
 if ok:checks.append(message)
 else:failures.append(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var r=Rewards.new();root.add_child(r);r.rng.seed=12032
 check(r.complete_wave(0,false)==0 and r.complete_wave(1,false)==0,"no reward at start or ordinary first wave")
 check(r.complete_wave(3,false)==1 and r.pending==1,"third clear queues one earned selection")
 check(r.complete_wave(3,true)==0 and r.pending==1,"wave clear cannot be claimed twice, including Boss argument changes")
 var kinds: Array=[]
 for item in r.offers:kinds.append(item.kind)
 check(kinds.has("skill") and kinds.has("gem") and kinds.has("affix"),"every offer contains all three reward categories")
 check(r.refresh_offer() and r.refreshes==0 and r.granted_count==0,"refresh uses one charge without granting a reward")
 check(not r.refresh_offer() and not r.choose(-1) and not r.choose(3),"spent refresh and invalid choices are rejected")
 r.offers[0]={"kind":"affix","key":"refresh","level":1};r.choose(0)
 check(r.extra_refresh==1 and r.pending==0 and not r.choose(0),"refresh trait is run-local and choice is consumed exactly once")
 r.complete_wave(6,false);check(r.refreshes==2,"refresh trait adds one charge to the next selection")
 r.offers[0]={"kind":"affix","key":"power","level":1};r.choose(0)
 check(is_equal_approx(r.attack_multiplier(),1.1),"power trait increases spell multiplier by ten percent")
 var boss_count:=r.complete_wave(15,true);check(boss_count>=2 and boss_count<=6,"wave fifteen combines milestone and one-to-five Boss choices")
 var before: int=r.pending;r.choose(0);check(r.pending==before-1 and r.refreshes==2,"Boss selections remain queued and each gets its own refresh budget")
 while r.pending>0:r.choose(0)
 check(r.offers.is_empty() and r.refreshes==0,"all offers clear when the queue is exhausted")
 var boss_bounds:=true
 for seed_value in range(100):
  var sample=Rewards.new();sample.rng.seed=seed_value;var amount:=sample.complete_wave(5,true)
  if amount<1 or amount>5:boss_bounds=false
  sample.free()
 check(boss_bounds,"one hundred seeded Boss rewards stay within one to five")
 var game=load("res://experiments/chain_lab/main.tscn").instantiate();game.persist_book=false;root.add_child(game);current_scene=game;game.set_physics_process(false)
 game.wave=3;game.remaining=0;game.chain.reset_runtime();game._physics_process(0.1)
 check(game.rewards.pending==1 and game.reward_panel.visible,"actual wave-clear flow opens the reward modal")
 var clock: float=game.combat_seconds;game._physics_process(1.0)
 check(game.combat_seconds==clock and game.wave==3,"reward choice freezes combat and next-wave progression")
 var index:=0
 for i in game.rewards.offers.size():
  if game.rewards.offers[i].kind=="gem":index=i
 game.rewards.choose(index)
 check(game.chain.items.size()==2 and game.chain.slots==[0,-1,-1,-1,-1,-1,-1,-1,-1,-1],"earned gem enters bag without replacing any slot")
 game.chain.equip(1,1);game.chain.connect_slots(0,1)
 check(game.effective_attack_period()==1.1,"a gem without a follow-up skill does not slow the starter attack")
 game.chain.load_kit();check(game.chain.items.size()==11 and game.chain.item_at(1).kind=="gem" and game.chain.item_at(2).key=="fire","training kit remains valid after obtaining real loot")
 var total: int=game.chain.items.size();game.chain.load_kit();check(game.chain.items.size()==total,"reloading training kit never duplicates its items")
 game.chain.discovered=[];check(not game.chain.arrange_discovered(),"unknown resonance cannot be auto-arranged")
 game.chain.discovered=["fire+ice+lightning"];check(game.chain.arrange_discovered() and game.chain.items.size()==total,"known resonance arrangement only uses owned items")
 var valid:=true
 for edge in game.chain.edges:
  if not game.chain.legal_edge(edge.from,edge.to,false):valid=false
 check(valid and game.chain.has_chained_skill(),"arranged reward inventory obeys alternating graph and physical capacity")
 var captured:=false
 for seed_value in range(20):
  var sample=Rewards.new();sample.rng.seed=seed_value;sample.complete_wave(5,true)
  if sample.pending==5:captured=true
  sample.free()
 check(captured,"seed fixtures cover the five-choice Boss boundary")
 game.rewards.pending=0;game.rewards.offers=[];game.chain.reset_runtime();game.wave=20;game.remaining=0;game.rest=0;game.boss_defeated=true
 game._physics_process(0.1)
 check(not game.over and game.rewards.pending>=1 and game.rewards.pending<=5,"final Boss rewards are offered before victory")
 while game.rewards.pending>0:game.rewards.choose(0)
 game._physics_process(0.1);check(game.over and game.wave==20,"claiming final rewards finishes at wave twenty without a new wave")
 game.queue_free();r.queue_free();await process_frame
 print("REWARDS_RESULT "+JSON.stringify({"checks":checks,"failures":failures}));quit(1 if failures.size() else 0)
