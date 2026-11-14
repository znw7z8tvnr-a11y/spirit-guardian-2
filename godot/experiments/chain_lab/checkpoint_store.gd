extends RefCounted
## One local intermission checkpoint; distinct from build and discovery-book saves.
const PATH:="user://chain_lab_run_v1.json"
const WEB_KEY:="sg_chain_lab_run_v1"
const FORMAT:="spirit_guardian_checkpoint"
const MAX_BYTES:=350000
const Chain=preload("res://experiments/chain_lab/chain.gd")
const Skills=preload("res://experiments/chain_lab/spell_effects.gd")
const Gems=preload("res://experiments/chain_lab/gem_rules.gd")
const Catalog=preload("res://modules/spell/catalog.gd")
const G_INTS=["wave","kills","next_id","boss_kills","summoned_minions","summon_events","critical_casts","critical_victims","drop_serial","speed_index","tempo"]
const G_FLOATS=["combat_seconds","rest","spawn_clock","attack_clock"]
const C_INTS=["serial","casts","hits","misses","jumps","empty_casts","retargets","rolls","resonances"]
const T_INTS=["flesh","total_absorbed","auto_cursor"]
const T_FLOATS=["hp","max_hp","wall_hp","wall_max"]
var last_error:=""
var last_digest:=""
var writes:=0
static func number(v: Variant,lo: float,hi: float,whole: bool=false) -> bool:
 return (v is int or v is float) and is_finite(float(v)) and float(v)>=lo and float(v)<=hi and (not whole or float(v)==floorf(float(v)))
static func fields(data: Variant,keys: Array,lo: float,hi: float,whole: bool=false) -> bool:
 if not data is Dictionary:return false
 for k in keys:
  if not data.has(k) or not number(data[k],lo,hi,whole):return false
 return true
static func int64_text(value: Variant) -> bool:
 if not value is String or not value.is_valid_int():return false
 var negative: bool=value.begins_with("-");var digits: String=value.substr(1) if negative else value
 var limit: String="9223372036854775808" if negative else "9223372036854775807"
 if digits.length()>19 or (digits.length()==19 and digits>limit):return false
 return str(int(value))==value
static func rng_data(rng: RandomNumberGenerator) -> Dictionary:return {"seed":str(rng.seed),"state":str(rng.state)}
static func restore_rng(rng: RandomNumberGenerator,data: Dictionary) -> void:rng.seed=int(data.seed);rng.state=int(data.state)
func capture(game: Node) -> Dictionary:
 if game.over or game.enemy_drill or game.chain.kit_loaded or game.wave<1 or game.remaining!=0 or not game.rewards.completed.has(game.wave) or game.enemies.get_child_count()>0 or game.shots.get_child_count()>0 or not game.chain.active.is_empty() or not game.chain.pending.is_empty() or not game.pending_flesh.is_empty():return {}
 var g: Dictionary={}
 for k in G_INTS+G_FLOATS:g[k]=game.get(k)
 for k in ["boss_defeated","user_paused","edit_open","growth_open"]:g[k]=game.get(k)
 var tower: Dictionary={"levels":game.tower.levels.duplicate(true),"wall_active":game.tower.wall_active,"auto_upgrade":game.tower.auto_upgrade}
 for k in T_INTS+T_FLOATS:tower[k]=game.tower.get(k)
 var chain: Dictionary={"items":game.chain.items.duplicate(true),"slots":game.chain.slots.duplicate(),"edges":game.chain.edges.duplicate(true),"clock":game.chain.clock,"cooldown_until":game.chain.cooldown_until,"discovered":game.chain.discovered.duplicate(),"gem_ready":[]}
 for k in C_INTS:chain[k]=game.chain.get(k)
 for id in game.chain.gem_ready_at:chain.gem_ready.append({"id":id,"ready":game.chain.gem_ready_at[id]})
 var rewards: Dictionary={"completed":game.rewards.completed.keys(),"offers":game.rewards.offers.duplicate(true),"history":game.rewards.history.duplicate(true)}
 for k in ["pending","refreshes","extra_refresh","attack_stacks","granted_count"]:rewards[k]=game.rewards.get(k)
 var guards: Array=[];game.guardians.purge()
 for actor in game.guardians.guards:guards.append({"species":actor.species,"x":actor.position.x,"y":actor.position.y,"remaining":actor.remaining,"age":actor.age,"cooldown":actor.cooldown,"power":actor.power,"strikes":actor.strikes})
 var guardian: Dictionary={"actors":guards,"counts":game.guardians.counts.duplicate(true),"spawns":game.guardians.spawns,"hits":game.guardians.hits,"kills":game.guardians.kills}
 return {"game":g,"tower":tower,"chain":chain,"rewards":rewards,"guardians":guardian,"rng":{"game":rng_data(game.rng),"chain":rng_data(game.chain.rng),"rewards":rng_data(game.rewards.rng),"resolver":rng_data(game.resolver.rng)},"resolver_serial":game.resolver.serial,"spell_cast_counts":game.spell_cast_counts.duplicate(),"spell_hit_counts":game.spell_hit_counts.duplicate(),"enemy_spawn_counts":game.enemy_spawn_counts.duplicate(),"enemy_tactic_counts":game.enemy_tactic_counts.duplicate()}
