extends Node
## Pause active play on interruption; never resume automatically or alter combat data.
var host: Node
func _ready() -> void:
 host=get_parent()
func _notification(what: int) -> void:
 if what!=NOTIFICATION_WM_WINDOW_FOCUS_OUT and what!=NOTIFICATION_APPLICATION_FOCUS_OUT and what!=NOTIFICATION_APPLICATION_PAUSED:return
 if not is_instance_valid(host) or not is_instance_valid(host.rewards):return
 if host.user_paused or host.over or host.resume_pending or host.edit_open or host.growth_open or host.rewards.pending>0:return
 host.toggle_pause()
