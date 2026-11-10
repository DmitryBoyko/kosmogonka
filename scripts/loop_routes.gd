extends Node3D
## Optional helical loops. Distance along the branch is independent of main-road s.
const Course=preload("res://scripts/course.gd")
const G=preload("res://scripts/geometry.gd")
const Stars=preload("res://scripts/collectible_star.gd")
const B=preload("res://scripts/booster_catalog.gd")
const SAMPLES:=160
const Layout=preload("res://scripts/loop_layout.gd")
const SPAN:=55.
static var mesh_cache:Dictionary={}
static var arc_cache:Dictionary={}
var routes:Array[Dictionary]=[]
var active:Dictionary={}
var travelled:=0.
var seed_value:=0
var extra_metres:=0.

static func point(kind:String,u:float) -> Vector3:
	u=clampf(u,0,1)
	var is_board:bool=Layout.board(kind);var turns:int=Layout.turns(kind)
	var side:float=1. if is_board else -1.
	if u<.2:
		var t:=u/.2
		if kind=="spiral":return Vector3(0,0,-12.*t)
		return Vector3(side*5.*smoothstep(0.,1.,t),4.*smoothstep(0.,1.,t) if is_board else 0.,-12.*t)
	if u>.8:
		var t:=(u-.8)/.2
		if kind=="spiral":return Vector3(0,0,lerpf(-24.,-SPAN,t))
		return Vector3(side*(5. if is_board else 5.+4.*turns)*(1.-smoothstep(0.,1.,t)),(4.+8.*turns)*(1.-smoothstep(0.,1.,t)) if is_board else 0.,lerpf(-12.,-SPAN,t))
	var t:=(u-.2)/.6
	var angle:=t*TAU*turns
	if kind=="spiral":return Vector3(9.*sin(angle),9.*(1.-cos(angle)),-12.-12.*t)
	if not is_board:return Vector3(side*(5.+4.*turns*t),11.*(1.-cos(angle)),-12.-11.*sin(angle))
	return Vector3(side*(5.+11.*(1.-cos(angle))),4.+8.*turns*t,-12.-11.*sin(angle))

static func frame(kind:String,u:float) -> Dictionary:
	var forward:Vector3=(point(kind,minf(1.,u+.0005))-point(kind,maxf(0.,u-.0005))).normalized()
	var up:=Vector3.UP
	if u>=.2 and u<=.8:
		var t:=(u-.2)/.6
		if kind=="spiral":up=Vector3(-sin(t*TAU),cos(t*TAU),0)
		elif not Layout.board(kind):up=Vector3(0,cos(t*TAU*Layout.turns(kind)),sin(t*TAU*Layout.turns(kind)))
		else: up=up.rotated(forward,-sin(t*PI)*1.05)
	up=(up-forward*up.dot(forward)).normalized()
	return {"position":point(kind,u),"forward":forward,"up":up,"right":forward.cross(up).normalized()}

static func arcs(kind:String) -> PackedFloat32Array:
	if arc_cache.has(kind): return arc_cache[kind]
	var values:=PackedFloat32Array([0.])
	for i in range(1,SAMPLES+1): values.append(values[-1]+point(kind,i/float(SAMPLES)).distance_to(point(kind,(i-1)/float(SAMPLES))))
	arc_cache[kind]=values
	return values

static func parameter(kind:String,metres:float) -> float:
	var values:=arcs(kind)
	var index:=clampi(values.bsearch(metres),1,SAMPLES)
	return (index-1+clampf((metres-values[index-1])/maxf(.001,values[index]-values[index-1]),0,1))/float(SAMPLES)

static func quad(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,d:Vector3,normal:Vector3,v0:float,v1:float) -> void:
	var points:=[a,b,c,a,c,d]
	var uvs:=[Vector2(0,v0),Vector2(0,v1),Vector2(1,v1),Vector2(0,v0),Vector2(1,v1),Vector2(1,v0)]
	for i in 6: st.set_normal(normal); st.set_uv(uvs[i]); st.add_vertex(points[i])

