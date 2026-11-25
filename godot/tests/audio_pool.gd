extends SceneTree
const Audio=preload("res://modules/audio/audio.gd")
var checks: Array=[]
var failures: Array=[]
func check(ok: bool,message: String) -> void:
 if ok:checks.append(message)
 else:failures.append(message)
func _initialize() -> void:call_deferred("run")
func finish(audio: Node) -> void:
 # Deterministic completion in the dummy audio driver; not an audible test.
 for player in audio.players:
  if player.get_meta("busy",false):player.stop();player.finished.emit()
func original_wave(frequency: float) -> PackedByteArray:
 var bytes:=PackedByteArray();bytes.resize(2205*2)
 for i in 2205:bytes.encode_s16(i*2,int(sin(TAU*frequency*i/22050.0)*(1.0-float(i)/2205)*2500))
 return bytes
func run() -> void:
 var audio=Audio.new();root.add_child(audio);audio.set_process(false)
 audio.cue("fire")
 check(audio.muted and audio.voices==0 and audio.players.is_empty() and audio.tones.is_empty(),"default mute allocates no wave or player")
 audio.muted=false;audio.cue("fire")
 var fire: AudioStreamWAV=audio.players[0].stream
 check(audio.voices==1 and audio.players.size()==1,"first enabled cue acquires one player")
 audio.cue("ice")
 check(audio.voices==1 and not audio.tones.has("ice"),"90ms throttle rejects cue before allocating stream or player")
 audio.clock=0;audio.cue("ice")
 check(audio.voices==2 and audio.players.size()==2,"overlapping cues have independent players")
 finish(audio)
 check(audio.voices==0 and audio.players.size()==2,"completed voices return to the pool without deleting players")
 for key in Audio.FREQUENCIES:
  audio.clock=0;audio.cue(key)
  var stream: AudioStreamWAV=audio.players[0].stream
  check(stream.format==AudioStreamWAV.FORMAT_16_BITS and stream.mix_rate==22050 and stream.data==original_wave(Audio.FREQUENCIES[key]),"cached PCM matches original waveform for "+key)
  finish(audio)
 check(audio.tones.size()==5,"all supported frequencies use only five shared wave resources")
 var fallback: AudioStreamWAV=audio.tones.other
 for key in ["poison","wind","unknown"]:
  audio.clock=0;audio.cue(key)
  check(audio.players[0].stream==fallback and audio.tones.size()==5,"unknown cue shares original fallback frequency: "+key)
  finish(audio)
 for i in Audio.MAX_VOICES:
  audio.clock=0;audio.cue("fire")
 var peak: Array=audio.players.map(func(player):return player.get_instance_id())
 check(audio.voices==8 and audio.players.size()==8 and audio.get_child_count()==8,"voice and node allocation remain bounded at eight")
 audio.clock=0;audio.cue("ice")
 check(audio.voices==8 and audio.players.size()==8,"ninth concurrent voice is rejected")
 finish(audio)
 for i in 25:
  audio.clock=0;audio.cue("fire");finish(audio)
 check(audio.voices==0 and audio.players.map(func(player):return player.get_instance_id())==peak and audio.tones.fire==fire,"repeated effects reuse player instances and immutable fire stream")
 check(audio.players.all(func(player):return player.get_signal_connection_list("finished").size()==1),"player reuse never duplicates completion callbacks")
 audio.players[0].finished.emit()
 check(audio.voices==0,"duplicate idle completion never makes voice count negative")
 audio.muted=true;audio.clock=0;audio.cue("arcane")
 check(audio.voices==0 and audio.players.size()==8,"mute still rejects subsequent cues after pool warmup")
 audio.clock=0.09;audio._process(0.05)
 check(is_equal_approx(audio.clock,0.04),"clock follows existing process delta semantics")
 audio.queue_free();await process_frame
 print("AUDIO_RESULT "+JSON.stringify({"checks":checks,"failures":failures}));quit(1 if failures.size() else 0)
