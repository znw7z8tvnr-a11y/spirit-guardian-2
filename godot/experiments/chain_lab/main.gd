extends Node2D
const SpellEffects=preload("res://experiments/chain_lab/spell_effects.gd")
const Chain=preload("res://experiments/chain_lab/chain.gd")
const Enemy=preload("res://modules/enemy/enemy.gd")
const Boss=preload("res://modules/boss/boss.gd")
const Tower=preload("res://experiments/chain_lab/flesh_castle.gd")
const Steering=preload("res://modules/enemy/steering.gd")
const Resolver=preload("res://modules/spell/combat_resolver.gd")
const FX=preload("res://modules/combat_fx/combat_fx.gd")
const Projectile=preload("res://modules/spell/projectile.gd")
const Catalog=preload("res://modules/spell/catalog.gd")
const Zh=preload("res://localization/zh_hant.gd")
const CENTER:=Vector2(900,500)
const BOOK_PATH:="user://chain_lab_book.json"
@export var persist_book:=true
var chain: Node
var rewards: Node
var reward_panel: PanelContainer
var spell_cast_counts: Dictionary={}
var spell_hit_counts: Dictionary={}
var boss_defeated:=false
var boss_kills:=0
var summoned_minions:=0
var summon_events:=0
var boss_info: Dictionary={}
var boss_label: Label
var boss_health: ProgressBar
var loadout_notice: Label
var enemies: Node2D
var shots: Node2D
var tower: Node2D
var fx: Node2D
var drops: Node2D
var pending_flesh: Dictionary={}
var drop_serial:=0
var growth_open:=false
var speed_index:=0
var combat_seconds:=0.0
const SPEEDS: Array[float]=[1.0,2.0,4.0,8.0]
var resolver: Node
var brain:=Steering.new()
var rng:=RandomNumberGenerator.new()
var wave:=0
var remaining:=0
var spawn_clock:=0.0
var rest:=3.0
var attack_clock:=0.0
var attack_period:=3.8
var flight_time:=0.62
var tempo:=0
var kills:=0
var next_id:=1
var over:=false
var user_paused:=false
var edit_open:=false
var root_ui: Control
var status: Label
var event_label: Label
var settings_label: Label
var health: ProgressBar
var wall_health: ProgressBar
var wall_label: Label
var growth_label: Label
var growth_panel: PanelContainer
var growth_summary: Label
var growth_buttons: Dictionary={}
var battle_controls: GridContainer
var bottom_box: VBoxContainer
var panel: PanelContainer
var grid: Control
var picker: OptionButton
var inventory: PanelContainer
var editor_status: Label
var links: Label
var book: Label
var selected:=0
var link_from:=-1
var buttons: Dictionary={}
var slot_buttons: Array=[]
var trail: Array=[]
var debug_clock:=0.0
var ui_clock:=0.0
var web_debug:=false
func _ready() -> void:
 Engine.time_scale=1.0
 TranslationServer.set_locale("zh_TW");rng.randomize()
 if OS.has_feature("web"):web_debug=bool(JavaScriptBridge.eval("new URLSearchParams(location.search).get('debug') === '1'"))
 var ground:=Sprite2D.new();ground.texture=preload("res://assets/legacy/terrain.png");ground.position=CENTER;ground.scale=Vector2.ONE*1.45;ground.z_index=-10;add_child(ground)
 var camera:=Camera2D.new();camera.position=CENTER;camera.zoom=Vector2.ONE*0.72;add_child(camera)
 enemies=Node2D.new();enemies.y_sort_enabled=true;add_child(enemies)
 shots=Node2D.new();add_child(shots)
 tower=Tower.new();tower.position=CENTER;tower.scale=Vector2.ONE/0.72;add_child(tower)
 tower.destroyed.connect(func():over=true;chain.reset_runtime();event_label.text="守護水晶已破碎；可重新開始試驗。")
 resolver=Resolver.new();add_child(resolver)
 fx=FX.new();add_child(fx)
 drops=Node2D.new();add_child(drops)
 chain=Chain.new();chain.host=self;add_child(chain)
 rewards=preload("res://experiments/chain_lab/rewards.gd").new();add_child(rewards);rewards.granted.connect(receive_reward)
 if web_debug:
  var seed_value: Variant=JavaScriptBridge.eval("Number(new URLSearchParams(location.search).get('seed') || 0)")
  if seed_value is float and is_finite(seed_value) and seed_value>0:
   rng.seed=int(seed_value);chain.rng.seed=int(seed_value)+19980;rewards.rng.seed=int(seed_value)+31000
 if persist_book and FileAccess.file_exists(BOOK_PATH):
  var saved: Variant=JSON.parse_string(FileAccess.get_file_as_string(BOOK_PATH))
  if saved is Array:
   for key in saved:
    if key in Catalog.data.FINISHERS and key not in chain.discovered:chain.discovered.append(key)
 chain.cast_requested.connect(cast_spell)
 chain.resonance_requested.connect(resonate)
 chain.pulse.connect(show_pulse)
 chain.changed.connect(func():refresh_editor.call_deferred())
 tower.growth_changed.connect(func():refresh_growth.call_deferred())
 create_ui()
 get_viewport().size_changed.connect(resize_ui)
 resize_ui();refresh_editor();refresh_status()
