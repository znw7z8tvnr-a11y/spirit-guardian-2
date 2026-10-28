extends SceneTree
var checks: Array[String]=[]
var failures: Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(value: bool, message: String) -> void:
 if value:checks.append(message)
 else:failures.append(message)
func frames(n: int) -> void:
 for i in n:await physics_frame
func covered(control: Control, text: String) -> bool:
 var font: Font=control.get_theme_font("font")
 for i in text.length():
  if text.unicode_at(i)>=32 and not font.has_char(text.unicode_at(i)):return false
 return true
func run() -> void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);current_scene=game
 game.intermission=999;game.attack_clock=999
 await frames(2)
 check(TranslationServer.get_locale()=="zh_TW","game explicitly selects Traditional Chinese on any device locale")
 check(game.hud.pause_button.text=="暫停" and game.hud.buttons.Fire.text=="爆裂火球","battle HUD displays Chinese while stable button IDs remain usable")
 check(game.hud.status.text.contains("水晶生命"),"live battle counters use Chinese")
 check(game.hud.status.get_theme_font("font").get_font_name().contains("Spirit Guardian"),"embedded Traditional Chinese font is actually assigned to the UI")
 check(covered(game.hud.status,game.hud.status.text),"battle HUD glyphs are present in embedded font")
 game.toggle_pause()
 check(game.hud.pause_button.text=="繼續" and game.hud.message.text=="戰鬥已暫停","pause/resume state changes remain translated")
 game.toggle_pause()
 game.hud.audio_requested.emit()
 check(game.hud.buttons["Audio: off"].text=="音效：開","audio state is translated without changing its stable ID")
 game.hud.audio_requested.emit()
 game.open_chain()
 check(game.graph_editor.skill.get_item_text(0)=="爆裂火球" and game.graph_editor.skill.get_item_metadata(0)=="fire","translated spell dropdown preserves canonical spell IDs")
 check(game.graph_editor.gem.get_item_text(0)=="命中觸發" and game.graph_editor.gem.get_item_metadata(0)=="hit","translated gem dropdown preserves canonical gem IDs")
 var before: Dictionary=game.chain.build()
 game.graph_editor.action_buttons.Add.pressed.emit()
 var added: Dictionary=game.chain.nodes.back()
 check(added.key=="fire" and added.gem=="hit","adding from Chinese dropdown writes compatible English-ID save data")
 game.graph_editor.action_buttons.Undo.pressed.emit()
 check(game.chain.build()==before,"undo preserves original English-ID build exactly")
 game.graph_editor.action_buttons["Export JSON"].pressed.emit()
 var exported: Dictionary=JSON.parse_string(game.graph_editor.json_text.text)
 check(game.chain.restore(exported) and game.chain.build()==before and exported.nodes[0].key=="fire","export remains schema-compatible after localization")
 game.graph_editor.json_text.text='{"schema":true,"nodes":[],"edges":[]}'
 game.graph_editor.action_buttons["Import JSON"].pressed.emit()
 check(game.graph_editor.status.text.begins_with("匯入失敗") and game.chain.build()==before,"invalid import reports a Chinese error and preserves the build")
 check(covered(game.graph_editor.status,game.graph_editor.status.text),"Chinese import error contains no missing glyphs")
 var node: GraphNode=game.graph_editor.graph.get_node("1")
 check(node.title=="爆裂火球" and covered(node,node.title),"graph node titles use readable Chinese with embedded glyphs")
 check(TranslationServer.translate("Zoom In")=="放大" and TranslationServer.translate("Paste")=="貼上","built-in graph/text-edit terminology uses Chinese translations")
 game.close_chain()
 game.reward_count=1;game.progression.pity=7;game.offer_reward()
 var card=game.reward_choices.get_child(0).get_child(0)
 check(game.reward_label.text.contains("成長三選一") and game.reward_reroll.text.contains("重抽"),"reward heading and reroll count are translated")
 check(card.text.contains("傳說") and covered(card,card.text),"legendary reward card displays Chinese with all glyphs")
 game.choose_reward(0)
 game.wave=4
 var boss=game.spawn_enemy();boss.phase=2;game.refresh_hud()
 check(game.hud.boss_status.text.contains("裂晶王") and game.hud.boss_status.text.contains("第 2 階段"),"Boss name and phase use Traditional Chinese")
 check(covered(game.hud.boss_status,game.hud.boss_status.text),"Boss display has no missing glyphs")
 game.tower.take_damage(100000)
 check(game.hud.message.text.contains("守護水晶已破碎"),"defeat screen message is translated")
 var result={"engine":Engine.get_version_info().string,"checks":checks,"failures":failures}
 print("LOCALIZATION_RESULT "+JSON.stringify(result))
 paused=false
 quit(0 if failures.is_empty() else 1)
