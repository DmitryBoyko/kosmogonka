extends RefCounted
const Planets=preload("res://scripts/planets.gd")
const G=preload("res://scripts/geometry.gd")
const SM=preload("res://scripts/salvage_mesh.gd")
const Mat=preload("res://scripts/salvage_materials.gd")
const Garden=preload("res://scripts/city_garden.gd")
const Windows=preload("res://scripts/city_windows.gd")
const Residents=preload("res://scripts/city_residents.gd")
const MODELS:=["hangar-largea","hangar-largeb","hangar-roundglass","hangar-rounda","structure-detailed","structure-closed"]
const FAMILIES:=[["hangar-rounda","structure-detailed"],["hangar-roundglass","hangar-rounda"],["hangar-largea","hangar-largeb"],["structure-closed","structure-detailed"]]
static var materials:Dictionary={}
static var scenes:Dictionary={}
static func coating(name_value: String, planet: int) -> Material:
	var key:=name_value+str(planet)
	if materials.has(key): return materials[key]
	var m:=ShaderMaterial.new(); m.shader=preload("res://assets/finish_city/bio_facade.gdshader")
	m.set_shader_parameter("surface_map",preload("res://assets/finish_city/MetalPlates006_1K-JPG_Color.jpg"))
	var color:=Color("b4cbd9")
	if name_value.contains("Red"): color=Color(["f3a27f","f1b3cb","8edbd5","c5abec"][Planets.biome(planet)])
	elif name_value.contains("Dark"): color=Color("526d88")
	elif name_value=="dark": color=Color("183e58")
	elif name_value=="_defaultMat": color=Color("6bbfc1") if planet==1 else Color("719fbc")
	m.set_shader_parameter("tint",color); m.set_shader_parameter("tile_scale",.4)
	m.set_shader_parameter("metalness",.35); m.set_shader_parameter("roughness",.57)
	materials[key]=m; return m

static func local_transform(piece: Node3D, root: Node3D) -> Transform3D:
	var t:=piece.transform; var parent:=piece.get_parent()
	while parent!=root: t=(parent as Node3D).transform*t; parent=parent.get_parent()
	return t

static func module(root: Node3D, key: String, at: Vector3, size: Vector3, yaw: float, planet: int) -> void:
	if not scenes.has(key): scenes[key]=load("res://assets/finish_city/"+key+".glb")
	var model:Node3D=scenes[key].instantiate(); root.add_child(model); model.rotation.y=yaw
	var bounds:=AABB(); var first:=true
	for piece: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		var t:=local_transform(piece,root)
		var box: AABB=t*piece.mesh.get_aabb(); bounds=box if first else bounds.merge(box); first=false
		for surface in piece.mesh.get_surface_count():
			var original:=piece.mesh.surface_get_material(surface)
			piece.set_surface_override_material(surface,coating(original.resource_name if original else "metal",planet))
	var scale_value:=size/bounds.size
	var holder:=Node3D.new(); root.add_child(holder)
	model.reparent(holder,false); holder.scale=scale_value
	holder.position=at-(bounds.position+Vector3(bounds.size.x*.5,0,bounds.size.z*.5))*scale_value

static func build(planet: int) -> Node3D:
	var root:=Node3D.new(); root.name="FinishCity"
	# Buildings frame an open garden district. No perimeter walls or return gate.
	for side in [-1,1]:
		for i in 5:
			building(root,i,Vector3(side*51,-.225,-59+i*18),side*PI*.5,planet)
		for i in 5:
			if side>0 and i==2: continue
			building(root,i+5,Vector3((i-2)*18,-.225,-76 if side<0 else 28),0 if side<0 else PI,planet)
	var windows:=Node3D.new(); windows.name="WindowBays"; root.add_child(windows)
	for side in [-1,1]:
		for i in 5: Windows.facade(windows,Vector3(side*51,-.225,-59+i*18),[13.,10.,8.,24.][Planets.biome(planet)]+(i%2)*[4.,2.,3.,8.][Planets.biome(planet)],i,planet)
		for i in 5:
			if side>0 and i==2: continue
			Windows.facade(windows,Vector3((i-2)*18,-.225,-76 if side<0 else 28),[13.,10.,8.,24.][Planets.biome(planet)]+((i+5)%2)*[4.,2.,3.,8.][Planets.biome(planet)],i+5,planet)
	G.batch(windows)
	Garden.plaza(root,planet)
	var residents:=Residents.new(); root.add_child(residents); residents.populate(planet)
	root.set_meta("open_approaches",true)
	root.set_meta("models",FAMILIES[Planets.biome(planet)]); root.set_meta("building_count",19); root.set_meta("architecture_family",planet); return root

