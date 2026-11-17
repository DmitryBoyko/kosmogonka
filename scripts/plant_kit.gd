extends RefCounted

const Course = preload("res://scripts/course.gd")
const Loops = preload("res://scripts/loop_layout.gd")
const Flora = preload("res://scripts/natural_flora.gd")
const FOLIAGE = preload("res://assets/plant_kit/foliage.gdshader")
const CANOPY_SHADOW = preload("res://assets/plant_kit/canopy_shadow.gdshader")
const ROOT := "res://assets/plant_kit/"
const TREE_SELECTION := "tree_selection.glb"
const SUNKEN_GROUND := -.24
const STORM_PLANTS := {"patch":["flower_blue","broad_fronds","golden_flower"],"trees":["pink_ancient","alien_leaf"],"bed":"flower_blue","tint":"95c4aa","density":9,"grove":4}
const BEND_PLANTS := [["crystals","flower_blue"],["fern","flower_bush"],["fork_cactus","golden_flower"],
	["alien_leaf","flower_blue"],["staghorn_coral","lettuce_coral"],["golden_flower","fork_cactus"],
	["amanita","morel"],["snow_pine","ice_grass"],["deadwood","dry_grass"],["alien_leaf","violet_grass"],
	["crystals","flower_white"]]

# Each palette defines roadside patches, the settlement canopy and its understory.
const BIOMES := [
	{"patch":["violet_grass","flower_blue"],"trees":["silver_birch","pink_ancient"],"bed":"flower_blue","tint":"7dbab4","density":17,"grove":7},
	{"patch":["fern","poppy","flower_bush","meadow_grass","golden_flower"],"trees":["alder","broadleaf","birch"],"bed":"flower_bush","tint":"88b957","density":24,"grove":9},
	{"patch":["small_cactus","dry_grass"],"trees":["tall_cactus","fork_cactus"],"bed":"dry_grass","tint":"b6a455","density":10,"grove":5},
	{"patch":["short_grass","flower_blue"],"trees":["silver_birch","poly_tree"],"bed":"flower_blue","tint":"66bac9","density":14,"grove":7},
	{"patch":["lily","reeds"],"trees":["coconut","leaning_palm"],"bed":"reeds","tint":"80b68b","density":9,"grove":6},
	{"patch":["golden_flower","dry_grass","short_grass"],"trees":["fork_cactus","poly_tree"],"bed":"golden_flower","tint":"c7a759","density":13,"grove":6},
	{"patch":["mushroom","bell"],"trees":["pink_ancient","mushroom"],"bed":"bell","tint":"b680c6","density":9,"grove":7},
	{"patch":["ice_grass","snow_pine"],"trees":["snow_pine","pine_group"],"bed":"ice_grass","tint":"a1c4d1","density":10,"grove":7},
	{"patch":["dry_grass","deadwood"],"trees":["deadwood","twisted"],"bed":"dry_grass","tint":"9c5d4f","density":8,"grove":4},
	{"patch":["violet_grass","bell","alien_leaf"],"trees":["pink_ancient","twisted"],"bed":"alien_leaf","tint":"aa76dc","density":14,"grove":6},
	{"patch":["ice_grass","flower_white"],"trees":["silver_birch","dark_pine"],"bed":"flower_white","tint":"a2dbe5","density":15,"grove":7},
]
const MODELS := {
	"silver_birch":[TREE_SELECTION,"birch7"],
	"snow_pine":[TREE_SELECTION,"pine5"],
	"dark_pine":[TREE_SELECTION,"pine4"],
	"coconut":[TREE_SELECTION,"coconut1"],
	"leaning_palm":[TREE_SELECTION,"coconut2"],
	"tall_cactus":[TREE_SELECTION,"cactus1"],
	"small_cactus":[TREE_SELECTION,"cactus3"],
	"fork_cactus":[TREE_SELECTION,"cactus4"],
	"lily":[TREE_SELECTION,"waterlily_pink2"],
	"twisted":[TREE_SELECTION,"creepy_tree1"],
	"pink_ancient":[TREE_SELECTION,"ancient_tree_pink_1"],
	"violet_grass":[TREE_SELECTION,"grass_purple"],
	"ice_grass":[TREE_SELECTION,"grass_blue"],
	"dry_grass":[TREE_SELECTION,"grass_yellow"],
	"alder":["niwl/alder_5.glb","",["T_willow_bark","T_Plants_General_LowPoly"]],
	"birch":["niwl/birch-tree-1.glb","",["T_birch_bark","T_Plants-TreeBranches"]],
	"fern":["niwl/fern-1.glb","",["T_Plants_General"]],
	"poppy":["niwl/poppy-1.glb","",["T_Plants_General"]],
	"meadow_grass":["niwl/grass_patch_7.glb","",["T_Plants_General"]],
	"reeds":["niwl/water-overgrowth.glb","",["T_Plants_General"]],
	"hanging_ivy":["niwl/ivy_2.glb","",["T_Plants_General"]],
	"golden_flower":["niwl/sunflower.glb","",["T_Plants_General"]],
	"mushroom":["mega/Mushroom_Common.gltf",""],
	"amanita":["kyle/amanita.glb",""],
	"morel":["kyle/morel.glb",""],
	"shelf_fungus":["mega/Mushroom_Laetiporus.gltf",""],
	"broad_fronds":["mega/Plant_1_Big.gltf",""],
	"alien_leaf":["mega/Plant_7_Big.gltf",""],
	"staghorn_coral":["reef/staghorn.glb",""],
	"lettuce_coral":["reef/lettuce.glb",""],
	"crystals":["../space_kit/rock_crystalsLargeA.glb",""],
	"bell":["additional/bell.obj",""],
	"deadwood":["additional/deadwood.glb","DeadTree_9"],
	"flower_bush":["additional/flower-bush.glb","Plant_Flowers"],
	"flower_blue":["additional/flower-clumps.glb","Flower_3_Clump"],
	"flower_white":["additional/flower-clumps.glb","Flower_4_Clump"],
	"short_grass":["additional/short-grass.glb","Grass_Small"],
	"pine_group":["additional/pine-grove.glb","Resource_PineTree_Group"],
	"poly_tree":["additional/poly-tree.glb","tree01"],
	"broadleaf":["additional/broadleaf.glb","NormalTree_5"],
}
const TALL_PATCHES := ["small_cactus","snow_pine","deadwood"]
const MUSHROOM_ATLASES := {"amanita":"amanita.png","morel":"morel.png"}
const OPEN_FLOWERS := ["poppy","golden_flower","flower_bush","flower_blue","flower_white","bell","lily"]
static var prototypes: Dictionary = {}
static var materials: Dictionary = {}
static var canopy_shadow_material: ShaderMaterial
static var canopy_shadow_mesh: PlaneMesh