func valid_reward(row: Variant) -> bool:
 if not row is Dictionary or not row.get("kind",null) is String or not row.get("key",null) is String or not number(row.get("level"),1,3,true):return false
 if row.kind=="skill":return row.key in Skills.PLAYABLE
 if row.kind=="gem":return row.key in Gems.KEYS
 return row.kind=="affix" and row.key in ["refresh","power"] and row.level==1
func validate(data: Variant) -> bool:
 if not data is Dictionary:return false
 for k in ["game","tower","chain","rewards","guardians","rng"]:
  if not data.get(k) is Dictionary:return false
 var g: Dictionary=data.game;var t: Dictionary=data.tower;var c: Dictionary=data.chain;var r: Dictionary=data.rewards;var h: Dictionary=data.guardians
 if not fields(g,G_INTS,0,1000000000,true) or not fields(g,G_FLOATS,-100,10000000):return false
 if not number(g.wave,1,20,true) or g.speed_index>3 or g.tempo>2 or g.rest<0 or g.rest>5 or g.combat_seconds<0 or g.boss_kills!=floori(g.wave/5.0) or g.next_id<1:return false
 for k in ["boss_defeated","user_paused","edit_open","growth_open"]:
  if not g.get(k) is bool:return false
 if g.boss_defeated!=(int(g.wave)%5==0):return false
 if not fields(t,T_INTS,0,1000000000,true) or not fields(t,T_FLOATS,0,1000000) or not fields(t.get("levels"),["atk","hp","armor","regen"],0,1000,true):return false
 if not t.get("wall_active") is bool or not t.get("auto_upgrade") is bool or t.hp<=0 or t.hp>t.max_hp or t.max_hp!=100 or t.wall_hp>t.wall_max or t.wall_max!=360+65*t.levels.hp or t.total_absorbed<t.flesh:return false
 if t.wall_hp==0 and t.wall_active:return false
 if not fields(c,C_INTS,0,1000000000,true) or not fields(c,["clock"],0,10000000) or not fields(c,["cooldown_until"],0,10000010):return false
 if not c.get("items") is Array or c.items.is_empty() or c.items.size()>256 or not c.get("slots") is Array or c.slots.size()!=10 or not c.get("edges") is Array or c.edges.size()>9:return false
 for i in c.items.size():
  if not valid_reward(c.items[i]) or c.items[i].kind=="affix" or not number(c.items[i].get("id"),i,i,true):return false
 var ids: Array=[]
 for id in c.slots:
  if not number(id,-1,c.items.size()-1,true) or (id>=0 and int(id) in ids):return false
  if id>=0:ids.append(int(id))
 if c.slots[0]<0 or c.items[int(c.slots[0])].kind!="skill":return false
 var model:=Chain.new();model.items=c.items.duplicate(true);model.slots.assign(c.slots.map(func(id):return int(id)));model.edges=[]
 var graph_ok:=true
 for e in c.edges:
  if not e is Dictionary or not fields(e,["from","to"],0,9,true):graph_ok=false;break
  if not model.connect_slots(int(e.from),int(e.to)):graph_ok=false;break
 model.free()
 if not graph_ok:return false
 if not c.get("discovered") is Array or c.discovered.size()>Catalog.data.FINISHERS.size() or not c.get("gem_ready") is Array or c.gem_ready.size()>c.items.size():return false
 var seen: Array=[]
 for key in c.discovered:
  if not key is String or not Catalog.data.FINISHERS.has(key) or key in seen:return false
  seen.append(key)
 seen=[]
 for row in c.gem_ready:
  if not row is Dictionary or not fields(row,["id"],0,c.items.size()-1,true) or not fields(row,["ready"],0,10000010) or int(row.id) in seen:return false
  if c.items[int(row.id)].kind!="gem" or c.items[int(row.id)].key!="delay":return false
  seen.append(int(row.id))
 if not fields(r,["pending","refreshes","extra_refresh","attack_stacks","granted_count"],0,100,true) or r.pending>6 or not r.get("completed") is Array or not r.get("history") is Array or not r.get("offers") is Array:return false
 if r.completed.size()!=int(g.wave) or r.history.size()!=int(r.granted_count) or r.history.size()>100:return false
 seen=[]
 for w in r.completed:
  if not number(w,1,g.wave,true) or int(w) in seen:return false
  seen.append(int(w))
 var earned: Array=[{"kind":"skill","key":"arcane","level":1,"id":0}];var power:=0;var refresh:=0
 for row in r.history:
  if not valid_reward(row):return false
  if row.kind=="affix":
   if row.key=="power":power+=1
   else:refresh+=1
  else:
   var item: Dictionary=row.duplicate(true);item.id=earned.size();earned.append(item)
 if power!=int(r.attack_stacks) or refresh!=int(r.extra_refresh) or earned.size()!=c.items.size() or r.refreshes>1+r.extra_refresh:return false
 for i in earned.size():
  for k in ["kind","key","level","id"]:
   if earned[i][k]!=c.items[i][k]:return false
 var total: int=int(r.granted_count+r.pending);var bosses:=floori(g.wave/5.0);var milestones:=floori(g.wave/3.0)
 if total<milestones+bosses or total>milestones+bosses*5:return false
 if r.offers.size()!=(3 if r.pending>0 else 0) or (r.pending==0 and r.refreshes!=0):return false
 seen=[]
 for offer in r.offers:
  if not valid_reward(offer) or offer.kind in seen:return false
  seen.append(offer.kind)
 if not fields(h,["spawns","hits","kills"],0,1000000000,true) or not h.get("actors") is Array or h.actors.size()>4 or not h.get("counts") is Dictionary:return false
 for species in ["summon","skeleton"]:
  if not fields(h.counts.get(species),["spawns","hits","kills"],0,1000000000,true):return false
 for actor in h.actors:
  if not actor is Dictionary or actor.get("species") not in ["summon","skeleton"] or not fields(actor,["x","y"],-100000,100000) or not fields(actor,["remaining","age"],0,8.01) or not fields(actor,["cooldown"],0,0.81) or not fields(actor,["power"],0.001,1000000) or not fields(actor,["strikes"],0,1000000000,true):return false
 for key in ["game","chain","rewards","resolver"]:
  var entry: Variant=data.rng.get(key)
  if not entry is Dictionary:return false
  for field in ["seed","state"]:
   if not int64_text(entry.get(field)):return false
 if not number(data.get("resolver_serial"),0,1000000000,true):return false
 for key in ["spell_cast_counts","spell_hit_counts","enemy_spawn_counts","enemy_tactic_counts"]:
  if not data.get(key) is Dictionary or data[key].size()>32:return false
  for id in data[key]:
   if not number(data[key][id],0,1000000000,true):return false
   if key.begins_with("spell_") and str(id) not in Skills.PLAYABLE:return false
   if key=="enemy_spawn_counts" and (not str(id).is_valid_int() or int(str(id))<0 or int(str(id))>5):return false
   if key=="enemy_tactic_counts" and str(id) not in ["靈彈","護盾蓄力","治療蓄力","鼓舞蓄力"]:return false
 return true
