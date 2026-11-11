extends RefCounted

const G = preload("res://scripts/geometry.gd")
const NOISE = preload("res://assets/effects/energy/noise_soft.png")
const VORTEX = preload("res://assets/effects/energy/vortex.gdshader")
const PLASMA = preload("res://assets/effects/energy/plasma.gdshader")
const FILAMENT = preload("res://assets/effects/energy/filament.gdshader")

static func material(shader: Shader, color: Color) -> ShaderMaterial:
	var result := ShaderMaterial.new()
	result.shader = shader
	result.set_shader_parameter("noise_map",NOISE)
	result.set_shader_parameter("tint",color)
	return result

static func vortex(parent: Node3D, size: Vector2, at: Vector3, color: Color, orbit: bool = false) -> MeshInstance3D:
	var shape := QuadMesh.new()
	shape.size = size
	var mat := material(VORTEX,color)
	mat.set_shader_parameter("hot",color.lerp(Color("d6f7ff"),.55))
	mat.set_shader_parameter("orbit",orbit)
	var result := G.part(parent,shape,at,mat)
	result.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return result

static func filaments(parent: Node3D, color: Color) -> MultiMeshInstance3D:
	var beam := QuadMesh.new()
	beam.size = Vector2(.67,2.75)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = beam
	mm.instance_count = 8
	for i in mm.instance_count:
		var angle := i*TAU/mm.instance_count
		var axis := Vector3(sin(angle),cos(angle),sin(angle*3.)*.42).normalized()
		var frame := Basis(Quaternion(Vector3.UP,axis))*Basis(Vector3.UP,i*.61)
		mm.set_instance_transform(i,Transform3D(frame,axis*1.85))
		mm.set_instance_custom_data(i,Color(i*.137,0,0,1))
	var arcs := MultiMeshInstance3D.new()
	arcs.multimesh = mm
	arcs.material_override = material(FILAMENT,color)
	arcs.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(arcs)
	return arcs
