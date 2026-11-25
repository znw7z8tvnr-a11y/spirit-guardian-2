extends Node
var muted := true
var clock := 0.0
var voices := 0
const MAX_VOICES := 8
const FREQUENCIES={"fire":196.0,"ice":330.0,"lightning":440.0,"arcane":294.0,"other":247.0}
var tones: Dictionary={}
var players: Array[AudioStreamPlayer]=[]
# Temporary synthesized SFX; immutable shared waves and bounded player reuse.
func cue(element: String) -> void:
 if muted or voices>=MAX_VOICES or clock>0:return
 var player: AudioStreamPlayer=null
 for available in players:
  if not available.get_meta("busy",false):player=available;break
 if player==null:
  if players.size()>=MAX_VOICES:return
  player=AudioStreamPlayer.new();add_child(player);players.append(player)
  player.finished.connect(_release_voice.bind(player))
 var key: String=element if FREQUENCIES.has(element) else "other"
 player.stream=_tone(key)
 player.set_meta("busy",true);voices+=1;clock=0.09
 player.play()
func _tone(key: String) -> AudioStreamWAV:
 if tones.has(key):return tones[key]
 var wav:=AudioStreamWAV.new()
 wav.format=AudioStreamWAV.FORMAT_16_BITS
 wav.mix_rate=22050
 var bytes:=PackedByteArray();bytes.resize(2205*2)
 var frequency: float=FREQUENCIES[key]
 for i in 2205:
  var sample:=int(sin(TAU*frequency*i/22050.0)*(1.0-float(i)/2205)*2500)
  bytes.encode_s16(i*2,sample)
 wav.data=bytes;tones[key]=wav
 return wav
func _release_voice(player: AudioStreamPlayer) -> void:
 if not is_instance_valid(player) or not player.get_meta("busy",false):return
 player.set_meta("busy",false);voices=maxi(0,voices-1)
func _process(delta: float) -> void:
 clock=maxf(0,clock-delta)
