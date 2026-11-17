extends RefCounted
const Planets=preload("res://scripts/planets.gd")
const G=preload("res://scripts/geometry.gd")
const SM=preload("res://scripts/salvage_mesh.gd")
const Mat=preload("res://scripts/salvage_materials.gd")
const Garden=preload("res://scripts/city_garden.gd")
const Windows=preload("res://scripts/city_windows.gd")
const Residents=preload("res://scripts/city_residents.gd")
const Interiors=preload("res://scripts/city_interiors.gd")
const MODELS:=["hangar-largea","hangar-largeb","hangar-roundglass","hangar-rounda","structure-detailed","structure-closed"]
const FAMILIES := [
	["bldg_corner_4st","bldg_apartments_5st"], ["bldg_shop_brick_3st","bldg_shop_stone_4st"],
	["bldg_bank_3st","bldg_shop_brick_2st"], ["bldg_office_tower_10st","bldg_shop_brick_6st"],
]
const WALL_TINTS := ["b8b6eb","a4d6b0","edc186","9d97d9","72c7d1","dac281","b69ad0","b2dbed","b98170","a38cc4","afccde"]
static var materials:Dictionary={}
static var scenes:Dictionary={}
static func horizon(planet:int) -> Node3D:
	var root:=Node3D.new(); root.name="DistantCitySilhouette"
	for side in [-1,1]:
		for i in 5:
			var height:float=[13.,10.,8.,24.][Planets.biome(planet)]+(i%2)*[4.,2.,3.,8.][Planets.biome(planet)]
			for at in [Vector3(side*51,0,-59+i*18),Vector3((i-2)*18,0,-76 if side<0 else 28)]:
				G.box(root,Vector3(14,height,16),at+Vector3(0,height*.5,0),"738b9e")
	G.merge_static(root); return root
static func coating(name_value: String, planet: int) -> Material:
	var key:=name_value+str(Planets.biome(planet))
	if materials.has(key): return materials[key]
	var m:=ShaderMaterial.new(); m.shader=preload("res://assets/finish_city/bio_facade.gdshader")
	var accent:=name_value.contains("Red")
	m.set_shader_parameter("surface_map",preload("res://assets/finish_city/exterior_wall_cladding_02_diff_1k.jpg") if accent else preload("res://assets/finish_city/concrete_wall_006_diff_1k.jpg"))
	m.set_shader_parameter("normal_map",preload("res://assets/finish_city/exterior_wall_cladding_02_nor_gl_1k.jpg") if accent else preload("res://assets/finish_city/concrete_wall_006_nor_gl_1k.jpg"))
	m.set_shader_parameter("roughness_map",preload("res://assets/finish_city/exterior_wall_cladding_02_rough_1k.jpg") if accent else preload("res://assets/finish_city/concrete_wall_006_rough_1k.jpg"))
	var color:=Color(["dbe4e8","d4e1ce","f1dec2","a2b7c8"][Planets.biome(planet)])
	if accent: color=Color(["e4b99f","dabdb2","eacb9b","c3b7d5"][Planets.biome(planet)])
	elif name_value.to_lower().contains("dark"): color=Color("7d91a3")
	m.set_shader_parameter("tint",color); m.set_shader_parameter("tile_scale",.45)
	m.set_shader_parameter("metalness",.08 if accent else .16); m.set_shader_parameter("roughness",.83)
	m.set_shader_parameter("normal_strength",.4); m.set_shader_parameter("panel_weight",.18 if accent else .55)
	materials[key]=m; return m

static func local_transform(piece: Node3D, root: Node3D) -> Transform3D:
	var t:=piece.transform; var parent:=piece.get_parent()
	while parent!=root: t=(parent as Node3D).transform*t; parent=parent.get_parent()
	return t

