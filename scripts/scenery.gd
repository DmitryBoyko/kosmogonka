extends Node3D
const G = preload("res://scripts/geometry.gd")
const Course = preload("res://scripts/course.gd")
var chunks: Dictionary = {}
var anims: Array[Node3D] = []
var decorations := 0

func sync(distance: float, dt: float, clock: float) -> void:
	var first := int(floor((distance - 42.0) / 30.0))
	var last := int(floor((distance + 155.0) / 30.0))
	for key in chunks.keys():
		if key < first or key > last:
			chunks[key].queue_free()
			chunks.erase(key)
	for index in range(first, last + 1):
		if not chunks.has(index): chunks[index] = make_chunk(index)
		chunks[index].position.z = distance - index * 30.0
	for item in anims:
		if not is_instance_valid(item) or item.is_queued_for_deletion(): continue
		if item.get_meta("motion", "") == "radar": item.rotation.y += dt * 0.45
		else: item.rotation.z = sin(clock * 1.6 + item.get_meta("phase", 0.0)) * 0.035
	if anims.size() > 100:
		anims = anims.filter(func(n): return is_instance_valid(n) and not n.is_queued_for_deletion())

func clear() -> void:
	for chunk in chunks.values(): chunk.free()
	chunks.clear()
	anims.clear()

func make_chunk(index: int) -> Node3D:
	var root := Node3D.new()
	add_child(root)
	root.name = "Aurora_%d" % index
	root.position.z = -index * 30.0
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(index * 7919 + 67)
	var mid := index * 30.0 + 15.0
	var lanes := Course.lanes_at(mid)
	var road_center := -1.3 if lanes.size() == 2 else 0.0
	var width := lanes.size() * 2.6 + 0.3
	G.box(root, Vector3(110, 0.65, 30.0), Vector3(0, -0.55, -15), "7061a6")
	G.box(root, Vector3(width + 0.8, 0.3, 30), Vector3(road_center, -0.15, -15), "373b69")
	G.box(root, Vector3(width, 0.05, 30), Vector3(road_center, 0.025, -15), "35365b")
	for side in [-1.0, 1.0]:
		G.box(root, Vector3(0.12, 0.09, 30), Vector3(road_center + side * (width * 0.5 + 0.11), 0.07, -15), "7cf3e4", 0.6)
		G.box(root, Vector3(0.24, 0.12, 30), Vector3(road_center + side * (width * 0.5 + 0.4), 0.0, -15), "927ccd")
	for lane in lanes:
		var x: float = (lane - 1) * 2.6
		for i in 5:
			G.box(root, Vector3(0.045, 0.025, 1.4), Vector3(x - 1.28, 0.065, -3 - i * 6), "9293bc", 0.1)
			G.box(root, Vector3(0.48, 0.015, 0.045), Vector3(x, 0.06, -3 - i * 6), "53567d")
	var theme := (index / 3) % 3
	for side in [-1.0, 1.0]:
		var x: float = side * rng.randf_range(9.0, 13.0)
		var z := rng.randf_range(-24, -6)
		if (index + int(side)) % 4 != 0:
			match theme:
				0: plant(root, Vector3(x, -0.2, z), rng, index)
				1: station(root, Vector3(x, 0, z), side)
				2: tower(root, Vector3(x, 0, z), rng, side)
		for i in 3:
			crystal(root, Vector3(side * rng.randf_range(5.6, 8), -0.2, -i * 10 - 3), rng.randf_range(0.5, 1.3), "bf80ee" if i % 2 else "57dace")
		var hill := G.ball(root, Vector3(rng.randf_range(14, 24), rng.randf_range(10, 22), 20), Vector3(side * rng.randf_range(28, 43), -1, -15), "9881c7" if index % 2 else "7d7db7")
		hill.rotation.z = side * 0.2
		if index % 3 == 0:
			plant(root, Vector3(side * 19, 0, -20), rng, index + 4)
	G.batch(root)
	return root

