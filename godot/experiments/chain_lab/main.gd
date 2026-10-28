extends Node2D
const Chain=preload("res://experiments/chain_lab/chain.gd")
const Enemy=preload("res://modules/enemy/enemy.gd")
const Boss=preload("res://modules/boss/boss.gd")
const Tower=preload("res://modules/tower/tower.gd")
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
var enemies: Node2D
var shots: Node2D
var tower: Node2D
var fx: Node2D
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
var panel: PanelContainer
var grid: GridContainer
var picker: OptionButton
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
 chain=Chain.new();chain.host=self;add_child(chain)
 if persist_book and FileAccess.file_exists(BOOK_PATH):
  var saved: Variant=JSON.parse_string(FileAccess.get_file_as_string(BOOK_PATH))
  if saved is Array:
   for key in saved:
    if key in Catalog.data.FINISHERS and key not in chain.discovered:chain.discovered.append(key)
 chain.cast_requested.connect(cast_spell)
 chain.resonance_requested.connect(resonate)
 chain.pulse.connect(show_pulse)
 chain.changed.connect(func():refresh_editor.call_deferred())
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
 label("靈境守衛｜連鎖戰鬥試驗室・單魔杖 10 格",top)
 status=label("",top)
 health=ProgressBar.new();health.custom_minimum_size=Vector2(280,14);health.show_percentage=false;top.add_child(health)
 label("暫用素材・試驗配置不代表正式掉落與平衡",top)
 var bottom:=VBoxContainer.new();bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE);bottom.offset_left=24;bottom.offset_right=-24;bottom.offset_top=-220;bottom.offset_bottom=-18;root_ui.add_child(bottom)
 event_label=label("開局只有奧彈；先載入試驗配置，觀察接續與分岔。",bottom)
 settings_label=label("",bottom)
 var row:=HBoxContainer.new();row.alignment=BoxContainer.ALIGNMENT_CENTER;bottom.add_child(row)
 make_button("Configure","配置／背包",row,func():open_editor())
 make_button("Kit","載入試驗配置",row,func():chain.load_kit();open_editor())
 make_button("Tempo","節奏：標準",row,cycle_tempo)
 make_button("Pause","暫停",row,func():user_paused=not user_paused;buttons.Pause.text="繼續" if user_paused else "暫停")
 make_button("Restart","重新開始",row,func():get_tree().reload_current_scene())
 panel=PanelContainer.new();panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);panel.offset_left=16;panel.offset_right=-16;panel.offset_top=16;panel.offset_bottom=-16;root_ui.add_child(panel)
 var bg:=StyleBoxFlat.new();bg.bg_color=Color("101a2c");bg.set_content_margin_all(16);panel.add_theme_stylebox_override("panel",bg)
 var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;panel.add_child(scroll)
 var box:=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(box)
 label("10 格配置｜技能 → 寶石 → 技能；三級寶石最多分兩線",box)
 var row2:=HBoxContainer.new();box.add_child(row2)
 make_button("Done","返回戰鬥",row2,func():edit_open=false;link_from=-1;panel.hide())
 make_button("Random","隨機排列",row2,func():chain.random_arrange();refresh_editor.call_deferred())
 make_button("Arrange","已知共振排列",row2,arrange_known)
 editor_status=label("",box)
 picker=OptionButton.new();picker.custom_minimum_size.y=72;box.add_child(picker)
 var row3:=HBoxContainer.new();box.add_child(row3)
 make_button("Equip","替換此格",row3,equip_selected)
 make_button("Source","設為起點",row3,func():link_from=selected;editor_status.text="已選起點 %d；點另一格，再按連到此格。" % [selected+1])
 make_button("Connect","連到此格",row3,func():
  var ok: bool=chain.connect_slots(link_from,selected)
  editor_status.text="連線完成。" if ok else "無法連線：需交替、不可循環，且普通寶石只能接一線。"
  if ok:link_from=-1
 )
 make_button("Disconnect","移除此連線",row3,func():chain.disconnect_slots(link_from,selected);link_from=-1)
 grid=GridContainer.new();grid.columns=5;box.add_child(grid)
 links=label("",box)
 book=label("",box)
 label("替換只使用本局持有物品；同一件不能重複裝備。先移除不相容連線才能換類型。試驗版不儲存戰局與配置；共振發現獨立保存。",box)
 panel.hide()
func resize_ui() -> void:
 var portrait:=get_viewport_rect().size.y>get_viewport_rect().size.x
 grid.columns=2 if portrait else 5
func name_of(item: Dictionary) -> String:
 if item.is_empty():return "空格"
 return "%s・%d 級" % [Zh.spell(str(item.key)) if item.kind=="skill" else "接續寶石",int(item.level)]
