extends SceneTree
const Store=preload("res://experiments/chain_lab/checkpoint_store.gd")
var checks: Array=[]
var failures: Array=[]
var storage:=Store.new()
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 if ok:checks.append(message)
 else:failures.append(message)
func frames(count: int=2) -> void:
 for i in count:await process_frame
func same_offers(a: Array,b: Array) -> bool:
 if a.size()!=b.size():return false
 for i in a.size():
  if a[i].kind!=b[i].kind or a[i].key!=b[i].key or int(a[i].level)!=int(b[i].level):return false
 return true
func fixture(persistent: bool) -> Node:
 var game=load("res://experiments/chain_lab/main.tscn").instantiate();game.persist_book=false;game.persist_run=persistent;root.add_child(game);current_scene=game;return game
func run() -> void:
 storage.clear()
 var build_before: String=FileAccess.get_file_as_string("user://sg_m2_build.json") if FileAccess.file_exists("user://sg_m2_build.json") else ""
 var game:=fixture(true);game.rng.seed=12032;game.chain.rng.seed=32012;game.rewards.rng.seed=43032;game.resolver.rng.seed=54032
 game.cycle_speed();game.cycle_speed();game.cycle_speed()
 var ticks:=0
 while game.rewards.pending==0 and not game.over and ticks<3000:
  await physics_frame;ticks+=1
 game.set_process(false);game.set_physics_process(false);await frames()
 var saved:=storage.load_checkpoint()
 check(game.wave==3 and game.rewards.pending==1 and saved.ok,"actual third-wave clear automatically saves an unclaimed award")
 if not saved.ok:
  failures.append("saved record unavailable: "+str(saved));print("CHECKPOINT_RESULT "+JSON.stringify({"checks":checks,"failures":failures}));quit(1);return
 check(saved.data.rewards.completed.size()==3 and saved.data.chain.items.size()==1 and saved.data.rewards.history.is_empty(),"saved clear flags, inventory and reward history agree before selection")
 game.rewards.refresh_offer();await frames();saved=storage.load_checkpoint()
 check(saved.ok and saved.data.rewards.refreshes==0 and same_offers(saved.data.rewards.offers,game.rewards.offers),"spent refresh budget and exact newly rolled offers persist")
 var guard=game.guardians.summon_at(Vector2(560,320),3,1.7,"skeleton")
 guard.remaining=3.25;guard.age=4.75;guard.cooldown=0.33;guard.strikes=7
 game.write_checkpoint();saved=storage.load_checkpoint()
 var snapshot: Dictionary=saved.data.duplicate(true)
 var clone:=fixture(false);clone.set_process(false);clone.set_physics_process(false)
 check(storage.apply(clone,snapshot),"validated checkpoint applies to a fresh game")
 check(clone.guardians.guards.size()==1 and is_equal_approx(clone.guardians.guards[0].power,guard.power) and clone.guardians.guards[0].remaining==3.25 and clone.guardians.guards[0].age==4.75 and is_equal_approx(clone.guardians.guards[0].cooldown,0.33) and clone.guardians.guards[0].strikes==7 and clone.guardians.counts==game.guardians.counts,"guardian life, cooldown, damage and counts restore without re-summoning boost")
 check(clone.rewards.offers==game.rewards.offers and clone.rewards.refreshes==0 and not clone.rewards.refresh_offer(),"restored award cannot gain an extra free refresh")
 for pair in [[game.rng,clone.rng],[game.chain.rng,clone.chain.rng],[game.rewards.rng,clone.rewards.rng],[game.resolver.rng,clone.resolver.rng]]:
  check(pair[0].randf()==pair[1].randf(),"64-bit string seed/state restores the exact next RNG draw")
 check(not storage.apply(clone,snapshot),"checkpoint cannot overwrite an already resumed live game")
 current_scene=game;clone.queue_free();await frames();game.write_checkpoint();saved=storage.load_checkpoint()
 call_deferred("reload_current_scene");await frames(3)
 game=current_scene;game.set_process(false);game.set_physics_process(false)
 check(game.resume_pending and game.checkpoint_view.visible and game.combat_seconds==0,"fresh scene pauses behind explicit continue/new-run prompt")
 game.buttons.CheckpointResume.pressed.emit();await frames()
 check(not game.resume_pending and game.wave==3 and game.rewards.pending==1 and game.rewards.refreshes==0,"real continue button restores saved intermission and award queue")
 var pick:=0
 for i in game.rewards.offers.size():
  if game.rewards.offers[i].kind=="gem":pick=i
 game.rewards.choose(pick);await frames();saved=storage.load_checkpoint()
 check(saved.ok and game.chain.items.size()==2 and saved.data.chain.items.size()==2 and saved.data.rewards.granted_count==1 and saved.data.game.edit_open,"last award saves inventory and pending equipment confirmation together")
 game.chain.equip(1,1);game.chain.connect_slots(0,1);game.queue_checkpoint();await frames();saved=storage.load_checkpoint()
 check(saved.data.chain.slots[1]==1 and saved.data.chain.edges==[{"from":0.0,"to":1.0}],"physical equipment and graph edges persist after actual edits")
 call_deferred("reload_current_scene");await frames(3);game=current_scene;game.set_process(false);game.set_physics_process(false);game.buttons.CheckpointResume.pressed.emit();await frames()
 check(game.chain.items.size()==2 and game.rewards.pending==0 and game.rewards.granted_count==1 and not game.rewards.choose(0),"second scene reload cannot grant the same award again")
 check(game.chain.slots[1]==1 and game.chain.edges.size()==1 and game.edit_open,"restored equipment confirmation uses the saved owned graph")
 var valid: Dictionary=storage.capture(game);check(storage.validate(valid),"restored game can make a validated next-generation checkpoint")
 for mutation in ["duplicate_item","edge_bounds","unknown_skill","health","bad_rng","missing_clear","awards","nonfinite"]:
  var bad: Dictionary=valid.duplicate(true)
  match mutation:
   "duplicate_item":bad.chain.slots[1]=0
   "edge_bounds":bad.chain.edges=[{"from":99,"to":1}]
   "unknown_skill":bad.chain.items[0].key="unknown"
   "health":bad.tower.hp=-1
   "bad_rng":bad.rng.rewards.state="184467440737095516160"
   "missing_clear":bad.rewards.completed=[]
   "awards":bad.rewards.granted_count+=1
   "nonfinite":bad.game.combat_seconds=INF
  check(not storage.validate(bad),"reject malformed checkpoint: "+mutation)
 var raw:=FileAccess.get_file_as_string(Store.PATH);game.remaining=3
 check(not storage.save_game(game) and FileAccess.get_file_as_string(Store.PATH)==raw,"unsafe active-wave save preserves last valid checkpoint")
 game.remaining=0;game.chain.kit_loaded=true
 check(not storage.save_game(game) and FileAccess.get_file_as_string(Store.PATH)==raw,"training inventory cannot overwrite normal checkpoint")
 game.chain.kit_loaded=false
 var file:=FileAccess.open(Store.PATH,FileAccess.WRITE);file.store_string("{truncated");file.close()
 var backup:=storage.load_checkpoint();check(backup.ok and backup.source=="backup","corrupt primary falls back to previously validated backup")
 storage.clear();file=FileAccess.open(Store.PATH,FileAccess.WRITE);file.store_string(JSON.stringify({"format":Store.FORMAT,"schema":99,"payload":"{}","sha256":"{}".sha256_text()}));file.close()
 var unsupported:=storage.load_checkpoint();check(not unsupported.ok and unsupported.exists and FileAccess.file_exists(Store.PATH),"unsupported schema is rejected and retained until explicit new-run choice")
 game.persist_run=true;game.restart_run();await frames(3);game=current_scene;game.set_process(false);game.set_physics_process(false)
 check(not game.resume_pending and game.chain.items.size()==1 and not FileAccess.file_exists(Store.PATH) and not FileAccess.file_exists(Store.PATH+".bak"),"explicit new-run button clears checkpoint and backup before fresh start")
 check((FileAccess.get_file_as_string("user://sg_m2_build.json") if FileAccess.file_exists("user://sg_m2_build.json") else "")==build_before,"legacy build save is not interpreted or overwritten as a run checkpoint")
 game.queue_free();await frames();storage.clear()
 print("CHECKPOINT_RESULT "+JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
