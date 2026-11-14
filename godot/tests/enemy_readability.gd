extends SceneTree
const View=preload("res://experiments/chain_lab/enemy_presentation.gd")
var checks: Array=[]
var failures: Array=[]
func check(ok: bool,message: String) -> void:
 if ok:checks.append(message)
 else:failures.append(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var game=load("res://experiments/chain_lab/main.tscn").instantiate();game.persist_book=false;game.persist_run=false;root.add_child(game);current_scene=game;game.set_process(false);game.set_physics_process(false);game.load_enemy_drill(true)
 var actors: Array=game.enemies.get_children()
 for e in actors:
  e.set_physics_process(false)
  if e.kind in [2,3,4]:e.tactical_clock=0;e.advance_tactics(0.01,200)
  if e.kind==3:e.advance_attack(0.01,200)
 await process_frame
 check(actors.size()==40 and actors.all(func(e):return e.get_child_count()==1),"forty real animated enemies have no per-enemy Label nodes")
 var timers: Array=actors.map(func(e):return [e.hp,e.ranged_warning,e.telegraph,e.haste])
 var text:=View.summary(actors)
 check("靈彈 ×8" in text and "另 8 項蓄力" in text,"HUD accounts for both simultaneous attacks and support without losing fourth category")
 check(View.seconds(0.001)=="0.1" and View.seconds(0.71)=="0.8","active warning never formats as zero seconds")
 var overlay: Control=game.enemy_presentation
 for box in [Rect2(0,0,1280,720),Rect2(0,0,820,1180),Rect2(40,270,1200,260)]:
  overlay.update_actors(actors,box)
  check(overlay.labels.size()==6 and overlay.placed.size()<=6 and (overlay.placed.size()>0 if box.position==Vector2.ZERO else true),"bounded visible label pool for viewport "+str(box))
  for i in overlay.placed.size():check(overlay.labels[i].get_rect()==overlay.placed[i].rect,"real Control rectangle matches collision placement")
  check(overlay.placed.filter(func(p):return p.key=="靈彈").size()<=2,"same attack shows at most two representative labels")
  var ids: Array=[]
  for row in overlay.placed:
   check(box.encloses(row.rect),"label stays inside permitted battle rectangle")
   check(row.id not in ids,"one enemy never takes two labels for simultaneous warnings");ids.append(row.id)
   for other in overlay.placed:
    if row.id!=other.id:check(not row.rect.intersects(other.rect),"actual placed rectangles never overlap")
  check(overlay.trials<=actors.size()*9,"placement search remains bounded for forty actors")
 var writes: int=overlay.text_writes;overlay.update_actors(actors,Rect2(40,270,1200,260));check(overlay.text_writes==writes,"identical paused state does not rewrite label text")
 overlay.update_actors(actors,Rect2(0,0,100,20));check(overlay.placed.is_empty(),"too-small viewport safely hides world labels while HUD remains separate")
 check(actors.map(func(e):return [e.hp,e.ranged_warning,e.telegraph,e.haste])==timers,"presentation never mutates real HP, attack timers, support timers or movement status")
 var dying: Node2D=actors[2];check(View.threats(actors).any(func(row):return row.id==dying.entity_id),"dead-actor fixture starts with a real pending warning")
 dying.dead=true;var rows:=View.threats(actors);check(not rows.any(func(row):return row.id==dying.entity_id),"dead actor does not keep a warning")
 game.queue_free();await process_frame
 print("READABILITY_RESULT "+JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
