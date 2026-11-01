extends SceneTree
var app: Node

func _initialize() -> void:
	call_deferred("run")

func shot(label_value: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("res://build/" + label_value + ".png")
	print("CAPTURE " + label_value)

func run() -> void:
	app = load("res://scenes/main.tscn").instantiate()
	app.test_mode = true
	root.add_child(app)
	await create_timer(0.4).timeout
	await shot("01-menu")
	app.on_action("select")
	await shot("02-crew")
	app.on_action("settings")
	await shot("03-settings")
	app.start_level()
	app.cinema_time = 2
	await shot("04-arrival")
	app.begin_run()
	app.set_physics_process(false)
	app.distance = 398
	app.lane = 1
	app.spawn_and_update()
	await create_timer(0.2).timeout
	await shot("05-running")
	app.distance = 902
	app.spawn_and_update()
	await create_timer(0.2).timeout
	await shot("06-front")
	app.distance = 1410
	app.activate_booster("jet")
	app.height = 3.2
	app.runner.position.y = 3.2
	app.spawn_and_update()
	await shot("07-jet")
	app.distance = 1800
	app.activate_booster("board")
	app.height = 0
	app.runner.position.y = 0.25
	app.spawn_and_update()
	await shot("08-board")
	app.distance = 2100
	app.finish_level()
	app.cinema_time = 8
	await shot("09-finale")
	app.show_results(true)
	await shot("10-results")
	app.free()
	quit()
