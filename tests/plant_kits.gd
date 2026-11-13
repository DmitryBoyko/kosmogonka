extends SceneTree

const Kit = preload("res://scripts/plant_kit.gd")
var checks := 0
var errors := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		errors += 1
		push_error(message)

func run() -> void:
	root.size = Vector2i(540,960)
	var app = load("res://scenes/main.tscn").instantiate()
	app.test_mode = true
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app.set_physics_process(false)
	var profile = root.get_node("Profile")
	profile.first_person = false
	profile.quality = true
	for species: String in Kit.MODELS:
		var data := Kit.prototype(species)
		check(not data.parts.is_empty() and is_equal_approx(data.bounds.size.y,1.),"source loads and is grounded for "+species)
		check(data.parts.all(func(part):return part.mesh.get_aabb().size.length()>.04),"valid mesh for "+species)
	for world in Kit.BIOMES.size():
		app.planet = world
		app.test_layout_seed = 177+world
		app.reset_course()
		app.begin_run()
		var settlements: Node3D = app.roadside_settlements
		check(settlements.sites.size()>=2,"world has settlements %d"%world)
		var finishes: Dictionary = {}
		for front_site: Dictionary in settlements.front_sites:
			for mesh: MeshInstance3D in front_site.node.find_children("*","MeshInstance3D",true,false):
				var material := mesh.material_override as ShaderMaterial
				if material and material.shader.resource_path.ends_with("coating.gdshader"):
					var cladding: Texture2D = material.get_shader_parameter("cladding")
					finishes[cladding.resource_path] = true
		check(finishes.size()>=2,"front districts use distinct cladding textures on world %d"%world)
		for station in [870.,910.,948.]:
			settlements.advance(true,station)
			var sides: Dictionary = {}
			for front_site: Dictionary in settlements.front_sites:
				if front_site.node.visible and front_site.s<station:
					sides[signf(front_site.x)] = true
			check(sides.size()==2,"front camera has settlements on both sides on world %d"%world)
		for site: Dictionary in settlements.sites:
			var grove: Node3D = site.node.get_node("SettlementVegetation")
			var count: int = grove.get_meta("grove_count")
			var minimum := 3 if world in [4,8] else 4
			check(count>=minimum and count<=9,"bounded settlement grove world %d (%d)"%[world,count])
			var groups := grove.find_children("PackFlora_*","MultiMeshInstance3D")
			check(groups.size()<=7,"settlement uses a bounded set of batches")
		var site: Dictionary = settlements.sites[0]
		app.distance = site.s-22.
		app.runner.position = Vector3.ZERO
		app._process(.016)
		var road_groups: Array[Node] = []
		for chunk: Node3D in app.scenery.chunks.values():
			road_groups.append_array(chunk.find_children("PackFlora_*","MultiMeshInstance3D",true,false))
		check(not road_groups.is_empty(),"roadside flora on world %d"%world)
		var visible_triangles := 0
		for group: MultiMeshInstance3D in road_groups:
			if not group.is_visible_in_tree(): continue
			visible_triangles += int(group.get_meta("plant_triangles"))*group.multimesh.instance_count
			check(group.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,"road plants skip per-blade shadows")
			var before := group.multimesh.visible_instance_count
			Kit.apply_quality(group,false)
			check(group.multimesh.visible_instance_count<=before,"lower quality reduces plant density")
			Kit.apply_quality(group,true)
		check(visible_triangles<65000,"bounded streamed flora triangles world %d (%d)"%[world,visible_triangles])
		print("PLANTS world=%d road_triangles=%d site_trees=%d"%[world,visible_triangles,site.node.get_node("SettlementVegetation").get_meta("grove_count")])
		if DisplayServer.get_name()!="headless" and world in [1,2,4,6,7,8]:
			app.camera.position = Vector3(-signf(site.x)*3.,5.4,4.6)
			app.camera.look_at(site.node.position+Vector3.UP*1.9)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://build/plants-world-%d.png"%world)
	preload("res://scripts/natural_flora.gd").set_motion(true)
	check(Kit.materials.values().all(func(mat):return mat.get_shader_parameter("wind")==0.),"reduced motion freezes all imported plants")
	preload("res://scripts/natural_flora.gd").set_motion(false)
	print("PLANT KIT: %d checks, %d failures"%[checks,errors])
	if is_instance_valid(app.mobile_presentation): app.mobile_presentation.free()
	else: app.free()
	await process_frame
	quit(1 if errors else 0)
