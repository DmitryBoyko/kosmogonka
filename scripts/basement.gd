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

static func touches_field(event:Dictionary,s:float,x:float,y:float) -> bool:
	if y>1.2 or y<-.7: return false
	var dx:=absf(x-(int(event.lane)-1)*2.6)
	for span:Vector2 in openings(event):
		if s>=span.x and s<=span.y and dx>=.99 and dx<=1.47: return true
		var sealed:=span.y if span.x<event.s else span.x
		if absf(s-sealed)<.48 and dx<1.2 and y>-.2: return true
	return false

static func add_fields(root:Node3D,event:Dictionary,planet:int) -> void:
	var mat:=ShaderMaterial.new()
	mat.shader=preload("res://assets/surfaces/finish_field.gdshader")
	mat.set_shader_parameter("tint",Color(preload("res://scripts/planets.gd").get_data(planet).accent))
	root.set_meta("opening_field",mat)
	var spans:=openings(event)
	for i in 2:
		var span:Vector2=spans[i]
		var centre:float=event.s-(span.x+span.y)*.5
		for side in [-1.,1.]:
			var side_mesh:=QuadMesh.new();side_mesh.size=Vector2(STAIRS,1.05)
			var wall:=G.part(root,side_mesh,Vector3(side*1.24,.53,centre),mat)
			wall.rotation.y=PI*.5;wall.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var end_mesh:=QuadMesh.new();end_mesh.size=Vector2(2.48,1.05)
		var end_z:float=event.s-(span.y if i==0 else span.x)
		G.part(root,end_mesh,Vector3(0,.53,end_z),mat).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

static func stair_run(root: Node3D, event: Dictionary, entry: bool, material: Material) -> void:
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half: float = event.length * .5
	var start_z := half if entry else -half + STAIRS
	var depth := STAIRS / STEPS
	var previous_y := 0. if entry else FLOOR
	const HALF_TREAD := 1.215
	for i in STEPS:
		var near_z := start_z - i * depth
		var far_z := start_z - (i + 1) * depth
		var y := floor_height(event, event.s - (near_z + far_z) * .5)
		var near_l := Vector3(-HALF_TREAD, y, near_z)
		var near_r := Vector3(HALF_TREAD, y, near_z)
		var far_l := Vector3(-HALF_TREAD, y, far_z)
		var far_r := Vector3(HALF_TREAD, y, far_z)
		SM._triangle(mesh, near_l, far_l, far_r)
		SM._triangle(mesh, near_l, far_r, near_r)
		var old_l := Vector3(-HALF_TREAD, previous_y, near_z)
		var old_r := Vector3(HALF_TREAD, previous_y, near_z)
		SM._triangle(mesh, old_l, near_l, near_r)
		SM._triangle(mesh, old_l, near_r, old_r)
		previous_y = y
	var stairs := G.part(root, mesh.commit(), Vector3.ZERO, material)
	stairs.name = "EntranceTreads" if entry else "ExitTreads"
	stairs.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

static func build(event:Dictionary,variant:int,planet:int=0) -> Node3D:
	var root:=Node3D.new(); root.name="UndergroundRoute"
	var shell:=Transport.paint(variant,"paint"); var frame:=Transport.paint(variant,"frame")
	var deck:=Transport.paint(variant,"deck")
	var treads := deck.duplicate() as ShaderMaterial
	treads.set_shader_parameter("surface_role",0)
	treads.set_shader_parameter("tile_scale",.55)
	treads.set_shader_parameter("roughness",.8)
	var half:float=event.length*.5
	stair_run(root, event, true, treads)
	stair_run(root, event, false, treads)
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
		for mouth in [-1., 1.]:
			var z: float = mouth * (half - STAIRS - .11)
			# Close the shoulders of the wider tunnel around the narrow stairwell.
			SM._box(root, Vector3(WIDTH * .5 - 1.11, DEPTH, .38),
				Vector3(side * (WIDTH * .25 + .61), FLOOR + DEPTH * .5 - .10, z), frame)
			var trim := G.material("78e8fa", .75)
			SM._beam(root, Vector3(side * 1.17, FLOOR + .44, mouth * (half - STAIRS)),
				Vector3(side * 1.17, .42, mouth * (half - .12)), .035, trim)
		for z in range(-int(half)+2,int(half),4):
			if absf(z)>half-STAIRS: continue
			var strip:=G.box(root,Vector3(.10,.10,3.85),Vector3(side*(1.6 if event.round else 2.4),FLOOR+4.45 if event.round else FLOOR+5.18,z))
			strip.material_override=preload("res://scripts/surface_style.gd").edge(planet)
	for mouth in [-1., 1.]:
		SM._box(root, Vector3(2.44, 1.1, .38), Vector3(0, -.55, mouth * (half - STAIRS - .11)), frame)
	# Local fill light actually lights the runner below the opaque road roof.
	for z in [-14,0,14]:
		var lamp:=OmniLight3D.new(); root.add_child(lamp)
		lamp.position=Vector3(1.9 if z!=0 else -1.9,FLOOR+4.6,z); lamp.omni_range=14; lamp.light_color=Color(preload("res://scripts/planets.gd").get_data(planet).accent); lamp.light_energy=1.1
	G.merge_static(root)
	add_fields(root,event,planet)
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