func make_button(id: String, text: String, parent: Node, action: Callable) -> Button:
 var b:=Button.new();b.text=text;b.custom_minimum_size=Vector2(152,72);parent.add_child(b);b.pressed.connect(action);buttons[id]=b;return b
func label(text: String, parent: Node) -> Label:
 var l:=Label.new();l.text=text;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(l);return l
func create_ui() -> void:
 var layer:=CanvasLayer.new();add_child(layer)
 root_ui=Control.new();root_ui.theme=load("res://localization/zh_hant_theme.tres");root_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root_ui.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(root_ui)
 var top:=VBoxContainer.new();top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE);top.offset_left=24;top.offset_right=-24;top.offset_top=18;root_ui.add_child(top)
 label("靈境守衛｜血肉城牆試驗・最高八倍速",top)
 status=label("",top)
 wall_label=label("",top)
 wall_health=ProgressBar.new();wall_health.custom_minimum_size=Vector2(280,14);wall_health.show_percentage=false;top.add_child(wall_health)
 health=ProgressBar.new();health.custom_minimum_size=Vector2(280,14);health.show_percentage=false;top.add_child(health)
 growth_label=label("",top)
 boss_label=label("",top)
 boss_health=ProgressBar.new();boss_health.custom_minimum_size=Vector2(280,14);boss_health.show_percentage=false;top.add_child(boss_health);boss_health.hide()
 label("暫用素材・血肉自動吸收，可開城牆調整強化",top)
 var bottom:=VBoxContainer.new();bottom_box=bottom;bottom.alignment=BoxContainer.ALIGNMENT_END;bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE);bottom.offset_left=24;bottom.offset_right=-24;bottom.offset_top=-220;bottom.offset_bottom=-18;root_ui.add_child(bottom)
 event_label=label("開局奧彈會快速出手；擊殺吸收血肉，強化城牆與攻擊。",bottom)
 event_label.custom_minimum_size.y=64;event_label.max_lines_visible=2
 settings_label=label("",bottom)
 var center:=CenterContainer.new();bottom.add_child(center)
 var row:=GridContainer.new();row.columns=8;battle_controls=row;center.add_child(row)
 make_button("Configure","配置／背包",row,func():open_editor())
 make_button("Kit","載入試驗配置",row,func():chain.load_kit();open_editor())
 make_button("SpellKit","八技能演練",row,func():chain.load_spell_kit();open_editor())
 make_button("Flesh","血肉城牆",row,open_growth)
 make_button("Tempo","節奏：標準",row,cycle_tempo)
 make_button("Speed","倍速：1×",row,cycle_speed)
 make_button("Pause","暫停",row,func():user_paused=not user_paused;buttons.Pause.text="繼續" if user_paused else "暫停")
 make_button("Restart","重新開始",row,func():get_tree().call_deferred("reload_current_scene"))
 panel=PanelContainer.new();panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);panel.offset_left=16;panel.offset_right=-16;panel.offset_top=16;panel.offset_bottom=-16;root_ui.add_child(panel)
 var bg:=StyleBoxFlat.new();bg.bg_color=Color("101a2c");bg.set_content_margin_all(16);panel.add_theme_stylebox_override("panel",bg)
 var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;panel.add_child(scroll)
 var box:=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(box)
 label("連鎖配置｜圓形技能 → 菱形寶石 → 技能；三級寶石可分岔",box)
 var row2:=HBoxContainer.new();box.add_child(row2)
 make_button("Done","完成配置／繼續戰鬥",row2,func():edit_open=false;link_from=-1;panel.hide();loadout_notice.hide())
 make_button("Random","隨機排列",row2,func():chain.random_arrange();refresh_editor.call_deferred())
 make_button("Arrange","已知共振排列",row2,arrange_known)
 loadout_notice=label("獎勵已入背包；選格子後開圖示背包裝配，準備好再繼續戰鬥。",box);loadout_notice.hide()
 editor_status=label("",box)
 picker=OptionButton.new();picker.custom_minimum_size.y=72;box.add_child(picker);picker.hide()
 make_button("Inventory","圖示背包／比較",box,func():inventory.open(chain,selected,spell_attack_multiplier()))
 var row3:=HBoxContainer.new();box.add_child(row3)
 make_button("Equip","替換此格",row3,func():inventory.open(chain,selected,spell_attack_multiplier()))
 make_button("Source","設為起點",row3,func():link_from=selected;editor_status.text="已選起點 %d；點另一格，再按連到此格。" % [selected+1])
 make_button("Connect","連到此格",row3,func():
  var ok: bool=chain.connect_slots(link_from,selected)
  editor_status.text="連線完成。" if ok else "無法連線：需交替、不可循環，且普通寶石只能接一線。"
  if ok:link_from=-1
 )
 make_button("Disconnect","移除此連線",row3,func():chain.disconnect_slots(link_from,selected);link_from=-1)
 grid=preload("res://experiments/chain_lab/tree_view.gd").new();grid.custom_minimum_size=Vector2(1120,465);box.add_child(grid)
 grid.slot_selected.connect(func(index: int):selected=index;refresh_editor.call_deferred())
 links=label("",box)
 book=label("",box)
 label("替換只使用本局持有物品；同一件不能重複裝備。先移除不相容連線才能換類型。試驗版不儲存戰局與配置；共振發現獨立保存。",box)
 panel.hide()
 create_growth_ui()
 inventory=preload("res://experiments/chain_lab/inventory_view.gd").new();root_ui.add_child(inventory)
 inventory.apply_requested.connect(func(id: int):
  if chain.equip(inventory.slot,id):inventory.hide()
  else:inventory.select_item(id)
 )
 reward_panel=preload("res://experiments/chain_lab/reward_view.gd").new();root_ui.add_child(reward_panel);reward_panel.bind(rewards)
 for i in range(3):buttons["Reward %d" % i]=reward_panel.choices[i]
 buttons.RewardRefresh=reward_panel.refresh
