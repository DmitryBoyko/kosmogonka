extends RefCounted
static var materials:Dictionary={}
static func build(shape:int,_color:String="ffffff") -> Node3D:
	if not materials.has(shape):
		var material:=StandardMaterial3D.new()
		material.albedo_texture=load("res://assets/badges/badge_%d.svg"%shape)
		material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		material.alpha_scissor_threshold=.025; material.roughness=.76
		material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		materials[shape]=material
	var root:=Node3D.new(); var mesh:=QuadMesh.new(); mesh.size=Vector2(.43,.28)
	var decal:=MeshInstance3D.new(); decal.mesh=mesh; decal.material_override=materials[shape]
	decal.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(decal); root.set_meta("flat_chest_decal",true)
	return root
