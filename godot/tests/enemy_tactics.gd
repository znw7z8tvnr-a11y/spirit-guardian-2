extends SceneTree
const Rules=preload("res://experiments/chain_lab/enemy_rules.gd")
const Actor=preload("res://experiments/chain_lab/combat_enemy.gd")
var checks: Array=[]
var failures: Array=[]
var game: Node
func check(ok: bool,message: String) -> void:
 if ok:checks.append(message)
 else:failures.append(message)
func _initialize() -> void:call_deferred("run")
func actor(kind: int,at: Vector2) -> Node2D:
 var e:=Actor.new();e.kind=kind;game.configure_enemy(e,false,at);e.set_physics_process(false);e.speed=0;return e
func run() -> void:
 game=load("res://experiments/chain_lab/main.tscn").instantiate();game.persist_book=false;root.add_child(game);current_scene=game;game.set_physics_process(false);game.set_process(false)
 for wave in range(1,6):
  for kind in range(5):check(is_equal_approx(Rules.stats(kind,wave).hp,[28,20,60,38,95][kind]+wave*3),"early HP unchanged wave %d type %d" % [wave,kind])
 check(3 not in Rules.pool(5) and 3 in Rules.pool(6),"shaman starts at wave six without changing first Boss roster")
 check(Rules.stats(0,20).hp>Rules.stats(0,8).hp and Rules.stats(0,20).damage>Rules.stats(0,8).damage,"late trial HP and damage grow monotonically")
 check(Rules.stats(5,20,true).hp==800,"Boss profile stays unchanged")
 game.wave=6
 var observed: Array=[]
 for count in range(12,0,-1):
  game.remaining=count;var spawned: Node2D=game.spawn_enemy();observed.append(spawned.kind)
 check(3 in observed,"actual scheduled wave six spawns include shaman")
 for unit in game.enemies.get_children():unit.free()
 var shaman:=actor(3,game.CENTER+Vector2(250,0));var victims: Array=[]
 for i in range(6):
  var e:=actor(0,shaman.position+Vector2(10+i*10,0));e.max_hp=100;e.hp=50;victims.append(e)
 var outside:=actor(0,shaman.position+Vector2(125,0));outside.max_hp=100;outside.hp=50
 var dead_ally:=actor(0,shaman.position+Vector2(1,0));dead_ally.hp=20;dead_ally.dead=true
 var boss=preload("res://modules/boss/boss.gd").new();game.configure_enemy(boss,true,shaman.position+Vector2(2,0));boss.set_physics_process(false);boss.hp=20
 shaman.tactical_clock=0;shaman.advance_tactics(0.01,250)
 check(shaman.telegraph>0 and victims.all(func(e):return e.hp==50),"support telegraphs before applying healing")
 shaman.advance_tactics(0.56,250)
 check(victims.filter(func(e):return e.hp==71).size()==4 and outside.hp==50,"source heal amount nine plus twice wave applies to nearest four inside 120 only")
 check(dead_ally.hp==20 and boss.hp==20,"dead allies and bosses cannot be healed")
 shaman.advance_tactics(0.56,250);check(shaman.tactical_casts==1,"finished telegraph cannot duplicate a support cast")
 var armor:=actor(2,game.CENTER+Vector2(200,0));armor.tactical_clock=0;armor.advance_tactics(0.01,200);armor.advance_tactics(0.56,200)
 var before: float=armor.hp;var result: Dictionary=armor.apply_hit(10,"arcane")
 check(is_equal_approx(before-armor.hp,maxf(0,10-maxf(8,armor.max_hp*0.12))) and result.absorbed>0,"ward absorbs actual incoming HP damage")
 var elite:=actor(4,shaman.position);elite.tactical_clock=0;elite.advance_tactics(0.01,250);elite.advance_tactics(0.56,250)
 check(victims.filter(func(e):return e.haste>0).size()<=4 and elite.support_targets==4,"rally respects four-target cap")
 var wall_before: float=game.tower.wall_hp;shaman.advance_attack(0.01,250)
 check(shaman.ranged_warning==0.75 and game.tower.wall_hp==wall_before,"ranged warning does not immediately damage castle")
 shaman.advance_attack(0.76,250);check(game.tower.wall_hp<wall_before and shaman.ranged_attacks==1,"completed ranged warning damages actual flesh wall once")
 shaman.attack_clock=0;shaman.advance_attack(0.01,250);var held: float=game.tower.wall_hp;shaman.advance_attack(0.76,400)
 check(game.tower.wall_hp==held and shaman.ranged_warning==0,"moving out of range cancels a pending ranged attack")
 game.load_enemy_drill();check(game.enemy_drill and game.wave==6 and game.enemies.get_child_count()==5 and not game.persist_book,"explicit real-enemy drill contains five roles and disables book persistence")
 var flesh_before: float=game.tower.flesh
 var drill_target: Node2D=game.enemies.get_child(0);drill_target.apply_hit(99999,"arcane")
 check(game.pending_flesh.is_empty() and game.tower.flesh==flesh_before,"drill kills do not create collectible meat rewards")
 for e in game.enemies.get_children():e.free()
 game.chain.reset_runtime();game._physics_process(1)
 check(game.wave==6 and game.rewards.pending==0,"completed drill never grants wave rewards or advances the run")
 game.queue_free();await process_frame
 print("ENEMYTACTICS_RESULT "+JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