func refresh_editor() -> void:
 if not is_instance_valid(grid):return
 slot_buttons=[]
 for old in grid.get_children():grid.remove_child(old);old.queue_free()
 for i in range(10):
  var b:=Button.new();b.custom_minimum_size=Vector2(224,96);b.text="%02d　%s\n%s" % [i+1,"已選" if i==selected else "",name_of(chain.item_at(i))];grid.add_child(b)
  b.pressed.connect(func():selected=i;refresh_editor.call_deferred());slot_buttons.append(b)
 picker.clear()
 picker.add_item("清空此格");picker.set_item_metadata(0,-1)
 for item in chain.items:
  if chain.slots.has(item.id) and chain.slots[selected]!=item.id:continue
  picker.add_item("%s　%s" % [name_of(item),"已裝備" if chain.slots[selected]==item.id else "背包"])
  picker.set_item_metadata(picker.item_count-1,item.id)
  if chain.slots[selected]==item.id:picker.select(picker.item_count-1)
 editor_status.text="選取第 %d 格；背包可替換物品如下。" % [selected+1]
 var texts: Array=[]
 for e in chain.edges:texts.append("%02d → %02d" % [int(e.from)+1,int(e.to)+1])
 links.text="連線："+"　／　".join(texts)
 var found: Array=[]
 for key in chain.discovered:found.append(str(Catalog.data.FINISHERS[key][0])+"（"+str(key).replace("fire","火").replace("ice","冰").replace("lightning","雷").replace("poison","毒")+"）")
 book.text="共振紀錄書：尚未發現配方，請在戰鬥中探索。" if found.is_empty() else "共振紀錄書："+"、".join(found)
 buttons.Arrange.disabled=chain.discovered.is_empty() or not chain.kit_loaded
 buttons.Random.disabled=not chain.kit_loaded
func equip_selected() -> void:
 var ok: bool=chain.equip(selected,int(picker.get_item_metadata(picker.selected)))
 if not ok:editor_status.text="替換失敗：物品已使用、起點需技能，或現有連線不相容。"
func open_editor() -> void:
 edit_open=true;panel.show();refresh_editor.call_deferred()
func arrange_known() -> void:
 if chain.discovered.is_empty() or not chain.kit_loaded:return
 # Lab owns one known three-element kit; never reveal an unknown recipe.
 if "fire+ice+lightning" in chain.discovered:chain.load_kit()
 else:editor_status.text="此試驗配置沒有足夠物品排列已知配方。"
func cycle_tempo() -> void:
 tempo=(tempo+1)%3
 chain.hop_delay=[0.32,0.48,0.20][tempo];attack_period=[3.8,5.2,3.2][tempo];flight_time=[0.62,0.85,0.45][tempo]
 buttons.Tempo.text=["節奏：標準","節奏：慢速","節奏：快速"][tempo]
func _physics_process(delta: float) -> void:
 if over or user_paused or edit_open:return
 brain.prepare(enemies.get_children());chain.advance(delta)
 attack_clock-=delta
 if attack_clock<=0 and chain.active.is_empty():
  var enemy:=target_near(CENTER,2000)
  if enemy!=null and chain.start(enemy):attack_clock=attack_period
 if remaining>0:
  spawn_clock-=delta
  if spawn_clock<=0 and enemies.get_child_count()<40:spawn_enemy();remaining-=1;spawn_clock=1.4
 elif enemies.get_child_count()==0 and chain.active.is_empty():
  rest-=delta
  if rest<=0:
   if wave>=20:over=true;event_label.text="20 波試驗完成！";return
   wave+=1;remaining=4+mini(wave,8);rest=5.0
func _process(delta: float) -> void:
 # Keep combat actors and projectile tweens frozen while the lab editor is open.
 var frozen:=over or user_paused or edit_open
 for node in [enemies,shots,fx]:node.process_mode=Node.PROCESS_MODE_DISABLED if frozen else Node.PROCESS_MODE_INHERIT
 ui_clock-=delta
 if ui_clock<=0:ui_clock=0.2;refresh_status()
 if web_debug:
  debug_clock-=delta
  if debug_clock<=0:debug_clock=0.2;publish_debug()
func spawn_enemy() -> Node2D:
 var is_boss:=wave%5==0 and remaining==4+mini(wave,8)
 var e: Node2D=Boss.new() if is_boss else Enemy.new()
 if is_boss:e.boss_kind=(int(wave/5)-1)%3
 else:e.kind=[0,0,1,2,4][(wave+remaining)%5]
 e.entity_id=next_id;next_id+=1;e.brain=brain;e.resolver=resolver
 var angle:=rng.randf_range(0,TAU);e.position=CENTER+Vector2(cos(angle)*820,sin(angle)*410);e.target=CENTER
 e.max_hp=([28.0,20.0,60.0,38.0,95.0,300.0][e.kind]+wave*(25 if is_boss else 3));e.hp=e.max_hp
 e.speed=[22.0,34.0,16.0,20.0,23.0,15.0][e.kind]+wave*0.35;e.damage=1.5+wave*0.18
 e.attacked.connect(func(amount: float):tower.take_damage(amount))
 e.died.connect(func(_enemy: Node2D):kills+=1)
 enemies.add_child(e);return e
