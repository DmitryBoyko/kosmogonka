extends RefCounted
## Planet-specific, instanced ecosystems; no generic green forest on water/lava/ice.
static var meshes:Dictionary={}
static var materials:Dictionary={}
const Plants = preload("res://scripts/plant_kit.gd")
const Rocks = preload("res://scripts/rock_terrain.gd")
const MeshTools = preload("res://scripts/salvage_mesh.gd")
const NATIVE_MODELS := {
	"light_reeds":"reeds", "light_bloom":"broad_fronds", "sun_grass":"golden_flower",
	"coral":"staghorn_coral", "coral_fan":"lettuce_coral",
	"fungus":"amanita", "fungus_shelf":"shelf_fungus", "fungus_bells":"morel",
	"cactus":"fork_cactus", "cactus_fork":"fork_cactus",
	"storm_bloom":"flower_bush", "storm_fronds":"broad_fronds",
}
const FAMILIES := [
	["crystal","crystal_fan","ledge"], [],
	["amber","ledge","cactus"], ["light_reeds","light_bloom","mirror"],
	["coral","coral_fan","ledge"], ["sun_grass","cactus_fork","ledge"],
	["fungus","fungus_shelf","fungus_bells"], ["ice","crystal_fan","ice_shelf"],
	["basalt","basalt_columns","ledge"], ["shard_orbit","fractured_ring","floating_shelf"],
	["mirror","mirror_fan","crystal_fan"],
]
const FEATURE_TINTS := [
	["ad8feb","8ce4dd"], ["a4d783","f5b1d1"], ["f6cb8e","ed9a86"],
	["78e2e8","ce9bea"], ["63d6d5","ec9ec4"], ["f0cc84","d8e397"],
	["e6a6f1","8cd9bf"], ["b9ebf6","a5afe9"], ["a98491","f4ac72"],
	["c9a1eb","9ab5ef"], ["b6e8f1","d2bced"],
]
static func part(st:SurfaceTool,mesh:Mesh,at:Vector3,size:Vector3,color:Color,rotation:Vector3=Vector3.ZERO) -> void:
	var arrays:=mesh.surface_get_arrays(0);var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL];var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
	var basis:=Basis.from_euler(rotation).scaled(size)
	for i in (indices.size() if not indices.is_empty() else vertices.size()):
		var index:int=indices[i] if not indices.is_empty() else i
		st.set_color(color);st.set_normal((basis.inverse().transposed()*normals[index]).normalized());st.add_vertex(basis*vertices[index]+at)
