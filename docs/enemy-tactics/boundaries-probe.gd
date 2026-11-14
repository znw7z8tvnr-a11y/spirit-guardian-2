extends SceneTree
const Actor=preload("res://experiments/chain_lab/combat_enemy.gd")
var checks: Array=[]
var failures: Array=[]
var game: Node
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 if ok:checks.append(message)
 else:failures.append(message)
func actor(kind: int,at: Vector2) -> Node2D:
 var e:=Actor.new();e.kind=kind;game.configure_enemy(e,false,at);e.set_physics_process(false);return e
func run() -> void:
 game=load("res://experiments/chain_lab/main.tscn").instantiate();game.persist_book=false;root.add_child(game);current_scene=game;game.set_process(false);game.set_physics_process(false);game.wave=6
 var healer:=actor(3,Vector2(200,0));var ally:=actor(0,Vector2(210,0));ally.max_hp=100;ally.hp=99
 var boss:=actor(5,Vector2(205,0));boss.hp=20
 var fallen:=actor(0,Vector2(201,0));fallen.hp=10;fallen.dead=true
 healer.tactical_clock=0;healer.advance_tactics(0.01,200);healer.advance_tactics(0.56,200)
 check(ally.hp==100,"source heal amount clamps an almost-full real ally to max HP")
 check(boss.hp==20 and fallen.hp==10,"support excludes nearest boss and fallen ally")
 var normal:=actor(0,Vector2.ZERO);normal.target=Vector2(1000,0);normal.brain=null;normal.speed=10;normal._physics_process(0.1)
 var boosted:=actor(0,Vector2(0,50));boosted.target=Vector2(1000,50);boosted.brain=null;boosted.speed=10;boosted.haste=1.2;boosted._physics_process(0.1)
 check(is_equal_approx(normal.position.x,1.0) and is_equal_approx(boosted.position.x,1.4),"rally haste multiplies actual movement by 1.4")
 boosted.position=Vector2(0,50);boosted.haste=1.2;boosted.slow_time=1;boosted._physics_process(0.1)
 check(is_equal_approx(boosted.position.x,0.7),"actual ice slow and rally speed combine without bypassing slow")
 game.queue_free();await process_frame
 print("ENEMY_BOUNDARIES_RESULT "+JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
