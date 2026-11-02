extends RefCounted
const Cargo=preload("res://scripts/cargo_containers.gd")
const Tunnel=preload("res://scripts/rocket_tunnel.gd")
const G = preload("res://scripts/geometry.gd")

static func obstacle(kind: String, variant: int = 0) -> Node3D:
	if kind in ["wall","barrier","cargo"]: return Cargo.obstacle(kind,variant)
	if kind == "tunnel": return Tunnel.build(variant)
	if kind == "alien": return running_alien()
	var root := Node3D.new()
	match kind:
		"leaf":
			G.ball(root, Vector3(2.1,0.35,1.7), Vector3(0,0.14,0), "52caaa")
			var hinge := Node3D.new()
			hinge.name = "Leaf"
			root.add_child(hinge)
			G.ball(hinge, Vector3(1.8,3.0,0.38), Vector3(0,1.45,0), "ff9ba8")
			G.link(hinge, Vector3.ZERO, Vector3(0,2.9,0),0.06,"a7ffd4")
			G.ball(root,Vector3.ONE*0.26,Vector3(0,0.4,0.7),"ffe295",0.6).name = "Warning"
		"gardener":
			G.ball(root,Vector3(1.2,0.4,1.1),Vector3(0,0.3,0),"5c7894")
			G.ball(root,Vector3(1,1.0,0.8),Vector3(0,1.1,0),"80dfb9")
			G.box(root,Vector3(0.75,0.3,0.12),Vector3(0,1.3,0.4),"345d72")
			for side in [-1,1]: G.ball(root,Vector3.ONE*0.12,Vector3(side*0.2,1.3,0.49),"ffe295",0.6)
			G.link(root,Vector3(0.5,1.1,0),Vector3(1,0.8,0),0.08,"a6eed6")
			G.label(root,"↔",Vector3(0,2.1,0),52).name = "Warning"
		"traffic":
			root.add_child(obstacle("truck"))
			G.label(root,"↔",Vector3(0,3.6,0),62).name = "Warning"
		"barrier":
			G.box(root, Vector3(2.0, 0.9, 1.0), Vector3(0, 0.45, 0), "ff957f")
			G.box(root, Vector3(2.08, 0.12, 1.08), Vector3(0, 0.91, 0), "ffe8b2")
			for i in 3:
				var stripe := G.box(root, Vector3(0.18, 0.65, 0.03), Vector3((i - 1) * 0.58, 0.46, 0.52), "794d6e")
				stripe.rotation.z = -0.4
		"arch":
			for s in [-1.0, 1.0]:
				G.box(root, Vector3(0.22, 2.6, 0.4), Vector3(s * 1.05, 1.3, 0), "dcb1e3")
			var lintel:=Cargo.fitted(variant,Vector3(2.3,1.0,0.6))
			root.add_child(lintel); lintel.position.y=1.5
			G.box(root, Vector3(2.1, 0.12, 0.66), Vector3(0, 1.5, 0), "ffe19a")
			G.label(root, "↓", Vector3(0, 2.05, 0.34), 70)
			var prize := G.label(root,"★ +3",Vector3(0,2.77,0),30)
			prize.modulate=Color("ffe295")
			prize.billboard=BaseMaterial3D.BILLBOARD_ENABLED
			for side in [-1.0,1.0]:
				G.box(root,Vector3(0.09,1.2,0.48),Vector3(side*1.05,0.75,0),"8ef9e1",0.45)
				G.ball(root,Vector3.ONE*0.19,Vector3(side*0.92,1.35,side*0.1),"ffe295",0.5)
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
		"truck", "broken", "carrier", "cargo":
			var carrier := kind == "carrier"
			var cargo := kind == "cargo"
			var length := 14.0 if cargo else 12.0 if carrier else 5.8
			var base := 1.05 if carrier else 0.55
			var color := "52c8bf" if carrier else ("a18bb1" if kind == "broken" else "f5b262")
			G.box(root, Vector3(2.15, 0.5, length), Vector3(0, base, 0), "424e77")
			G.box(root, Vector3(2.05, 0.25, length - 0.2), Vector3(0, base + 0.3, 0), color)
			if cargo:
				for i in 3:
					var z := (i-1)*4.2
					G.box(root,Vector3(2.08,2.1,3.8),Vector3(0,1.75,z),"56bfc0" if i%2==0 else "7c8fc2")
					for side in [-1.0,1.0]:
						G.box(root,Vector3(0.08,1.8,0.12),Vector3(side*1.07,1.75,z+1.5),"ffe0a3")
						G.box(root,Vector3(0.08,0.08,3.4),Vector3(side*1.07,2.65,z),"9af6df",0.4)
			elif not carrier:
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