static func ribbon(kind:String,edge:bool) -> ArrayMesh:
	var key:=kind+str(edge)
	if mesh_cache.has(key): return mesh_cache[key]
	var st:=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var values:=arcs(kind)
	for i in SAMPLES:
		var a:=frame(kind,i/float(SAMPLES)); var b:=frame(kind,(i+1)/float(SAMPLES))
		var pa:Vector3=a.position; var pb:Vector3=b.position
		if edge:
			for side in [-1.,1.]:
				quad(st,pa+a.right*(side*1.10-.045)+a.up*.055,pb+b.right*(side*1.10-.045)+b.up*.055,pb+b.right*(side*1.10+.045)+b.up*.055,pa+a.right*(side*1.10+.045)+a.up*.055,a.up,values[i]/6.,values[i+1]/6.)
		else:
			quad(st,pa-a.right*1.15,pb-b.right*1.15,pb+b.right*1.15,pa+a.right*1.15,a.up,values[i]/6.,values[i+1]/6.)
			quad(st,pa+a.right*1.15-a.up*.18,pb+b.right*1.15-b.up*.18,pb-b.right*1.15-b.up*.18,pa-a.right*1.15-a.up*.18,-a.up,values[i]/6.,values[i+1]/6.)
			for side in [-1.,1.]:
				quad(st,pa+a.right*side*1.15-a.up*.18,pb+b.right*side*1.15-b.up*.18,pb+b.right*side*1.15,pa+a.right*side*1.15,a.right*side,0,1)
	var mesh:=st.commit(); mesh_cache[key]=mesh
	return mesh

func setup(world:int,layout_seed:int) -> void:
	for child in get_children(): get_node("/root/SceneDisposal").retire(child)
	routes.clear(); active={}; travelled=0.; extra_metres=0.; seed_value=layout_seed+world*271
	for kind:String in preload("res://scripts/loop_layout.gd").kinds(world):
		var route:Dictionary={"kind":kind,"start":Layout.start(kind),"lane":2 if Layout.board(kind) else 0,"taken":false,"passed":false,"rewards":[],"u":0.,"visit_reward":0}
		route.booster="board" if Layout.board(kind) else "jet"
		if kind=="spiral":route.lane=1
		var body:=Node3D.new(); add_child(body); body.name="VerticalLoop" if kind=="jet" else "SideLoop" if kind=="board" else "SpiralLoop"; route.node=body
		body.position=Vector3((route.lane-1)*2.6,0,-route.start); body.hide()
		var deck:=G.part(body,ribbon(kind,false),Vector3.ZERO,preload("res://scripts/surface_style.gd").road(world,1))
		var core:=preload("res://scripts/loop_core.gd").new();body.add_child(core);core.name="EnergyCore";core.build(world)
		core.position=Vector3(0,9.,-18.) if kind=="spiral" else Vector3(16.,8.+(Layout.turns(kind)-1)*4.,-12.) if Layout.board(kind) else Vector3(-7.,11.,-12.)
		deck.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		G.part(body,ribbon(kind,true),Vector3.ZERO,preload("res://scripts/surface_style.gd").edge(world)).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var sign:=G.label(body,("ЭНЕРГИЯ" if Layout.board(kind) else "ОГОНЬ")+" · "+("ТРОЙНАЯ" if Layout.turns(kind)==3 else "ДВОЙНАЯ" if Layout.turns(kind)==2 else "СПИРАЛЬ" if kind=="spiral" else "ПЕТЛЯ")+" · 72 ★",Vector3(0,4.,-3),24)
		sign.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		var icon:=Sprite3D.new(); icon.texture=preload("res://assets/ui/boost-fire.svg") if route.booster=="jet" else preload("res://assets/ui/boost-energy.svg"); icon.pixel_size=.018; icon.billboard=BaseMaterial3D.BILLBOARD_ENABLED; icon.position=Vector3(0,2.8,-2); body.add_child(icon)
		for j in 15:
			var u:float=.12+j*.76/14.
			var pose:=frame(kind,u)
			var mega:bool=j in [4,7,10]
			var node:=Stars.build(body,16 if mega else 2,mega)
			node.position=pose.position+pose.up*1.15
			route.rewards.append({"u":u,"value":16 if mega else 2,"done":false,"node":node,"mega":mega})
		routes.append(route)