func apply(game: Node,data: Dictionary) -> bool:
 if not validate(data) or game.wave!=0 or game.over or not game.run_summary.is_empty() or game.enemies.get_child_count()>0 or game.shots.get_child_count()>0:return false
 var g: Dictionary=data.game;var t: Dictionary=data.tower;var c: Dictionary=data.chain;var r: Dictionary=data.rewards;var h: Dictionary=data.guardians
 for k in G_INTS:game.set(k,int(g[k]))
 for k in G_FLOATS:game.set(k,float(g[k]))
 for k in ["boss_defeated","user_paused","edit_open","growth_open"]:game.set(k,g[k])
 game.remaining=0
 for k in T_INTS:game.tower.set(k,int(t[k]))
 for k in T_FLOATS:game.tower.set(k,float(t[k]))
 game.tower.levels={}
 for k in t.levels:game.tower.levels[k]=int(t.levels[k])
 game.tower.wall_active=t.wall_active;game.tower.auto_upgrade=t.auto_upgrade
 game.chain.reset_runtime();game.chain.items=c.items.duplicate(true)
 for item in game.chain.items:item.id=int(item.id);item.level=int(item.level)
 game.chain.slots=c.slots.map(func(id):return int(id));game.chain.edges=[]
 for e in c.edges:game.chain.edges.append({"from":int(e.from),"to":int(e.to)})
 for k in C_INTS:game.chain.set(k,int(c[k]))
 game.chain.clock=float(c.clock);game.chain.cooldown_until=float(c.cooldown_until);game.chain.gem_ready_at={}
 for row in c.gem_ready:game.chain.gem_ready_at[int(row.id)]=float(row.ready)
 for key in c.discovered:
  if key not in game.chain.discovered:game.chain.discovered.append(key)
 game.rewards.completed={}
 for w in r.completed:game.rewards.completed[int(w)]=true
 for k in ["pending","refreshes","extra_refresh","attack_stacks","granted_count"]:game.rewards.set(k,int(r[k]))
 game.rewards.offers=r.offers.duplicate(true);game.rewards.history=r.history.duplicate(true)
 for row in game.rewards.offers+game.rewards.history:row.level=int(row.level)
 game.guardians.guards.clear()
 for node in game.guardians.get_children():game.guardians.remove_child(node);node.queue_free()
 for k in ["spawns","hits","kills"]:game.guardians.set(k,int(h[k]))
 game.guardians.counts={}
 for species in ["summon","skeleton"]:
  game.guardians.counts[species]={}
  for field in ["spawns","hits","kills"]:game.guardians.counts[species][field]=int(h.counts[species][field])
 for row in h.actors:
  var actor=preload("res://experiments/chain_lab/guardian_actor.gd").new();actor.species=row.species;actor.position=Vector2(row.x,row.y)
  for k in ["remaining","age","cooldown","power"]:actor.set(k,float(row[k]))
  actor.strikes=int(row.strikes);game.guardians.add_child(actor);game.guardians.guards.append(actor)
 restore_rng(game.rng,data.rng.game);restore_rng(game.chain.rng,data.rng.chain);restore_rng(game.rewards.rng,data.rng.rewards);restore_rng(game.resolver.rng,data.rng.resolver);game.resolver.serial=int(data.resolver_serial)
 for key in ["spell_cast_counts","spell_hit_counts","enemy_tactic_counts"]:game.set(key,data[key].duplicate(true))
 game.enemy_spawn_counts={}
 for id in data.enemy_spawn_counts:game.enemy_spawn_counts[int(str(id))]=int(data.enemy_spawn_counts[id])
 game.chain.hop_delay=[0.32,0.48,0.20][game.tempo];game.attack_period=[3.8,5.2,3.2][game.tempo];game.flight_time=[0.62,0.85,0.45][game.tempo]
 Engine.time_scale=game.SPEEDS[game.speed_index];game.buttons.Speed.text="倍速：%d×" % Engine.time_scale;game.buttons.Pause.text="繼續" if game.user_paused else "暫停";game.buttons.Tempo.text=["節奏：標準","節奏：慢速","節奏：快速"][game.tempo]
 game.panel.visible=game.edit_open;game.growth_panel.visible=game.growth_open;game.loadout_notice.visible=game.edit_open;game.rewards.changed.emit();game.chain.changed.emit();game.tower.growth_changed.emit();game.refresh_status()
 return true
