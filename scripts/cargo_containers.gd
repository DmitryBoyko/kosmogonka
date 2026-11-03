extends RefCounted
const SM=preload("res://scripts/salvage_mesh.gd")
const Mat=preload("res://scripts/salvage_materials.gd")
const NAMES := ["Экспедиционный", "Грузовой", "Медицинский", "Полевой", "Рифлёный кофр", "Шестигранная цистерна", "Двойной криоблок", "Клиновидный сейф", "Капсула семян", "Биореактор", "Кассетный сервер", "Сферический резервуар", "Тройной баллон", "Асимметричный технобокс"]
const COLORS := ["70b8ca","e7a266","c6e3dc","9b94cc","e1a276","73bed5","b7cfe8","d69d9a","9ecf91","72c8b3","a793d5","d0b77f","a1bad5","d58bb3"]
static var finishes: Dictionary = {}
static var prototypes: Dictionary = {}

static func coating(variant: int) -> ShaderMaterial:
	if finishes.has(variant): return finishes[variant]
	var m := Mat.material(["hull-titanium","hull-ceramic","hull-salvage"][variant%3]).duplicate() as ShaderMaterial
	m.set_shader_parameter("finish_pattern",variant-4)
	m.set_shader_parameter("tint",Color(COLORS[variant]))
	m.set_shader_parameter("accent",Color(COLORS[(variant+5)%14]))
	m.set_shader_parameter("metalness",0.2 if variant%3==1 else 0.55)
	finishes[variant]=m
	return m

static func vessel(root: Node3D, radius: float, height: float, at: Vector3, mat: Material, sides: int=20) -> void:
	var n:=SM._cylinder(root,radius,height,at,mat,radius*0.86)
	(n.mesh as CylinderMesh).radial_segments=sides

