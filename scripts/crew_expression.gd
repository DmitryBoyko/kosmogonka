extends RefCounted

const FaceShader = preload("res://assets/suits/crew_expression.gdshader")
const SkinShader = preload("res://assets/suits/crew_skin.gdshader")
const Crew = preload("res://scripts/crew.gd")
const Hair = preload("res://scripts/crew_hair.gd")
static var clean_heads: Dictionary = {}
const COMPLEXIONS := ["f2c49e","d7a17a","ad7452","78503b"]
const COMPLEXION_BY_HERO := [2,2,1,0,0,2,0,1,1,3,3,0,1,2,1,0,0,1,0,2]
const EYES := ["466477","65533c","614231","6d7153","4c667b"]

static func build(head: MeshInstance3D, mount: Node3D, origin: Vector3, index: int) -> ShaderMaterial:
	if not clean_heads.has(index):
		clean_heads[index] = style_head(head.mesh, index)
	head.mesh = clean_heads[index]
	var face := MeshInstance3D.new()
	face.name = "Expression"
	var panel := QuadMesh.new()
	panel.size = Vector2(.24,.20)
	face.mesh = panel
	face.position = Vector3(0,.468,.162) - origin
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := ShaderMaterial.new()
	material.shader = FaceShader
	material.set_shader_parameter("makeup",1. if Crew.is_female(index) else .18)
	material.set_shader_parameter("iris",Color(EYES[index % EYES.size()]))
	material.set_shader_parameter("third_eye",Crew.MODELS[index] == "alien")
	material.set_shader_parameter("digital",Crew.MODELS[index] in ["robot","knight"])
	face.material_override = material
	mount.add_child(face)
	if Crew.MODELS[index] not in ["robot","knight"]:
		var geometry:=preload("res://scripts/geometry.gd")
		var nose:=geometry.ball(mount,Vector3(.042,.035,.025),Vector3(0,.464,.173)-origin,COMPLEXIONS[COMPLEXION_BY_HERO[index]])
		nose.name="Nose"
	return material

static func style_head(source: Mesh, index: int) -> ArrayMesh:
	var result := ArrayMesh.new()
	var model: String = Crew.MODELS[index]
	var style: Array = Hair.STYLES.get(model,[])
	for surface in source.get_surface_count():
		var arrays := source.surface_get_arrays(surface)
		var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var remaining := PackedInt32Array()
		var strands := PackedInt32Array()
		for triangle in range(0,indices.size(),3):
			var old_mark := true
			var opaque_lens := index in [0,8]
			var hair := not style.is_empty()
			for corner in 3:
				var vertex := indices[triangle + corner]
				old_mark = old_mark and absf(points[vertex].z - .159605) < .0002
				opaque_lens = opaque_lens and uv[vertex].x > .95 and points[vertex].z > .162
				hair = hair and Hair.strand(style,model,uv[vertex],points[vertex])
			if (old_mark and model != "knight") or opaque_lens:
				continue
			for corner in 3:
				if hair: strands.append(indices[triangle + corner])
				else: remaining.append(indices[triangle + corner])
		var rounded:=points.duplicate()
		for vertex in rounded.size():
			var point:=rounded[vertex]
			# Retain the flat face centre so the animated eyes stay on the surface.
			var shoulder:=smoothstep(.089,.165,absf(point.x))
			point.x*=1.-.08*smoothstep(.07,.17,absf(point.z))
			point.z*=1.-shoulder*.09
			rounded[vertex]=point
		arrays[Mesh.ARRAY_VERTEX]=rounded
		arrays[Mesh.ARRAY_INDEX] = remaining
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		var original := source.surface_get_material(surface) as BaseMaterial3D
		if original and original.albedo_texture:
			var skin := ShaderMaterial.new()
			skin.shader = SkinShader
			skin.set_shader_parameter("source_atlas",original.albedo_texture)
			skin.set_shader_parameter("complexion",Color(COMPLEXIONS[COMPLEXION_BY_HERO[index]]))
			skin.set_shader_parameter("extra_skin_cell",Vector2i(5,1) if model=="alien" else Vector2i(9,2) if model=="zombie" else Vector2i(-1,-1))
			skin.set_shader_parameter("metal_mask",model in ["robot","knight"])
			skin.set_shader_parameter("steel_mask",model=="robot")
			result.surface_set_material(result.get_surface_count()-1,skin)
		else:
			result.surface_set_material(result.get_surface_count()-1,original)
		if not strands.is_empty():
			var hair_arrays := arrays.duplicate()
			var shaped := points.duplicate()
			var colors := PackedColorArray()
			colors.resize(points.size())
			for vertex in strands:
				var point := Hair.shape(points[vertex],style)
				if model=="female-a":
					point.y -= maxf(0.,point.y-.59)*.57
				shaped[vertex] = point
				colors[vertex] = Hair.tint(style,uv[vertex],shaped[vertex])
			hair_arrays[Mesh.ARRAY_VERTEX] = shaped
			hair_arrays[Mesh.ARRAY_COLOR] = colors
			hair_arrays[Mesh.ARRAY_INDEX] = strands
			result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,hair_arrays)
			result.surface_set_material(result.get_surface_count()-1,Hair.material(style))
	return result