static func prototype(species: String) -> Dictionary:
	if prototypes.has(species):
		return prototypes[species]
	var spec: Array = MODELS[species]
	var resource := load(ROOT+str(spec[0]))
	var model: Node3D
	var meshes: Array[MeshInstance3D] = []
	if resource is Mesh:
		var mesh := MeshInstance3D.new()
		mesh.mesh = resource
		model = mesh
		meshes.append(mesh)
	else:
		model = resource.instantiate()
		if spec[1]!="":
			var selected := model.find_child(spec[1],true,false) as MeshInstance3D
			if selected: meshes.append(selected)
		else:
			if model is MeshInstance3D: meshes.append(model)
			for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
				meshes.append(mesh)
	var parts: Array[Dictionary] = []
	var bounds := AABB()
	for mesh in meshes:
		var placement := mesh.transform
		var parent := mesh.get_parent()
		while parent and parent!=model:
			placement = parent.transform*placement
			parent = parent.get_parent()
		if species=="hanging_ivy":
			placement = Transform3D(Basis(Vector3.RIGHT,PI*.5),Vector3.ZERO)*placement
		var box := placement*mesh.mesh.get_aabb()
		bounds = box if parts.is_empty() else bounds.merge(box)
		for surface in mesh.mesh.get_surface_count():
			var original := mesh.mesh.surface_get_material(surface) as BaseMaterial3D
			var texture := original.albedo_texture if original else null
			var color := original.albedo_color if original else Color.WHITE
			var bark := original!=null and ("Bark" in original.resource_name or original.resource_name=="Wood")
			var cutout := original!=null and original.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED
			if spec.size()>2:
				var atlas_name: String = spec[2][meshes.find(mesh)]
				texture = load(ROOT+"niwl/"+atlas_name+".png")
				bark = atlas_name.ends_with("bark")
				cutout = not bark
			elif species=="bell":
				texture = load(ROOT+"additional/Bell.png")
				cutout = true
			elif MUSHROOM_ATLASES.has(species):
				texture = load(ROOT+"kyle/"+MUSHROOM_ATLASES[species])
				cutout = false
			parts.append({"source":mesh.mesh,"surface":surface,"placement":placement,"texture":texture,"color":color,"bark":bark,"cutout":cutout,"crystal":original!=null and original.resource_name=="crystal"})
	var factor := 1./maxf(bounds.size.y,.0001)
	var fit := Transform3D(Basis.from_scale(Vector3.ONE*factor),-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*factor)
	for part in parts:
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		tool.append_from(part.source,part.surface,fit*part.placement)
		part.mesh = tool.commit()
		part.erase("source")
		part.erase("placement")
	model.free()
	var triangles := 0
	for part in parts:
		triangles += part.mesh.surface_get_array_index_len(0)/3
	var result := {"parts":parts,"bounds":fit*bounds,"triangles":triangles}
	prototypes[species] = result
	return result

