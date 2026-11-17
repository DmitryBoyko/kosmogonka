extends SceneTree

const Planets = preload("res://scripts/planets.gd")
const Cache = preload("res://scripts/planet_cache.gd")
const Course = preload("res://scripts/course.gd")
const Shops = preload("res://scripts/monument_shops.gd")

class AdBridge extends YandexAds:
	var shows := 0

	func _enter_tree(): pass

	func load_interstitial() -> void:
		_is_interstitial_loaded = true

	func show_interstitial() -> void:
		shows += 1
		_is_interstitial_loaded = false
		interstitial_shown.emit()

var app: Node

func _initialize() -> void:
	run.call_deferred()

func tap(command: String) -> void:
	await process_frame
	var point := Vector2.INF
	for button: Button in app.hud.screen.find_children("*", "Button", true, false):
		if button.is_visible_in_tree() and button.get_meta("command", "") == command:
			assert(not button.disabled, command)
			point = button.get_global_rect().get_center()
			break
	assert(point.is_finite(), "Missing visible control: " + command)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame

func run() -> void:
	assert(DisplayServer.get_name() != "headless", "Run with the desktop renderer and -- --mobile-render")
	root.size = Vector2i(486, 1069)
	var profile = root.get_node("Profile")
	profile.persistence_enabled = false
	profile.retry_points.clear()
	profile.hero = 1
	profile.selected_planet = 3
	app = load("res://scenes/main.tscn").instantiate()
	app.test_mode = true
	root.add_child(app)
	while not is_instance_valid(app.hud) or app.hud.current != "menu":
		await process_frame
	assert(app.get_viewport() == root and app.fitting_camera != app.camera)
	app.set_physics_process(false)
	var ads = root.get_node("CosmoAds")
	var bridge := AdBridge.new()
	root.add_child(bridge)
	ads.bridge = bridge
	ads.shop_flow.setup(bridge)
	bridge.interstitial_shown.connect(ads.mark_presented)
	bridge.load_interstitial()
	var worlds := [3]
	for world in range(Planets.count()):
		if world != 3:
			worlds.append(world)
	for world: int in worlds:
		Cache.request(world)
		while not Cache.ready(world):
			await process_frame
		Cache.collect(world)
		app.test_mode = true
		app.planet = world
		await app.start_level()
		await app.begin_run()
		app.distance = Course.length_for(world)
		app.spawn_and_update()
		app.finish_level()
		app.test_mode = false

		for terminal in range(Shops.POSITIONS.size()):
			app.finish_walk.avatar.position = Shops.POSITIONS[terminal] + Vector3(0, 0, 3)
			await process_frame
			await RenderingServer.frame_post_draw
			var plaza_frame := root.get_texture().get_image()
			var shows_before := bridge.shows
			await tap("shop_nearest")
			assert(app.state == "shop" and app.hud.current == "shop")
			await RenderingServer.frame_post_draw
			assert(bridge.shows == shows_before, "Ad preceded the first shop frame")
			assert(root.get_camera_3d() == app.fitting_camera)
			var frame := root.get_texture().get_image()
			assert(not frame.is_empty(), "Fitting room has no rendered image")
			var lit_samples := 0
			var changed_samples := 0
			for y in range(0, frame.get_height(), 12):
				for x in range(0, frame.get_width(), 12):
					var pixel := frame.get_pixel(x, y)
					if pixel.v > .16:
						lit_samples += 1
					if not pixel.is_equal_approx(plaza_frame.get_pixel(x, y)):
						changed_samples += 1
			assert(lit_samples > 20, "Fitting room rendered a black frame")
			assert(changed_samples > 20, "Window still displays the plaza frame")
			await tap("shop_cat_pack")
			assert(app.state == "shop" and app.shop_category == "pack")
			await tap("shop_mode_galaxy")
			assert(app.shop_mode == "galaxy")
			await tap("close_gear")
			assert(app.state == "explore" and app.track_root.visible)
			assert(root.get_camera_3d() == app.camera)
		print("SHOP RENDERED PASS %d %s" % [world, Planets.get_data(world).name])
	assert(bridge.shows == 0)
	print("SHOP RENDERED PASS: 60 entries rendered to the window")
	quit()
