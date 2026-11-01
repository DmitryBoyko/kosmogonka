extends RefCounted
const G = preload("res://scripts/geometry.gd")

static func obstacle(kind: String) -> Node3D:
	var root := Node3D.new()
	match kind:
		"barrier":
			G.box(root, Vector3(2.0, 0.9, 1.0), Vector3(0, 0.45, 0), "ff957f")
			G.box(root, Vector3(2.08, 0.12, 1.08), Vector3(0, 0.91, 0), "ffe8b2")
			for i in 3:
				var stripe := G.box(root, Vector3(0.18, 0.65, 0.03), Vector3((i - 1) * 0.58, 0.46, 0.52), "794d6e")
				stripe.rotation.z = -0.4
		"arch":
			for s in [-1.0, 1.0]:
				G.box(root, Vector3(0.22, 2.6, 0.4), Vector3(s * 1.05, 1.3, 0), "dcb1e3")
			G.box(root, Vector3(2.3, 1.0, 0.6), Vector3(0, 2.0, 0), "a46dcc")
			G.box(root, Vector3(2.1, 0.12, 0.66), Vector3(0, 1.5, 0), "ffe19a")
			G.label(root, "↓", Vector3(0, 2.05, 0.34), 70)
		"wall":
			G.box(root, Vector3(2.1, 2.9, 1.7), Vector3(0, 1.45, 0), "7872a5")
			G.box(root, Vector3(2.18, 0.22, 1.78), Vector3(0, 0.2, 0), "cf91c5")
			G.box(root, Vector3(2.18, 0.22, 1.78), Vector3(0, 2.7, 0), "cf91c5")
			for s in [-1.0, 1.0]:
				var slash := G.box(root, Vector3(0.13, 1.9, 0.04), Vector3(0, 1.45, 0.89), "ffca9e", 0.25)
				slash.rotation.z = s * 0.65
		"plant":
			G.ball(root, Vector3(2.1, 0.5, 1.8), Vector3(0, 0.2, 0), "69528e")
			for i in 5:
				var a := i * TAU / 5
				var leaf := G.ball(root, Vector3(0.6, 2.5, 0.6), Vector3(sin(a) * 0.5, 1.15, cos(a) * 0.45), "52caaa")
				leaf.rotation.z = sin(a) * 0.35
			G.ball(root, Vector3(0.85, 0.8, 0.85), Vector3(0, 2.15, 0), "e785d0")
		"truck", "broken", "carrier":
			var carrier := kind == "carrier"
			var length := 12.0 if carrier else 5.8
			var base := 1.05 if carrier else 0.55
			var color := "52c8bf" if carrier else ("a18bb1" if kind == "broken" else "f5b262")
			G.box(root, Vector3(2.15, 0.5, length), Vector3(0, base, 0), "424e77")
			G.box(root, Vector3(2.05, 0.25, length - 0.2), Vector3(0, base + 0.3, 0), color)
			if not carrier:
				G.ball(root, Vector3(2.0, 2.6, 2.0), Vector3(0, 1.65, -1.9), color)
				G.box(root, Vector3(1.65, 0.7, 0.12), Vector3(0, 2.1, -2.8), "35516c")
				G.box(root, Vector3(1.7, 0.65, 2.6), Vector3(0, 1.15, 0.8), "9982bb")
			for s in [-1.0, 1.0]:
				G.box(root, Vector3(0.08, 0.1, length * 0.8), Vector3(s * 1.09, base + 0.22, 0), "8ef9e1", 0.6)
				for j in [-1.0, 1.0]:
					G.ball(root, Vector3(0.45, 0.25 if carrier else 0.65, 0.7), Vector3(s * 1.0, base - 0.35, j * (length * 0.32)), "7af0e9" if carrier else "394460", 0.25 if carrier else 0)
			if carrier:
				for z in [-3.0, 0.0, 3.0]: G.box(root, Vector3(0.9, 0.03, 0.12), Vector3(0, 1.49, z), "e1ffea", 0.2)
			if kind == "broken":
				for i in 4:
					var flame := G.ball(root, Vector3(0.4, 1.2 + i * 0.1, 0.4), Vector3(sin(i) * 0.7, 1.7, cos(i)), "ffad67", 0.7)
					flame.rotation.z = i * 0.2
		"ramp":
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			for tri in [[Vector3(-1.1, 0, 3), Vector3(-1.1, 1.48, -3), Vector3(1.1, 1.48, -3)], [Vector3(-1.1, 0, 3), Vector3(1.1, 1.48, -3), Vector3(1.1, 0, 3)]]:
				for p: Vector3 in tri: st.add_vertex(p)
			st.generate_normals()
			G.part(root, st.commit(), Vector3.ZERO, G.material("91c7cf"))
			for i in 4:
				G.box(root, Vector3(1.7, 0.05, 0.1), Vector3(0, i * 0.33 + 0.12, 2.5 - i * 1.4), "e5ffde", 0.2)
		"jet", "board":
			var color := "8af9ed" if kind == "jet" else "ffc985"
			G.ring(root, 0.65, 0.72, Vector3(0, 1.5, 0), color, 0.5).rotation.x = PI * 0.5
			if kind == "jet":
				G.box(root, Vector3(0.65, 0.6, 0.35), Vector3(0, 1.5, 0), "7377bc")
				for s in [-1.0, 1.0]:
					G.tube(root, 0.16, 0.75, Vector3(s * 0.34, 1.45, 0), color)
					G.ball(root, Vector3(0.16, 0.4, 0.16), Vector3(s * 0.34, 0.95, 0), "c3ffff", 0.6)
			else:
				G.ball(root, Vector3(1.25, 0.22, 1.5), Vector3(0, 1.4, 0), color)
				G.label(root, "↟", Vector3(0, 1.8, 0.1), 70)
	return root