static func mesh(kind:String) -> ArrayMesh:
	if meshes.has(kind):return meshes[kind]
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	if kind in ["basalt","basalt_columns"]:
		for i in (4 if kind=="basalt_columns" else 2):
			basalt_column(st,i)
		var result:=st.commit()
		meshes[kind]=result
		return result
	var cylinder:=CylinderMesh.new();cylinder.top_radius=.5;cylinder.bottom_radius=.5;cylinder.height=1.;cylinder.radial_segments=8
	var ball:=SphereMesh.new();ball.radius=.5;ball.height=1.;ball.radial_segments=10;ball.rings=5
	var panel:=BoxMesh.new();panel.size=Vector3.ONE
	if kind in ["shard_orbit","floating_shelf","fractured_ring"]:
		cylinder.radial_segments=5
		if kind=="shard_orbit":
			cylinder.top_radius=.025
			part(st,cylinder,Vector3(0,.36,0),Vector3(.51,1.05,.45),Color("8b69c7"),Vector3(.43,0,.48))
			part(st,cylinder,Vector3(.48,.6,.1),Vector3(.21,.48,.19),Color("85d3dc"),Vector3(-.5,0,.66))
			part(st,cylinder,Vector3(-.33,.1,.2),Vector3(.17,.35,.17),Color("eab3e7"),Vector3(.5,0,-.6))
		elif kind=="floating_shelf":
			for i in 3:
				part(st,panel,Vector3((i-1)*.31,.35+i*.15,0),Vector3(.88-i*.19,.20,.64-i*.08),
					[Color("574679"),Color("a283b4"),Color("85a8d4")][i],Vector3(.14,i*.36,.2))
		else:
			for i in 5:
				var angle := float(i)*TAU/6.
				part(st,panel,Vector3(cos(angle)*.43,.53+sin(angle)*.43,0),Vector3(.37,.15,.31),
					Color("9ac7e7") if i%2==0 else Color("775aab"),Vector3(.15,0,angle+PI*.5))
	elif kind in ["light_reeds","light_bloom","sun_grass"]:
		var luminous := kind!="sun_grass"
		for i in (4 if kind=="light_reeds" else 3):
			var h := .52 + i*.16
			var x := (i-1.25)*.24
			var shade := Color("497984") if luminous else Color("788540")
			part(st,cylinder,Vector3(x,h*.45,0),Vector3(.08,h,.08),shade,Vector3(0,0,(i-1.)*.15))
			var tip := Color("b66cff") if i%2==0 else Color("56e6e1")
			if not luminous: tip=Color("ebba4b")
			var head := Vector3(.24,.20,.23) if kind=="light_reeds" else Vector3(.40,.17,.35)
			part(st,ball,Vector3(x,h,0),head,tip)
			if kind=="light_bloom":
				for petal in 4:
					var a := petal*TAU/4.
					part(st,ball,Vector3(x+cos(a)*.18,h,sin(a)*.18),Vector3(.19,.09,.19),tip.lightened(.14))
	elif kind in ["mirror","mirror_fan"]:
		part(st,panel,Vector3(0,.6,0),Vector3(.45,1.2,.10),Color("a9cfe9"),Vector3(0,.4,.15))
		part(st,panel,Vector3(.30,.36,.16),Vector3(.35,.72,.08),Color("dfa8da"),Vector3(0,-.5,-.20))
		if kind=="mirror_fan":
			part(st,panel,Vector3(-.32,.39,-.10),Vector3(.37,.82,.09),Color("7cbeb9"),Vector3(0,.4,.48))
	elif kind in ["crystal","ice","silicon","amber","crystal_fan"]:
		cylinder.top_radius=.035;cylinder.radial_segments=6
		var tall := 1.3 if kind in ["ice","silicon"] else .77 if kind=="amber" else 1.
		var ink := Color("e3b069") if kind=="amber" else Color("b0e7ec")
		part(st,cylinder,Vector3(0,tall*.5,0),Vector3(.6,tall,.6),ink)
		part(st,cylinder,Vector3(.24,.25,.12),Vector3(.32,.5,.32),Color("83bcc8"),Vector3(0,0,-.23))
		if kind=="crystal_fan":
			part(st,cylinder,Vector3(-.32,.37,.16),Vector3(.34,.81,.34),Color("ccacdf"),Vector3(0,0,.48))
	elif kind in ["fungus","fungus_shelf","fungus_bells"]:
		var height := .56 if kind=="fungus_shelf" else 1.12 if kind=="fungus_bells" else .90
		part(st,cylinder,Vector3(0,height*.5,0),Vector3(.18,height,.18),Color(.7,.73,.63,0))
		part(st,ball,Vector3(0,height,0),Vector3(1.3,.61 if kind=="fungus_bells" else .32,1.1),Color(.62,.36,.74,1))
		if kind=="fungus_shelf":
			part(st,ball,Vector3(.39,.32,0),Vector3(.7,.20,.6),Color(.77,.58,.47,1))
	elif kind in ["coral","coral_fan"]:
		# The branches repeat across the ocean surface. Small tips need only a
		# few segments, leaving room for the more detailed shoreline plants.
		ball.radial_segments=8;ball.rings=3
		for i in 5:
			var a:=i*TAU/5.;var height:=.7+float(i%3)*.24
			var spread := 1.55 if kind=="coral_fan" else 1.
			part(st,cylinder,Vector3(sin(a)*.24*spread,height*.5,cos(a)*.24),Vector3(.13,height,.13),Color("a788a7"),Vector3(sin(a)*.35,0,cos(a)*.35))
			part(st,ball,Vector3(sin(a)*.4*spread,height,cos(a)*.4),Vector3(.35,.25,.35),Color("7bcbbd"))
	elif kind in ["cactus","cactus_fork"]:
		var height := 1.3 if kind=="cactus" else .79
		part(st,cylinder,Vector3(0,height*.5,0),Vector3(.32,height,.32),Color("9ca66b"))
		part(st,ball,Vector3(0,height,0),Vector3(.32,.32,.32),Color("c8b878"))
		for side in [-1.,1.]:
			part(st,cylinder,Vector3(side*.26,.65,0),Vector3(.19,.6,.19),Color("949d67"),Vector3(0,0,side*.8))
	else:
		cylinder.radial_segments=6
		for i in 3:
			var height := .26+i*.12
			var ink := Color("9cbace") if kind=="ice_shelf" else Color("777177") if kind=="ledge" else Color(.24,.20,.21,.6)
			part(st,cylinder,Vector3((i-1)*.32,height*.5,0),Vector3(.49,height,.64),ink,Vector3(.13,i*.4,.08))
	var result:=st.commit();meshes[kind]=result;return result