func read_file(path: String) -> Dictionary:
 if not FileAccess.file_exists(path):return {"ok":false,"reason":"missing"}
 var f:=FileAccess.open(path,FileAccess.READ)
 if f==null or f.get_length()>MAX_BYTES:return {"ok":false,"reason":"size"}
 return decode_text(f.get_as_text())
func decode_text(text: String) -> Dictionary:
 if text.to_utf8_buffer().size()>MAX_BYTES:return {"ok":false,"reason":"size"}
 var outer_reader:=JSON.new()
 if outer_reader.parse(text)!=OK:return {"ok":false,"reason":"json"}
 var outer: Variant=outer_reader.data
 if not outer is Dictionary or outer.get("format")!=FORMAT or outer.get("schema")!=1 or not outer.get("payload") is String or not outer.get("sha256") is String:return {"ok":false,"reason":"format"}
 if outer.payload.length()>250000 or outer.payload.sha256_text()!=outer.sha256:return {"ok":false,"reason":"checksum"}
 var payload_reader:=JSON.new()
 if payload_reader.parse(outer.payload)!=OK:return {"ok":false,"reason":"json"}
 var data: Variant=payload_reader.data
 if not validate(data):return {"ok":false,"reason":"invalid"}
 return {"ok":true,"data":data,"digest":outer.sha256}
func load_checkpoint() -> Dictionary:
 if OS.has_feature("web"):return load_web()
 var primary:=read_file(PATH)
 if primary.ok:primary.source="primary";return primary
 var backup:=read_file(PATH+".bak")
 if backup.ok:backup.source="backup";backup.primary_error=primary.reason;return backup
 return {"ok":false,"reason":primary.reason,"exists":FileAccess.file_exists(PATH) or FileAccess.file_exists(PATH+".bak")}
