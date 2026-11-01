extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(540,960)
	var app=load("res://scenes/main.tscn").instantiate()
	app.test_mode=true
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app.set_physics_process(false)
	app.start_level()
	app.begin_run()
	app.distance=400
	app.toast_timer=0
	app.spawn_and_update()
	app.stars=3
	app.pickup_feedback.notify(3)
	for frame in 28:
		app._process(1.0/60)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/pickup-frame-%02d.png" % frame)
	app.distance=900
	app.spawn_and_update()
	app.stars=4
	app.pickup_feedback.notify(1)
	for i in 6: app._process(1.0/60)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/pickup-front.png")
	app.free()
	await process_frame
	quit()