static func new_model(variant: int) -> Node3D:
	var root:=Node3D.new()
	var hull:=coating(variant)
	var trim:=Mat.material("hull-titanium",true)
	var metal_mat:=Mat.material("hull-titanium")
	var glow:=Mat.glow(Color(COLORS[variant]).lightened(0.35))
	match variant:
		4:
			SM.block(root,Vector3(1.8,2.1,1.5),Vector3(0,1.2,0),hull,0.2)
			for i in 7: SM.block(root,Vector3(1.98,0.08,1.62),Vector3(0,0.36+i*0.28,0),metal_mat,0.18)
		5:
			vessel(root,0.96,2.15,Vector3(0,1.22,0),hull,6)
			for y in [0.3,2.2]: vessel(root,1.0,0.13,Vector3(0,y,0),trim,6)
			vessel(root,0.23,0.18,Vector3(0,2.4,0),metal_mat)
		6:
			for side in [-1,1]:
				vessel(root,0.48,2.15,Vector3(side*0.5,1.25,0),hull)
				for y in [0.45,1.85]: vessel(root,0.51,0.12,Vector3(side*0.5,y,0),metal_mat)
			SM.block(root,Vector3(2.05,0.2,1.18),Vector3(0,0.2,0),trim)
			SM.block(root,Vector3(1.8,0.15,0.7),Vector3(0,2.35,0),hull)
		7:
			var body:=SM.block(root,Vector3(2.0,1.8,1.55),Vector3(0,1.05,0),hull,0.32)
			body.rotation.z=0.10
			SM.block(root,Vector3(1.35,0.48,1.15),Vector3(-0.18,2.12,0),metal_mat,0.28)
			for side in [-1,1]: SM.block(root,Vector3(0.16,1.6,1.68),Vector3(side*0.75,1.1,0),trim)
		8:
			var capsule:=CapsuleMesh.new(); capsule.radius=0.77; capsule.height=2.45
			SM._part(root,capsule,hull,Vector3(0,1.3,0))
			for y in [0.7,1.3,1.9]: vessel(root,0.8,0.09,Vector3(0,y,0),trim)
			for side in [-1,1]: SM.block(root,Vector3(0.2,1.4,0.35),Vector3(side*0.81,1.15,0),metal_mat)
		9:
			vessel(root,0.8,1.95,Vector3(0,1.2,0),hull,12)
			for i in 6:
				var a:=i*TAU/6
				SM.limb(root,[Vector3(cos(a)*0.7,0.3,sin(a)*0.7),Vector3(cos(a+0.3)*0.96,1.2,sin(a+0.3)*0.96),Vector3(cos(a+0.6)*0.7,2.2,sin(a+0.6)*0.7)],[0.065,0.065,0.065],metal_mat)
			vessel(root,0.48,0.3,Vector3(0,2.3,0),trim)
		10:
			for i in 5:
				SM.block(root,Vector3(1.85-i*0.07,0.37,1.45),Vector3(0,0.4+i*0.43,0),hull,0.16)
				SM.block(root,Vector3(0.6,0.045,0.03),Vector3(0,0.4+i*0.43,0.74),glow,0.01)
			for side in [-1,1]: SM.block(root,Vector3(0.15,2.25,0.25),Vector3(side*0.9,1.22,-0.62),trim)
		11:
			var sphere:=SphereMesh.new(); sphere.radius=0.91; sphere.height=1.82
			SM._part(root,sphere,hull,Vector3(0,1.22,0))
			for side in [-1,1]:
				SM.block(root,Vector3(0.19,2.3,1.65),Vector3(side*0.93,1.23,0),trim)
			for y in [0.2,2.25]: SM.block(root,Vector3(2.02,0.16,1.8),Vector3(0,y,0),metal_mat,0.25)
			vessel(root,0.25,0.3,Vector3(0,2.15,0),metal_mat)
		12:
			for i in 3:
				var a:=i*TAU/3+PI*0.5
				var at:=Vector3(cos(a)*0.52,1.2,sin(a)*0.52)
				vessel(root,0.48,2.0,at,hull)
				vessel(root,0.25,0.25,at+Vector3.UP*1.12,metal_mat)
			for y in [0.35,1.9]: vessel(root,1.02,0.13,Vector3(0,y,0),trim,3)
		13:
			SM.block(root,Vector3(1.25,2.1,1.6),Vector3(-0.35,1.25,0),hull,0.22)
			SM.block(root,Vector3(0.7,1.55,1.25),Vector3(0.64,0.98,0.08),metal_mat,0.25)
			SM.block(root,Vector3(1.3,0.2,1.68),Vector3(-0.35,2.4,0),trim,0.22)
			for i in 4: SM.block(root,Vector3(0.5,0.055,0.025),Vector3(0.62,0.7+i*0.23,0.72),trim,0.01)
	# Common production details: grounded skids, protected corners, recessed access,
	# attached handles, hinges, locking dogs and identity beacons.
	for side in [-1,1]:
		SM.block(root,Vector3(0.32,0.17,1.65),Vector3(side*0.61,0.10,0),trim,0.06)
		SM.limb(root,[Vector3(side*0.95,1.15,-0.22),Vector3(side*1.06,1.32,-0.22),Vector3(side*1.06,1.32,0.22),Vector3(side*0.95,1.15,0.22)],[0.045,0.045,0.045,0.045],metal_mat,8)
		SM.block(root,Vector3(0.18,0.3,0.09),Vector3(side*0.55,1.95,0.8),trim,0.035)
		SM.block(root,Vector3(0.08,0.14,0.04),Vector3(side*0.55,1.95,0.86),metal_mat,0.015)
	SM.block(root,Vector3(0.65,0.42,0.04),Vector3(0,0.93,0.83),trim,0.05)
	for i in 3: SM.block(root,Vector3(0.08,0.14,0.025),Vector3((i-1)*0.16,0.93,0.87),glow,0.008)
	beacon(root,Vector3(0.44,1.48,0.86),variant)
	SM.batch(root)
	return root

static func fitted(variant: int, size: Vector3) -> Node3D:
	variant=posmod(variant,NAMES.size())
	if not prototypes.has(variant):
		var source:=crate(variant,variant) if variant<4 else new_model(variant)
		var parts: Array=[]
		var bounds:=AABB()
		var first:=true
		for child: MeshInstance3D in source.get_children():
			parts.append([child.mesh,child.material_override,child.transform])
			var box: AABB=child.transform*child.mesh.get_aabb()
			bounds=box if first else bounds.merge(box); first=false
		prototypes[variant]={"parts":parts,"bounds":bounds}
		source.free()
	var data: Dictionary=prototypes[variant]
	var root:=Node3D.new(); root.name="Cargo_"+str(variant)
	root.set_meta("container_variant",variant); root.set_meta("container_name",NAMES[variant])
	root.set_meta("dimensions_m",size)
	var model:=Node3D.new(); root.add_child(model)
	model.scale=size/data.bounds.size
	model.position=-(data.bounds.position+Vector3(data.bounds.size.x*0.5,0,data.bounds.size.z*0.5))*model.scale
	for item: Array in data.parts:
		var child:=SM._part(model,item[0],item[1]); child.transform=item[2]
	return root