func target_near(at: Vector2, radius: float) -> Node2D:
 var best: Node2D=null;var distance:=radius*radius
 for e in enemies.get_children():
  if not is_instance_valid(e) or e.dead:continue
  var d: float=e.position.distance_squared_to(at)
  if d<=distance:distance=d;best=e
 return best
func cast_spell(slot: int, item: Dictionary, target: Node2D, run: Dictionary) -> void:
 if not chain.current(run):return
 var shot:=Sprite2D.new();shot.texture=Projectile.TEXTURES[str(item.key)];shot.scale=Vector2.ONE*0.20
 shot.position=run.get("last_at",CENTER+Vector2(0,-65));shots.add_child(shot)
 var at: Vector2=target.position
 var tween:=shot.create_tween()
 var lift: Vector2=(shot.position+at)*0.5+Vector2(0,-90)
 tween.tween_property(shot,"position",lift,flight_time*0.5).set_trans(Tween.TRANS_SINE)
 tween.tween_property(shot,"position",at,flight_time*0.5).set_trans(Tween.TRANS_SINE)
 tween.tween_callback(func():
  if not chain.current(run):shot.queue_free();return
  var victim: Node2D=target
  if not is_instance_valid(victim) or victim.dead:
   victim=target_near(at,chain.retarget_radius)
   if victim!=null:chain.retargets+=1
  if victim==null:
   run.inflight-=1;chain.finish_if_idle();shot.queue_free();return
  var key: String=item.key
  var result: Dictionary=resolver.resolve(victim,Catalog.power(key)*(1+0.55*(int(item.level)-1)),Catalog.element(key),{"critical":false})
  fx.impact(victim.position,StringName(key))
  if key in ["fire","lightning"]:
   var count:=0
   for other in enemies.get_children():
    if other!=victim and not other.dead and other.position.distance_to(victim.position)<150:
     resolver.resolve(other,Catalog.power(key)*0.45,Catalog.element(key),{"critical":false});count+=1
     if count>=2:break
  chain.complete_skill(slot,victim,result,run)
  shot.queue_free()
 )
func show_pulse(slot: int, _message: String) -> void:
 var item: Dictionary=chain.item_at(slot)
 trail.append("%02d %s" % [slot+1,name_of(item)])
 if trail.size()>5:trail.pop_front()
 event_label.text=" → ".join(trail)
 if slot<slot_buttons.size():
  slot_buttons[slot].modulate=Color("ffe4a0")
func resonate(recipe: String, target: Node2D) -> void:
 var at: Vector2=target.position if is_instance_valid(target) else CENTER
 event_label.text="共振發現："+str(Catalog.data.FINISHERS[recipe][0])
 fx.impact(at,&"arcane");fx.impact(at,&"lightning")
 for e in enemies.get_children():
  if not e.dead and e.position.distance_to(at)<240:resolver.resolve(e,45.0,"arcane",{"critical":false})
 if persist_book:
  var file:=FileAccess.open(BOOK_PATH,FileAccess.WRITE)
  if file!=null:file.store_string(JSON.stringify(chain.discovered))
 refresh_editor.call_deferred()
func refresh_status() -> void:
 if not is_instance_valid(status):return
 status.text="第 %d／20 波　擊殺 %d　水晶 %d／100　共振 %d　轉移 %d" % [wave,kills,tower.hp,chain.resonances,chain.retargets]
 health.value=tower.hp
 settings_label.text="每輪至少 %.1f 秒・每段 %.2f 秒・共振冷卻 %.0f 秒・%d FPS" % [attack_period,chain.hop_delay,chain.resonance_cooldown,Engine.get_frames_per_second()]
func publish_debug() -> void:
 var bounds: Dictionary={}
 for key in buttons:
  var rect: Rect2=buttons[key].get_global_rect();bounds[key]=[rect.get_center().x,rect.get_center().y,rect.size.x,rect.size.y]
 for i in slot_buttons.size():
  var rect: Rect2=slot_buttons[i].get_global_rect();bounds["Slot %d" % i]=[rect.get_center().x,rect.get_center().y,rect.size.x,rect.size.y]
 JavaScriptBridge.eval("window.SG_LAB_STATE="+JSON.stringify({"wave":wave,"hp":tower.hp,"kills":kills,"enemies":enemies.get_child_count(),"casts":chain.casts,"retargets":chain.retargets,"resonances":chain.resonances,"rolls":chain.rolls,"slots":chain.slots,"edges":chain.edges,"kit":chain.kit_loaded,"edit_open":edit_open,"paused":user_paused,"tempo":tempo,"selected":selected,"buttons":bounds,"viewport":[get_viewport_rect().size.x,get_viewport_rect().size.y],"capacity":10,"discovered":chain.discovered,"arrange_disabled":buttons.Arrange.disabled}))