static func paint(world: int, species: String, part: Dictionary, index: int) -> ShaderMaterial:
	world = preload("res://scripts/planets.gd").style_index(world)
	var key := "%d/%s/%d"%[world,species,index]
	if materials.has(key):
		return materials[key]
	var mat := ShaderMaterial.new()
	mat.shader = FOLIAGE
	mat.set_shader_parameter("atlas",part.texture)
	mat.set_shader_parameter("textured",part.texture!=null)
	mat.set_shader_parameter("cutout",part.cutout)
	mat.set_shader_parameter("base_color",part.color)
	mat.set_shader_parameter("biome_tint",Color(BIOMES[world].tint))
	mat.set_shader_parameter("grain_map",preload("res://scripts/arcade_materials.gd").MAPS[world])
	mat.set_shader_parameter("grain_strength",.10 if part.texture else .48)
	var strength := .18 if world==1 or species in OPEN_FLOWERS else .71 if world in [0,3,7,9,10] else .42
	if species.ends_with("_coral"):
		var reef_tint := "56dfd2" if species == "staghorn_coral" else "ee81ae"
		mat.set_shader_parameter("base_color",Color(reef_tint))
		mat.set_shader_parameter("grain_map",preload("res://assets/surfaces/aurora_ground_v1.png"))
		mat.set_shader_parameter("mineral",true)
		strength = 0.
	if species in ["amanita","morel"]: strength=.23
	if species=="crystals":
		mat.set_shader_parameter("base_color",Color(["88e0dc","80d18b","f5c276","cda6fa","65ebab","ffc780","eabaff","9defff","ff844b","d79eff","8df4f7"][world]) if part.crystal else Color("4f5266"))
		mat.set_shader_parameter("grain_map",preload("res://assets/surfaces/aurora_ground_v1.png"))
		mat.set_shader_parameter("mineral",true)
		strength = 0.
	mat.set_shader_parameter("recolor",0. if part.bark else strength)
	mat.set_shader_parameter("bend",.08 if part.bark or species in ["deadwood","twisted"] else .28 if species in ["mushroom","lily"] else .90)
	mat.set_shader_parameter("glow",.11 if world in [6,9] and not part.bark else .025)
	if species.ends_with("_coral") or species=="crystals":
		mat.set_shader_parameter("glow",.12 if part.crystal or species.ends_with("_coral") else .015)
		mat.set_shader_parameter("bend",0.)
	mat.set_shader_parameter("atlas_bias",.55 if world==1 and part.cutout else 0.)
	mat.set_shader_parameter("wind",0. if Flora.reduced_motion else 1.)
	materials[key] = mat
	Flora.mats["plant_pack/"+key] = mat
	return mat

