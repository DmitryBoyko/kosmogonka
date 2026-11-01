extends SceneTree
var app: Node
func _initialize() -> void: call_deferred("run")
func capture(label_value: String) -> void:
	app.spawn_and_update()
	for i in 2: app._process(1.0/60)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+label_value+".png")

func run() -> void:
	root.size=Vector2i(540,960)
	app=load("res://scenes/main.tscn").instantiate()
	app.test_mode=true
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app.set_physics_process(false)
	for planet in 4:
		app.planet=planet
		app.start_level()
		app.begin_run()
		app.toast_timer=0
		app.distance=989
		app.lane=planet%3
		app.x=(app.lane-1)*2.6
		app.runner.position.x=app.x
		await capture("course-dense-"+str(planet))
	app.planet=0
	app.start_level()
	app.begin_run()
	app.toast_timer=0
	app.lane=0
	app.x=-2.6
	app.runner.position.x=app.x
	app.distance=1193
	await capture("course-arch-reward")
	app.slide_timer=0.6
	app.distance=1200
	await capture("course-arch-under")
	app.slide_timer=0
	for i in 3:
		app.distance=746+[-22,0,22][i]
		await capture("course-courier-"+str(i))
	app.stars=285
	app.commit_result(true)
	app.show_results(true)
	await capture("course-results-goal")
	app.show_menu()
	app.hud.planets(0,3)
	app.state="planets"
	await capture("course-planets-goals")
	app.free()
	await process_frame
	quit()