static func downtown_material(original: StandardMaterial3D, planet: int) -> Material:
	var name_value := original.resource_name
	var style := Planets.style_index(planet)
	var key := "downtown/%s/%d/%s"%[name_value,style,Planets.get_data(planet).accent]
	if materials.has(key): return materials[key]
	var material := original.duplicate() as StandardMaterial3D
	var accent := Color(Planets.get_data(planet).accent)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if name_value.contains("glass"):
		material.albedo_color = material.albedo_color.lerp(accent, .26)
		material.roughness = maxf(material.roughness,.26)
		material.emission_enabled = true
		material.emission = Color("ffc98c").lerp(accent,.30)
		material.emission_energy_multiplier = .58
		if name_value=="mat_glass_clear":
			material.albedo_color.a=.12
			material.emission_energy_multiplier=.05
	elif name_value.contains("roof") or name_value.contains("dark"):
		material.albedo_color = material.albedo_color.lerp(accent.darkened(.71),.55)
	else:
		material.albedo_color = Color(WALL_TINTS[style]).lerp(Color.WHITE,.21)
	if material.normal_texture:
		material.normal_scale = .55
		material.roughness_texture = null
		material.roughness = .82
	materials[key]=material
	return material

static func module(root: Node3D, key: String, at: Vector3, size: Vector3, yaw: float, planet: int) -> Dictionary:
	var from_kit := key.begins_with("bldg_")
	if not scenes.has(key):
		var location := "downtown/models/buildings/"+key+".gltf" if from_kit else key+".glb"
		scenes[key]=load("res://assets/finish_city/"+location)
	var model:Node3D=scenes[key].instantiate(); root.add_child(model); model.rotation.y=yaw
	var bounds:=AABB(); var first:=true
	var front_window := AABB()
	for piece: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		var t:=local_transform(piece,root)
		var box: AABB=t*piece.mesh.get_aabb(); bounds=box if first else bounds.merge(box); first=false
		for surface in piece.mesh.get_surface_count():
			var original:=piece.mesh.surface_get_material(surface)
			piece.set_surface_override_material(surface,downtown_material(original,planet) if from_kit and original is StandardMaterial3D else coating(original.resource_name if original else "metal",planet))
			if from_kit and original and original.resource_name=="mat_glass_clear":
				front_window=Interiors.front_window(piece.mesh.surface_get_arrays(surface))
	var scale_value:=size/bounds.size
	var holder:=Node3D.new(); root.add_child(holder)
	model.reparent(holder,false); holder.scale=scale_value
	holder.position=at-(bounds.position+Vector3(bounds.size.x*.5,0,bounds.size.z*.5))*scale_value
	if not front_window.has_surface(): return {}
	var facing := Basis(Vector3.UP,yaw)
	var front := holder.position+(facing*front_window.get_center())*scale_value
	front.y=at.y
	return {"front":front,"yaw":yaw,"width":front_window.size.x*(facing.x.abs().dot(scale_value)),
		"height":front_window.end.y*scale_value.y,"depth_scale":facing.z.abs().dot(scale_value)}

static func build(planet: int) -> Node3D:
	var root:=Node3D.new(); root.name="FinishCity"
	root.set_meta("stream_partition",true)
	root.set_meta("downtown_kit",true)
	var interiors:=Interiors.new()
	interiors.name="WindowInteriors"
	# Buildings frame an open garden district. No perimeter walls or return gate.
	for side in [-1,1]:
		for i in 5:
			building(root,interiors,i,Vector3(side*51,-.225,-59+i*18),side*PI*.5,planet)
		for i in 5:
			if side>0 and i==2: continue
			building(root,interiors,i+5,Vector3((i-2)*18,-.225,-76 if side<0 else 28),PI if side<0 else 0.,planet)
	root.add_child(interiors)
	add_urban_park(root,planet)
	var residents:=Residents.new(); root.add_child(residents); residents.populate(planet)
	root.set_meta("flower_gardens",true)
	root.set_meta("open_approaches",true)
	root.set_meta("models",FAMILIES[Planets.biome(planet)]); root.set_meta("building_count",19); root.set_meta("architecture_family",planet); return root

