extends RefCounted

const Course = preload("res://scripts/course.gd")
const Loops = preload("res://scripts/loop_layout.gd")
const Flora = preload("res://scripts/natural_flora.gd")
const FOLIAGE = preload("res://assets/plant_kit/foliage.gdshader")
const CANOPY_SHADOW = preload("res://assets/plant_kit/canopy_shadow.gdshader")
const ROOT := "res://assets/plant_kit/"
const TREE_SELECTION := "tree_selection.glb"
const SUNKEN_GROUND := -.24

# Each palette defines roadside patches, the settlement canopy and its understory.
const BIOMES := [
	{"patch":["violet_grass","flower_blue"],"trees":["silver_birch","pink_ancient"],"bed":"flower_blue","tint":"7dbab4","density":17,"grove":7},
	{"patch":["fern","poppy","flower_bush","meadow_grass"],"trees":["alder","broadleaf","birch"],"bed":"flower_bush","tint":"88b957","density":24,"grove":9},
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
	"golden_flower":["niwl/sunflower.glb","",["T_Plants_General"]],
	"mushroom":["mega/Mushroom_Common.gltf",""],
	"alien_leaf":["mega/Plant_7_Big.gltf",""],
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
			parts.append({"source":mesh.mesh,"surface":surface,"placement":placement,"texture":texture,"color":color,"bark":bark,"cutout":cutout})
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
	var result := {"parts":parts,"bounds":fit*bounds}
	prototypes[species] = result
	return result

static func paint(world: int, species: String, part: Dictionary, index: int) -> ShaderMaterial:
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
	var strength := .18 if world==1 or species in OPEN_FLOWERS else .71 if world in [0,3,7,9,10] else .42
	mat.set_shader_parameter("recolor",0. if part.bark else strength)
	mat.set_shader_parameter("bend",.08 if part.bark or species in ["deadwood","twisted"] else .28 if species in ["mushroom","lily"] else .90)
	mat.set_shader_parameter("glow",.17 if world in [6,9] and not part.bark else .035)
	mat.set_shader_parameter("wind",0. if Flora.reduced_motion else 1.)
	materials[key] = mat
	Flora.mats["plant_pack/"+key] = mat
	return mat

static func instance(rng: RandomNumberGenerator, point: Vector3, height: float, width_scale: float = 1.) -> Transform3D:
	var scale_value := Vector3(height*width_scale,height,height*width_scale)
	return Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(scale_value),point)

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
	var profile: Dictionary = BIOMES[world]
	var species: String = profile.patch[posmod(index,profile.patch.size())]
	var tall := species in TALL_PATCHES
	var count: int = mini(5,profile.density) if tall else profile.density
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ (world*45379+index*7919+163)
	var placements: Array[Transform3D] = []
	var reserves: Array[AABB] = clearings.duplicate()
	for kind: String in Loops.kinds(world):
		var clearance := Loops.clearance(kind)
		clearance.position.z += index*30.
		reserves.append(clearance)
	var positions: Array[Vector2] = []
	for patch in 4:
		var side := -1. if patch%2==0 else 1.
		var shoulder := rng.randf_range(6.4,10.8)
		if world==4 or tall: shoulder+=3.
		positions.append(Vector2(side*shoulder,rng.randf_range(-25.,-5.)))
	for i in count:
		var patch := positions[i%positions.size()]
		var px := patch.x+rng.randf_range(-1.25,1.25)
		var pz := clampf(patch.y+rng.randf_range(-3.6,3.6),-29.4,-.6)
		var height := rng.randf_range(1.35,2.6) if tall else rng.randf_range(.34,.77)
		var y := SUNKEN_GROUND
		var width := 1.
		if species=="lily":
			y = -.219
			height = rng.randf_range(.13,.22)
			width = .61
		elif world==4:
			y = -.32
		elif species=="mushroom":
			height *= 1.6
		elif world==8:
			var s := index*30.-pz
			var lava := sin(px*.25+sin(-s*.19))+sin(-s*.28-sin(px*.14))
			if absf(lava)<1.32: continue
		var transform := instance(rng,Vector3(px,y,pz),height,width)
		var bounds: AABB = transform*prototype(species).bounds
		if bounds.position.x<5.0 and bounds.end.x> -5.0: continue
		if reserves.any(func(box: AABB) -> bool: return box.intersects(bounds)): continue
		placements.append(transform)
	batch(parent,world,species,placements,quality,118. if tall else 78.)

static func populate_settlement(parent: Node3D, world: int, site_x: float, rng: RandomNumberGenerator, quality: bool, buildings: Array[Rect2]) -> void:
	var profile: Dictionary = BIOMES[world]
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