func resize_ui() -> void:
 var portrait:=get_viewport_rect().size.y>get_viewport_rect().size.x
 # Graph keeps spatial relationships in both orientations; outer panel scrolls.
 battle_controls.columns=4 if portrait else 8
 bottom_box.offset_top=-310 if portrait else -240
 for key in ["Configure","Kit","SpellKit","Flesh","Tempo","Speed","Pause","Restart"]:
  buttons[key].custom_minimum_size=Vector2(196 if portrait else 144,72)
func name_of(item: Dictionary) -> String:
 if item.is_empty():return "空格"
 return "%s・%d 級" % [Zh.spell(str(item.key)) if item.kind=="skill" else preload("res://experiments/chain_lab/gem_rules.gd").title(str(item.key)),int(item.level)]
func refresh_editor() -> void:
 if not is_instance_valid(grid):return
 grid.rebuild(chain,selected)
 slot_buttons=grid.nodes
 picker.clear()
 picker.add_item("清空此格");picker.set_item_metadata(0,-1)
 for item in chain.items:
  if chain.slots.has(item.id) and chain.slots[selected]!=item.id:continue
  picker.add_item("%s　%s" % [name_of(item),"已裝備" if chain.slots[selected]==item.id else "背包"])
  picker.set_item_metadata(picker.item_count-1,item.id)
  if chain.slots[selected]==item.id:picker.select(picker.item_count-1)
 editor_status.text="魔杖 %d / 10 格｜第 %d 格：%s｜點圖示背包比較與替換。" % [10-chain.slots.count(-1),selected+1,name_of(chain.item_at(selected))]
 var texts: Array=[]
 for e in chain.edges:texts.append("%02d → %02d" % [int(e.from)+1,int(e.to)+1])
 links.text="連線："+"　／　".join(texts)
 var found: Array=[]
 for key in chain.discovered:found.append(str(Catalog.data.FINISHERS[key][0])+"（"+str(key).replace("fire","火").replace("ice","冰").replace("lightning","雷").replace("poison","毒")+"）")
 book.text="共振紀錄書：尚未發現配方，請在戰鬥中探索。" if found.is_empty() else "共振紀錄書："+"、".join(found)
 buttons.Arrange.disabled=chain.discovered.is_empty()
 buttons.Random.disabled=chain.items.size()<2