static func add_urban_park(root: Node3D, planet: int) -> void:
	var park := Node3D.new()
	park.name="UrbanPark"
	root.add_child(park)
	var style := Planets.style_index(planet)
	var accent := Color(Planets.get_data(planet).accent)
	var names := ["park-pavilion","park-vendor","park-shelter"]
	var spots := [
		Vector3(-35.,-.225,-54.),Vector3(35.,-.225,-53.),Vector3(34.,-.225,17.)
	]
	for i in spots.size():
		var group := Node3D.new()
		park.add_child(group)
		var key: String = names[(i+style)%names.size()]
		if not scenes.has(key): scenes[key]=load("res://assets/finish_city/urban_park/"+key+".glb")
		var model: Node3D = scenes[key].instantiate()
		group.add_child(model)
		var bounds := AABB()
		var first := true
		for piece: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
			var box := local_transform(piece,group)*piece.mesh.get_aabb()
			bounds=box if first else bounds.merge(box)
			first=false
			for surface in piece.mesh.get_surface_count():
				var source := piece.mesh.surface_get_material(surface) as StandardMaterial3D
				if not source: continue
				var base := source.albedo_color
				var foliage := base.g>base.r*1.15 and base.g>base.b*1.12
				var tone := base.lerp(Color(WALL_TINTS[style]),.70 if not foliage else .28)
				if base.r>base.g*1.4: tone=tone.lerp(accent,.66)
				piece.set_surface_override_material(surface,preload("res://scripts/arcade_materials.gd").coating(tone,accent,style,foliage))
		var size := Vector3(7.4,4.1,4.9) if key=="park-pavilion" else Vector3(5.5,3.6,4.2)
		model.scale=size/bounds.size.max(Vector3.ONE*.001)
		model.position=-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*model.scale
		group.position=spots[i]
		group.rotation.y=PI*.5 if spots[i].x<0. else -PI*.5
		G.merge_static(group)
		var collision: Array = root.get_meta("collision_boxes",[])
		var extent := Vector3(size.z,size.y,size.x)
		collision.append(AABB(group.position-Vector3(extent.x*.5,0.,extent.z*.5),extent))
		root.set_meta("collision_boxes",collision)

static func building(root:Node3D,interiors:Node3D,index:int,at:Vector3,yaw:float,planet:int) -> void:
	var bounds:Array=root.get_meta("collision_boxes",[])
	var height:float=[13.,10.,8.,24.][Planets.biome(planet)]+(index%2)*[4.,2.,3.,8.][Planets.biome(planet)]
	bounds.append(AABB(at-Vector3(7,0,8),Vector3(14,height,16))); root.set_meta("collision_boxes",bounds)
	var group:=Node3D.new(); root.add_child(group); group.name="Building_%d_%d"%[int(at.x),int(at.z)]
	var window:=house(group,index,at,yaw,planet)
	preload("res://scripts/arcade_materials.gd").apply(group,planet)
	batch(group)
	if not window.is_empty(): interiors.add_room(window,planet)

static func house(root:Node3D, index:int, at:Vector3, yaw:float, planet:int) -> Dictionary:
	var height:float=[13.0,10.0,8.0,24.0][Planets.biome(planet)]+(index%2)*[4.0,2.0,3.0,8.0][Planets.biome(planet)]
	var key:String=FAMILIES[Planets.biome(planet)][index%2]
	var window:=module(root,key,at,Vector3(14,height,16),yaw,planet)
	Garden.entrance(root,at,index,planet,height)
	if planet==0 and index%3==0:
		module(root,"satellitedish-detailed",at+Vector3(0,height,0),Vector3(3.5,3,3.5),yaw,planet)
	elif planet==1:
		# Conservatory roof gardens repeat the planet's living green architecture.
		G.box(root,Vector3(10,.5,10),at+Vector3(0,.2,0),"63b894")
		for side in [-1,1]: G.ball(root,Vector3(3.2,2.4,3.2),at+Vector3(side*5,1,6),"7ccf9e")
	return window

static func batch(root: Node3D) -> void:
	var groups:Dictionary={}
	for piece:MeshInstance3D in root.find_children("*","MeshInstance3D",true,false):
		var transform:=local_transform(piece,root)
		for surface in piece.mesh.get_surface_count():
			var mat:Material=piece.get_active_material(surface)
			if not groups.has(mat):
				var tool:=SurfaceTool.new(); tool.begin(Mesh.PRIMITIVE_TRIANGLES); groups[mat]=tool
			var tool:SurfaceTool=groups[mat]
			tool.append_from(piece.mesh,surface,transform)
	for label:Label3D in root.find_children("*","Label3D",true,false):
		if label.get_parent()==root: continue
		var transform:=local_transform(label,root)
		label.reparent(root,false); label.transform=transform
	for child in root.get_children():
		if not child is Label3D: child.free()
	for mat:Material in groups:
		var mesh:=SM._part(root,groups[mat].commit(),mat); mesh.set_meta("architecture_solid",true)
