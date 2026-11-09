extends RefCounted
const G=preload("res://scripts/geometry.gd")
const Mat=preload("res://scripts/salvage_materials.gd")

static func starfield(root:Node3D,world:int=0) -> void:
	var mesh:=SphereMesh.new(); mesh.radius=900; mesh.height=1800; mesh.radial_segments=48; mesh.rings=24
	var material:=ShaderMaterial.new(); material.shader=preload("res://assets/spaceflight/starfield.gdshader")
	material.set_shader_parameter("stars_map",preload("res://scripts/space_backdrops.gd").texture(world))
	var sky:=G.part(root,mesh,Vector3.ZERO,material); sky.name="DeepStarfield"; sky.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sky.rotation=Vector3(.30,.45,.32)
	preload("res://scripts/space_backdrops.gd").apply(root,world)

static func beacon() -> Node3D:
	var root:=Node3D.new(); root.name="NavigationBuoys"
	for side in [-1,1]:
		G.ball(root,Vector3(.22,.15,.42),Vector3(side*7.4,-.55,0),"86c5d7",.25)
		G.box(root,Vector3(.045,.025,1.15),Vector3(side*7.4,-.58,.58),"526f89",.1)
	G.batch(root); return root

static func charge() -> Node3D:
	var root:=Node3D.new(); root.name="IonCharge"
	var core:=G.ball(root,Vector3(.65,1.15,.65),Vector3.ZERO,"9ce7f2",.65)
	core.rotation.z=.35
	for side in [-1,1]:
		var fin:=G.box(root,Vector3(.055,.48,.10),Vector3(side*.32,0,0),"ffe3ab",.35)
		fin.rotation.z=side*-.5
	return root

static func port() -> Node3D:
	var root:=Node3D.new(); root.name="OrbitalPort"
	var dark:=Mat.material("hull-titanium",true)
	G.tube(root,1.8,5,Vector3(0,0,0),"647381").material_override=dark
	G.ball(root,Vector3(5,1.5,5),Vector3(0,2.1,0),"a4b2ba").material_override=Mat.material("hull-titanium")
	for side in [-1,1]:
		G.link(root,Vector3(0,1,0),Vector3(side*8,1,0),.18,"778e9e")
		for i in 4:
			G.box(root,Vector3(3.2,.12,2.8),Vector3(side*(4.6+(i%2)*3.5),1.,(int(i/2)-.5)*3.2),"203b5a")
			for line in 5: G.box(root,Vector3(3.0,.015,.025),Vector3(side*(4.6+(i%2)*3.5),1.07,(int(i/2)-.5)*3.2+(line-2)*.48),"547a98")
	var cargo:Node3D=preload("res://assets/spaceflight/craft-cargoa.glb").instantiate(); root.add_child(cargo); cargo.scale=Vector3.ONE*4; cargo.position=Vector3(-4,-2.5,4)
	var dish:Node3D=preload("res://assets/spaceflight/satellitedish-detailed.glb").instantiate(); root.add_child(dish); dish.position=Vector3(0,2.6,0); dish.scale=Vector3.ONE*3.0
	preload("res://scripts/space_ship.gd").center_asset(cargo); cargo.position+=Vector3(-4,-2.5,4)
	preload("res://scripts/space_ship.gd").center_asset(dish); dish.position+=Vector3(0,2.6,0)
	root.remove_child(cargo); root.remove_child(dish)
	G.batch(root)
	root.add_child(cargo); root.add_child(dish)
	return root
