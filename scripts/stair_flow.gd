extends RefCounted
static func material(root:Node3D,planet:int=0) -> ShaderMaterial:
	var mat:=ShaderMaterial.new(); mat.shader=preload("res://assets/surfaces/stair_flow.gdshader")
	mat.set_shader_parameter("light_color",Color(preload("res://scripts/planets.gd").get_data(planet).accent))
	root.set_meta("stair_flow",mat); return mat
static func advance(root:Node3D,distance:float,event:Dictionary,reduced:bool) -> void:
	var mat:ShaderMaterial=root.get_meta("stair_flow",null)
	if mat==null: return
	var ahead:float=event.s-event.length*.5-distance
	var past:float=distance-event.s-event.length*.5
	mat.set_shader_parameter("activation",(1.-smoothstep(4.,30.,ahead))*(1.-smoothstep(0.,5.,past)))
	mat.set_shader_parameter("flow_distance",distance*1.7)
	mat.set_shader_parameter("reduced_motion",reduced)
