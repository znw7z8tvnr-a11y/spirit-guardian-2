extends Node
## Read-only observer of Lab chain signals. Never starts casts or changes damage.
const Sound=preload("res://modules/audio/audio.gd")
const Catalog=preload("res://modules/spell/catalog.gd")
var audio: Node
var host: Node
var button: Button
var bound:=false
func _ready() -> void:
 audio=Sound.new();add_child(audio)
 bind_host.call_deferred()
func bind_host() -> void:
 if bound:return
 host=get_parent()
 if not is_instance_valid(host) or not host.has_method("make_button") or not ("chain" in host) or not ("event_label" in host):return
 if not is_instance_valid(host.chain) or not is_instance_valid(host.event_label):return
 button=host.make_button("Audio","音效：關",host.event_label.get_parent(),toggle_audio)
 host.chain.cast_requested.connect(on_cast)
 host.chain.resonance_requested.connect(on_resonance)
 bound=true
func toggle_audio() -> void:
 audio.muted=not audio.muted
 button.text="音效：關" if audio.muted else "音效：開"
func on_cast(_slot: int,item: Dictionary,_target: Node2D,run: Dictionary,_context: Dictionary) -> void:
 if not bound or not is_instance_valid(host) or not host.chain.current(run):return
 audio.cue(Catalog.element(str(item.key)))
func on_resonance(_recipe: String,_at: Vector2,run_id: int) -> void:
 if not bound or not is_instance_valid(host) or not host.chain.current({"id":run_id}):return
 audio.cue("arcane")
