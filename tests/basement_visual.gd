extends SceneTree
const Basement=preload("res://scripts/basement.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(540,960)
	var app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; app.set_process(false); app.set_physics_process(false)
	app.planet=0; app.start_level(); app.begin_run()
	var routes:Array=[]; var sky:Dictionary={}
	for event:Dictionary in app.events:
		if event.kind=="basement": routes.append(event)
		if event.kind=="tunnel": sky=event
	for shot in 5:
		var route:Dictionary=routes[0 if shot<3 else 1]
		app.lane=route.lane; app.x=(route.lane-1)*2.6
		app.distance=route.s-route.length*.5-10 if shot==0 else route.s-route.length*.5+6 if shot==1 else route.s-9
		app.height=0 if shot==0 else -2.4 if shot==1 else Basement.FLOOR
		app.support=app.height; app.roll_timer=1 if shot in [2,3] else 0; app.slide_timer=app.roll_timer
		if shot==4:
			app.distance=sky.s-30; app.height=0; app.roll_timer=0; app.slide_timer=0
		app.runner.position=Vector3(app.x,app.height,0); app.spawn_and_update()
		for i in 50: app._process(1./60)
		await process_frame; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/basement-%d.png"%shot)
	app.free(); await create_timer(.1).timeout; quit()