static func basalt_column(tool: SurfaceTool, index: int) -> void:
	var base := Vector3((index-1.5)*.22,0.,sin(index*2.4)*.24)
	var height: float = [.55,1.10,.83,.62][index]
	var rings: Array[PackedVector3Array] = []
	for band in 5:
		var ring := PackedVector3Array()
		var y := height*float(band)/4.
		for face in 6:
			var angle := face*TAU/6.+index*.48
			var radius := .205*(1.+.17*sin(face*13.1+band*2.1+index))*(.77 if band==4 else 1.)
			var corner := Vector3(cos(angle)*radius+band*.014,y,sin(angle)*radius)
			corner.y += y*.16*sin(angle+index*1.7)
			ring.append(base+corner)
		rings.append(ring)
	for band in 4:
		for face in 6:
			var following := (face+1)%6
			var lower := rings[band]
			var upper := rings[band+1]
			rock_triangle(tool,lower[face],lower[following],upper[following])
			rock_triangle(tool,lower[face],upper[following],upper[face])
	for face in 6:
		rock_triangle(tool,base+Vector3.UP*height,rings[4][face],rings[4][(face+1)%6])

static func rock_triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	tool.set_color(Color(.0,.0,.0,1.))
	MeshTools._triangle(tool,a,b,c)
static func material(world:int) -> ShaderMaterial:
	var wind := preload("res://scripts/rock_terrain.gd").is_floating_world(world)
	world=preload("res://scripts/planets.gd").style_index(world)
	var key := -1 if wind else world
	if materials.has(key):return materials[key]
	var mat:=ShaderMaterial.new();mat.shader=preload("res://assets/surfaces/biome_life.gdshader");mat.set_shader_parameter("world",world);mat.set_shader_parameter("motion",0. if preload("res://scripts/natural_flora.gd").reduced_motion else 1.)
	mat.set_shader_parameter("grain_map",preload("res://scripts/arcade_materials.gd").MAPS[world])
	mat.set_shader_parameter("wind_islands",wind)
	materials[key]=mat;preload("res://scripts/natural_flora.gd").mats["biome-life-"+str(key)]=mat
	return mat