static func running_alien() -> Node3D:
	var root := Node3D.new()
	var body := Node3D.new()
	body.name = "AlienBody"
	root.add_child(body)
	body.rotation.y = PI*0.5
	G.ball(body,Vector3(0.9,0.85,0.68),Vector3(0,0.72,0),"8fe4ae")
	G.ball(body,Vector3(0.54,0.5,0.16),Vector3(0,0.65,0.32),"fff0b0")
	G.ball(body,Vector3(0.88,0.63,0.7),Vector3(0,1.03,0.03),"8fe4ae")
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var eye := Node3D.new()
		eye.name = "Eye%d" % i
		body.add_child(eye)
		eye.position = Vector3(side*0.2,1.14,0.32)
		G.ball(eye,Vector3(0.3,0.32,0.2),Vector3.ZERO,"fff9ed")
		G.ball(eye,Vector3(0.11,0.16,0.04),Vector3(0,0,0.11),"3c4a64")
		var leg := Node3D.new()
		leg.name = "Leg%d" % i
		body.add_child(leg)
		leg.position = Vector3(side*0.24,0.38,0)
		G.link(leg,Vector3.ZERO,Vector3(0,-0.22,0),0.09,"6eb291")
		G.ball(leg,Vector3(0.28,0.16,0.42),Vector3(0,-0.28,0.08),"edb564")
		var arm := Node3D.new()
		arm.name = "Arm%d" % i
		body.add_child(arm)
		arm.position = Vector3(side*0.42,0.83,0)
		G.link(arm,Vector3.ZERO,Vector3(0,-0.24,0.12),0.07,"8fe4ae")
		G.ball(arm,Vector3.ONE*0.2,Vector3(0,-0.27,0.15),"6eb291")
		if i == 0:
			G.box(arm,Vector3(0.35,0.32,0.4),Vector3(0,-0.3,0.34),"bf98ec")
			G.box(arm,Vector3(0.09,0.34,0.42),Vector3(0,-0.3,0.34),"ffda94")
	G.ball(body,Vector3(0.18,0.065,0.03),Vector3(0,0.93,0.38),"4c7865")
	var antenna := Node3D.new()
	antenna.name = "Antenna"
	body.add_child(antenna)
	antenna.position.y = 1.29
	G.link(antenna,Vector3.ZERO,Vector3(0.14,0.31,0),0.035,"6eb291")
	G.ball(antenna,Vector3.ONE*0.18,Vector3(0.14,0.31,0),"ffb85f",0.3)
	G.label(root,"↔",Vector3(0,2.1,0),65).name = "Warning"
	var crossing := Node3D.new()
	crossing.name = "Crossing"
	root.add_child(crossing)
	for i in 13:
		G.box(crossing,Vector3(0.35,0.04,0.2),Vector3((i-6)*0.62,0.06,0),"ffda94",0.4)
	return root

static func animate_alien(root: Node3D, clock: float) -> void:
	var body: Node3D = root.get_node("AlienBody")
	var phase := clock*13.0
	body.position.y = absf(sin(phase))*0.07
	body.rotation.z = sin(phase)*0.07
	for i in 2:
		var wave := sin(phase+i*PI)
		body.get_node("Leg%d" % i).rotation.x = wave*0.7
		body.get_node("Arm%d" % i).rotation.x = -wave*0.8
		body.get_node("Eye%d" % i).scale.y = 0.15 if fposmod(clock,3.8)>3.65 else 1.0
	body.get_node("Antenna").rotation.z = sin(phase-0.5)*0.24

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

static func ship(kind: int = -1) -> Node3D:
	if kind == 1:
		var saucer := Node3D.new()
		G.ball(saucer,Vector3(5.5,0.65,5.5),Vector3.ZERO,"eaaa83")
		G.ball(saucer,Vector3(2.7,1.5,2.7),Vector3(0,0.65,0),"74c9c6")
		G.ring(saucer,2.4,2.65,Vector3.ZERO,"ffe0a3",0.7)
		G.ball(saucer,Vector3(1.5,1.1,2.0),Vector3(0,-0.3,2),"806db4")
		G.ball(saucer,Vector3(1.0,0.7,2.0),Vector3(0,-0.3,3),"9fffe2",0.8)
		add_ship_eyes(saucer)
		return saucer
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
	if kind >= 0:
		add_ship_eyes(p)
		if kind == 0:
			p.scale = Vector3(0.75,0.85,1.1)
			G.box(p,Vector3(0.2,1.1,1.9),Vector3(0,1.2,0.4),"ff82bc")
		else:
			for i in 5:
				G.box(p,Vector3(0.8,0.5,0.6),Vector3((i%2*2-1)*2.0,0.2,i*0.7-1),["ff9a91","ffe49d","92e4cb"][i%3])
			G.link(p,Vector3(1,0.5,0),Vector3(1.3,2.2,0),0.05,"cfabf0")
			G.star(p,0.3,Vector3(1.3,2.2,0))
	return p

static func add_ship_eyes(root: Node3D) -> void:
	for side in [-1.0,1.0]:
		G.ball(root,Vector3(0.48,0.55,0.3),Vector3(side*0.48,0.9,0.9),"fff9df")
		G.ball(root,Vector3(0.2,0.3,0.12),Vector3(side*0.48,0.9,1.05),"333557")

static func flower(root: Node3D, at: Vector3, size: float = 1.0) -> Node3D:
	var p := Node3D.new()
	root.add_child(p)
	p.position = at
	p.scale = Vector3.ONE * size
	G.tube(p,0.3,2,Vector3(0,1,0),"62bca4",0.18)
	G.ball(p,Vector3(2.4,0.6,2.4),Vector3(0,2.0,0),"ffe4a0",0.15)
	for i in 8:
		var hinge := Node3D.new()
		p.add_child(hinge)
		hinge.name = "Petal%d" % i
		hinge.position.y = 2
		hinge.rotation.y = i * TAU / 8
		G.ball(hinge,Vector3(1.0,0.35,3.5),Vector3(0,0,1.7),"ff94b5")
	return p

static func arch(root: Node3D, at: Vector3) -> Node3D:
	var p := Node3D.new()
	root.add_child(p)
	p.position = at
	for i in 13:
		var a := i * PI / 12
		G.ball(p,Vector3(2,2,2),Vector3(cos(a)*7,sin(a)*7,0),"e3b081")
	return p
