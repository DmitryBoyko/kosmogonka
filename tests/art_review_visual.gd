extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(960,720)
	var app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; app.set_process(false); app.set_physics_process(false)
	var metrics:Array=[]
	for planet in [0,1,2,3,9]:
		app.planet=planet; app.start_level(); app.begin_run(); app.distance=2100; app.spawn_and_update(); app.finish_level(); app.hud.hide()
		app.camera.position=Vector3(0,4.2,18); app.camera.look_at(Vector3(0,4.,0)); app.camera.fov=62
		for i in 4: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/finish-arch-%d.png"%planet)
		metrics.append({"planet":planet,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})
	var file:=FileAccess.open("res://build/art-render-metrics.json",FileAccess.WRITE); file.store_string(JSON.stringify(metrics,"  ")); file.close()
	app.free(); await create_timer(.1).timeout; quit()
