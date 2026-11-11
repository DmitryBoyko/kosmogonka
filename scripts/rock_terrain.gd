extends RefCounted

const Track = preload("res://scripts/turn_track.gd")
const Course = preload("res://scripts/course.gd")
const Loops = preload("res://scripts/loop_layout.gd")
const RockShader = preload("res://assets/terrain_kit/stratified_rock.gdshader")
const ROOT := "res://assets/terrain_kit/"
const MAPS := [
	preload("res://assets/surfaces/aurora_ground_v1.png"),
	preload("res://assets/surfaces/flora_ground_v1.png"),
	preload("res://assets/surfaces/amber_ground_v1.png"),
	preload("res://assets/surfaces/neon_ground_v1.png"),
]
const LOOKS := [
	["514963","88769c","a6e6db",.55,.08,0,["massif","spire"],["rock-spikes","strata"]],
	["545643","837656","a4ad72",.48,0.,1,["rounded-range","valley"],["strata","boulder"]],
	["854331","d49357","f8c982",.57,0.,2,["ledge","massif"],["strata","scree"]],
	["344451","536d77","7bd9de",.48,.12,3,["block-outcrop","ledge"],["rock-spikes","boulder"]],
	["345a5c","658077","c8d4ae",.37,0.,0,["ledge","rounded-range"],["boulder","strata"]],
	["79553b","ae8653","e4b866",.50,0.,2,["valley","ledge"],["scree","strata"]],
	["4c354b","806287","cda3c9",.52,.13,1,["rounded-range","massif"],["boulder","strata"]],
	["486879","7ea8bb","edf8fd",.96,.03,0,["snow-range","snow-shelf","massif"],["snow-shelf","boulder"]],
	["311f25","624132","ff965b",.36,.37,2,["spire","massif"],["rock-spikes","ledge"]],
	["493654","725991","d0a8ee",.59,.19,3,["massif","valley"],["rock-spikes","boulder"]],
	["3e4e68","7482a7","b9edee",.70,.13,0,["block-outcrop","massif","snow-shelf"],["rock-spikes","strata"]],
]
static var meshes: Dictionary = {}
static var coatings: Dictionary = {}

static func mesh(key: String) -> ArrayMesh:
	if meshes.has(key): return meshes[key]
	var source: PackedScene = load(ROOT+key+".glb")
	var root := source.instantiate() as Node3D
	var pieces := root.find_children("*","MeshInstance3D",true,false)
	if root is MeshInstance3D: pieces.push_front(root)
	var bounds := AABB()
	var transforms: Array[Transform3D] = []
	for piece: MeshInstance3D in pieces:
		var t := piece.transform
		var parent := piece.get_parent()
		while parent and parent!=root:
			t=parent.transform*t
			parent=parent.get_parent()
		var box := t*piece.mesh.get_aabb()
		bounds = box if transforms.is_empty() else bounds.merge(box)
		transforms.append(t)
	var center := Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)
	var size := bounds.size.max(Vector3.ONE*.00001)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in pieces.size():
		var piece: MeshInstance3D = pieces[i]
		var t := transforms[i]
		var n_transform := (Basis.from_scale(Vector3.ONE/size)*t.basis).inverse().transposed()
		for surface in piece.mesh.get_surface_count():
			var mat := piece.mesh.surface_get_material(surface)
			var role := String(mat.resource_name).to_lower() if mat else ""
			var mask := Color(.9 if "snow" in role or (key.begins_with("snow") and role=="mat21") else 0.,.8 if "dirt" in role or "grass" in role or "ground" in role else 0.,0.)
			var arrays := piece.mesh.surface_get_arrays(surface)
			var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
			for j in (indices.size() if not indices.is_empty() else points.size()):
				var vertex: int = indices[j] if not indices.is_empty() else j
				tool.set_color(mask)
				tool.set_normal((n_transform*normals[vertex]).normalized() if not normals.is_empty() else Vector3.UP)
				tool.add_vertex((t*points[vertex]-center)/size)
	tool.index()
	var result := tool.commit()
	root.free()
	meshes[key]=result
	return result

static func coating(world: int) -> ShaderMaterial:
	if coatings.has(world): return coatings[world]
	var style: Array = LOOKS[world]
	var mat := ShaderMaterial.new()
	mat.shader = RockShader
	mat.set_shader_parameter("rock",Color(style[0]))
	mat.set_shader_parameter("layer",Color(style[1]))
	mat.set_shader_parameter("accent",Color(style[2]))
	mat.set_shader_parameter("caps",style[3])
	mat.set_shader_parameter("glow",style[4])
	mat.set_shader_parameter("grain_map",MAPS[style[5]])
	coatings[world]=mat
	return mat