static func instance(rng: RandomNumberGenerator, point: Vector3, height: float, width_scale: float = 1.) -> Transform3D:
	var scale_value := Vector3(height*width_scale,height,height*width_scale)
	return Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(scale_value),point)

static func flora_landmark(root: Node3D, index: int, quality: bool) -> void:
	var trees: Array[Transform3D] = [Transform3D(Basis.from_scale(Vector3.ONE*7.1),Vector3.ZERO)]
	batch(root,1,"broadleaf",trees,quality,155.)
	var flowers: Array[Transform3D] = []
	var rng := RandomNumberGenerator.new()
	rng.seed=index*137+59
	for i in 7:
		var angle := i*TAU/7.
		flowers.append(instance(rng,Vector3(cos(angle)*2.,0.,sin(angle)*2.),.77))
	batch(root,1,"flower_bush",flowers,quality,105.)

static func batch(root: Node3D, world: int, species: String, placements: Array[Transform3D], quality: bool, reach: float) -> void:
	if placements.is_empty():
		return
	var data := prototype(species)
	for i in data.parts.size():
		var part: Dictionary = data.parts[i]
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.use_custom_data = true
		multi.mesh = part.mesh
		multi.instance_count = placements.size()
		var bounds := AABB()
		for j in placements.size():
			multi.set_instance_transform(j,placements[j])
			multi.set_instance_custom_data(j,Color(fposmod(j*.618,.99),fposmod(j*.381+.45,1.),0,0))
			var placed := placements[j]*multi.mesh.get_aabb()
			bounds = placed if j==0 else bounds.merge(placed)
		multi.custom_aabb = bounds.grow(.38)
		var group := MultiMeshInstance3D.new()
		group.name = "PackFlora_%s_%d"%[species,i]
		group.multimesh = multi
		group.material_override = paint(world,species,part,i)
		group.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		group.visibility_range_end = reach
		group.visibility_range_end_margin = 8.
		group.set_meta("plant_species",species)
		group.set_meta("plant_triangles",multi.mesh.surface_get_array_index_len(0)/3)
		root.add_child(group)
		apply_quality(group,quality)

static func apply_quality(group: MultiMeshInstance3D, quality: bool) -> void:
	var count := group.multimesh.instance_count
	group.multimesh.visible_instance_count = count if quality else maxi(1,ceili(count*.62))

static func set_quality(root: Node, quality: bool) -> void:
	for group: MultiMeshInstance3D in root.find_children("PackFlora_*","MultiMeshInstance3D",true,false):
		apply_quality(group,quality)

