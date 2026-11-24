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
 var before: Array=game.chain.slots.duplicate();var edges: Array=game.chain.edges.duplicate(true)
 game.inventory.select_item(8)
 check(game.chain.slots==before and game.chain.edges==edges,"candidate preview does not change inventory or links")
 check(not game.inventory.apply.disabled and game.inventory.detail.text.contains("3 級"),"level-three fire upgrade can be compared before applying")
 check(game.inventory.stats(game.chain.items[8]).contains(str("%.1f" % (game.Catalog.power("fire")*2.1*1.5))),"preview uses the same level and meat power formula as direct damage")
 game.inventory.apply.pressed.emit();await process_frame
 check(game.chain.slots[2]==8 and not game.inventory.visible,"confirm equips the selected physical item and closes drawer")
 check(not game.chain.slots.has(2) and game.chain.edges==edges,"old item returns to bag while compatible links remain")
 game.inventory.open(game.chain,2,1.0);game.inventory.select_item(3)
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
 touch.pressed=false;game.inventory._input(touch)
 check(game.inventory.drag_finger== -1 and not game.inventory.dragging_items,"touch release ends inventory drag ownership")
 game.inventory.show_page(1);await process_frame
 check(game.inventory.item_scroll.scroll_vertical==0,"changing inventory pages resets item scroll to the top")
 var snapshot: Array=game.chain.slots.duplicate();game.chain.pending=[{"sentinel":true}]
 check(not game.chain.equipment_error(1,9).is_empty() and game.chain.slots==snapshot and game.chain.pending.size()==1,"validation never mutates graph or pending attacks")
 check(not game.chain.equip(1,9) and game.chain.slots==snapshot and game.chain.pending.size()==1,"rejected application preserves pending chain")
 game.queue_free();await process_frame
 print("INVENTORY_RESULT "+JSON.stringify({"checks":checks,"failures":failures}));quit(1 if failures.size() else 0)