func crystal(root: Node3D, at: Vector3, size: float, color: String) -> void:
	var p := Node3D.new()
	root.add_child(p)
	p.position = at
	p.rotation.z = sin(at.z) * 0.2
	G.tube(p, size * 0.38, size * 1.9, Vector3(0, size * 0.9, 0), color, 0)
	G.tube(p, size * 0.27, size, Vector3(size * 0.4, size * 0.4, 0.2), color, 0)
	G.ring(p, size * 0.28, size * 0.33, Vector3(0, size * 0.3, 0), "e7b6ff", 0.25)

func plant(root: Node3D, at: Vector3, rng: RandomNumberGenerator, phase: int) -> void:
	var trunk := Node3D.new()
	root.add_child(trunk)
	trunk.position = at
	var h := rng.randf_range(2.7, 4.8)
	G.tube(trunk, 0.23, h, Vector3(0, h * 0.5, 0), "535a80", 0.12)
	var crown := Node3D.new()
	trunk.add_child(crown)
	crown.position.y = h * 0.8
	for i in 5:
		var a := i * TAU / 5
		var leaf := G.ball(crown, Vector3(0.7, 0.35, 2.9), Vector3(sin(a) * 0.8, sin(i) * 0.3, cos(a) * 0.8), "4bd0ba" if phase % 2 else "cf73c6")
		leaf.rotation = Vector3(-0.3, a, 0)
	G.ball(crown, Vector3(0.55, 0.65, 0.55), Vector3(0, 0.5, 0), "ffe5a7", 0.3)
	# Keep a single animated parent; geometry below it is still batched locally.
	G.batch(crown)
	crown.set_meta("motion", "plant")
	crown.set_meta("phase", float(phase))
	anims.append(crown)

func station(root: Node3D, at: Vector3, side: float) -> void:
	var p := Node3D.new()
	root.add_child(p)
	p.position = at
	p.rotation.y = -side * PI * 0.5
	G.box(p, Vector3(4.8, 0.4, 4.0), Vector3(0, 0.2, 0), "4b4c7e")
	G.ball(p, Vector3(4.9, 3.1, 3.8), Vector3(0, 1.8, 0), "e2c9eb")
	G.box(p, Vector3(4.3, 0.2, 3.4), Vector3(0, 1.25, 0), "ff9bb7")
	G.box(p, Vector3(1.8, 1.15, 0.09), Vector3(0, 1.9, 1.85), "37577d")
	G.box(p, Vector3(1.5, 0.1, 0.11), Vector3(0, 2.3, 1.91), "6ff8de", 0.8)
	G.tube(p, 0.065, 2.2, Vector3(1.4, 3.4, 0), "f6d5ef")
	var radar := Node3D.new()
	p.add_child(radar)
	radar.position = Vector3(1.4, 4.5, 0)
	var dish := G.ball(radar, Vector3(1.3, 0.25, 1.3), Vector3.ZERO, "64f1d9")
	dish.rotation.z = 0.6
	radar.set_meta("motion", "radar")
	anims.append(radar)
	G.batch(radar)
	for i in 3:
		G.box(p, Vector3(0.9, 0.75, 0.9), Vector3(3.0, 0.4, i * 1.1 - 1.1), "9296c2")

func tower(root: Node3D, at: Vector3, rng: RandomNumberGenerator, side: float) -> void:
	var p := Node3D.new()
	root.add_child(p)
	p.position = at
	var h := rng.randf_range(5.5, 10)
	G.box(p, Vector3(4.5, h, 4.4), Vector3(0, h * 0.5, 0), "625087")
	G.box(p, Vector3(4.9, 0.4, 4.8), Vector3(0, h, 0), "d684bb")
	for row in range(1, int(h)):
		G.box(p, Vector3(4.55, 0.12, 4.45), Vector3(0, row, 0), "a6d9df" if row % 2 else "ff9fd5", 0.25)
	var sign_node := G.box(p, Vector3(0.12, 1.8, 2.6), Vector3(-side * 2.4, h * 0.62, 0), "56cabd", 0.2)
	G.box(p, Vector3(0.13, 0.18, 1.6), sign_node.position + Vector3(-side * 0.03, 0.3, 0), "d9ffef", 0.3)
