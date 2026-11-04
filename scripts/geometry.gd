extends RefCounted
## Small shared mesh kit. Batching follows spacetamagoshi/SurfaceGeometry and ShipKit.
static var mats: Dictionary = {}
static var meshes: Dictionary = {}

static func recolor(root: Node3D, palette: Dictionary) -> void:
	if palette.is_empty(): return
	for node: Node in root.find_children("*", "GeometryInstance3D", true, false):
		if node is MeshInstance3D and node.material_override is StandardMaterial3D:
			node.material_override = tint_material(node.material_override, palette)
		elif node is MultiMeshInstance3D:
			if node.material_override is StandardMaterial3D:
				node.material_override=tint_material(node.material_override,palette); continue
			if node.material_override!=null: continue
			var original: Mesh = node.multimesh.mesh
			var copy:=ArrayMesh.new()
			for surface in original.get_surface_count():
				copy.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,original.surface_get_arrays(surface))
				copy.surface_set_material(surface,original.surface_get_material(surface))
			for i in copy.get_surface_count():
				if copy.surface_get_material(i) is StandardMaterial3D:
					copy.surface_set_material(i, tint_material(copy.surface_get_material(i), palette))
			node.multimesh.mesh = copy

static func tint_material(original: StandardMaterial3D, palette: Dictionary) -> Material:
	var hex := original.albedo_color.to_html(false)
	return material(palette[hex], original.emission_energy_multiplier if original.emission_enabled else 0.0) if palette.has(hex) else original

static func material(hex: String, glow: float = 0.0) -> StandardMaterial3D:
	var key := hex + str(glow)
	if mats.has(key): return mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	m.roughness = 0.65
	if glow > 0:
		m.emission_enabled = true
		m.emission = Color(hex)
		m.emission_energy_multiplier = glow
	mats[key] = m
	return m

