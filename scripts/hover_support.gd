extends RefCounted
const G=preload("res://scripts/geometry.gd")
static var reduced:=false
static var flame:ShaderMaterial
static var nozzle:TorusMesh
static func set_motion(value:bool) -> void:
	reduced=value
	if flame:flame.set_shader_parameter("motion",0. if reduced else 1.)
static func suspended(e:Dictionary) -> bool:return e.kind in ["stairs","stairs_down","skycarrier","tunnel"] or e.kind.begins_with("upper_")
static func phase(e:Dictionary,clock:float) -> float:
	if reduced:return 0.
	return clock*1.35+float(e.get("sway_group",e.origin))*.017
static func offset(e:Dictionary,clock:float) -> float:
	if not suspended(e) or reduced:return 0.
	return sin(phase(e,clock))*(.10 if e.kind.begins_with("upper_") else .045)
static func roll(e:Dictionary,clock:float) -> float:
	if not suspended(e) or reduced:return 0.
	return sin(phase(e,clock)*.72)*(.018 if e.kind.begins_with("upper_") else .008)
static func floor_delta(e:Dictionary,clock:float,local_x:float=0.) -> float:return offset(e,clock)+tan(roll(e,clock))*local_x
static func mount(root:Node3D,width:float,length_value:float,start_height:float,end_height:float) -> void:
	if root.has_node("CornerJets"):return
	var jets:=Node3D.new();jets.name="CornerJets";root.add_child(jets)
	if flame==null:
		flame=ShaderMaterial.new();flame.shader=preload("res://assets/surfaces/hover_flame.gdshader");flame.set_shader_parameter("motion",0. if reduced else 1.)
	var quad:=QuadMesh.new();quad.size=Vector2(.65,1.65)
	if nozzle==null:
		nozzle=TorusMesh.new();nozzle.inner_radius=.12;nozzle.outer_radius=.21;nozzle.rings=12;nozzle.ring_segments=4
	for end in [-1.,1.]:
		for side in [-1.,1.]:
			var at:=Vector3(side*(width*.5+.1),(start_height if end>0 else end_height)-.48,end*maxf(.7,length_value*.5-.7))
			G.tube(jets,.20,.28,at,"627b8b")
			G.part(jets,nozzle,at+Vector3(0,-.15,0),G.material("b6f7ed",.7))
			for plane in 2:
				var plume:=G.part(jets,quad,at+Vector3(0,-.96,0),flame);plume.rotation.y=plane*PI*.5;plume.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	G.merge_static(jets);root.set_meta("hover_engine_count",4)
