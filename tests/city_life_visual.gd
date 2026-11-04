extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(960,720)
	var app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; app.set_process(false); app.set_physics_process(false)
	app.planet=1; app.start_level(); app.begin_run(); app.distance=2100; app.spawn_and_update(); app.finish_level()
	app.hud.hide()
	var life=app.finish.get_node("FinishCity/RunningResidents")
	for shot in 3:
		life.advance(1.4)
		app.camera.position=[Vector3(4,8,25),Vector3(24,3,-8),Vector3(0,18,55)][shot]
		app.camera.look_at([Vector3(0,2,-17),Vector3(33,1.7,-25),Vector3(0,3,-15)][shot])
		await process_frame; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/city-life-%d.png"%shot)
	app.free(); await create_timer(.1).timeout; quit()