static func part(parent: Node3D, mesh: Mesh, at: Vector3, mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = at
	if preload("res://scripts/mobile_render.gd").enabled(): node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node

static func box(parent: Node3D, size: Vector3, at: Vector3, color: String = "ffffff", glow: float = 0.0) -> MeshInstance3D:
	var key := "b" + str(size)
	if not meshes.has(key):
		var mesh := BoxMesh.new()
		mesh.size = size
		meshes[key] = mesh
	return part(parent, meshes[key], at, material(color, glow))

static func ball(parent: Node3D, size: Vector3, at: Vector3, color: String = "ffffff", glow: float = 0.0) -> MeshInstance3D:
	if not meshes.has("sphere"):
		var sphere := SphereMesh.new()
		sphere.radius = 0.5
		sphere.height = 1.0
		sphere.radial_segments = 12 if preload("res://scripts/mobile_render.gd").enabled() else 24
		sphere.rings = 6 if preload("res://scripts/mobile_render.gd").enabled() else 12
		meshes["sphere"] = sphere
	var node := part(parent, meshes["sphere"], at, material(color, glow))
	node.scale = size
	return node

static func tube(parent: Node3D, radius: float, height: float, at: Vector3, color: String, top: float = -1.0) -> MeshInstance3D:
	var key := "c" + str(Vector3(radius, height, top))
	if not meshes.has(key):
		var mesh := CylinderMesh.new()
		mesh.top_radius = radius if top < 0 else top
		mesh.bottom_radius = radius
		mesh.height = height
		mesh.radial_segments = 12
		meshes[key] = mesh
	return part(parent, meshes[key], at, material(color))

static func link(parent: Node3D, a: Vector3, b: Vector3, radius: float, color: String) -> MeshInstance3D:
	var node := tube(parent, radius, a.distance_to(b), (a + b) * 0.5, color)
	node.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
	return node

static func ring(parent: Node3D, inner: float, outer: float, at: Vector3, color: String = "ffffff", glow: float = 0.0) -> MeshInstance3D:
	var key := "t" + str(Vector2(inner, outer))
	if not meshes.has(key):
		var mesh := TorusMesh.new()
		mesh.inner_radius = inner
		mesh.outer_radius = outer
		mesh.rings = 32
		mesh.ring_segments = 8
		meshes[key] = mesh
	return part(parent, meshes[key], at, material(color, glow))

static func star(parent: Node3D, radius: float, at: Vector3) -> Node3D:
	if not meshes.has("star"):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for side in [-1.0, 1.0]:
			for i in 10:
				var a := PI * 0.5 + i * TAU / 10
				var b := PI * 0.5 + (i + 1) * TAU / 10
				var r1 := 1.0 if i % 2 == 0 else 0.46
				var r2 := 1.0 if (i + 1) % 2 == 0 else 0.46
				var p := Vector3(cos(a) * r1, sin(a) * r1, 0)
				var q := Vector3(cos(b) * r2, sin(b) * r2, 0)
				for v: Vector3 in ([Vector3(0, 0, side * 0.25), q, p] if side > 0 else [Vector3(0, 0, side * 0.25), p, q]):
					st.add_vertex(v)
		st.generate_normals()
		meshes["star"] = st.commit()
	var node := part(parent, meshes["star"], at, material("ffe295", 0.35))
	node.scale = Vector3.ONE * radius
	return node

static func label(parent: Node3D, text: String, at: Vector3, font_size: int = 48) -> Label3D:
	var node := Label3D.new()
	node.text = text
	node.font = preload("res://assets/fonts/RussoOne-Regular.ttf")
	node.font_size = font_size
	node.pixel_size = 0.012
	node.modulate = Color("e9ffff")
	node.position = at
	node.outline_size = 5
	parent.add_child(node)
	return node

static func batch(root: Node3D) -> void:
	if preload("res://scripts/mobile_render.gd").enabled():
		merge_static(root); return
	var groups: Dictionary = {}
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var piece := node as MeshInstance3D
		var ancestor := piece.get_parent()
		var animated := false
		while ancestor != root:
			if ancestor.has_meta("motion"): animated = true
			ancestor = ancestor.get_parent()
		if animated: continue
		var key := str(piece.mesh.get_instance_id()) + "/" + str(piece.material_override.get_instance_id())
		if not groups.has(key): groups[key] = []
		groups[key].append(piece)
	for group: Array in groups.values():
		if group.size() < 2: continue
		var first: MeshInstance3D = group[0]
		var shared := ArrayMesh.new()
		shared.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, first.mesh.surface_get_arrays(0))
		shared.surface_set_material(0, first.material_override)
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = shared
		multi.instance_count = group.size()
		for i in group.size():
			# Builders also batch before the subtree enters the SceneTree.
			var transform: Transform3D = group[i].transform
			var parent:Node3D=group[i].get_parent()
			while parent!=root:
				transform=parent.transform*transform
				parent=parent.get_parent()
			multi.set_instance_transform(i, transform)
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = multi
		root.add_child(instance)
		for piece: MeshInstance3D in group:
			piece.get_parent().remove_child(piece)
			piece.queue_free()

static func merge_static(root:Node3D) -> void:
	var groups:Dictionary={}
	for piece:MeshInstance3D in root.find_children("*","MeshInstance3D",true,false):
		if piece.has_meta("surface_role") or piece.has_meta("road_edge_led"): continue
		var transform:=piece.transform; var ancestor:=piece.get_parent(); var animated:=false
		while ancestor!=root:
			if ancestor.has_meta("motion"): animated=true; break
			transform=(ancestor as Node3D).transform*transform; ancestor=ancestor.get_parent()
		if animated: continue
		for surface in piece.mesh.get_surface_count():
			var material:=piece.get_active_material(surface)
			if material==null: continue
			var key:=str(material.get_instance_id())+"/"+str(piece.cast_shadow)
			if not groups.has(key): groups[key]={"material":material,"shadow":piece.cast_shadow,"parts":[],"solid":false}
			groups[key].solid=groups[key].solid or piece.get_meta("architecture_solid",false)
			groups[key].parts.append({"node":piece,"surface":surface,"transform":transform})
	var removed:Dictionary={}
	for group:Dictionary in groups.values():
		var tool:=SurfaceTool.new(); tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		for item:Dictionary in group.parts:
			tool.append_from(item.node.mesh,item.surface,item.transform); removed[item.node]=true
		var combined:=part(root,tool.commit(),Vector3.ZERO,group.material); combined.cast_shadow=group.shadow
		if group.solid: combined.set_meta("architecture_solid",true)
	for piece:Node in removed:
		piece.get_parent().remove_child(piece); piece.queue_free()
