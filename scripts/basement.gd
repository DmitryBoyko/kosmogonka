extends RefCounted
## Optional below-road route. Distances increase along -Z in the scrolling scene.
const G=preload("res://scripts/geometry.gd")
const SM=preload("res://scripts/salvage_mesh.gd")
const Transport=preload("res://scripts/hover_transport.gd")
const DEPTH:=6.6
const STAIRS:=12.0
const LENGTH:=64.0
const HEIGHT:=5.5
const WIDTH:=5.4
const STEPS:=36
const FLOOR:=-DEPTH
const GLOVE_CLEARANCE:=1.775
const GLOVE_LIFT:=.7

static func floor_height(event:Dictionary, s:float) -> float:
	var along:float=s-(event.s-event.length*.5)
	var steps:=STEPS
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
	var flow:=preload("res://scripts/stair_flow.gd").material(root,planet)
	for i in STEPS:
		var depth:=STAIRS/STEPS
		for entry in [true,false]:
			var rel:float=-half+(i+.5)*depth if entry else half-STAIRS+(i+.5)*depth
			var y:=floor_height(event,event.s+rel)
			SM.block(root,Vector3(2.36,.20,depth+.015),Vector3(0,y-.1,-rel),deck,.025)
			for side in [-1,1]: G.box(root,Vector3(.07,.025,depth*.85),Vector3(side*1.03,y+.02,-rel),"87f8d5",.4).material_override=flow
	SM.block(root,Vector3(WIDTH,.22,event.length-STAIRS*2),Vector3(0,FLOOR-.11,0),deck,.04)
	# The round and rectangular interiors share the same physical floor and clearance.
	if event.round:
		var outer:=SurfaceTool.new(); outer.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in 18:
			var a:=PI*i/18; var b:=PI*(i+1)/18
			var p:=Vector3(-cos(a)*(WIDTH*.5+.12),FLOOR+sin(a)*HEIGHT,half-STAIRS)
			var q:=Vector3(-cos(b)*(WIDTH*.5+.12),FLOOR+sin(b)*HEIGHT,half-STAIRS)
			var length_value:float=event.length-STAIRS*2
			SM._triangle(outer,p,q,q-Vector3(0,0,length_value)); SM._triangle(outer,p,q-Vector3(0,0,length_value),p-Vector3(0,0,length_value))
			SM._triangle(outer,q-Vector3(0,0,length_value),q,p); SM._triangle(outer,p-Vector3(0,0,length_value),q-Vector3(0,0,length_value),p)
		# Both winding directions keep the lining visible with existing one-sided hull shaders.
		var mesh:=outer.commit(); var inside:=MeshInstance3D.new(); inside.mesh=mesh; inside.material_override=shell; root.add_child(inside)
	else:
		SM.block(root,Vector3(WIDTH+.3,.24,event.length-STAIRS*2),Vector3(0,FLOOR+HEIGHT,0),shell,.06)
	for side in [-1,1]:
		if not event.round: SM.block(root,Vector3(.20,HEIGHT,event.length-STAIRS*2),Vector3(side*(WIDTH*.5+.06),FLOOR+HEIGHT*.5,0),shell,.04)
		for entry_z in [-half+STAIRS*.5,half-STAIRS*.5]:
			SM.block(root,Vector3(.14,DEPTH,STAIRS),Vector3(side*1.28,-DEPTH*.5,entry_z),shell,.04)
		for z in [-half+STAIRS*.5,half-STAIRS*.5]:
			G.box(root,Vector3(.10,.06,STAIRS),Vector3(side*1.22,.05,z),"ffc77d",.5)
		for z in range(-int(half)+2,int(half),4):
			if absf(z)>half-STAIRS: continue
			var strip:=G.box(root,Vector3(.10,.10,3.85),Vector3(side*(1.6 if event.round else 2.4),FLOOR+4.45 if event.round else FLOOR+5.18,z))
			strip.material_override=preload("res://scripts/surface_style.gd").edge(planet)
	G.label(root,"↓ ПОДЗЕМНЫЙ ХОД / ↑ ПЕРЕПРЫГНИ",Vector3(0,1.6,half+1),20)
	var instruction:=G.label(root,"↓ ПОДКАТ / ↓↓ НА СПИНУ · ★ ×2",Vector3(0,FLOOR+4.45,half-STAIRS-2),18)
	instruction.pixel_size=.006; instruction.modulate.a=.7; instruction.visibility_range_end=20.
	# Local fill light actually lights the runner below the opaque road roof.
	for z in [-14,0,14]:
		var lamp:=OmniLight3D.new(); root.add_child(lamp)
		lamp.position=Vector3(1.9 if z!=0 else -1.9,FLOOR+4.6,z); lamp.omni_range=14; lamp.light_color=Color(preload("res://scripts/planets.gd").get_data(planet).accent); lamp.light_energy=1.1
	G.merge_static(root)
	return root

static func glove(planet:int=0) -> Node3D:
	var root:=Node3D.new(); root.name="CeilingGlove"
	G.box(root,Vector3(3.3,.25,1.7),Vector3(0,FLOOR+5.15,0),"5c6a84")
	G.tube(root,.16,1.,Vector3(0,FLOOR+3.8,0),"91c8c3").name="Piston"
	var punch:=Node3D.new(); punch.name="Punch"; root.add_child(punch)
	G.ball(punch,Vector3(2.15,1.25,1.55),Vector3(0,1.7,0),"f36c89")
	G.ball(punch,Vector3(.7,.8,.9),Vector3(.8,1.5,.35),"dd5374")
	G.box(punch,Vector3(1.25,.25,.9),Vector3(0,2.35,0),"ffe3ba")
	for side in [-1,1]:
		G.link(punch,Vector3(side*.55,1.45,.65),Vector3(side*.55,1.92,.65),.025,"ffc2cb")
	var finish:=ShaderMaterial.new(); finish.shader=preload("res://assets/surfaces/glove_finish.gdshader"); finish.set_shader_parameter("planet",planet)
	for piece:MeshInstance3D in punch.get_children():
		if piece.mesh is SphereMesh: piece.material_override=finish
	root.set_meta("glove_planet",planet)
	var warning:=G.label(root,"↓ ПОДКАТ",Vector3(0,FLOOR+4.35,1.0),26)
	warning.pixel_size=.005; warning.modulate=Color("ffbda2"); warning.visibility_range_end=28.
	return root

static func glove_offset(rel:float,speed:float=17.) -> float:
	# One deterministic attack: telegraph, downstroke, hold, recovery.
	# Rendering and contact checks use this same piston position.
	var time_to:float=-rel/maxf(1.,speed)
	var strike:=smoothstep(-.65,-.22,-time_to)
	var recover:=smoothstep(.18,.65,-time_to)
	return 1.95*(1.-strike*(1.-recover))

static func glove_hits(rel:float,speed:float,feet:float,stance_height:float) -> bool:
	return absf(rel)<1.12 and feet+stance_height>FLOOR+GLOVE_CLEARANCE+glove_offset(rel,speed) and feet<FLOOR+2.5+GLOVE_LIFT+glove_offset(rel,speed)

static func animate_glove(root:Node3D, rel:float,speed:float=17.) -> void:
	var offset:=glove_offset(rel,speed)
	root.get_node("Punch").position.y=FLOOR+GLOVE_LIFT+offset
	root.get_node("Piston").position.y=FLOOR+(5.05+2.45+GLOVE_LIFT+offset)*.5
	root.get_node("Piston").scale.y=maxf(.1,5.05-2.45-GLOVE_LIFT-offset)