static func obstacle(kind: String, variant: int) -> Node3D:
	if kind=="barrier": return fitted(variant,Vector3(2.08,0.98,1.08))
	if kind=="wall": return fitted(variant,Vector3(2.1,2.9,1.7))
	var root:=Node3D.new()
	SM.block(root,Vector3(2.15,0.32,14),Vector3(0,0.2,0),Mat.material("hull-titanium",true))
	for i in 3:
		var c:=fitted(variant+i,Vector3(2.08,2.55,3.8)); root.add_child(c); c.position=Vector3(0,0.42,(i-1)*4.2)
	# Continuous flat catwalk bridges the gaps between differently shaped containers.
	var deck:=BoxMesh.new(); deck.size=Vector3(2.08,.055,14)
	SM._part(root,deck,preload("res://scripts/hover_transport.gd").paint(0,"deck"),Vector3(0,3.0-.0275,0))
	return root
static func metal(key: String,tint: Color=Color.WHITE) -> ShaderMaterial:
	var mat := Mat.material(key).duplicate() as ShaderMaterial
	mat.set_shader_parameter("tint",tint); mat.set_shader_parameter("metalness",.4); mat.set_shader_parameter("roughness",.8)
	return mat

static func beacon(root: Node3D,at: Vector3,seed_value: int) -> void:
	SM.block(root,Vector3(.17,.16,.11),at,Mat.material("hull-titanium",true),.025)
	SM.block(root,Vector3(.105,.07,.025),at+Vector3(0,.015,.062),Mat.glow(Color("ffd08c")),.018)

static func crate(seed_value: int,variant: int) -> Node3D:
	var root := Node3D.new(); root.name = "GroundedCargo"+str(variant)
	var sizes := [Vector3(1.5,1.05,1.15),Vector3(2.8,1.75,1.85),Vector3(1.1,.70,.75),Vector3(1.6,1.15,1.0)]
	var size: Vector3 = sizes[variant%4]; var w := size.x; var h := size.y; var d := size.z
	var hull := metal(["hull-titanium","hull-salvage","hull-ceramic","hull-titanium"][variant%4],[Color("9bada8"),Color("b19b77"),Color("9eb4b6"),Color("829b87")][variant%4])
	var trim := metal("hull-titanium",Color("414c52")); var inset := metal("hull-salvage",Color("556064"))
	root.set_meta("surface_kind","container"); root.set_meta("dimensions_m",size)
	SM.block(root,Vector3(w,h-.13,d),Vector3(0,h*.5-.015,0),hull,.13)
	# Separate gasket, armoured lid, corner protectors, hinge pins and recessed panel.
	SM.block(root,Vector3(w+.04,.05,d+.04),Vector3(0,h-.10,0),trim,.12)
	SM.block(root,Vector3(w+.06,.13,d+.06),Vector3(0,h+.01,0),hull,.14)
	SM.block(root,Vector3(w*.68,h*.56,.035),Vector3(0,h*.45,d*.5+.01),inset,.06)
	for side in [-1,1]:
		SM.block(root,Vector3(.13,h+.06,.15),Vector3(side*(w*.5-.06),h*.5,d*.5-.045),trim,.035)
		SM.block(root,Vector3(.13,h+.06,.15),Vector3(side*(w*.5-.06),h*.5,-d*.5+.045),trim,.035)
		SM.block(root,Vector3(.18,.25,.085),Vector3(side*w*.26,h-.14,d*.5+.055),trim,.035)
		SM.block(root,Vector3(.075,.12,.035),Vector3(side*w*.26,h-.13,d*.5+.11),hull,.012)
		SM.limb(root,[Vector3(side*w*.26-.13,h-.07,-d*.5-.025),Vector3(side*w*.26+.13,h-.07,-d*.5-.025)],[.055,.055],trim,8)
		SM.block(root,Vector3(.20,.12,d*.88),Vector3(side*w*.32,.025,0),trim,.04)
	# Closed handles have two mounted feet and a connected crosspiece.
	for side in [-1,1]:
		var x: float = side*(w*.5+.045)
		SM.limb(root,[Vector3(x,h*.48,-.18),Vector3(x+side*.08,h*.58,-.18),Vector3(x+side*.08,h*.58,.18),Vector3(x,h*.48,.18)],[.035,.035,.035,.035],trim,6)
	for i in 3:
		SM.block(root,Vector3(w*.09,.045,.018),Vector3((i-1)*w*.14,h*.40,d*.5+.04),hull,.006)
	beacon(root,Vector3(w*.34,h*.72,d*.5+.075),seed_value)
	SM.batch(root)
	return root
