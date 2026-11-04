extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(540,960)
	var app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; app.set_process(false); app.set_physics_process(false)
	app.start_flight(0)
	for shot in 3:
		for i in 200: app.flight.advance(1./60); app._process(1./60)
		await process_frame; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/spaceflight-%d.png"%shot)
	app.free(); await create_timer(.1).timeout; quit()