static func populate(parent:Node3D,world:int,index:int,quality:bool,clearings:Array[AABB]=[],run_seed:int=0) -> Node3D:
	var root:=Node3D.new();parent.add_child(root);root.name="PlanetEcosystem"
	root.set_meta("biome_world",world)
	var rng:=RandomNumberGenerator.new();rng.seed=(world*7919+index*137+53)^run_seed
	var style := preload("res://scripts/planets.gd").style_index(world)
	var wind := preload("res://scripts/rock_terrain.gd").is_floating_world(world)
	var storm := world>=11 and style==8
	var families: Array = ["storm_bloom","storm_fronds","basalt_columns","ledge"] if storm else ["light_reeds","light_bloom","crystal_fan"] if wind else FAMILIES[style]
	if families.is_empty(): return root
	var count:int=58 if style in [0,3,6,7] else 40 if style in [4,8,9] else 32
	if world>=9:count=ceili(count*.65)
	var expedition_mobile := world>=11 and preload("res://scripts/mobile_render.gd").enabled()
	if expedition_mobile: count=ceili(count*.7)
	var batches: Dictionary = {}
	var solids: Array = []
	for kind: String in families: batches[kind] = []
	var district_family := posmod(floori(float(index)/3.)+run_seed,families.size())
	for i in count:
		var family_index := district_family if rng.randf()<.49 else rng.randi_range(0,families.size()-1)
		if i<families.size(): family_index=i
		var kind: String = families[family_index]
		var species: String = NATIVE_MODELS.get(kind,"")
		var data := {} if species.is_empty() else Plants.prototype(species)
		var mesh_bounds: AABB = mesh(kind).get_aabb() if species.is_empty() else data.bounds
		var side:float=-1. if i%2==0 else 1.;var x:float=side*rng.randf_range(5.8,14.);var z:float=rng.randf_range(-29.8,-.2)
		var large := i<4
		var giant := i==posmod(index,2) and index>1
		var height: float = rng.randf_range(3.4,6.2) if large else rng.randf_range(.45,2.0)
		if world in [2,5]:height*=.65
		if wind: height*=.46
		if giant:
			height = rng.randf_range(8.5,14.8) if style in [1,3,4,6,7] else rng.randf_range(7.5,12.5)
			x = side*rng.randf_range(8.8,13.7)
		elif large: x=side*rng.randf_range(7.0,12.8)
		if storm:
			height=height*.62 if kind=="basalt_columns" else height*.77
			z=-7.-float(i)*5.5 if large else z
		var finish_z:float=z-index*30.+preload("res://scripts/course.gd").length_for(world)
		for home:Vector2 in [Vector2(-21,10),Vector2(21,10),Vector2(0,-51)]:
			if absf(x-home.x)<3.5 and absf(finish_z-home.y)<4.:x=side*34.
		var y:float=-.65 if style==4 else rng.randf_range(.6,4.8) if style==9 else -.22
		var width := height*rng.randf_range(.58,.93) if style in [3,4,5,6] else height*rng.randf_range(.45,.85)
		var basis:=Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3(width,height,width))
		var footprint := Transform3D(basis,Vector3(x,y,z))*mesh_bounds
		var near_edge := footprint.position.x if side>0. else -footprint.end.x
		# Keep the broad canopy and tall branches outside the runner's view corridor.
		if i<4:
			var shoulder_edge := 5.55 if storm else 6.15 if giant else 5.65
			x += side*(shoulder_edge+rng.randf_range(0.,.55)-near_edge)
		else:
			x += side*maxf(0.,5.35-near_edge)
		for loop_kind:String in preload("res://scripts/loop_layout.gd").kinds(world):
			var reserve:=preload("res://scripts/loop_layout.gd").roadside_clearance(loop_kind,world)
			var bounds:AABB=Transform3D(basis,Vector3(x,y,z-index*30.))*mesh_bounds
			if bounds.intersects(reserve):x=reserve.end.x+bounds.size.x*.5+1. if side>0 else reserve.position.x-bounds.size.x*.5-1.
		var transform:=Transform3D(basis,Vector3(x,y,z))
		var tint := Color(["64dcb0","87c7ff"][i%2] if wind else FEATURE_TINTS[style][i%2])
		var phase:=rng.randf()
		var bounds:=transform*mesh_bounds
		var reserved:=false
		for clearing in clearings:
			if clearing.intersects(bounds):
				reserved=true
				break
		if reserved: continue
		if not species.is_empty():
			var limit := clampi(1500/maxi(1,data.triangles),1,6)
			if batches[kind].size()>=limit: continue
			if data.triangles>2800 and posmod(index,2)!=0: continue
		batches[kind].append({"at":transform,"tint":tint,"phase":phase,"large":large})
		if large and world!=9: solids.append(bounds)
	for kind: String in families:
		var instances: Array = batches[kind]
		if instances.is_empty(): continue
		if NATIVE_MODELS.has(kind):
			var placements: Array[Transform3D] = []
			for item in instances: placements.append(item.at)
			Plants.batch(root,world,NATIVE_MODELS[kind],placements,quality,126.)
			continue
		add_batch(root,world,kind,instances,false,quality)
		var shadows := instances.filter(func(item):return item.large) if not expedition_mobile else []
		if not shadows.is_empty(): add_batch(root,world,kind,shadows,true,quality)
	root.set_meta("solid_nature_boxes",solids)
	return root

static func add_batch(root: Node3D, world: int, kind: String, instances: Array, shadows: bool, quality: bool) -> void:
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.use_custom_data = true
	multi.mesh = mesh(kind)
	multi.instance_count = instances.size()
	for i in instances.size():
		var item: Dictionary = instances[i]
		multi.set_instance_transform(i,item.at)
		multi.set_instance_color(i,item.tint)
		multi.set_instance_custom_data(i,Color(item.phase,0,0,0))
	if not quality and not shadows: multi.visible_instance_count=ceili(instances.size()*.65)
	var node := MultiMeshInstance3D.new()
	node.name = ("BiomeShadows_" if shadows else "BiomePopulation_")+kind
	node.multimesh = multi
	node.material_override = Rocks.coating(world) if kind in ["basalt","basalt_columns"] else material(world)
	if kind in ["basalt","basalt_columns","ledge"]:
		node.set_meta("embed_footprint",true)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(node)