func save_game(game: Node) -> bool:
 var data:=capture(game)
 if data.is_empty():return false
 return save_data(data)
func save_data(data: Dictionary) -> bool:
 if not validate(data):last_error="資料不完整，保留原進度";return false
 var text:=JSON.stringify(data,"",true,true);var digest:=text.sha256_text()
 if OS.has_feature("web"):return save_web(text,digest)
 if digest==last_digest and read_file(PATH).ok:return true
 var file:=FileAccess.open(PATH+".tmp",FileAccess.WRITE)
 if file==null:last_error="無法寫入續玩進度";return false
 file.store_string(JSON.stringify({"format":FORMAT,"schema":1,"payload":text,"sha256":digest}));file.flush();file.close()
 if not read_file(PATH+".tmp").ok:last_error="續玩進度驗證失敗";return false
 if FileAccess.file_exists(PATH):
  if read_file(PATH).ok:
   if FileAccess.file_exists(PATH+".bak") and DirAccess.remove_absolute(PATH+".bak")!=OK:last_error="無法更新備份";return false
   if DirAccess.rename_absolute(PATH,PATH+".bak")!=OK:last_error="無法備份原進度";return false
  elif DirAccess.remove_absolute(PATH)!=OK:last_error="無法替換損壞進度";return false
 if DirAccess.rename_absolute(PATH+".tmp",PATH)!=OK:
  if FileAccess.file_exists(PATH+".bak"):DirAccess.rename_absolute(PATH+".bak",PATH)
  last_error="無法完成續玩保存";return false
 last_digest=digest;last_error="";writes+=1
 return true
func clear() -> bool:
 if OS.has_feature("web"):
  var cleared: bool=bool(JavaScriptBridge.eval("(()=>{try{localStorage.removeItem("+JSON.stringify(WEB_KEY)+");localStorage.removeItem("+JSON.stringify(WEB_KEY+".bak")+");return true;}catch(e){return false;}})()"))
  if cleared:last_digest=""
  return cleared
 var ok:=true
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(PATH+suffix) and DirAccess.remove_absolute(PATH+suffix)!=OK:ok=false
 last_digest=""
 return ok

func web_read(key: String) -> Dictionary:
 var raw: Variant=JavaScriptBridge.eval("(()=>{try{return JSON.stringify({available:true,text:localStorage.getItem("+JSON.stringify(key)+")});}catch(e){return JSON.stringify({available:false});}})()")
 if not raw is String:return {"available":false}
 var value: Variant=JSON.parse_string(raw)
 return value if value is Dictionary else {"available":false}
func web_available() -> bool:return bool(web_read(WEB_KEY).available)
func load_web() -> Dictionary:
 var first:=web_read(WEB_KEY);var second:=web_read(WEB_KEY+".bak")
 if not first.available or not second.available:return {"ok":false,"reason":"storage_unavailable","exists":false}
 var primary:=decode_text(first.text) if first.text is String else {"ok":false,"reason":"missing"}
 if primary.ok:primary.source="primary";return primary
 var backup:=decode_text(second.text) if second.text is String else {"ok":false,"reason":"missing"}
 if backup.ok:backup.source="backup";backup.primary_error=primary.reason;return backup
 return {"ok":false,"reason":primary.reason,"exists":first.text is String or second.text is String}
func save_web(text: String,digest: String) -> bool:
 var previous:=web_read(WEB_KEY)
 if not previous.available:last_error="此瀏覽器無法寫入續玩進度";return false
 var old:=decode_text(previous.text) if previous.text is String else {"ok":false}
 if digest==last_digest and old.ok and old.digest==digest:return true
 var envelope:=JSON.stringify({"format":FORMAT,"schema":1,"payload":text,"sha256":digest})
 var script: String="(()=>{try{"
 if old.ok:script+="localStorage.setItem("+JSON.stringify(WEB_KEY+".bak")+","+JSON.stringify(previous.text)+");"
 script+="localStorage.setItem("+JSON.stringify(WEB_KEY)+","+JSON.stringify(envelope)+");return true;}catch(e){return false;}})()"
 if not bool(JavaScriptBridge.eval(script)):last_error="本機空間不足或瀏覽器禁止儲存，保留原進度";return false
 var readback:=web_read(WEB_KEY)
 if not readback.available or readback.text!=envelope:last_error="續玩進度讀回驗證失敗";return false
 last_digest=digest;last_error="";writes+=1
 return true
