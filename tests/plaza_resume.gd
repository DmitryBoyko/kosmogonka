extends SceneTree

const World := 3
const SavePath := "user://plaza-resume-test.cfg"
const Course = preload("res://scripts/course.gd")

func _initialize() -> void:
	run.call_deferred()

func launch() -> Node:
	var app := load("res://scenes/main.tscn").instantiate() as Node
	app.test_mode = true
	root.add_child(app)
	while not is_instance_valid(app.hud) or app.hud.current == "boot":
		await process_frame
	app.set_process(false)
	app.set_physics_process(false)
	return app

func run() -> void:
	var profile = root.get_node("Profile")
	profile.persistence_enabled = false
	profile.plaza_resume.clear()
	profile.pending_trip = {}
	profile.selected_planet = World
	profile.unlocked = maxi(profile.unlocked, World)
	profile.retry_points.clear()
	var app := await launch()
	await app.start_level()
	await app.begin_run()
	var length := Course.length_for(World)
	var light_levels: Array[float] = []
	for remaining: float in [220., 150., 85., 20.]:
		app.distance = length - remaining
		app._process(.016)
		light_levels.append(app.plaza_dusk)
	assert(light_levels[0] == 0. and light_levels[3] == 1.)
	assert(0. < light_levels[1] and light_levels[1] < light_levels[2] and light_levels[2] < 1.)
	app.distance = length
	app.stars = 29
	app.spawn_and_update()
	app.finish_level()
	assert(app.state == "explore" and app.victory_fx.celebrating and app.plaza_dusk == 1.)
	assert(profile.plaza_resume.planet == World)
	var bank: int = profile.bank
	var at := Vector3(-27, .12, 13.)
	app.finish_walk.avatar.position = at
	app.finish_walk.last_grounded_position = at
	app.finish_walk.yaw = .7
	app.test_mode = false
	await app.on_action("shop_nearest")
	assert(app.state == "shop" and profile.plaza_resume.position == at)
	assert(profile.save(SavePath) == OK)
	app.free()
	await process_frame
	var cfg := ConfigFile.new()
	assert(cfg.load(SavePath) == OK)
	profile.plaza_resume = {}
	profile.load_plaza_state(cfg)
	assert(profile.plaza_resume.planet == World and profile.plaza_resume.position == at)
	app = await launch()
	assert(app.state == "explore" and app.planet == World and app.plaza_dusk == 1.)
	var restored: Vector3 = app.finish_walk.avatar.position
	assert(Vector2(restored.x, restored.z).is_equal_approx(Vector2(at.x, at.z)) and absf(restored.y - at.y) < .4)
	assert(is_equal_approx(app.finish_walk.yaw, .7))
	assert(profile.bank == bank and not app.victory_fx.celebrating)
	app.begin_departure()
	assert(profile.plaza_resume.is_empty() and app.state == "outro")
	app.free()
	await process_frame
	DirAccess.remove_absolute(SavePath)
	print("PLAZA RESUME PASS: darkness before finish, plaza saved from shop, restore without rewards, departure clears save")
	quit()
