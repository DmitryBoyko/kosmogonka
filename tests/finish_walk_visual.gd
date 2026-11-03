extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(540,960)
	var app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; app.set_process(false); app.set_physics_process(false)
	app.planet=0; app.start_level(); app.begin_run(); app.distance=2100; app.spawn_and_update(); app.finish_level()
	for i in 12: await physics_frame; app.finish_walk.advance(1./60,false); app._process(1./60)
	for pose in [Vector3(0,.21,0),Vector3(17,.21,-22),Vector3(0,.21,-44)]:
		app.finish_walk.avatar.position=pose
		app.finish_walk.yaw=0 if pose.z==0 else PI*.5 if pose.x>0 else PI
		for i in 40: app._process(1./60)
		await process_frame; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/finish-walk-"+str(int(pose.z))+".png")
	app.free(); await create_timer(.2).timeout; quit()