func reserve(events:Array[Dictionary],pickups:Array[Dictionary]) -> void:
	# The two bypass lanes stay clear; distant authored features stay unchanged.
	for route:Dictionary in routes:
		for index in range(events.size()-1,-1,-1):
			var e:Dictionary=events[index]
			if e.s+e.length*.5+18.>=route.start-80. and e.s-e.length*.5<=route.start+SPAN+30.: events.remove_at(index)
		for index in range(pickups.size()-1,-1,-1):
			if pickups[index].s>=route.start-24. and pickups[index].s<=route.start+SPAN+20.: pickups.remove_at(index)
		for offset in [-30.,-22.,-14.,-6.]: Course.add_star(pickups,route.start+offset,route.lane)
		for offset in [8.,20.,32.,44.,63.]: Course.add_star(pickups,route.start+offset,1)

func install_drop(kind:String) -> void:
	for route:Dictionary in routes:
		if route.booster!=kind: continue
		var icon:=Sprite3D.new(); icon.texture=preload("res://assets/ui/boost-fire.svg") if kind=="jet" else preload("res://assets/ui/boost-energy.svg")
		icon.pixel_size=.022; icon.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		var pose:=frame(route.kind,.5); icon.position=pose.position+pose.up*1.8
		route.node.add_child(icon); route.drop_icon=icon

func hide_drops() -> void:
	for route:Dictionary in routes:
		if route.has("drop_icon"):route.drop_icon.hide()

func try_enter(distance_value:float,hero_x:float,hero_y:float,booster:String,requested_lane:int=-1) -> bool:
	if not active.is_empty(): return false
	for route:Dictionary in routes:
		if distance_value>route.start+12.: route.passed=true
		if route.passed or route.taken or route.booster!=booster: continue
		var aligned:bool=requested_lane==route.lane if requested_lane>=0 else absf(hero_x-(route.lane-1)*2.6)<1.1
		if distance_value>=route.start-8. and distance_value<=route.start+12. and aligned and hero_y>=-.3:
			active=route; route.taken=true; travelled=0.
			route.visit_reward=0
			route.entry_distance=distance_value
			route.entry_offset=Vector3(hero_x-(route.lane-1)*2.6,hero_y,-(distance_value-route.start))
			return true
	return false

func step(metres:float) -> Dictionary:
	travelled+=metres
	var total:float=arcs(active.kind)[-1]
	var u:=parameter(active.kind,minf(travelled,total)); active.u=u
	var pose:=frame(active.kind,u)
	var main_distance:float=lerpf(float(active.get("entry_distance",active.start)),active.start+SPAN,u)
	pose.position+=Vector3((active.lane-1)*2.6,0,main_distance-active.start)
	pose.position+=Vector3(active.get("entry_offset",Vector3.ZERO))*(1.-smoothstep(0.,18.,travelled))
	pose["distance"]=main_distance
	pose["rewards"]=[]
	for reward:Dictionary in active.rewards:
		if not reward.done and u>=reward.u: reward.done=true; reward.node.hide(); pose.rewards.append(reward)
	pose["finished"]=travelled>=total
	if pose.finished: extra_metres+=total-SPAN
	return pose

func present(distance_value:float,clock:float,reduced:bool) -> void:
	for route:Dictionary in routes:
		route.node.position=Vector3((route.lane-1)*2.6,0,distance_value-route.start)
		route.node.visible=distance_value>route.start-180. and distance_value<route.start+SPAN+50.
		if not route.node.visible: continue
		route.node.get_node("EnergyCore").advance(clock,reduced)
		for reward:Dictionary in route.rewards:
			if not reward.done: Stars.animate(reward.node,clock,reward.u*7,reduced)
