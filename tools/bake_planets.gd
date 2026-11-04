extends SceneTree
func _initialize() -> void: call_deferred("bake")
func own(node:Node,scene_root:Node) -> void:
	for child in node.get_children(): child.owner=scene_root; own(child,scene_root)
func bake() -> void:
	var app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; await process_frame; app.set_process(false); app.set_physics_process(false)
	DirAccess.make_dir_recursive_absolute("res://assets/planet_cache")
	for world in 10:
		app.planet=world
		var finish:Node3D=app.make_finish(); app.track_root.add_child(finish)
		preload("res://scripts/finish_walk.gd").prepare_collisions(finish)
		own(finish,finish)
		var scene:=PackedScene.new(); var error:=scene.pack(finish)
		if error!=OK: push_error("Pack failed"); quit(1); return
		error=ResourceSaver.save(scene,"res://assets/planet_cache/finish_%d.scn"%world,ResourceSaver.FLAG_COMPRESS)
		print("BAKED ",world," ",error)
		finish.free()
		var data:=preload("res://scripts/landscape_data.gd").new()
		app.scenery.planet=world
		for index in range(-2,75):
			var landscape:Node3D=app.scenery.make_landscape(index); own(landscape,landscape)
			var chunk:=PackedScene.new(); chunk.pack(landscape); data.chunks.append(chunk); landscape.free()
		app.scenery.anims.clear()
		ResourceSaver.save(data,"res://assets/planet_cache/landscape_%d.res"%world,ResourceSaver.FLAG_COMPRESS)
		await process_frame
	app.free(); await process_frame; quit()
