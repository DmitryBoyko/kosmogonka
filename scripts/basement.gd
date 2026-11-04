extends RefCounted
## Optional below-road route. Distances increase along -Z in the scrolling scene.
const G=preload("res://scripts/geometry.gd")
const SM=preload("res://scripts/salvage_mesh.gd")
const Transport=preload("res://scripts/hover_transport.gd")
const DEPTH:=4.8
const STAIRS:=12.0
const LENGTH:=64.0
const FLOOR:=-DEPTH

static func floor_height(event:Dictionary, s:float) -> float:
	var along:float=s-(event.s-event.length*.5)
	var steps:=26
	if along<STAIRS: return -DEPTH*minf(steps,floor(maxf(0,along)/STAIRS*steps)+1)/steps
	if along>event.length-STAIRS: return -DEPTH*maxf(0,steps-floor((along-event.length+STAIRS)/STAIRS*steps)-1)/steps
	return FLOOR

static func openings(event:Dictionary) -> Array:
	var begin:float=event.s-event.length*.5
	return [Vector2(begin,begin+STAIRS),Vector2(begin+event.length-STAIRS,begin+event.length)]

static func build(event:Dictionary,variant:int,planet:int=0) -> Node3D:
	var root:=Node3D.new(); root.name="UndergroundRoute"
	var shell:=Transport.paint(variant,"paint"); var frame:=Transport.paint(variant,"frame")
	var deck:=Transport.paint(variant,"deck")
	var half:float=event.length*.5
	for i in 26:
		var depth:=STAIRS/26
		for entry in [true,false]:
			var rel:float=-half+(i+.5)*depth if entry else half-STAIRS+(i+.5)*depth
			var y:=floor_height(event,event.s+rel)
			SM.block(root,Vector3(2.36,.20,depth+.015),Vector3(0,y-.1,-rel),deck,.025)
			for side in [-1,1]: G.box(root,Vector3(.07,.025,depth*.85),Vector3(side*1.03,y+.02,-rel),"87f8d5",.4)
	SM.block(root,Vector3(2.36,.22,event.length-STAIRS*2),Vector3(0,FLOOR-.11,0),deck,.04)
	# The round and rectangular interiors share the same physical floor and clearance.
	if event.round:
		var outer:=SurfaceTool.new(); outer.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in 18:
			var a:=PI*i/18; var b:=PI*(i+1)/18
			var p:=Vector3(-cos(a)*1.34,FLOOR+sin(a)*3.6,half-STAIRS)
			var q:=Vector3(-cos(b)*1.34,FLOOR+sin(b)*3.6,half-STAIRS)
			var length_value:float=event.length-STAIRS*2
			SM._triangle(outer,p,q,q-Vector3(0,0,length_value)); SM._triangle(outer,p,q-Vector3(0,0,length_value),p-Vector3(0,0,length_value))
			SM._triangle(outer,q-Vector3(0,0,length_value),q,p); SM._triangle(outer,p-Vector3(0,0,length_value),q-Vector3(0,0,length_value),p)
		# Both winding directions keep the lining visible with existing one-sided hull shaders.
		var mesh:=outer.commit(); var inside:=MeshInstance3D.new(); inside.mesh=mesh; inside.material_override=shell; root.add_child(inside)
	else:
		SM.block(root,Vector3(2.65,.24,event.length-STAIRS*2),Vector3(0,FLOOR+3.5,0),shell,.06)
	for side in [-1,1]:
		SM.block(root,Vector3(.20,DEPTH+.12,event.length),Vector3(side*1.28,-DEPTH*.5,0),shell,.04)
		for z in [-half+STAIRS*.5,half-STAIRS*.5]:
			G.box(root,Vector3(.10,.06,STAIRS),Vector3(side*1.22,.05,z),"ffc77d",.5)
		for z in range(-int(half)+2,int(half),4):
			var strip:=G.box(root,Vector3(.10,.10,3.85),Vector3(side*(.62 if event.round else .95),FLOOR+3.08 if event.round else FLOOR+3.28,z))
			strip.material_override=preload("res://scripts/surface_style.gd").edge(planet)
	G.label(root,"↓ ПОДЗЕМНЫЙ ХОД / ↑ ПЕРЕПРЫГНИ",Vector3(0,1.6,half+1),20)
	G.label(root,"ПЕРЧАТКА: ↓↓ НА СПИНУ / ★ ×2",Vector3(0,FLOOR+2.9,half-STAIRS-2),19)
	# Local fill light actually lights the runner below the opaque road roof.
	for z in [-14,0,14]:
		var lamp:=OmniLight3D.new(); root.add_child(lamp)
		lamp.position=Vector3(.85 if z!=0 else -.85,FLOOR+2.7,z); lamp.omni_range=11; lamp.light_color=Color(preload("res://scripts/planets.gd").get_data(planet).accent); lamp.light_energy=.9
	return root

static func glove(planet:int=0) -> Node3D:
	var root:=Node3D.new(); root.name="CeilingGlove"
	G.box(root,Vector3(2.3,.25,1.5),Vector3(0,FLOOR+3.25,0),"5c6a84")
	var punch:=Node3D.new(); punch.name="Punch"; root.add_child(punch)
	G.tube(punch,.16,1.0,Vector3(0,2.75,0),"91c8c3")
	G.ball(punch,Vector3(2.15,1.25,1.55),Vector3(0,1.7,0),"f36c89")
	G.ball(punch,Vector3(.7,.8,.9),Vector3(.8,1.5,.35),"dd5374")
	G.box(punch,Vector3(1.25,.25,.9),Vector3(0,2.35,0),"ffe3ba")
	for side in [-1,1]:
		G.link(punch,Vector3(side*.55,1.45,.65),Vector3(side*.55,1.92,.65),.025,"ffc2cb")
	var finish:=ShaderMaterial.new(); finish.shader=preload("res://assets/surfaces/glove_finish.gdshader"); finish.set_shader_parameter("planet",planet)
	for piece:MeshInstance3D in punch.get_children():
		if piece.mesh is SphereMesh: piece.material_override=finish
	root.set_meta("glove_planet",planet)
	G.label(root,"↓↓",Vector3(0,FLOOR+2.75,1.0),40).modulate=Color("ffbda2")
	return root

static func animate_glove(root:Node3D, rel:float) -> void:
	# Triggered by approach, rather than a random clock: the warning is predictable.
	var extend:=smoothstep(-13,-4,rel)*(1-smoothstep(2,8,rel))
	root.get_node("Punch").position.y=FLOOR+lerpf(1.4,0.0,extend)