static func populate_road(parent: Node3D, world: int, index: int, quality: bool, clearings: Array[AABB], seed_value: int) -> void:
	if index<2 or index*30.>Course.length_for(world)-92.:
		return
	var style := preload("res://scripts/planets.gd").style_index(world)
	var storm := world>=11 and style==8
	var profile: Dictionary = STORM_PLANTS if storm else BIOMES[style]
	var species: String = profile.patch[posmod(index,profile.patch.size())]
	var tall := species in TALL_PATCHES
	var count: int = mini(5,profile.density) if tall else profile.density
	if world>=9: count=ceili(count*.65)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ (world*45379+index*7919+163)
	var placements: Array[Transform3D] = []
	var reserves: Array[AABB] = clearings.duplicate()
	for kind: String in Loops.kinds(world):
		var clearance := Loops.roadside_clearance(kind,world)
		clearance.position.z += index*30.
		reserves.append(clearance)
	var positions: Array[Vector2] = []
	for patch in 4:
		var side := -1. if patch%2==0 else 1.
		var shoulder := rng.randf_range(5.8,6.65)
		if style==4 or tall: shoulder+=.85
		positions.append(Vector2(side*shoulder,rng.randf_range(-25.,-5.)))
	for i in count:
		var patch := positions[i%positions.size()]
		var px := patch.x+rng.randf_range(-.85,.85)
		var pz := clampf(patch.y+rng.randf_range(-3.6,3.6),-29.4,-.6)
		var height := rng.randf_range(1.35,2.6) if tall else rng.randf_range(.50,1.06)
		var y := SUNKEN_GROUND
		var width := 1.
		if species=="lily":
			y = -.219
			height = rng.randf_range(.13,.22)
			width = .61
		elif style==4:
			y = -.32
		elif species=="mushroom":
			height *= 1.6
		elif style==8 and not storm:
			var s := index*30.-pz
			var lava := sin(px*.25+sin(-s*.19))+sin(-s*.28-sin(px*.14))
			if absf(lava)<1.32: continue
		var mesh_bounds: AABB = prototype(species).bounds
		var transform := instance(rng,Vector3(px,y,pz),height,width)
		var volume := transform*mesh_bounds
		var side := signf(px)
		var inner := volume.position.x if side>0. else -volume.end.x
		transform.origin.x+=side*maxf(0.,5.45-inner)
		var bounds := transform*mesh_bounds
		if reserves.any(func(box: AABB) -> bool: return box.intersects(bounds)): continue
		placements.append(transform)
	batch(parent,world,species,placements,quality,118. if tall else 78.)
	populate_canopy(parent,world,index,quality,reserves,rng,profile)

static func populate_bend(parent: Node3D, world: int, index: int, route: RefCounted, quality: bool, clearings: Array[AABB]) -> void:
	var start := index*30.
	if start<60. or start>Course.length_for(world)-110.: return
	var data := preload("res://scripts/planets.gd")
	var style: int = data.style_index(world)
	var storm := world>=11 and style==8
	var species: Array = ["broad_fronds","flower_bush"] if storm else BEND_PLANTS[style]
	for turn: Vector4 in route.turns:
		if turn.x>=start+30.: break
		if turn.y<start: continue
		var station := lerpf(turn.x,turn.y,.21)
		if station<start or station>=start+30.: continue
		var side := -signf(route.sample(station).y)
		var rng := RandomNumberGenerator.new()
		rng.seed=route.seed_value^(world*4129+floori(turn.x))
		for slot in range(2):
			var key: String = species[slot]
			var along := station+1.6+slot*3.25
			var height := (5.2 if storm else 4.05) if slot==0 else (2.15 if storm else 1.5)
			var basis := instance(rng,Vector3.ZERO,height,.77)
			var bounds: AABB = prototype(key).bounds
			var radius := ((basis*bounds).size.x)*.5
			var point: Vector3 = route.local_curve(Vector3(side*(5.84+radius+slot*.34),0,start-along),along)
			point.y=-.26 if style==4 else route.terrain_height(along,point.x)-.31
			basis.origin=point
			var volume := basis*bounds
			if clearings.any(func(box: AABB) -> bool: return box.intersects(volume)): continue
			volume.position.z-=start
			if Loops.kinds(world).any(func(kind: String) -> bool: return Loops.roadside_clearance(kind,world).intersects(volume)): continue
			var placements: Array[Transform3D] = [basis]
			batch(parent,world,key,placements,quality,123.)