static func alien() -> Node3D:
	var p := Node3D.new()
	G.ball(p, Vector3(0.9, 0.85, 0.75), Vector3(0, 0.8, 0), "b19bff")
	for s in [-1.0, 1.0]:
		G.ball(p, Vector3(0.3, 0.33, 0.23), Vector3(s * 0.23, 1.05, 0.3), "fff3ed")
		G.ball(p, Vector3(0.13, 0.19, 0.06), Vector3(s * 0.23, 1.05, 0.42), "333f60")
		G.ball(p, Vector3(0.24, 0.18, 0.4), Vector3(s * 0.23, 0.18, 0.1), "8d73cf")
		G.link(p, Vector3(s * 0.4, 0.85, 0), Vector3(s * 0.67, 0.65, 0.2), 0.07, "b19bff")
	G.ball(p, Vector3(0.12, 0.06, 0.03), Vector3(0, 0.69, 0.37), "555280")
	G.link(p, Vector3(0, 1.15, 0), Vector3(0.2, 1.65, 0), 0.04, "b19bff")
	G.ball(p, Vector3.ONE * 0.18, Vector3(0.2, 1.65, 0), "ffce8a", 0.3)
	return p

static func ship() -> Node3D:
	var p := Node3D.new()
	G.ball(p, Vector3(3.5, 1.6, 6.2), Vector3.ZERO, "d5d8f5")
	G.ball(p, Vector3(2.1, 1.1, 2.6), Vector3(0, 0.7, -0.7), "49748a")
	G.ball(p, Vector3(1.8, 0.5, 2.3), Vector3(0, 1.0, -0.8), "70dbdd", 0.3)
	for s in [-1.0, 1.0]:
		var wing := G.ball(p, Vector3(3.8, 0.27, 2.3), Vector3(s * 1.9, -0.2, 0.8), "a396db")
		wing.rotation.y = s * -0.35
		G.ball(p, Vector3(0.7, 0.8, 1.8), Vector3(s * 2.3, -0.2, 1.7), "626698")
		G.ball(p, Vector3(0.45, 0.5, 2.3), Vector3(s * 2.3, -0.2, 3.0), "74fce5", 1.2)
	G.box(p, Vector3(0.11, 0.9, 1.5), Vector3(0, 0.9, 1.7), "fb91c3")
	return p
