extends RefCounted
## Small shared mesh kit. Batching follows spacetamagoshi/SurfaceGeometry and ShipKit.
static var mats: Dictionary = {}
static var meshes: Dictionary = {}

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
	parent.add_child(node)
	return node

static func box(parent: Node3D, size: Vector3, at: Vector3, color: String, glow: float = 0.0) -> MeshInstance3D:
	var key := "b" + str(size)
	if not meshes.has(key):
		var mesh := BoxMesh.new()
		mesh.size = size
		meshes[key] = mesh
	return part(parent, meshes[key], at, material(color, glow))

static func ball(parent: Node3D, size: Vector3, at: Vector3, color: String, glow: float = 0.0) -> MeshInstance3D:
	if not meshes.has("sphere"):
		var sphere := SphereMesh.new()
		sphere.radius = 0.5
		sphere.height = 1.0
		sphere.radial_segments = 24
		sphere.rings = 12
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

static func ring(parent: Node3D, inner: float, outer: float, at: Vector3, color: String, glow: float = 0.0) -> MeshInstance3D:
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
	node.font = preload("res://assets/fonts/Nunito-Bold.ttf")
	node.font_size = font_size
	node.pixel_size = 0.012
	node.modulate = Color("e9ffff")
	node.position = at
	node.outline_size = 5
	parent.add_child(node)
	return node

static func batch(root: Node3D) -> void:
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
			var transform: Transform3D = root.global_transform.affine_inverse() * group[i].global_transform
			multi.set_instance_transform(i, transform)
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = multi
		root.add_child(instance)
		for piece: MeshInstance3D in group:
			piece.get_parent().remove_child(piece)
			piece.queue_free()
