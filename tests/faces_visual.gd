extends SceneTree
const Hero = preload("res://scripts/hero.gd")

func _initialize() -> void: call_deferred("run")
func capture(path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+path+".png")

func run() -> void:
	root.size = Vector2i(768,768)
	var world := Node3D.new()
	root.add_child(world)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("17263b")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("dfefff")
	environment.environment.ambient_light_energy = 0.6
	world.add_child(environment)
	var key := DirectionalLight3D.new()
	world.add_child(key)
	key.rotation_degrees = Vector3(-25,-30,0)
	key.light_energy = 1.0
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.fov = 22
	for girl in [false,true]:
		var hero = Hero.new()
		world.add_child(hero)
		hero.build(girl)
		var label_value := "girl" if girl else "boy"
		for i in 60: hero.animate(1.0/60,"idle")
		camera.position = Vector3(0,2.08,4)
		camera.look_at(Vector3(0,2.08,0))
		await capture("face-"+label_value+"-neutral")
		camera.position = Vector3(2.4,2.15,3.6)
		camera.look_at(Vector3(0,2.04,0))
		await capture("face-"+label_value+"-quarter")
		camera.position = Vector3(0,2.08,4)
		camera.look_at(Vector3(0,2.08,0))
		hero.clock = 0.15
		for i in 20: hero.animate(1.0/60,"win")
		await capture("face-"+label_value+"-smile")
		hero.free()
	world.free()
	# Capture the real gameplay camera, not just a studio portrait.
	root.size = Vector2i(540,960)
	var app = load("res://scenes/main.tscn").instantiate()
	app.test_mode = true
	root.add_child(app)
	await process_frame
	app.set_physics_process(false)
	app.set_process(false)
	for girl in [false,true]:
		root.get_node("Profile").hero = 1 if girl else 0
		app.start_level()
		app.begin_run()
		app.distance = 900
		app.spawn_and_update()
		for i in 60: app._process(1.0/60)
		await capture("face-game-"+("girl" if girl else "boy"))
	app.free()
	await process_frame
	quit()
