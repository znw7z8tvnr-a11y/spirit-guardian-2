extends SceneTree
const Filter=preload("res://experiments/chain_lab/inventory_filter.gd")
var checks: Array=[]
var failures: Array=[]
var emitted:=0
class CountedModel extends Node:
 var source: Node
 var validations:=0
 var items: Array:
  get:return source.items
 var slots: Array:
  get:return source.slots
 func equipment_error(slot: int,id: int) -> String:
  validations+=1
  return source.equipment_error(slot,id)
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 if ok:checks.append(message)
 else:failures.append(message)
func run() -> void:
 var game=load("res://experiments/chain_lab/main.tscn").instantiate();game.persist_book=false;game.persist_run=false;root.add_child(game);current_scene=game;game.set_process(false);game.set_physics_process(false)
 var view=game.inventory;var chain=game.chain
 view.apply_requested.connect(func(_id):emitted+=1)
 view.open(chain,0,1.0)
 check(view.filtered_ids==[-1,0] and Filter.counts(chain,0)=={"all":1,"skill":1,"gem":0,"available":0},"normal arcane-only start has no invented inventory or compatible replacements")
 check(view.filters.size()==4 and view.filter_mode=="all","drawer opens in the established all-items order with four filter controls")
 view.set_filter("gem")
 check(view.filtered_ids.is_empty() and view.empty_notice.visible and view.page_label.text=="0／0 頁" and view.apply.disabled,"empty gem filter displays an explicit empty state and disables confirmation")
 check(view.cards.InventoryNext.disabled and view.cards.InventoryPrev.disabled,"empty results cannot turn pages")
 view.select_item(0);view.apply.pressed.emit()
 check(view.candidate== -2 and chain.slots[0]==0 and emitted==0,"hidden card or stale confirm cannot equip an invisible item")
 check(not view.set_filter("unknown") and view.filter_mode=="gem","unknown filter is rejected without changing the current view")
 check(Filter.ids(chain,-1,"all").is_empty() and Filter.ids(chain,10,"available").is_empty(),"invalid slots do not return misleading available items")
 chain.load_spell_kit();view.open(chain,0,1.0)
 var owned: Array=chain.items.duplicate(true);var slots: Array=chain.slots.duplicate();var edges: Array=chain.edges.duplicate(true);var rng_state: int=chain.rng.state
 var skills: Array=chain.items.filter(func(i):return i.kind=="skill").map(func(i):return int(i.id))
 var gems: Array=chain.items.filter(func(i):return i.kind=="gem").map(func(i):return int(i.id))
 check(Filter.counts(chain,0).all==32 and skills.size()+gems.size()==32,"counts use physical copies, including duplicate spell names and levels")
 var expected_counts: Dictionary={}
 for mode in Filter.MODES:expected_counts[mode]=Filter.ids(chain,0,mode).size()-(1 if mode=="all" else 0)
 for mode in Filter.MODES:
  var scanned: Dictionary=Filter.snapshot(chain,0,mode)
  check(scanned.ids==Filter.ids(chain,0,mode) and scanned.counts==expected_counts,"single-pass snapshot preserves ordered IDs and all counts for "+mode)
 var counted:=CountedModel.new();counted.source=chain;root.add_child(counted)
 var once: Dictionary=Filter.snapshot(counted,0,"available")
 check(counted.validations==chain.items.size()-1 and once.ids==Filter.ids(chain,0,"available"),"available snapshot validates each non-current physical item exactly once")
 counted.queue_free()
 check(Filter.counts(chain,-1)=={"all":0,"skill":0,"gem":0,"available":0} and Filter.snapshot(chain,10,"all").ids.is_empty(),"invalid slot returns zero counts rather than negative all-items count")
 check(Filter.counts(null,0)=={"all":0,"skill":0,"gem":0,"available":0} and Filter.ids(null,0,"all").is_empty(),"missing model returns empty results without dereferencing it")
 var isolated: Dictionary=Filter.snapshot(chain,0,"all");isolated.ids.append(999)
 check(Filter.snapshot(chain,0,"all").ids==range(-1,32) and chain.items==owned and chain.slots==slots and chain.edges==edges and chain.rng.state==rng_state,"snapshot output cannot mutate ownership, graph, RNG or later results")
 view.set_filter("skill")
 check(view.filtered_ids==skills and view.filtered_ids.size()>15 and not view.filtered_ids.has(-1),"skill filter preserves acquisition order and excludes gems and the clear action")
 view.show_page(999)
 var visible: Array=[]
 for id in range(-1,chain.items.size()):
  if view.cards["Item %d" % id].visible:visible.append(id)
 check(visible==skills.slice(15,30) and view.page==1 and view.cards.InventoryNext.disabled,"filtered pagination shows the actual skill IDs on its last page")
 view.select_item(skills[-1])
 check(not view.apply.disabled,"visible replacement on last page enables confirmation")
 view.show_page(0)
 check(view.candidate== -2 and view.apply.disabled,"paging away cancels an off-page preview and disables confirmation")
 view.confirm_candidate();view.select_item(skills[-1]);view.confirm_candidate()
 check(emitted==0 and chain.slots==slots,"off-page stale selection and direct confirmation cannot equip a hidden item")
 view.show_page(1);view.select_item(skills[-1])
 check(view.candidate==skills[-1] and not view.apply.disabled,"returning to the page allows an explicit fresh selection")
 view.set_filter("all")
 check(view.candidate==skills[-1] and view.page==int((skills[-1]+1)/15) and view.cards["Item %d" % view.candidate].visible,"retained preview is brought into view when switching filters")
 view.set_filter("gem")
 check(view.filtered_ids==gems and view.candidate== -2 and view.apply.disabled,"switching away from the preview type clears it without clearing equipment")
 check(view.filters.gem.button_pressed and not view.filters.skill.button_pressed,"active filter is explicit without relying only on card colour")
 view.set_filter("available")
 check(not view.filtered_ids.has(0) and view.filtered_ids.all(func(id):return chain.items[id].kind=="skill" and chain.slots.find(id)== -1),"root-compatible list excludes gems, currently equipped and other-slot physical copies")
 check(chain.items==owned and chain.slots==slots and chain.edges==edges and chain.rng.state==rng_state,"browsing and pagination do not mutate inventory, graph or RNG")
 view.open(chain,0,1.0)
 check(view.filter_mode=="all" and view.page==0 and view.filtered_ids==range(-1,32),"reopening resets to the original all-items first-page contract")
 view.select_item(8);chain.equip(9,8);view.apply.pressed.emit()
 check(emitted==0 and chain.slots[0]==0 and view.apply.disabled,"confirm revalidates ownership if a candidate became equipped elsewhere")
 chain.equip(9,-1);view.set_filter("available");view.select_item(8);view.apply.pressed.emit()
 check(emitted==1 and chain.slots[0]==8 and not view.visible and chain.items==owned,"real confirm equips one owned physical item, consumes nothing, and closes drawer")
 check(chain.edges==edges and not chain.slots.has(0),"compatible links survive and replaced arcane returns to inventory")
 view.open(chain,0,1.0);view.set_filter("available")
 check(view.filtered_ids.has(0) and not view.filtered_ids.has(8),"availability follows the returned item and new current root after reopening")
 chain.load_kit();chain.items.append({"id":chain.items.size(),"kind":"gem","key":"relay","level":3});view.open(chain,1,1.0);view.set_filter("available")
 check(not view.filtered_ids.has(9) and view.filtered_ids.has(32),"fork compatibility excludes a lower gem but allows a distinct owned tier-three relay")
 view.set_filter("all");view.select_item(-1)
 check(view.apply.disabled,"clear card still obeys occupied-link restrictions")
 view.open(chain,9,1.0);view.select_item(8);view.apply.pressed.emit();view.open(chain,9,1.0);view.select_item(-1);view.apply.pressed.emit()
 check(chain.slots[9]== -1 and chain.items.size()==33,"clear action remains available in all-items and returns the same physical item")
 game.queue_free();await process_frame
 print("INVENTORYFILTERS_RESULT "+JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