static func building(root:Node3D,index:int,at:Vector3,yaw:float,planet:int) -> void:
	var group:=Node3D.new(); root.add_child(group); group.name="Building_%d_%d"%[int(at.x),int(at.z)]
	house(group,index,at,yaw,planet)
	batch(group)

static func house(root:Node3D, index:int, at:Vector3, yaw:float, planet:int) -> void:
	var height:float=[13.0,10.0,8.0,24.0][Planets.biome(planet)]+(index%2)*[4.0,2.0,3.0,8.0][Planets.biome(planet)]
	var key:String=FAMILIES[Planets.biome(planet)][index%2]
	module(root,key,at,Vector3(14,height,16),yaw,planet)
	if key.begins_with("structure"):
		# Habitable floors sit inside the downloaded external structural frame.
		SM.block(root,Vector3(12,height-1.2,14),at+Vector3(0,(height-1.2)*.5,0),coating("metal",planet),.3)

	Garden.entrance(root,at,index,planet,height)
	if planet==0 and index%3==0:
		module(root,"satellitedish-detailed",at+Vector3(0,height,0),Vector3(3.5,3,3.5),yaw,planet)
	elif planet==1:
		# Conservatory roof gardens repeat the planet's living green architecture.
		G.box(root,Vector3(10,.5,10),at+Vector3(0,.2,0),"63b894")
		for side in [-1,1]: G.ball(root,Vector3(3.2,2.4,3.2),at+Vector3(side*5,1,6),"7ccf9e")
	elif planet==2:
		# Low sun-shaded pavilions with a broad overhanging canopy.
		SM.block(root,Vector3(15.5,.45,17),at+Vector3(0,height+.2,0),coating("metalRed",planet),.4)
	elif planet==3:
		for floor in range(4,int(height),4):
			G.box(root,Vector3(14.15,.15,16.15),at+Vector3(0,floor,0),"e3a1ff",.35)

static func batch(root: Node3D) -> void:
	var groups:Dictionary={}
	for piece:MeshInstance3D in root.find_children("*","MeshInstance3D",true,false):
		var transform:=local_transform(piece,root)
		for surface in piece.mesh.get_surface_count():
			var mat:Material=piece.get_active_material(surface)
			if not groups.has(mat):
				var tool:=SurfaceTool.new(); tool.begin(Mesh.PRIMITIVE_TRIANGLES); groups[mat]=tool
			var tool:SurfaceTool=groups[mat]; var a:=piece.mesh.surface_get_arrays(surface)
			var vertices:PackedVector3Array=a[Mesh.ARRAY_VERTEX]; var normals:PackedVector3Array=a[Mesh.ARRAY_NORMAL]
			var indices:PackedInt32Array=a[Mesh.ARRAY_INDEX] if a[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
			for i in (indices.size() if not indices.is_empty() else vertices.size()):
				var j:int=indices[i] if not indices.is_empty() else i
				tool.set_normal((transform.basis.inverse().transposed()*normals[j]).normalized())
				if a[Mesh.ARRAY_TEX_UV]!=null: tool.set_uv(a[Mesh.ARRAY_TEX_UV][j])
				tool.add_vertex(transform*vertices[j])
	for label:Label3D in root.find_children("*","Label3D",true,false):
		if label.get_parent()==root: continue
		var transform:=local_transform(label,root)
		label.reparent(root,false); label.transform=transform
	for child in root.get_children():
		if not child is Label3D: child.free()
	for mat:Material in groups:
		var mesh:=SM._part(root,groups[mat].commit(),mat); mesh.set_meta("architecture_solid",true)
