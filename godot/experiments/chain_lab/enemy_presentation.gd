extends Control
## Presentation only: no combat timer, targeting or damage mutation.
const LIMIT:=6
const BOX:=Vector2(240,48)
const GAP:=6.0
var labels: Array[Label]=[]
var placed: Array=[]
var refreshes:=0
var text_writes:=0
var trials:=0
var hidden_count:=0
var scanned:=0
static func seconds(value: float) -> String:return "%.1f" % (ceilf(maxf(value,0.001)*10.0)/10.0)
static func threats(actors: Array) -> Array:
 var rows: Array=[]
 for e in actors:
  if not is_instance_valid(e) or e.dead or not ("ranged_warning" in e):continue
  if e.ranged_warning>0:rows.append({"id":e.entity_id,"key":"靈彈","left":e.ranged_warning,"actor":e})
  if e.telegraph>0:rows.append({"id":e.entity_id,"key":str(e.tactic_name).trim_suffix("蓄力"),"left":e.telegraph,"actor":e})
 rows.sort_custom(func(a,b):return a.left<b.left if not is_equal_approx(a.left,b.left) else a.id<b.id)
 return rows
static func summary(actors: Array) -> String:
 var groups: Dictionary={};var order: Array=[]
 for row in threats(actors):
  if not groups.has(row.key):groups[row.key]={"count":0,"left":row.left};order.append(row.key)
  groups[row.key].count+=1
 if "靈彈" in order:order.erase("靈彈");order.push_front("靈彈")
 var parts: Array=[]
 for key in order.slice(0,3):parts.append("%s ×%d（%s 秒）" % [key,groups[key].count,seconds(groups[key].left)])
 var remaining:=0
 for key in order.slice(3):remaining+=int(groups[key].count)
 if remaining>0:parts.append("另 %d 項蓄力" % remaining)
 return "敵情："+("／".join(parts) if not parts.is_empty() else "警戒中")
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 for i in LIMIT:
  var l:=Label.new();l.mouse_filter=Control.MOUSE_FILTER_IGNORE;l.add_theme_font_size_override("font_size",24);l.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
  var bg:=StyleBoxFlat.new();bg.bg_color=Color(0.035,0.055,0.1,0.92);bg.set_content_margin_all(5);l.add_theme_stylebox_override("normal",bg);add_child(l);labels.append(l);l.hide()
func update_actors(actors: Array,safe: Rect2) -> void:
 refreshes+=1;trials=0;scanned=actors.size();placed=[]
 for l in labels:l.hide()
 var urgent:=threats(actors);var candidates: Array=[];var listed: Array=[]
 for row in urgent:
  if row.id not in listed:candidates.append(row);listed.append(row.id)
 for e in actors:
  if not is_instance_valid(e) or e.dead or not ("ranged_warning" in e) or e.kind not in [2,3,4]:continue
  if urgent.any(func(row):return row.id==e.entity_id):continue
  candidates.append({"id":e.entity_id,"key":"","left":0.0,"actor":e})
 hidden_count=candidates.size()
 if safe.size.x<BOX.x or safe.size.y<BOX.y:queue_redraw();return
 var groups_shown: Dictionary={}
 for row in candidates:
  if placed.size()>=LIMIT:break
  var e: Node2D=row.actor
  var group: String=row.key if not row.key.is_empty() else "idle_%d" % e.kind
  if int(groups_shown.get(group,0))>=(2 if not row.key.is_empty() else 1):continue
  var at: Vector2=e.get_global_transform_with_canvas().origin
  if not safe.has_point(at):continue
  var role: String={2:"護甲",3:"薩滿",4:"精英"}.get(e.kind,"敵人")
  var text: String=role+("｜%s %s 秒" % [row.key,seconds(row.left)] if not row.key.is_empty() else "")
  var found:=false
  for dy in [-80.0,-140.0,-200.0]:
   for dx in [0.0,-250.0,250.0]:
    trials+=1
    var point:=at+Vector2(dx-BOX.x*0.5,dy)
    point.x=clampf(point.x,safe.position.x,safe.end.x-BOX.x);point.y=clampf(point.y,safe.position.y,safe.end.y-BOX.y)
    var rect:=Rect2(point,BOX)
    if placed.any(func(p):return p.rect.grow(GAP).intersects(rect)):continue
    var l:=labels[placed.size()]
    if l.text!=text:l.text=text;text_writes+=1
    l.position=point;l.size=BOX;l.modulate=Color("ffe2a1") if not row.key.is_empty() else Color("b8cadf");l.show()
    placed.append({"id":row.id,"key":row.key,"rect":rect,"anchor":at,"urgent":not row.key.is_empty()});groups_shown[group]=int(groups_shown.get(group,0))+1;hidden_count-=1;found=true;break
   if found:break
 queue_redraw()
func _draw() -> void:
 for row in placed:draw_line(row.anchor+Vector2(0,-20),Vector2(row.rect.get_center().x,row.rect.end.y),Color(0.65,0.75,0.9,0.55),1.0,true)
func snapshot() -> Dictionary:
 return {"shown":visible,"allocated":labels.size(),"visible":placed.size(),"hidden":hidden_count,"trials":trials,"scanned":scanned,"refreshes":refreshes,"text_writes":text_writes,"rects":placed.map(func(p):return {"id":p.id,"key":p.key,"rect":[p.rect.position.x,p.rect.position.y,p.rect.size.x,p.rect.size.y],"urgent":p.urgent})}
