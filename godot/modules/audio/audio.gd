extends Node
var muted := true
var clock := 0.0
var voices := 0
const MAX_VOICES := 8
# Temporary synthesized SFX; no claim that original music scenes were ported.
func cue(element: String) -> void:
 if muted or voices>=MAX_VOICES or clock>0:return
 clock=0.09
 var wav:=AudioStreamWAV.new()
 wav.format=AudioStreamWAV.FORMAT_16_BITS
 wav.mix_rate=22050
 var bytes:=PackedByteArray();bytes.resize(2205*2)
 var frequency: float={"fire":196.0,"ice":330.0,"lightning":440.0,"arcane":294.0}.get(element,247.0)
 for i in 2205:
  var sample:=int(sin(TAU*frequency*i/22050.0)*(1.0-float(i)/2205)*2500)
  bytes.encode_s16(i*2,sample)
 wav.data=bytes
 var player:=AudioStreamPlayer.new();player.stream=wav;add_child(player);voices+=1
 player.finished.connect(func():voices-=1;player.queue_free())
 player.play()
func _process(delta: float) -> void:
 clock=maxf(0,clock-delta)
