extends SceneTree
var app:Node
func _initialize() -> void: call_deferred("run")
func shot(key:String) -> void:
	await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/space-review-"+key+".png")
func run() -> void:
	root.size=Vector2i(540,960)
	app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; app.set_process(false); app.set_physics_process(false)
	app.show_menu(); app.menu_crew.wait=99; app._process(.016); await shot("menu")
	app.on_action("select"); app._process(.016); await shot("selection")
	for who in 2:
		root.get_node("Profile").hero=who
		app.planet=1; app.start_level(); app.cinema_time=3.5; app._process(.016)
		await shot("orbit-"+str(who))
		app.camera.position=app.orbit.ship.global_transform*Vector3(4.0,3.3,-6.0)
		app.camera.look_at(app.orbit.ship.global_transform*Vector3(0,1.4,0)); app.camera.fov=57
		await shot("cockpit-"+str(who))
	app.cinema_time=7.8; app._process(.016); await shot("landing")
	for planet in [0,2,6,9]:
		app.planet=planet; app.start_level(); app.begin_run(); app.distance=390; app.spawn_and_update()
		for i in 12: app._process(1./60)
		await shot("sky-"+str(planet))
	app.free(); await create_timer(.1).timeout; quit()
