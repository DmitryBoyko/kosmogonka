extends SceneTree

const Stars = preload("res://scripts/booster_stars.gd")
const Course = preload("res://scripts/course.gd")
const Layout = preload("res://scripts/loop_layout.gd")
const Portals = preload("res://scripts/mirror_portals.gd")
var checks := 0
var errors := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		errors += 1
		push_error(label)

func run() -> void:
	root.size = Vector2i(540,960)
	var app = load("res://scenes/main.tscn").instantiate()
	app.test_mode = true
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app.set_physics_process(false)
	var profile = root.get_node("Profile")
	profile.booster_loss_cycles.clear()
	profile.retry_points.clear()
	profile.hero = 0
	app.planet = 1
	app.reset_course()
	check(app.booster_stars.is_empty(),"new level starts without special stars")
	for losses in range(1,10):
		app.committed = false
		app.commit_result(false)
		var enabled := losses%6>=3
		check(profile.booster_stars_enabled(0,1)==enabled,"toggle after %d defeats"%losses)
		check(not profile.booster_stars_enabled(1,1) and not profile.booster_stars_enabled(0,0),"independent hero and planet")
		if losses in [3,6,9]:
			app.reset_course()
			check(app.booster_stars.size()==(3 if enabled else 0),"retry produces correct number after %d defeats"%losses)
	var path := "user://test-booster-loss-cycle.cfg"
	check(profile.save(path)==OK,"cycle saves")
	var cfg := ConfigFile.new()
	check(cfg.load(path)==OK,"saved config opens")
	var restored := preload("res://scripts/profile.gd").new()
	restored.load_charge_state(cfg)
	check(restored.booster_stars_enabled(0,1),"active cycle survives reopening")
	restored.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	var gate_positions: Array = []
	for row in Portals.ROWS: gate_positions.append({"s":row[0]})
	for world in 11:
		for seed_value in [0,1,2,3,79,417,771,999991,-101,-670287]:
			Course.layout_seed = seed_value
			Layout.route_seed = seed_value
			var events := Course.events(world)
			var routes: Array = []
			for kind: String in Layout.kinds(world): routes.append({"start":Layout.start(kind)})
			for checkpoint in [0.,Course.length_for(world)*.5]:
				var layout := Stars.place(world,checkpoint,seed_value,events,routes,gate_positions if world==10 else [],[])
				check(layout.size()==3,"three clear stars on world %d, seed %d, checkpoint %d"%[world,seed_value,checkpoint])
				for star in layout:
					check(star.s>checkpoint+60. and Stars.lane_clear(star.s,star.lane,events),"star reachable after checkpoint in clear lane")
	app.reset_course()
	app.begin_run()
	var star: Dictionary = app.booster_stars[0]
	app.distance = star.s
	app.lane = star.lane
	app.x = (star.lane-1)*Course.LANE_WIDTH
	app.height = 0.
	app.support = 0.
	profile.charges["0"] = {"jet":0,"board":0}
	app.update_booster_stars()
	check(not star.done and profile.charge_count(star.kind)==0,"running below a star cannot pick it up")
	app.height = 1.4
	app.update_booster_stars()
	check(not star.done,"airborne without a jump cannot pick it up")
	app.height = 0.
	app.speed = Course.expected_speed(star.s,app.planet)
	app.distance = star.s-app.speed*.31
	app.invulnerable = 5.
	app.jump()
	for i in 45:
		if star.done: break
		app.simulate(1./60.)
	check(star.done and profile.charge_count(star.kind)==1,"ordinary jump picks up one charge")
	app.update_booster_stars()
	check(profile.charge_count(star.kind)==1,"same star never pays twice")
	if DisplayServer.get_name()!="headless":
		var next: Dictionary = app.booster_stars[2]
		app.distance = next.s-12.
		app.lane = next.lane
		app.x = (app.lane-1)*Course.LANE_WIDTH
		app.height = 0.
		app.runner.position = Vector3(app.x,0.,0.)
		app.turn_track.set_distance(app.distance)
		app.spawn_and_update()
		app.scenery.sync(app.distance,app.x,0.)
		app.update_booster_stars()
		app._process(0.)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/booster-star-preview.png")
	print("BOOSTER STARS: %d checks, %d failures"%[checks,errors])
	if is_instance_valid(app.mobile_presentation): app.mobile_presentation.free()
	else: app.free()
	await process_frame
	quit(1 if errors else 0)