func equip_selected() -> void:
 var ok: bool=chain.equip(selected,int(picker.get_item_metadata(picker.selected)))
 if not ok:editor_status.text="替換失敗：物品已使用、起點需技能，或現有連線不相容。"
func open_editor(from_reward:=false) -> void:
 loadout_notice.visible=from_reward
 edit_open=true;panel.show();refresh_editor.call_deferred()
func arrange_known() -> void:
 if chain.discovered.is_empty():return
 if not chain.arrange_discovered():editor_status.text="持有物品不足以排列已發現的配方；不會產生額外物品。"
func cycle_tempo() -> void:
 tempo=(tempo+1)%3
 chain.hop_delay=[0.32,0.48,0.20][tempo];attack_period=[3.8,5.2,3.2][tempo];flight_time=[0.62,0.85,0.45][tempo]
 buttons.Tempo.text=["節奏：標準","節奏：慢速","節奏：快速"][tempo]
func _physics_process(delta: float) -> void:
 if over or user_paused or edit_open or growth_open or rewards.pending>0:return
 combat_seconds+=delta;tower.recover(delta)
 brain.prepare(enemies.get_children());chain.advance(delta)
 attack_clock-=delta
 if attack_clock<=0 and chain.active.is_empty():
  var enemy:=target_near(CENTER,2000)
  if enemy!=null and chain.start(enemy):attack_clock=effective_attack_period()
 if remaining>0:
  spawn_clock-=delta
  if spawn_clock<=0 and enemies.get_child_count()<40:spawn_enemy();remaining-=1;spawn_clock=1.4
 elif enemies.get_child_count()==0 and chain.active.is_empty():
  collect_all_flesh()
  rewards.complete_wave(wave,boss_defeated)
  if rewards.pending>0:return
  rest-=delta
  if rest<=0:
   if wave>=20:over=true;event_label.text="20 波試驗完成！";return
   wave+=1;boss_defeated=false;remaining=4+mini(wave,8);rest=5.0
func _process(delta: float) -> void:
 # Keep combat actors and projectile tweens frozen while the lab editor is open.
 var frozen: bool=over or user_paused or edit_open or growth_open or rewards.pending>0
 for node in [enemies,shots,fx,drops]:node.process_mode=Node.PROCESS_MODE_DISABLED if frozen else Node.PROCESS_MODE_INHERIT
 var real_delta:=delta/maxf(Engine.time_scale,0.001)
 ui_clock-=real_delta
 if ui_clock<=0:ui_clock=0.2;refresh_status()
 if web_debug:
  debug_clock-=real_delta
  if debug_clock<=0:debug_clock=0.2;publish_debug()
func spawn_enemy() -> Node2D:
 var is_boss:=wave%5==0 and remaining==4+mini(wave,8)
 var e: Node2D=Boss.new() if is_boss else Enemy.new()
 if is_boss:e.boss_kind=(int(wave/5)-1)%3
 else:
  var kinds: Array=[0,0,1] if wave<=2 else [0,0,1,2] if wave==3 else [0,0,1,2,4]
  e.kind=kinds[(wave+remaining)%kinds.size()]
 var angle:=rng.randf_range(0,TAU)
 return configure_enemy(e,is_boss,CENTER+Vector2(cos(angle)*820,sin(angle)*410))
func configure_enemy(e: Node2D, is_boss: bool, at: Vector2) -> Node2D:
 e.entity_id=next_id;next_id+=1;e.brain=brain;e.resolver=resolver;e.position=at;e.target=CENTER
 e.max_hp=([28.0,20.0,60.0,38.0,95.0,300.0][e.kind]+wave*(25 if is_boss else 3));e.hp=e.max_hp
 e.speed=[22.0,34.0,16.0,20.0,23.0,15.0][e.kind]+wave*0.35;e.damage=1.5+wave*0.18
 e.attacked.connect(func(amount: float):tower.take_damage(amount))
 e.died.connect(on_enemy_died)
 if is_boss:e.summon_requested.connect(spawn_boss_minions)
 enemies.add_child(e);return e
