extends SceneTree
func _initialize() -> void: call_deferred("run")
func shot(name_value:String) -> void:
	await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/feature-"+name_value+".png")
func run() -> void:
	root.size=Vector2i(540,960)
	var app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; app.set_process(false); app.set_physics_process(false)
	app.planet=1; app.start_level(); app.begin_run(); app.toast_timer=0
	var stairs:Dictionary={}; var passage:Dictionary={}
	for e in app.events:
		if e.kind=="stairs" and stairs.is_empty(): stairs=e
		if e.kind=="basement" and passage.is_empty(): passage=e
	for offset in [-25.,stairs.length*.5-1.]:
		app.distance=stairs.s+offset; app.lane=stairs.lane; app.x=(stairs.lane-1)*2.6
		app.height=0. if offset<0 else stairs.top; app.runner.position=Vector3(app.x,app.height,0)
		app.spawn_and_update(); app._process(.016); await shot("stairs-"+str(int(offset)))
	for offset in [-passage.length*.5-14,0.]:
		app.distance=passage.s+offset; app.lane=passage.lane; app.x=(passage.lane-1)*2.6
		app.height=0 if offset<0 else -4.8; app.runner.position=Vector3(app.x,app.height,0); app.spawn_and_update()
		for i in 60: app._process(1./60)
		await shot("passage-"+str(int(offset)))
	app.free(); await create_timer(.15).timeout; quit()
