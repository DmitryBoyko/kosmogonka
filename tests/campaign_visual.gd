extends SceneTree
var app: Node

func _initialize() -> void: call_deferred("run")

func shot(label_value: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+label_value+".png")
	print("CAPTURE "+label_value)

func run() -> void:
	app=load("res://scenes/main.tscn").instantiate()
	app.test_mode=true
	root.add_child(app)
	await process_frame
	app.set_physics_process(false)
	app.start_level()
	app.begin_run()
	app.distance=390
	app.spawn_and_update()
	for framing in [1.0,1.5,2.0]:
		app.camera_variant=framing
		await shot("camera-"+str(framing))
	for index in [1,2,3]:
		app.planet=index
		app.start_level()
		app.begin_run()
		app.distance=[200,520,185][index-1]
		app.spawn_and_update()
		await shot("planet-"+str(index))
		app.distance=900
		app.spawn_and_update()
		await shot("planet-front-"+str(index))
		app.finish_level()
		app.cinema_time=2.5
		await shot("planet-launch-"+str(index))
		app.cinema_time=8
		await shot("planet-orbit-"+str(index))
	app.planet=1
	app.start_level()
	app.begin_run()
	app.distance=180
	app.spawn_and_update()
	app.roll_timer=0.8
	app.slide_timer=0.8
	for i in 15: app._process(1.0/60)
	await shot("trick-roll")
	app.roll_timer=0
	app.slide_timer=0
	app.flip_used=true
	app.flip_elapsed=0.38
	app.height=4
	app.runner.position.y=4
	await shot("trick-flip")
	app.start_flight(0)
	for i in 350: app.flight.advance(1.0/60)
	await shot("flight-0")
	app.pause_game()
	await shot("flight-pause")
	app.state="flight"
	app.flight.distance=820
	app.flight.place=2
	app.complete_flight(false)
	await shot("flight-result")
	app.show_menu()
	app.hud.planets(0,3)
	app.state="planets"
	await shot("planets-menu")
	app.free()
	await create_timer(0.12).timeout
	quit()
