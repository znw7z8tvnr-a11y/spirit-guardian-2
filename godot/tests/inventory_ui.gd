extends SceneTree
var checks: Array=[]
var failures: Array=[]
func check(ok: bool,message: String) -> void:
 if ok:checks.append(message)
 else:failures.append(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var game=load("res://experiments/chain_lab/main.tscn").instantiate();game.persist_book=false;game.persist_run=false;game.criticals_enabled=false;root.add_child(game);current_scene=game
 game.set_physics_process(false);game.chain.load_kit();await process_frame
 game.selected=2;game.inventory.open(game.chain,2,1.5)
 check(game.inventory.cards.size()==15,"all ten physical items plus clear, two actions and two page controls are visible")
 var card_ids: Array=game.inventory.entries.get_children().map(func(card):return card.get_instance_id())
 var icon_ids: Array=game.inventory.entries.get_children().map(func(card):return card.get_children().map(func(icon):return icon.get_instance_id()))
 for repetition in range(20):game.inventory.open(game.chain,2,1.5)
 check(game.inventory.entries.get_children().map(func(card):return card.get_instance_id())==card_ids and game.inventory.entries.get_children().map(func(card):return card.get_children().map(func(icon):return icon.get_instance_id()))==icon_ids,"reopening reuses physical buttons and icon nodes")
 check(game.inventory.cards["Item 8"].get_signal_connection_list("pressed").size()==1,"reopening never duplicates card callbacks")
 game.inventory.open(game.chain,0,1.0)
 check("目前此格" in game.inventory.cards["Item 0"].text and "第 3 格使用中" in game.inventory.cards["Item 2"].text,"reused cards reflect the newly edited slot")
 game.inventory.open(game.chain,2,1.5)
 var before: Array=game.chain.slots.duplicate();var edges: Array=game.chain.edges.duplicate(true)
 game.inventory.select_item(8)
 check(game.chain.slots==before and game.chain.edges==edges,"candidate preview does not change inventory or links")
 check(not game.inventory.apply.disabled and game.inventory.detail.text.contains("3 級"),"level-three fire upgrade can be compared before applying")
 check(game.inventory.stats(game.chain.items[8]).contains(str("%.1f" % (game.Catalog.power("fire")*2.1*1.5))),"preview uses the same level and meat power formula as direct damage")
 game.inventory.apply.pressed.emit();await process_frame
 check(game.chain.slots[2]==8 and not game.inventory.visible,"confirm equips the selected physical item and closes drawer")
 check(not game.chain.slots.has(2) and game.chain.edges==edges,"old item returns to bag while compatible links remain")
 game.inventory.open(game.chain,2,1.0)
 check("目前此格" in game.inventory.cards["Item 8"].text and "背包可用" in game.inventory.cards["Item 2"].text and game.inventory.entries.get_children().map(func(card):return card.get_instance_id())==card_ids,"equipment changes update ownership without rebuilding the bag")
 game.inventory.select_item(3)
 check(game.inventory.apply.disabled and game.inventory.detail.text.contains("不能重複"),"an item equipped elsewhere is viewable but cannot be duplicated")
 game.inventory.open(game.chain,1,1.0);game.inventory.select_item(9)
 check(game.inventory.apply.disabled and game.inventory.detail.text.contains("分岔"),"lower gem cannot silently remove an existing fork")
 game.inventory.open(game.chain,0,1.0);game.inventory.select_item(-1)
 check(game.inventory.apply.disabled,"root skill cannot be cleared")
 game.inventory.open(game.chain,8,1.0);game.inventory.select_item(2)
 check(not game.inventory.apply.disabled,"returned item can be selected for an empty slot")
 game.inventory.cards.InventoryClose.pressed.emit();check(game.chain.slots[8]==-1,"closing preview cancels without consuming the item")
 check(game.inventory.candidate== -2 and game.inventory.apply.disabled,"closing the drawer clears the candidate and disables confirmation")
 game.inventory.confirm_candidate();game.inventory.apply.pressed.emit()
 check(game.chain.slots[8]==-1,"late confirmation after closing cannot equip the cancelled candidate")
 game.inventory.open(game.chain,8,1.0)
 check(game.inventory.candidate== -1 and game.inventory.apply.disabled,"reopening previews the actual empty slot rather than the cancelled item")
 game.inventory.select_item(2);game.inventory.hide();game.inventory.confirm_candidate()
 check(game.chain.slots[8]==-1 and game.inventory.candidate== -2,"programmatic hide also cancels preview and rejects a stale confirm")
 game.chain.load_spell_kit();game.inventory.open(game.chain,0,1.0)
 game.inventory.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT);game.inventory.size=Vector2(1180,660)
 await process_frame;await process_frame
 var confirm_before: Vector2=game.inventory.apply.global_position
 var close_before: Vector2=game.inventory.cards.InventoryClose.global_position
 var card_before: Vector2=game.inventory.cards["Item 0"].global_position
 game.inventory.item_scroll.scroll_vertical=150
 await process_frame
 check(game.inventory.item_scroll.scroll_vertical>0,"short drawer scrolls only its overflowing item grid")
 check(game.inventory.apply.global_position==confirm_before and game.inventory.cards.InventoryClose.global_position==close_before,"return and confirmation remain fixed while inventory items scroll")
 check(game.inventory.cards["Item 0"].global_position.y<card_before.y,"item cards actually move inside the scroll region")
 game.inventory.item_scroll.scroll_vertical=0
 var touch:=InputEventScreenTouch.new();touch.index=0;touch.pressed=true;touch.position=game.inventory.item_scroll.get_global_rect().get_center();game.inventory._input(touch)
 var drag:=InputEventScreenDrag.new();drag.index=1;drag.position=touch.position+Vector2(0,-70);drag.relative=Vector2(0,-70);game.inventory._input(drag)
 check(game.inventory.item_scroll.scroll_vertical==0,"a second finger cannot take over the active inventory drag")
 drag.index=0;drag.position=touch.position+Vector2(0,-5);drag.relative=Vector2(0,-5);game.inventory._input(drag)
 check(not game.inventory.dragging_items and game.inventory.item_scroll.scroll_vertical==0,"small touch movement remains a tap without scrolling")
 drag.position=touch.position+Vector2(0,-70);drag.relative=Vector2(0,-65);game.inventory._input(drag)
 check(game.inventory.dragging_items and game.inventory.item_scroll.scroll_vertical>0,"vertical touch drag moves overflowing items after the deadzone")
 var stopped_scroll: int=game.inventory.item_scroll.scroll_vertical;var preview_before: int=game.inventory.candidate;var slots_before_focus: Array=game.chain.slots.duplicate()
 game.inventory.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
 check(game.inventory.drag_finger== -1 and not game.inventory.dragging_items and game.inventory.candidate==preview_before and game.chain.slots==slots_before_focus and game.inventory.item_scroll.scroll_vertical==stopped_scroll,"focus loss cancels inventory gesture while preserving preview, equipment and scroll")
 game.inventory._input(drag)
 check(game.inventory.item_scroll.scroll_vertical==stopped_scroll,"old inventory finger cannot continue after focus loss")
 game.inventory.item_scroll.scroll_vertical=0;touch.index=3;touch.pressed=true;touch.position=game.inventory.item_scroll.get_global_rect().get_center();game.inventory._input(touch)
 drag.index=3;drag.position=touch.position+Vector2(0,-70);drag.relative=Vector2(0,-70);game.inventory._input(drag)
 check(game.inventory.dragging_items and game.inventory.item_scroll.scroll_vertical>0,"a fresh inventory finger works after an interrupted gesture")
 touch.pressed=false;game.inventory._input(touch)
 check(game.inventory.drag_finger== -1 and not game.inventory.dragging_items,"touch release ends inventory drag ownership")
 var app_cancelled:=true
 for notification in [Node.NOTIFICATION_APPLICATION_FOCUS_OUT,Node.NOTIFICATION_APPLICATION_PAUSED]:
  touch.pressed=true;game.inventory._input(touch);game.inventory._input(drag)
  app_cancelled=app_cancelled and game.inventory.dragging_items
  game.inventory.notification(notification)
  app_cancelled=app_cancelled and game.inventory.drag_finger== -1 and not game.inventory.dragging_items
 check(app_cancelled,"application focus loss and pause both cancel restarted inventory gestures")
 game.inventory.show_page(1);await process_frame
 check(game.inventory.item_scroll.scroll_vertical==0,"changing inventory pages resets item scroll to the top")
 var existing_cards: Array=game.inventory.entries.get_children().map(func(card):return card.get_instance_id())
 var added_id: int=game.chain.items.size();game.chain.items.append({"id":added_id,"kind":"gem","key":"relay","level":3});game.inventory.open(game.chain,0,1.0)
 check(game.inventory.entries.get_children().map(func(card):return card.get_instance_id()).slice(0,existing_cards.size())==existing_cards and game.inventory.entries.get_child_count()==existing_cards.size()+1,"new loot adds one card and retains all existing cards")
 var added: Button=game.inventory.cards["Item %d" % added_id];var art: TextureRect=added.get_child(0);var gem_texture: Texture2D=art.texture
 game.chain.items[added_id]={"id":added_id,"kind":"skill","key":"fire","level":2};game.inventory.open(game.chain,0,1.0)
 check(game.inventory.cards["Item %d" % added_id]==added and added.get_child(0)==art and art.texture!=gem_texture and art.modulate==Color.WHITE and "2 級" in added.text,"reused card updates type, texture, tint and level")
 game.chain.items.pop_back();game.inventory.open(game.chain,0,1.0);added.pressed.emit()
 check(not game.inventory.cards.has("Item %d" % added_id) and game.inventory.entries.get_child_count()==existing_cards.size() and game.inventory.candidate==0,"removed loot releases its card and stale input cannot select it")
 var snapshot: Array=game.chain.slots.duplicate();game.chain.pending=[{"sentinel":true}]
 check(not game.chain.equipment_error(1,9).is_empty() and game.chain.slots==snapshot and game.chain.pending.size()==1,"validation never mutates graph or pending attacks")
 check(not game.chain.equip(1,9) and game.chain.slots==snapshot and game.chain.pending.size()==1,"rejected application preserves pending chain")
 game.queue_free();await process_frame
 print("INVENTORY_RESULT "+JSON.stringify({"checks":checks,"failures":failures}));quit(1 if failures.size() else 0)
