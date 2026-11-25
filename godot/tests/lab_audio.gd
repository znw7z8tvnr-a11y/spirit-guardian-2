extends SceneTree
const Store=preload("res://experiments/chain_lab/checkpoint_store.gd")
const Catalog=preload("res://modules/spell/catalog.gd")
const Effects=preload("res://experiments/chain_lab/spell_effects.gd")
var checks: Array=[]
var failures: Array=[]
func check(ok: bool,message: String) -> void:
 if ok:checks.append(message)
 else:failures.append(message)
func _initialize() -> void:call_deferred("run")
func finish(audio: Node) -> void:
 for player in audio.players:
  if player.get_meta("busy",false):player.stop();player.finished.emit()
func run() -> void:
 var game=load("res://experiments/chain_lab/main.tscn").instantiate();game.persist_run=false;game.persist_book=false;root.add_child(game);current_scene=game;game.set_process(false);game.set_physics_process(false)
 await process_frame;await process_frame
 var controller=game.get_node("AudioController");var sound: Node=controller.audio
 check(controller.bound and game.buttons.has("Audio") and sound.muted and controller.button.text=="音效：關","Lab exposes a default-muted audio control after ready")
 check(controller.button.custom_minimum_size.y>=72 and game.battle_controls.get_child_count()==8,"audio uses event row without adding a battle-grid row")
 var callbacks: int=game.chain.cast_requested.get_connections().size();var controls: int=game.buttons.size();controller.bind_host()
 check(game.chain.cast_requested.get_connections().size()==callbacks and game.buttons.size()==controls,"repeated binding does not duplicate observers or buttons")
 var before: Dictionary=Store.new().capture(game)
 controller.button.pressed.emit()
 check(not sound.muted and controller.button.text=="音效：開" and Store.new().capture(game)==before,"audio toggle changes neither checkpoint schema nor game snapshot")
 var saved_active: Dictionary=game.chain.active.duplicate(true)
 game.chain.active={"id":91,"events":0,"elements":[],"checked":false,"inflight":0,"visited":[]}
 var routing_ok:=true
 for key in Effects.PLAYABLE:
  finish(sound);sound.clock=0
  controller.on_cast(0,{"kind":"skill","key":key,"level":1},null,{"id":91},{})
  var element:=Catalog.element(key);var expected: String=element if sound.FREQUENCIES.has(element) else "other"
  routing_ok=routing_ok and sound.voices==1 and sound.players[0].stream==sound.tones[expected]
 check(routing_ok,"all 22 spell keys route through existing element frequencies or fallback")
 finish(sound);sound.clock=0;controller.on_resonance("fixture",Vector2.ZERO,91)
 check(sound.voices==1 and sound.players[0].stream==sound.tones.arcane,"current resonance uses existing arcane cue")
 finish(sound);sound.clock=0;controller.on_cast(0,{"kind":"skill","key":"fire","level":1},null,{"id":90},{})
 controller.on_resonance("fixture",Vector2.ZERO,90)
 check(sound.voices==0,"stale run cast and resonance events produce no sound")
 check(game.chain.active.id==91 and game.chain.active.events==0,"sound observers never change chain execution state")
 game.chain.active=saved_active;finish(sound);sound.clock=0
 controller.button.pressed.emit();controller.on_cast(0,{"kind":"skill","key":"fire","level":1},null,{"id":-1},{})
 check(sound.muted and sound.voices==0,"mute remains explicit and observers never unmute automatically")
 controller.button.pressed.emit();game.request_early_wave();game.set_physics_process(true)
 var frames:=0
 while sound.voices==0 and frames<800:await physics_frame;frames+=1
 game.set_physics_process(false)
 check(game.chain.casts>0 and sound.voices>0,"real opening combat signal reaches sound module without replacing cast handler")
 check(sound.voices<=8 and sound.players.size()<=8,"Lab inherits bounded player and voice limits")
 game.queue_free();await process_frame
 print("LABAUDIO_RESULT "+JSON.stringify({"checks":checks,"failures":failures}));quit(1 if failures.size() else 0)
