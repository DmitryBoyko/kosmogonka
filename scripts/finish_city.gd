extends RefCounted
const G=preload("res://scripts/geometry.gd")
const SM=preload("res://scripts/salvage_mesh.gd")
const Mat=preload("res://scripts/salvage_materials.gd")
const MODELS:=["hangar-largea","hangar-largeb","hangar-roundglass","hangar-rounda","structure-detailed","structure-closed"]
const FAMILIES:=[["hangar-rounda","structure-detailed"],["hangar-roundglass","hangar-rounda"],["hangar-largea","hangar-largeb"],["structure-closed","structure-detailed"]]
static var materials:Dictionary={}
static var scenes:Dictionary={}
static func coating(name_value: String, planet: int) -> Material:
	var key:=name_value+str(planet)
	if materials.has(key): return materials[key]
	var m:=ShaderMaterial.new(); m.shader=preload("res://assets/salvage/transport_surface.gdshader")
	m.set_shader_parameter("surface_map",preload("res://assets/finish_city/MetalPlates006_1K-JPG_Color.jpg"))
	var color:=Color("b4cbd9")
	if name_value.contains("Red"): color=Color(["f3a27f","f1b3cb","8edbd5","c5abec"][planet])
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
	# Continuous, visible retaining walls join the buildings; no invisible perimeter.
	for side in [-1,1]:
		G.box(root,Vector3(.55,4.4,88),Vector3(side*43.6,1.975,-24)).material_override=coating("metalDark",planet)
		G.box(root,Vector3(88,4.4,.55),Vector3(0,1.975,-68.6 if side<0 else 20.6)).material_override=coating("metalDark",planet)
		for i in 5:
			house(root,i,Vector3(side*51,-.225,-59+i*18),side*PI*.5,planet)
		for i in 5:
			if side>0 and i==2: continue
			house(root,i+5,Vector3((i-2)*18,-.225,-76 if side<0 else 28),0 if side<0 else PI,planet)
		for i in 11:
			G.box(root,Vector3(.08,.13,5),Vector3(side*43.25,3.7,-64+i*8),"7cdded",.4)
	# Replace the front wall's road section with a gate, open throughout the race.
	# The wall is cut geometrically, rather than leaving an invisible collider in the entry.
	for piece in root.get_children():
		if piece is MeshInstance3D and piece.position.z>20 and piece.position.z<21: piece.free()
	for side in [-1,1]:
		G.box(root,Vector3(38,4.4,.55),Vector3(side*25,1.975,20.6)).material_override=coating("metalDark",planet)
		G.box(root,Vector3(1,6,.9),Vector3(side*6,2.8,20.6)).material_override=coating("metal",planet)
	G.box(root,Vector3(13,1,.9),Vector3(0,5.8,20.6)).material_override=coating("metalRed",planet)
	G.label(root,"КОСМОПОРТ",Vector3(0,5.7,20.05),38).rotation.y=PI
	batch(root)
	var gate:=G.box(root,Vector3(11.5,4.8,.3),Vector3(0,2.175,20.6),"58a9c4")
	gate.name="ReturnGate"; gate.visible=false; gate.set_meta("architecture_solid",true)
	gate.material_override=coating("metalRed",planet)
	root.set_meta("models",FAMILIES[planet]); root.set_meta("building_count",19); root.set_meta("architecture_family",planet); return root

static func house(root:Node3D, index:int, at:Vector3, yaw:float, planet:int) -> void:
	var height:float=[13.0,10.0,8.0,24.0][planet]+(index%2)*[4.0,2.0,3.0,8.0][planet]
	var key:String=FAMILIES[planet][index%2]
	module(root,key,at,Vector3(14,height,16),yaw,planet)
	if key.begins_with("structure"):
		# Habitable floors sit inside the downloaded external structural frame.
		SM.block(root,Vector3(12,height-1.2,14),at+Vector3(0,(height-1.2)*.5,0),coating("metal",planet),.3)
		for floor in range(2,int(height)-1,3):
			for side in [-1,1]:
				G.box(root,Vector3(10,1.3,.06),at+Vector3(0,floor,side*7.02),"357d9d",.12)
				G.box(root,Vector3(.06,1.3,12),at+Vector3(side*6.02,floor,0),"357d9d",.12)
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
				tool.set_normal((transform.basis.inverse().transposed()*normals[j]).normalized()); tool.add_vertex(transform*vertices[j])
	for child in root.get_children():
		if not child is Label3D: child.free()
	for mat:Material in groups:
		var mesh:=SM._part(root,groups[mat].commit(),mat); mesh.set_meta("architecture_solid",true)