static func populate_canopy(parent: Node3D, world: int, index: int, quality: bool, reserves: Array[AABB], rng: RandomNumberGenerator, profile: Dictionary) -> void:
	var style := preload("res://scripts/planets.gd").style_index(world)
	var storm := world>=11 and style==8
	if style==4 or (style==8 and not storm) or (style!=1 and posmod(index+world,3)!=1):
		return
	var species: String = profile.trees[posmod(int(index/2)+world,profile.trees.size())]
	var data := prototype(species)
	var bounds: AABB = data.bounds
	var placements: Array[Transform3D] = []
	var vines: Array[Transform3D] = []
	var blooms: Array[Transform3D] = []
	var trunks: Array = parent.get_meta("solid_nature_boxes",[])
	for side in [-1.,1.]:
		if style!=1 and data.triangles>1800 and side!=(1. if posmod(index,2)==0 else -1.): continue
		var count := 2 if style==1 else 1
		for i in count:
			var x: float = side * (8.8 + i * 8. + rng.randf_range(-1.3,1.3))
			var at := Vector3(x,SUNKEN_GROUND,rng.randf_range(-25.,-5.))
			var height := rng.randf_range(4.8,6.8) if storm else rng.randf_range(8.5,13.) if style in [1,6,7] else rng.randf_range(5.2,8.8)
			var placement := instance(rng,at,height,.88)
			var volume := placement*bounds
			var inner_edge := volume.position.x if side>0. else -volume.end.x
			if inner_edge<6.6:
				var shift: float = side*(6.6-inner_edge)
				at.x += shift
				placement.origin.x += shift
				volume.position.x += shift
			if reserves.any(func(box: AABB) -> bool: return box.intersects(volume)): continue
			placements.append(placement)
			if style==1:
				trunks.append(AABB(at-Vector3(.42,0,.42),Vector3(.84,height*.65,.84)))
			if i==0 and style in [1,3,6,9] and posmod(index+int(side),2)==0:
				var vine_at := at+Vector3(side*.25,height*.21,.7)
				var vine := Transform3D(Basis(Vector3.UP,.27*side)*Basis.from_scale(Vector3(height*.49,height*.61,height*.53)),vine_at)
				if not reserves.any(func(box: AABB) -> bool: return box.intersects(vine*prototype("hanging_ivy").bounds)):
					vines.append(vine)
			if i==0 and style in [1,3,5] and posmod(index,2)==0:
				var flower := instance(rng,Vector3(side*rng.randf_range(8.2,10.),SUNKEN_GROUND,at.z-3.),rng.randf_range(3.2,4.8),.74)
				var species_at := "golden_flower" if style!=3 else "flower_blue"
				var flower_bounds: AABB = flower*prototype(species_at).bounds
				if not reserves.any(func(box: AABB) -> bool: return box.intersects(flower_bounds)):
					blooms.append(flower)
	batch(parent,world,species,placements,quality,145.)
	batch(parent,world,"hanging_ivy",vines,quality,126.)
	batch(parent,world,"flower_blue" if style==3 else "golden_flower",blooms,quality,120.)
	parent.set_meta("solid_nature_boxes",trunks)

