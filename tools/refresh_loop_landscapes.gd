extends SceneTree
func _initialize() -> void: call_deferred("run")
func own(node:Node,scene_root:Node) -> void:
	for child in node.get_children(): child.owner=scene_root; own(child,scene_root)
func run() -> void:
	var app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; app.set_process(false); app.set_physics_process(false)
	for world in 10:
		var path:="res://assets/planet_cache/landscape_%d.res"%world
		var data=load(path); app.scenery.planet=world
		for index in range(-2,75):
			var changed:=false
			for kind:String in preload("res://scripts/loop_layout.gd").kinds(world):
				var start:float=preload("res://scripts/loop_layout.gd").start(kind)
				if index*30.<start+70. and (index+1)*30.>start-30.: changed=true
			if not changed: continue
			var landscape:Node3D=app.scenery.make_landscape(index); own(landscape,landscape)
			var scene:=PackedScene.new(); scene.pack(landscape); data.chunks[index+2]=scene; landscape.free()
		var error:=ResourceSaver.save(data,path,ResourceSaver.FLAG_COMPRESS)
		if error!=OK: push_error("Landscape save failed "+str(world)); quit(1); return
		print("LOOP LANDSCAPE ",world)
		await process_frame
	app.free(); await process_frame; quit()
