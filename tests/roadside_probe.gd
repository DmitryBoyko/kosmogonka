extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	root.size = Vector2i(540,1188)
	var app = load("res://scenes/main.tscn").instantiate()
	app.test_mode = true
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app.set_physics_process(false)
	var profile = root.get_node("Profile")
	profile.persistence_enabled = false
	profile.retry_points.clear()
	profile.first_person = false
	app.planet = 9
	app.test_layout_seed = 2457
	app.start_level()
	app.begin_run()
	var probe: Node3D = app.roadside_probe
	for world in 11:
		for seed_value in [2457,2458,8119]:
			app.planet = world
			app.test_layout_seed = seed_value
			app.reset_course()
			check(not probe.encounters.is_empty(),"probe has space to appear on world %d"%world)
	app.planet = 9
	app.test_layout_seed = 2457
	app.reset_course()
	app.begin_run()
	probe.configure(9,2457,app.events,app.loop_routes.routes)
	var original: Array = probe.encounters.duplicate()
	check(not original.is_empty(),"course has a probe encounter")
	probe.configure(9,2458,app.events,app.loop_routes.routes)
	check(original!=probe.encounters,"new layout seed varies encounter placement")
	probe.configure(9,2457,app.events,app.loop_routes.routes)
	for encounter: Vector2 in probe.encounters:
		for span: Vector2 in probe.exclusions:
			check(encounter.x>=span.y or encounter.x+probe.FLIGHT_LENGTH<=span.x,"probe flight stays clear of special routes")
	if not original.is_empty():
		app.distance = original[0].x+probe.FLIGHT_LENGTH*.36
		app._process(.016)
		check(probe.visible and probe.craft.position.y>3.5 and probe.craft.position.z<0.,"probe flies above the road ahead of the runner")
		check(probe.beam.visible,"probe scans the runner")
		var first_side := signf(probe.craft.position.x)
		if DisplayServer.get_name()!="headless":
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://build/roadside-probe-scan.png")
		app.distance = original[0].x+probe.FLIGHT_LENGTH*.71
		app._process(.016)
		check(probe.visible and signf(probe.craft.position.x)==-first_side,"probe crosses above the runner to the other side")
		probe.present(app.distance,app.runner.position,app.turn_track,false,false)
		check(not probe.visible,"probe disappears when the runner enters a tunnel")
	print("ROADSIDE PROBE: %d failures"%failures)
	if is_instance_valid(app.mobile_presentation): app.mobile_presentation.free()
	else: app.free()
	await process_frame
	quit(1 if failures else 0)