static func populate_settlement(parent: Node3D, world: int, site_x: float, rng: RandomNumberGenerator, quality: bool, buildings: Array[Rect2]) -> void:
	var profile: Dictionary = BIOMES[preload("res://scripts/planets.gd").style_index(world)]
	var side := signf(site_x)
	var root := Node3D.new()
	root.name = "SettlementVegetation"
	parent.add_child(root)
	var grouped: Dictionary = {}
	# Leave the fronts open. Taller plants frame the buildings from their sides and rear.
	var slots := [Vector2(-3.,-9.),Vector2(3.,10.),Vector2(7.,-10.),Vector2(-4.,10.),Vector2(9.,7.),
		Vector2(1.,-11.5),Vector2(10.,-7.),Vector2(-5.2,-7.),Vector2(8.,10.8),Vector2(-4.,13.),Vector2(6.,-13.),
		Vector2(-5.8,5.3),Vector2(-5.9,-1.),Vector2(8.7,-1.2),Vector2(1.8,-5.),
		Vector2(1.,13.3),Vector2(2.,-13.9),Vector2(-3.4,7.6),Vector2(6.3,12.7)]
	var canopy: Array[Vector3] = []
	for slot: Vector2 in slots:
		if canopy.size()>=int(profile.grove):
			break
		var at := Vector3(side*(slot.x+rng.randf_range(-.65,.65)),SUNKEN_GROUND,slot.y+rng.randf_range(-.7,.7))
		if world in [4,8]:
			at.x = lerpf(at.x,side*2.8,.13)
			at.z *= .93
			at.y = -.02
		if buildings.any(func(box:Rect2) -> bool: return box.grow(.75).has_point(Vector2(at.x,at.z))): continue
		if canopy.any(func(point:Vector3) -> bool: return point.distance_squared_to(at)<6.25): continue
		var species: String = profile.trees[canopy.size()%profile.trees.size()]
		var height := rng.randf_range(4.2,6.9)
		if world in [2,5]: height*=.64
		if species=="mushroom": height*=.68
		var placement := instance(rng,at,height,rng.randf_range(.80,1.04))
		var bounds: AABB = placement*prototype(species).bounds
		if bounds.position.x+site_x<5.6 and bounds.end.x+site_x> -5.6: continue
		if not grouped.has(species): grouped[species]=[]
		grouped[species].append(placement)
		canopy.append(at)
	for species: String in grouped:
		var trees: Array[Transform3D] = []
		trees.assign(grouped[species])
		batch(root,world,species,trees,quality,205.)
	if world not in [4,8]:
		add_canopy_shadows(root,grouped)
	var shrubs: Array[Transform3D] = []
	for i in (18 if world in [0,1,3,6,9,10] else 12):
		var at := Vector3(side*rng.randf_range(-5.4,-3.),-.23,rng.randf_range(-11.5,11.5))
		if world==4:
			at.x = side*rng.randf_range(-3.7,1.5)
			at.z *= .85
			at.y = -.03
		elif world==8:
			at.x = side*rng.randf_range(-3.7,-1.3)
			at.z *= .68
			at.y = -.03
		if buildings.any(func(box:Rect2) -> bool: return box.grow(.22).has_point(Vector2(at.x,at.z))): continue
		shrubs.append(instance(rng,at,rng.randf_range(.40,.88)))
	batch(root,world,profile.bed,shrubs,quality,110.)
	root.set_meta("grove_count",canopy.size())

static func add_canopy_shadows(root: Node3D, grouped: Dictionary) -> void:
	if grouped.is_empty():
		return
	if not canopy_shadow_mesh:
		canopy_shadow_mesh = PlaneMesh.new()
		canopy_shadow_mesh.size = Vector2.ONE
		canopy_shadow_material = ShaderMaterial.new()
		canopy_shadow_material.shader = CANOPY_SHADOW
	var placements: Array[Transform3D] = []
	for species: String in grouped:
		for tree: Transform3D in grouped[species]:
			var height := tree.basis.y.length()
			var at := tree.origin + Vector3(-height*.17,0.,height*.18)
			at.y = -.209
			placements.append(Transform3D(Basis(Vector3.UP,.65).scaled(Vector3(height*.72,1.,height*.94)),at))
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = canopy_shadow_mesh
	multi.instance_count = placements.size()
	for i in placements.size():
		multi.set_instance_transform(i,placements[i])
	var shadows := MultiMeshInstance3D.new()
	shadows.name = "CanopyShadows"
	shadows.multimesh = multi
	shadows.material_override = canopy_shadow_material
	shadows.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shadows.visibility_range_end = 100.
	root.add_child(shadows)
