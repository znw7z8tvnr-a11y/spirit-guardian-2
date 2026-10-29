extends SceneTree
var checks: Array=[]
var failures: Array=[]
func check(ok: bool,message: String) -> void:
 if ok:checks.append(message)
 else:failures.append(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var game=load("res://experiments/chain_lab/main.tscn").instantiate();game.persist_book=false;root.add_child(game);current_scene=game
 game.set_physics_process(false);game.chain.load_kit();await process_frame
 game.selected=2;game.inventory.open(game.chain,2,1.5)
 check(game.inventory.cards.size()==13,"all ten physical items plus clear and two actions are visible")
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
 var snapshot: Array=game.chain.slots.duplicate();game.chain.pending=[{"sentinel":true}]
 check(not game.chain.equipment_error(1,9).is_empty() and game.chain.slots==snapshot and game.chain.pending.size()==1,"validation never mutates graph or pending attacks")
 check(not game.chain.equip(1,9) and game.chain.slots==snapshot and game.chain.pending.size()==1,"rejected application preserves pending chain")
 game.queue_free();await process_frame
 print("INVENTORY_RESULT "+JSON.stringify({"checks":checks,"failures":failures}));quit(1 if failures.size() else 0)
