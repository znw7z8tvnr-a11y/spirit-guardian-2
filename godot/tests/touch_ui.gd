extends SceneTree
var checks: Array[String]=[]
var failures: Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(value: bool, message: String) -> void:
 if value:checks.append(message)
 else:failures.append(message)
func run() -> void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);current_scene=game
 game.intermission=999;game.attack_clock=999
 await physics_frame
 var editor=game.graph_editor
 game.chain.demo();editor.rebuild();game.open_chain()
 var scroll: Vector2=editor.graph.scroll_offset
 editor.action_buttons["Pan down"].pressed.emit()
 check(editor.graph.scroll_offset.y>scroll.y,"touch pan moves graph without a middle mouse button")
 editor.action_buttons["Pan up"].pressed.emit()
 check(editor.graph.scroll_offset.is_equal_approx(scroll),"opposite pan restores view without editing layout")
 var before: Dictionary=game.chain.build()
 editor.action_buttons["Target 3"].pressed.emit()
 await process_frame
 check(game.chain.build()==before and editor.link_hint.text.contains("起點"),"target without source cannot mutate graph")
 editor.action_buttons["Source 1"].pressed.emit()
 check(editor.link_source==1 and editor.action_buttons["Source 1"].button_pressed,"tap source provides selection feedback")
 editor.action_buttons["Target 3"].pressed.emit()
 await process_frame
 check(game.chain.edges.has({"from":1,"to":3}),"two button taps create a real chain edge")
 editor.action_buttons["Undo"].pressed.emit()
 check(game.chain.build()==before,"one undo restores complete pre-link build")
 editor.action_buttons["Redo"].pressed.emit()
 check(game.chain.edges.has({"from":1,"to":3}),"redo restores a touch-created edge")
 var depth: int=editor.history.size()
 editor.choose_source(3);editor.apply_target(1)
 check(editor.history.size()==depth and not game.chain.edges.has({"from":3,"to":1}),"cyclic touch link rejected without consuming undo history")
 editor.choose_source(1);editor.apply_target(1)
 check(editor.history.size()==depth,"self-link rejected without history mutation")
 editor.cancel_link();check(editor.link_source==-1,"cancel clears pending source")
 editor.action_buttons["Link mode"].pressed.emit()
 editor.choose_source(1);editor.apply_target(3)
 check(not game.chain.edges.has({"from":1,"to":3}),"remove mode disconnects selected edge")
 editor.undo();check(game.chain.edges.has({"from":1,"to":3}),"touch disconnect can be undone")
 editor.choose_source(1);game.close_chain()
 check(editor.link_source==-1,"closing editor cancels pending link")
 check(game.hud.buttons.Fire.custom_minimum_size.y>=72,"battle touch targets reserve 72 logical pixels")
 game.hud.buttons.Performance.pressed.emit()
 check(game.hud.performance.visible,"performance display can be enabled")
 game.hud.performance_clock=1;game.hud._process(0.01)
 check(game.hud.performance.text.contains("FPS"),"performance label shows measured frame rate")
 game.hud.buttons.Performance.pressed.emit()
 check(not game.hud.performance.visible,"performance display can be hidden")
 root.size=Vector2i(820,1180)
 await process_frame;await process_frame
 game.hud.resize_touch_layout()
 check(game.hud.spell_grid.columns==4,"portrait viewport uses four spell columns")
 check(game.hud.buttons.Fire.custom_minimum_size.x>=196,"portrait buttons reserve wider touch areas")
 root.size=Vector2i(1180,820)
 await process_frame;await process_frame
 game.hud.resize_touch_layout()
 check(game.hud.spell_grid.columns==8,"landscape viewport restores eight spell columns")
 game.chain.restore(before)
 var result={"engine":Engine.get_version_info().string,"checks":checks,"failures":failures}
 print("TOUCH_RESULT "+JSON.stringify(result))
 paused=false
 quit(0 if failures.is_empty() else 1)