func spawn_boss_minions(boss: Node2D, count: int) -> void:
 if not is_instance_valid(boss) or boss.dead or over or count<=0:return
 var available:=maxi(0,40-enemies.get_child_count())
 var total:=mini(count,available)
 if total>0:summon_events+=1
 for i in range(total):
  var minion:=Enemy.new();minion.kind=i%2
  var angle:=rng.randf_range(0,TAU)
  configure_enemy(minion,false,boss.position+Vector2.from_angle(angle)*72)
  summoned_minions+=1
func target_near(at: Vector2, radius: float) -> Node2D:
 var best: Node2D=null;var distance:=radius*radius
 for e in enemies.get_children():
  if not is_instance_valid(e) or e.dead:continue
  var d: float=e.position.distance_squared_to(at)
  if d<=distance:distance=d;best=e
 return best
func cast_spell(slot: int, item: Dictionary, target: Node2D, run: Dictionary, context: Dictionary) -> void:
 if not chain.current(run):return
 var shot:=Sprite2D.new();shot.texture=SpellEffects.texture(str(item.key));shot.scale=Vector2.ONE*0.20
 if context.get("is_echo",false):shot.modulate=Color(0.85,0.65,1.0,0.78)
 shot.position=context.origin;shot.set_meta("spell_key",str(item.key));shots.add_child(shot)
 var at: Vector2=context.aim
 var attack_boost: float=spell_attack_multiplier()*float(context.get("damage_scale",1.0))
 var target_ref: WeakRef=weakref(target) if is_instance_valid(target) else null
 var tween:=shot.create_tween()
 if str(item.key)=="meteor":
  shot.position=at+Vector2(0,-260);shot.scale=Vector2.ONE*0.38;shot.rotation=-PI/2
  tween.tween_interval(0.25)
  tween.tween_property(shot,"position",at,flight_time*1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
 else:
  var lift: Vector2=(shot.position+at)*0.5+Vector2(0,-90)
  tween.tween_property(shot,"position",lift,flight_time*0.5).set_trans(Tween.TRANS_SINE)
  tween.tween_property(shot,"position",at,flight_time*0.5).set_trans(Tween.TRANS_SINE)
 tween.tween_callback(func():
  if not chain.current(run):shot.queue_free();return
  var victim: Node2D=target_ref.get_ref() if target_ref!=null else null
  if not chain.alive(victim):
   victim=null if str(item.key) in ["meteor","nova","beam"] else chain.choose_target(at,run)
   if victim!=null:
    chain.retargets+=1
    if chain.target_id(victim) not in run.visited:run.visited.append(chain.target_id(victim))
  var key: String=item.key
  var impact_at: Vector2=victim.position if chain.alive(victim) else at
  if chain.alive(victim):context["target_id"]=chain.target_id(victim)
  var result: Dictionary=SpellEffects.impact(key,victim,context.origin,impact_at,int(item.level),attack_boost,enemies.get_children(),resolver)
  if bool(result.hit):
   context["target_id"]=int(result.target_id)
   if int(result.target_id) not in run.visited:run.visited.append(int(result.target_id))
  spell_cast_counts[key]=int(spell_cast_counts.get(key,0))+1
  spell_hit_counts[key]=int(spell_hit_counts.get(key,0))+int(result.hit_count)
  # Ground casts retain shaped FX; only the resolver supplies real hit/kill gates.
  spell_impact(impact_at,key)
  if key in ["meteor","nova","poison","beam"]:spell_visual(key,context.origin,impact_at)
  chain.complete_skill(slot,victim,result,run,context)
  shot.queue_free()
 )
func show_pulse(slot: int, _message: String) -> void:
 var item: Dictionary=chain.item_at(slot)
 trail.append("%02d %s%s" % [slot+1,name_of(item),"・施放" if item.kind=="skill" else "・判定"])
 if trail.size()>5:trail.pop_front()
 event_label.text=" → ".join(trail)
 if slot<slot_buttons.size():
  slot_buttons[slot].modulate=Color("ffe4a0")
func resonate(recipe: String, at: Vector2, _run_id: int) -> void:
 event_label.text="共振發現："+str(Catalog.data.FINISHERS[recipe][0])
 spell_impact(at,"arcane");spell_impact(at,"lightning")
 for e in enemies.get_children():
  if not e.dead and e.position.distance_to(at)<240:resolver.resolve(e,45.0*tower.attack_multiplier(),"arcane",{"critical":false})
 if persist_book:
  var file:=FileAccess.open(BOOK_PATH,FileAccess.WRITE)
  if file!=null:file.store_string(JSON.stringify(chain.discovered))
 refresh_editor.call_deferred()
func refresh_status() -> void:
 refresh_boss_status()
 if not is_instance_valid(status):return
 status.text="第 %d／20 波　擊殺 %d　水晶 %d／100　共振 %d　跳躍 %d　落空 %d" % [wave,kills,tower.hp,chain.resonances,chain.jumps,chain.misses]
 health.max_value=tower.max_hp;health.value=tower.hp
 wall_health.max_value=tower.wall_max;wall_health.value=tower.wall_hp
 wall_label.text="城牆 %d／%d・%s　核心 %d／%d" % [tower.wall_hp,tower.wall_max,"防線正常" if tower.wall_active else "破牆，修復中",tower.hp,tower.max_hp]
 growth_label.text="血肉 %d（已吸收 %d）・攻擊 ×%.2f・減傷 %d%%・回血 %.1f／秒" % [tower.flesh,tower.total_absorbed,spell_attack_multiplier(),tower.reduction()*100,tower.regeneration()]
 settings_label.text="每輪至少 %.1f 秒・每段 %.2f 秒・共振冷卻 %.0f 秒・%d FPS" % [effective_attack_period(),chain.hop_delay,chain.resonance_cooldown,Engine.get_frames_per_second()]
func publish_debug() -> void:
 var bounds: Dictionary={}
 for key in buttons:
  var rect: Rect2=buttons[key].get_global_rect();bounds[key]=[rect.get_center().x,rect.get_center().y,rect.size.x,rect.size.y]
 for i in slot_buttons.size():
  var rect: Rect2=slot_buttons[i].get_global_rect();bounds["Slot %d" % i]=[rect.get_center().x,rect.get_center().y,rect.size.x,rect.size.y]
 if is_instance_valid(inventory):
  for key in inventory.cards:
   var rect: Rect2=inventory.cards[key].get_global_rect();bounds[key]=[rect.get_center().x,rect.get_center().y,rect.size.x,rect.size.y]
 JavaScriptBridge.eval("window.SG_LAB_STATE="+JSON.stringify({"wave":wave,"hp":tower.hp,"wall_hp":tower.wall_hp,"wall_max":tower.wall_max,"wall_active":tower.wall_active,"flesh":tower.flesh,"absorbed":tower.total_absorbed,"attack_multiplier":tower.attack_multiplier(),"defense":tower.reduction(),"regen":tower.regeneration(),"growth_levels":tower.levels,"auto_growth":tower.auto_upgrade,"growth_open":growth_open,"speed":SPEEDS[speed_index],"combat_seconds":combat_seconds,"meat_pending":pending_flesh.size(),"kills":kills,"enemies":enemies.get_child_count(),"casts":chain.casts,"hits":chain.hits,"misses":chain.misses,"jumps":chain.jumps,"empty_casts":chain.empty_casts,"trace":chain.trace,"pending":chain.pending.size(),"active":not chain.active.is_empty(),"retargets":chain.retargets,"resonances":chain.resonances,"rolls":chain.rolls,"slots":chain.slots,"edges":chain.edges,"kit":chain.kit_loaded,"edit_open":edit_open,"paused":user_paused,"tempo":tempo,"selected":selected,"buttons":bounds,"viewport":[get_viewport_rect().size.x,get_viewport_rect().size.y],"spell_flights":shots.get_children().map(func(node):return str(node.get_meta("spell_key",""))),"spell_visuals":fx.get_children().map(func(node):return str(node.get_meta("spell_key",""))),"spell_casts":spell_cast_counts,"spell_hits":spell_hit_counts,"spell_keys":Catalog.PLAYABLE,"spell_kit":chain.spell_kit_loaded,"spell_kit_ids":chain.spell_kit_ids,"boss":boss_info,"boss_kills":boss_kills,"summoned_minions":summoned_minions,"summon_events":summon_events,"attack_period":effective_attack_period(),"reward_loadout":loadout_notice.visible,"reward_pending":rewards.pending,"reward_offers":rewards.offers,"reward_refreshes":rewards.refreshes,"reward_granted":rewards.granted_count,"reward_extra_refresh":rewards.extra_refresh,"reward_attack_stacks":rewards.attack_stacks,"item_count":chain.items.size(),"spell_attack_multiplier":spell_attack_multiplier(),"reward_completed":rewards.completed.keys(),"inventory_open":inventory.visible,"candidate":inventory.candidate,"inventory_apply_disabled":inventory.apply.disabled,"inventory_detail":inventory.detail.text,"capacity":10,"discovered":chain.discovered,"arrange_disabled":buttons.Arrange.disabled}))

func effective_attack_period() -> float:
 # A lone starting spell should not wait for a nonexistent long chain.
 var skills: int=chain.reachable_skill_count()
 if skills<=1:return minf(attack_period,1.1)
 if skills==2:return minf(attack_period,1.8)
 return attack_period
func cycle_speed() -> void:
 speed_index=(speed_index+1)%SPEEDS.size()
 Engine.time_scale=SPEEDS[speed_index]
 buttons.Speed.text="倍速：%d×" % int(SPEEDS[speed_index])
func _exit_tree() -> void:
 Engine.time_scale=1.0
func on_enemy_died(enemy: Node2D) -> void:
 if enemy.get_meta("lab_drop_claimed",false):return
 enemy.set_meta("lab_drop_claimed",true);kills+=1
 if enemy.kind==5:boss_defeated=true;boss_kills+=1
 var amount:=48 if enemy.kind==5 else 16 if enemy.kind==4 else 4
 drop_serial+=1
 var id:=drop_serial
 if pending_flesh.size()>=32:
  tower.absorb(amount);return
 var sprite:=Sprite2D.new();sprite.texture=preload("res://experiments/chain_lab/assets/flesh.svg");sprite.scale=Vector2.ONE*0.65;sprite.position=enemy.position;sprite.z_index=5;drops.add_child(sprite)
 pending_flesh[id]={"amount":amount,"visual":weakref(sprite)}
 var tween:=sprite.create_tween()
 tween.tween_property(sprite,"position",CENTER,0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
 tween.tween_callback(func():collect_flesh(id))
func collect_flesh(id: int) -> void:
 if not pending_flesh.has(id):return
 var drop: Dictionary=pending_flesh[id];pending_flesh.erase(id)
 var visual: Node=drop.visual.get_ref()
 if is_instance_valid(visual):visual.queue_free()
 tower.absorb(int(drop.amount))
func collect_all_flesh() -> void:
 for id in pending_flesh.keys():collect_flesh(int(id))
func create_growth_ui() -> void:
 growth_panel=PanelContainer.new();growth_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);growth_panel.offset_left=16;growth_panel.offset_right=-16;growth_panel.offset_top=16;growth_panel.offset_bottom=-16;root_ui.add_child(growth_panel)
 var style:=StyleBoxFlat.new();style.bg_color=Color("151b2c");style.set_content_margin_all(20);growth_panel.add_theme_stylebox_override("panel",style)
 var scroll:=ScrollContainer.new();growth_panel.add_child(scroll)
 var box:=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(box)
 label("血肉城牆｜當局強化，新局重置",box)
 growth_summary=label("",box)
 var row:=HBoxContainer.new();box.add_child(row)
 make_button("GrowthDone","返回戰鬥",row,func():growth_open=false;growth_panel.hide())
 make_button("AutoGrowth","自動強化：開",row,func():tower.set_auto(not tower.auto_upgrade);refresh_growth())
 for stat in ["atk","hp","armor","regen"]:
  var key: String=stat
  var b:=make_button("Grow "+key,"",box,func():tower.upgrade(key);refresh_growth())
  b.custom_minimum_size=Vector2(700,86);growth_buttons[key]=b
 label("擊殺掉肉：普通4、精英16、Boss48；自動吸收，無須點撿。自動強化依攻擊、生命、防禦、回血輪流購買，可關閉後手動分配。",box)
 label("城牆先承傷，破牆後核心承傷；回血先修城牆，滿後補核心。破牆需修至20%才重新形成防線。這些為本次試玩調校值。",box)
 growth_panel.hide();refresh_growth()
func open_growth() -> void:
 if edit_open:edit_open=false;panel.hide()
 growth_open=true;growth_panel.show();refresh_growth()
func refresh_growth() -> void:
 if not is_instance_valid(growth_summary):return
 growth_summary.text="血肉 %d・累計吸收 %d\n城牆 %d／%d・核心 %d／%d\n攻擊 ×%.2f・減傷 %d%%・每秒恢復 %.1f" % [tower.flesh,tower.total_absorbed,tower.wall_hp,tower.wall_max,tower.hp,tower.max_hp,spell_attack_multiplier(),tower.reduction()*100,tower.regeneration()]
 growth_summary.text+="\n本局詞條：靈能增幅 %d 層・額外刷新 %d 次" % [rewards.attack_stacks,rewards.extra_refresh]
 buttons.AutoGrowth.text="自動強化：開" if tower.auto_upgrade else "自動強化：關"
 var names: Dictionary={"atk":"攻擊：所有法術＋50%基礎倍率","hp":"生命：城牆上限與當前生命＋65","armor":"防禦：減傷＋14%，上限70%","regen":"回血：每秒修復＋2"}
 for key in growth_buttons:
  growth_buttons[key].text="%s　Lv %d → %d　消耗 %d 血肉" % [names[key],tower.levels[key],tower.levels[key]+1,tower.cost(key)]
  growth_buttons[key].disabled=tower.flesh<tower.cost(key) or over

func spell_attack_multiplier() -> float:
 return tower.attack_multiplier()*rewards.attack_multiplier()
func receive_reward(reward: Dictionary) -> void:
 if reward.kind in ["skill","gem"]:
  var item: Dictionary=reward.duplicate(true);item.id=chain.items.size();chain.items.append(item);chain.changed.emit()
 if rewards.pending==0:open_editor(true)
 event_label.text="已獲得："+reward_panel.description(reward).replace("\n","　")
 refresh_status()

func refresh_boss_status() -> void:
 boss_info={}
 for enemy in enemies.get_children():
  if not is_instance_valid(enemy) or enemy.dead or enemy.kind!=5:continue
  var moves: Dictionary={"crystalSpear":"裂晶槍","fracture":"地裂環","summon":"召喚虛空獸","crystalStorm":"晶暴","ultimate":"終結爆發","voidBolt":"虛空彈","rift":"裂隙","seal":"封印","starPulse":"星脈衝","gravity":"重力場","meteor":"隕星"}
  var warning: String="蓄力：%s・%.1f 秒" % [moves.get(enemy.move,"攻擊"),enemy.warning] if enemy.warning>0 else ("失衡中" if enemy.stunned>0 else "準備攻擊")
  boss_label.text="%s｜階段 %d／3｜生命 %d／%d｜%s" % [Zh.BOSS_NAMES[enemy.boss_kind],enemy.phase,enemy.hp,enemy.max_hp,warning]
  boss_health.max_value=enemy.max_hp;boss_health.value=enemy.hp;boss_health.show()
  boss_info={"hp":enemy.hp,"max_hp":enemy.max_hp,"phase":enemy.phase,"warning":enemy.warning,"move":enemy.move,"attacks":enemy.attacks}
  return
 boss_label.text="";boss_health.hide()

func spell_visual(key: String, origin: Vector2, at: Vector2) -> void:
 if fx.get_child_count()>=FX.MAX_EFFECTS:return
 var art:=Sprite2D.new();art.texture=SpellEffects.impact_texture(key);art.position=at;art.modulate.a=0.65;art.set_meta("spell_key",key);fx.add_child(art)
 var duration:=0.55
 if key=="beam":
  var length:=clampf(origin.distance_to(at)+160,120,1000)
  var axis: Vector2=(at-origin).normalized()
  if axis==Vector2.ZERO:axis=Vector2.RIGHT
  art.position=origin+axis*length*0.5;art.rotation=axis.angle()
  art.scale=Vector2(length/art.texture.get_width(),0.58);duration=0.3
 elif key=="poison":art.scale=Vector2(0.6,0.38);duration=2.5
 elif key=="meteor":art.scale=Vector2(290.0/art.texture.get_width(),145.0/art.texture.get_height())
 else:art.scale=Vector2(150.0/art.texture.get_width(),100.0/art.texture.get_height())
 var fade:=art.create_tween();fade.tween_property(art,"modulate:a",0.0,duration);fade.tween_callback(art.queue_free)

func spell_impact(at: Vector2, key: String) -> void:
 if fx.get_child_count()>=FX.MAX_EFFECTS:return
 var art:=Sprite2D.new();art.texture=SpellEffects.impact_texture(key);art.position=at;art.scale=Vector2.ONE*0.26;fx.add_child(art)
 var tween:=art.create_tween().set_parallel(true)
 tween.tween_property(art,"scale",Vector2.ONE*0.75,0.22)
 tween.tween_property(art,"modulate:a",0.0,0.22)
 tween.chain().tween_callback(art.queue_free)