static func populate(root: Node3D, world: int, index: int, route: Track, clearings: Array[AABB]) -> void:
	var origin := index*30.
	if index<2 or origin>Course.length_for(world)-145.: return
	var mid := origin+15.
	var curve := route.sample(mid)
	var bend := absf(curve.x)>2.6 or absf(curve.y)>.19
	var rng := RandomNumberGenerator.new()
	rng.seed = route.seed_value ^ (index*33719+world*6431+903)
	var style: Array = LOOKS[world]
	var cliffs: Array = style[6]
	var rocks: Array = style[7]
	if world!=4 and posmod(index+world,5)==0:
		for ridge_side in [-1.,1.]:
			var ridge_s:=mid+rng.randf_range(-9.,9.)
			var ridge_x:float=route.sample(ridge_s).x+ridge_side*rng.randf_range(53.,81.)
			var ridge_key:String=cliffs[posmod(int(index/5)+int(ridge_side)+world,cliffs.size())]
			place(root,world,ridge_key,Vector3(ridge_x,0.,origin-ridge_s),Vector3(rng.randf_range(39.,60.),rng.randf_range(22.,38.),rng.randf_range(45.,69.)),rng.randf_range(-.55,.55),route,origin,clearings)
	if not bend and posmod(index+world,3)!=0: return
	var side := signf(curve.x) if bend and absf(curve.x)>.15 else (-1. if rng.randf()<.5 else 1.)
	var total_height := rng.randf_range(10.,17.) if bend else rng.randf_range(15.,27.)
	if world==4: total_height*=.57
	if world in [2,5]: total_height*=.73
	if world in [7,8,10]: total_height*=1.13
	var width := rng.randf_range(14.,23.) if bend else rng.randf_range(21.,35.)
	var s := mid+rng.randf_range(-3.,3.)
	var turn := route.sample(s)
	var at := Vector3(turn.x+side*(width*.55+(10.2 if bend else 22.)),0.,origin-s)
	var key: String = cliffs[posmod(index+world,cliffs.size())]
	place(root,world,key,at,Vector3(width,total_height,rng.randf_range(15.,23.)),rng.randf_range(-.42,.42),route,origin,clearings)
	if bend or posmod(index+world,6)==0:
		var foot := Vector3(turn.x-side*rng.randf_range(11.5,15.8),0.,at.z+rng.randf_range(-6.,6.))
		var stone: String = rocks[posmod(index,rocks.size())]
		var depth := rng.randf_range(4.3,8.)
		var height := rng.randf_range(3.8,7.4)*(0.52 if stone=="scree" else 1.)
		place(root,world,stone,foot,Vector3(depth,height,depth*1.12),rng.randf()*TAU,route,origin,clearings)

static func place(root: Node3D, world: int, key: String, at: Vector3, size: Vector3, yaw: float, route: Track, origin: float, clearings: Array[AABB]) -> void:
	var model := mesh(key)
	var s := origin-at.z
	var ground := 0. if world==4 else route.terrain_height(s,at.x)
	if world!=4 and size.x>=36.:
		# Broad formations must meet the hillside across their footprint.
		for x in [-.40,.40]:
			for z in [-.40,.40]:
				var foot:=Vector3(x*size.x,0,z*size.z).rotated(Vector3.UP,yaw)
				ground=minf(ground,route.terrain_height(s-foot.z,at.x+foot.x))
	at.y = ground-maxf(.5,size.y*(.29 if size.x>=36. else .17))
	var placement := Transform3D(Basis(Vector3.UP,yaw)*Basis.from_scale(size),at)
	var box := placement*model.get_aabb()
	var at_left := at.x<route.sample(s).x
	for i in 7:
		var along := lerpf(origin-box.end.z,origin-box.position.z,i/6.)
		var road_x := route.sample(along).x
		if at_left and box.end.x>road_x-7.2 or not at_left and box.position.x<road_x+7.2:
			return
	for clearing in clearings:
		var land := Rect2(Vector2(clearing.position.x,clearing.position.z),Vector2(clearing.size.x,clearing.size.z)).grow(2.5)
		if land.intersects(Rect2(Vector2(box.position.x,box.position.z),Vector2(box.size.x,box.size.z))): return
	var global_box := box
	global_box.position.z-=origin
	for kind: String in Loops.kinds(world):
		if Loops.clearance(kind).grow(1.4).intersects(global_box): return
	var rock := MeshInstance3D.new()
	rock.name = "TerrainFormation"
	rock.mesh = model
	rock.transform = placement
	rock.material_override = coating(world)
	rock.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rock.visibility_range_end = 202.
	rock.set_meta("terrain_source",key)
	root.add_child(rock)
