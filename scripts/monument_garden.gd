extends RefCounted

const G = preload("res://scripts/geometry.gd")
const SM = preload("res://scripts/salvage_mesh.gd")
const Plants = preload("res://scripts/plant_kit.gd")
const Surface = preload("res://scripts/surface_style.gd")
const LAWNS := [Vector2(24.,-10.),Vector2(28.,-33.),Vector2(11.2,-55.)]
const TREES := [
	["silver_birch","pink_ancient"],["alder","birch"],["poly_tree","alder"],["silver_birch","poly_tree"],
	["coconut","leaning_palm"],["poly_tree","birch"],["pink_ancient","alder"],["snow_pine","silver_birch"],
	["alder","poly_tree"],["pink_ancient","silver_birch"],["silver_birch","dark_pine"],
]
const FLOWERS := ["flower_blue","flower_bush","golden_flower","flower_blue","flower_white","golden_flower","bell","flower_white","poppy","bell","flower_white"]

static func side_ornament(bounds: AABB) -> bool:
	var center := bounds.get_center()
	return absf(absf(center.x)-23.)<3.8 and center.z> -36. and center.z< -17. and bounds.size.x<20. and bounds.size.z<24.

static func install(finish: Node3D, world: int, quality: bool) -> void:
	var garden := finish.get_node_or_null("FinishCity/FlowerGardens")
	if garden:
		garden.free()
	for child: Node3D in finish.get_children():
		# Older packed finishes combined the side decorations into local meshes.
		if child.has_meta("architecture_name") and absf(child.position.x)>20.:
			child.free()
		elif child is MeshInstance3D and side_ornament(child.transform*child.mesh.get_aabb()):
			child.free()

	var plaza := Node3D.new()
	plaza.name = "MonumentGarden"
	finish.add_child(plaza)
	if world in [4,8]:
		ground_island(plaza,world)
	var paving: String = ["bbc8be","c2c9ae","c7ab83","859cab","b6c6be","d6bb8f","ac9cab","b9ccd5","95786d","aa98b4","b5c8d0"][world]
	var stone := ShaderMaterial.new()
	stone.shader = preload("res://assets/salvage/space_surface.gdshader")
	stone.set_shader_parameter("surface_map",preload("res://assets/finish_city/concrete_wall_006_diff_1k.jpg"))
	stone.set_shader_parameter("tint",Color(paving))
	stone.set_shader_parameter("tile_scale",.48)
	stone.set_shader_parameter("metalness",.02)
	stone.set_shader_parameter("roughness",.89)
	var central := G.box(plaza,Vector3(7.7,.18,9.),Vector3(0,-.04,-4.5),paving)
	central.material_override = stone
	central.set_meta("architecture_solid",true)
	for side in [-1.,1.]:
		G.box(plaza,Vector3(5.2,.04,65.),Vector3(side*18.,-.20,-33.5),paving).material_override = stone
	G.box(plaza,Vector3(41.,.04,4.8),Vector3(0.,-.20,-46.),paving).material_override = stone
	G.box(plaza,Vector3(41.,.04,4.4),Vector3(0.,-.20,-1.9),paving).material_override = stone

	var rng := RandomNumberGenerator.new()
	rng.seed = 91871+world*4177
	var lawns: Array[Transform3D] = []
	var blooms: Array[Transform3D] = []
	var trees := [[],[]]
	var trunks: Array[AABB] = []
	for side in [-1.,1.]:
		for i in LAWNS.size():
			var island: Vector2 = LAWNS[i]
			var at := Vector3(side*island.x,-.20,island.y)
			var edge := G.box(plaza,Vector3(8.45,.052,7.0),at,Color(paving).darkened(.25).to_html(false))
			var grass := G.box(plaza,Vector3(8.,.06,6.6),at+Vector3.UP*.012,"7eaf6d")
			grass.material_override = Surface.ground(1,true)
			for tile: MeshInstance3D in [edge,grass]: tile.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var tree_pos := at+Vector3(side*rng.randf_range(-.65,.8),.04,-.85)
			var tree_scale := rng.randf_range(4.7,6.2)
			trees[i%2].append(Plants.instance(rng,tree_pos,tree_scale,.86))
			trunks.append(AABB(tree_pos-Vector3(.19,0.,.19),Vector3(.38,tree_scale*.56,.38)))
			for strand in 17:
				var scatter := Vector3(rng.randf_range(-3.65,3.65),.04,rng.randf_range(-2.86,2.86))
				lawns.append(Plants.instance(rng,at+scatter,rng.randf_range(.20,.38)))
			for flower in 7:
				var scatter := Vector3(-side*rng.randf_range(1.8,3.7),.055,rng.randf_range(-2.1,2.3))
				blooms.append(Plants.instance(rng,at+scatter,rng.randf_range(.37,.63)))
	for i in 2:
		var placements: Array[Transform3D] = []
		placements.assign(trees[i])
		Plants.batch(plaza,world,TREES[world][i],placements,quality,135.)
	Plants.batch(plaza,world,"meadow_grass",lawns,quality,94.)
	Plants.batch(plaza,world,FLOWERS[world],blooms,quality,88.)
	plaza.set_meta("solid_nature_boxes",trunks)
	G.merge_static(plaza)

static func ground_island(plaza: Node3D, world: int) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center := Vector3(0,-.201,-24.)
	for i in 20:
		var points: Array[Vector3] = []
		for j in [i,i+1]:
			var angle: float = j*TAU/20.
			var edge := 1.+sin(angle*5.)*.035
			points.append(center+Vector3(cos(angle)*69.*edge,0.,sin(angle)*81.*edge))
		SM._triangle(tool,center,points[0],points[1])
	var slab := G.part(plaza,tool.commit(),Vector3.ZERO,Surface.ground(4,true) if world==4 else Surface.ground(5,true))
	slab.name = "GardenIsland"
	slab.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
