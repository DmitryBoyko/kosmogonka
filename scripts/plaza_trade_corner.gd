extends RefCounted

const G = preload("res://scripts/geometry.gd")
const Bounds = preload("res://scripts/loop_layout.gd")
const Planets = preload("res://scripts/planets.gd")
const KIT := "res://assets/finish_city/trade/"
const BUNKER := "res://assets/finish_city/bunker/"
static var models: Dictionary = {}

static func place(root: Node3D, model_name: String, at: Vector3, width: float, yaw: float=0.) -> Node3D:
	if not models.has(model_name): models[model_name]=load(KIT+model_name+".gltf")
	var model: Node3D = models[model_name].instantiate()
	var bounds := Bounds.bounds(model,Transform3D.IDENTITY)
	var fit := width / maxf(bounds.size.x,bounds.size.z)
	var holder := Node3D.new()
	holder.set_meta("motion",model_name.begins_with("Enemy"))
	root.add_child(holder)
	holder.add_child(model)
	model.scale=Vector3.ONE*fit
	model.position=-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*fit
	holder.rotation.y=yaw
	holder.position=at
	if model_name.begins_with("Enemy"):
		for player: AnimationPlayer in model.find_children("*","AnimationPlayer",true,false):
			for clip: String in player.get_animation_list():
				if clip.to_lower().contains("idle"):
					player.get_animation(clip).loop_mode=Animation.LOOP_LINEAR
					player.play(clip)
					break
	return holder

static func bunker_panel(root: Node3D, model_name: String, at: Vector3, size: Vector3, yaw: float=0.) -> void:
	if not models.has(model_name): models[model_name]=load(BUNKER+model_name+".gltf")
	var model: Node3D = models[model_name].instantiate()
	var bounds := Bounds.bounds(model,Transform3D.IDENTITY)
	var holder := Node3D.new()
	root.add_child(holder)
	holder.add_child(model)
	holder.position=at
	holder.rotation.y=yaw
	model.scale=size/bounds.size
	model.position=-bounds.get_center()*model.scale

static func build_bunker(root: Node3D, accent: String) -> void:
	bunker_panel(root,"Platform_DarkPlates",Vector3(0,-.035,-.48),Vector3(12.4,.16,9.1))
	bunker_panel(root,"Platform_Metal",Vector3(0,4.65,-.48),Vector3(12.8,.50,9.5))
	for side in [-1.,1.]:
		G.box(root,Vector3(.22,4.47,8.75),Vector3(side*6.14,2.25,-.49),"233247")
		G.box(root,Vector3(3.7,4.47,.18),Vector3(side*4.20,2.25,3.74),"26374c")
		bunker_panel(root,"ShortWall_MetalPlates_Straight",Vector3(side*6.0,2.28,-.48),Vector3(8.9,4.5,.40),PI/2.)
		bunker_panel(root,"ShortWall_AccentStrip_Straight",Vector3(side*4.2,2.28,3.85),Vector3(3.7,4.5,.40))
		bunker_panel(root,"Prop_Light_Wide",Vector3(side*3.4,4.25,-.9),Vector3(2.05,.24,.42))
	bunker_panel(root,"ShortWall_MetalPlates_Straight",Vector3(0,2.28,-4.83),Vector3(12.3,4.5,.40))
	G.box(root,Vector3(12.3,4.47,.18),Vector3(0,2.25,-4.97),"26374c")
	bunker_panel(root,"Door_Frame_Square",Vector3(0,2.15,3.82),Vector3(4.75,4.3,.58))
	bunker_panel(root,"Prop_Vent_Wide",Vector3(0,3.7,-4.51),Vector3(2.6,.54,.22))
	var light := OmniLight3D.new()
	light.position=Vector3(0,3.8,.5)
	light.light_color=Color(accent).lerp(Color.WHITE,.65)
	light.light_energy=2.4
	light.omni_range=10.
	root.add_child(light)

static func build(world: int) -> Node3D:
	var root := Node3D.new()
	root.name="ExpeditionTradeCorner"
	var accent: String = Planets.get_data(world).accent
	build_bunker(root,accent)
	G.box(root,Vector3(4.3,.075,.15),Vector3(0,.069,4.23),accent,.58)
	G.label(root,"АРСЕНАЛ ЭКСПЕДИЦИИ",Vector3(0,4.17,4.25),33)
	var desk := place(root,"Prop_Desk_Medium",Vector3(-.55,0,-.15),3.5)
	var desk_bounds := Bounds.bounds(desk,Transform3D.IDENTITY)
	var tabletop := desk_bounds.end.y
	root.set_meta("tabletop",tabletop)
	for item in [["Gun_Pistol",Vector3(-1.5,tabletop,-.18),.8,.25],["Gun_Rifle",Vector3(-.45,tabletop,-.18),1.45,-.12]]:
		lay_weapon(root,item[0],item[1],item[2],item[3])
	place(root,"Prop_Shelves_WideTall",Vector3(-3.3,0,-2.76),2.85)
	place(root,"Prop_Shelves_WideTall",Vector3(3.3,0,-2.76),2.85)
	for row in [["Gun_SMG_Ammo",-3.35,1.12,-2.54,1.18,.08],["Gun_Pistol",-3.52,1.91,-2.60,.8,-.20],
		["Gun_Rifle",3.34,1.95,-2.58,1.45,.0],["Prop_HealthPack",3.3,1.12,-2.48,.85,.30],
		["Prop_Ammo_Closed",1.70,0,-2.7,.75,.3],["Prop_Crate",-4.5,0,.42,.92,-.26],
		["Enemy_Trilobite",-.05,0,-2.6,1.6,-.12]]:
		place(root,row[0],Vector3(row[1],row[2],row[3]),row[4],row[5])
	var spider := preload("res://scripts/bunker_spider.gd").new()
	root.add_child(spider)
	spider.build(tabletop)
	for side in [-1.,1.]:
		for shelf_y in [1.12,1.95,2.70]:
			G.box(root,Vector3(2.7,.045,.045),Vector3(side*3.3,shelf_y,-2.30),accent,.65)
	preload("res://scripts/arcade_materials.gd").apply(root,world)
	G.merge_static(root)
	var guard := preload("res://scripts/bunker_guard.gd").new()
	root.add_child(guard)
	guard.build()
	root.set_meta("trade_boxes",[
		AABB(Vector3(-6.25,0,-5),Vector3(.5,4.5,9.1)),
		AABB(Vector3(5.75,0,-5),Vector3(.5,4.5,9.1)),
		AABB(Vector3(-6.,0,-5),Vector3(12.,4.5,.4)),
		AABB(Vector3(-6.,0,3.65),Vector3(3.9,4.5,.4)),
		AABB(Vector3(2.1,0,3.65),Vector3(3.9,4.5,.4)),
		AABB(Vector3(-6.25,4.42,-5.2),Vector3(12.5,.45,9.5)),
		AABB(Vector3(-2.3,0,-.7833),Vector3(3.5,tabletop,1.2666)),
		AABB(Vector3(-4.72,0,-3.18),Vector3(2.84,2.75,.84)),
		AABB(Vector3(1.88,0,-3.18),Vector3(2.84,2.75,.84)),
	])
	return root

static func lay_weapon(root: Node3D, key: String, at: Vector3, width: float, yaw: float) -> void:
	var weapon := place(root,key,Vector3.ZERO,width)
	weapon.rotation=Vector3(PI*.5,yaw,0.)
	var bounds := Bounds.bounds(weapon,Transform3D(weapon.basis,Vector3.ZERO))
	weapon.position=at-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)+Vector3.UP*.012
	weapon.set_meta("display_weapon",true)
