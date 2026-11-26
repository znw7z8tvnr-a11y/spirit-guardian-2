extends SceneTree
var checks: Array=[]
var failures: Array=[]
func check(ok: bool,message: String) -> void:
 if ok:checks.append(message)
 else:failures.append(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var game=load("res://experiments/chain_lab/main.tscn").instantiate();game.persist_book=false;game.persist_run=false;root.add_child(game);current_scene=game;game.set_process(false);game.set_physics_process(false)
 await process_frame
 var controller: Node=game.get_node("FocusPauseController")
 for notification in [Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT,Node.NOTIFICATION_APPLICATION_FOCUS_OUT,Node.NOTIFICATION_APPLICATION_PAUSED]:
  game.user_paused=false;game.buttons.Pause.text="暫停"
  var before: Dictionary=game.checkpoint_store.capture(game)
  controller.notification(notification);game._process(0)
  check(game.user_paused and game.buttons.Pause.text=="繼續" and game.enemies.process_mode==Node.PROCESS_MODE_DISABLED,"interruption pauses active battle and updates its real control: "+str(notification))
  var clock: float=game.combat_seconds;var casts: int=game.chain.casts;var hp: float=game.tower.hp
  game._physics_process(1.0)
  check(game.combat_seconds==clock and game.chain.casts==casts and game.tower.hp==hp,"paused interruption freezes real combat clock, casts and health: "+str(notification))
  controller.notification(notification);controller.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_IN)
  check(game.user_paused,"duplicate interruption or focus return never unpauses: "+str(notification))
  game.buttons.Pause.pressed.emit();game._process(0)
  check(not game.user_paused and game.buttons.Pause.text=="暫停" and game.checkpoint_store.capture(game)==before,"deliberate continue restores controls without changing inventory, graph, RNG or save snapshot: "+str(notification))
 for blocked in ["edit_open","growth_open","resume_pending","over"]:
  game.set(blocked,true);controller.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
  check(not game.user_paused,"interruption does not change modal or completed state: "+blocked)
  game.set(blocked,false)
 game.rewards.pending=1;controller.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
 check(not game.user_paused and game.rewards.pending==1,"reward interruption neither adds a manual pause nor consumes an offer")
 game.rewards.pending=0;game.user_paused=true;controller.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
 check(game.user_paused,"existing manual pause stays paused")
 game.queue_free();await process_frame
 print("FOCUSPAUSE_RESULT "+JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
