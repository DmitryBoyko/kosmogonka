extends SceneTree
const Course = preload("res://scripts/course.gd")
var app: Node
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func step(n: int) -> void:
	for i in n:
		app.simulate(1.0 / 60)
		app._process(1.0 / 60)

func run() -> void:
	app = load("res://scenes/main.tscn").instantiate()
	app.test_mode = true
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app.set_physics_process(false)
	check(app.state == "menu", "starts in menu")
	check(app.previews.size() == 2, "both astronauts built")
	app.planet = 0
	app.start_level()
	check(app.state == "intro", "arrival before gameplay")
	app.begin_run()
	app.move_screen(-1)
	check(app.lane == 1, "single lane cannot leave road")
	app.jump()
	step(15)
	check(app.height > 1.0, "jump rises")
	step(50)
	check(is_equal_approx(app.height, 0), "jump lands")
	app.slide()
	check(app.slide_timer > 0, "slide can activate")
	app.pause_game()
	var paused_distance: float = app.distance
	app._process(1)
	app._physics_process(1)
	check(app.distance == paused_distance, "pause freezes simulation")
	app.resume_game()
	app._process(3.1)
	check(app.state == "run", "resume countdown returns to run")
	app.distance = 900
	app.lane = 1
	app.move_screen(-1)
	check(app.lane == 2, "front left maps to screen left")
	app.distance = 840
	app.move_screen(1)
	check(app.lane == 2, "cannot change lane during orbit transition")
	app.distance = 1100
	app.lane = 1
	app.move_screen(-1)
	check(app.lane == 0, "rear left maps to lane zero")
	app.invulnerable = 0
	app.activate_booster("board")
	var before: int = app.lives
	app.take_hit()
	check(app.lives == before and app.booster == "", "board absorbs first hit")
	app.take_hit()
	check(app.lives == before, "invulnerability prevents repeat hit")
	app.invulnerable = 0
	app.take_hit()
	check(app.lives == before - 1, "unprotected hit costs one life")
	app.activate_booster("jet")
	step(45)
	check(app.height > 3 and app.booster == "jet", "jet flight lifts hero")
	app.end_booster()
	step(60)
	check(app.height < 0.1, "jet safely descends")
	# Ramp and carrier use the same speed and remain connected for the whole run.
	var ramp: Dictionary
	var carrier: Dictionary
	for e in app.events:
		if e.kind == "ramp" and ramp.is_empty(): ramp = e
		if e.kind == "carrier" and carrier.is_empty(): carrier = e
	check(absf((carrier.s - 6) - (ramp.s + 3)) < 0.001, "moving ramp connects to carrier")
	app.distance = ramp.s + 2
	app.lane = 1
	app.x = 0
	app.height = 0
	app.support = 0
	app.vertical_speed = 0
	step(5)
	check(app.height > 1.2, "ramp raises support")
	app.distance = carrier.s
	app.height = 1.48
	app.support = 1.48
	check(app.find_support() > 1.4, "carrier roof supports runner")
	# End-to-end run uses only ordinary lane/jump/slide commands.
	app.reset_course()
	app.begin_run()
	var board_used := false
	var jet_used := false
	var roof_used := false
	var front_used := false
	var elapsed := 0.0
	for frame in 14000:
		if app.state != "run": break
		autopilot()
		app.simulate(1.0 / 60)
		app._process(1.0 / 60)
		elapsed += 1.0 / 60
		board_used = board_used or app.booster == "board"
		jet_used = jet_used or app.booster == "jet"
		roof_used = roof_used or app.support > 1.4
		front_used = front_used or Course.front_at(app.distance) > 0.99
		if frame % 60 == 0: await process_frame
	check(app.distance >= Course.LENGTH, "entire planet reachable with ordinary controls")
	check(app.lives == 3, "authored route can be completed without damage")
	check(board_used and jet_used, "both boosters usable on route")
	check(roof_used, "roof route usable during full run")
	check(front_used, "front section reached")
	check(app.stars > 10, "stars collected throughout route")
	check(app.state == "outro" and app.committed, "finish commits result before finale")
	var full_stars: int = app.stars
	var final_score: int = app.score
	app.commit_result(true)
	check(app.score == final_score, "finish cannot award twice")
	app.on_action("skip")
	check(app.state == "results", "finale can be skipped into results")
	app.show_menu()
	check(app.previews[0].position.x < 0 and app.previews[1].position.x > 0, "menu restores two hero positions")
	var profile := root.get_node("Profile")
	var original_hero: int = profile.hero
	profile.hero = 1 - original_hero
	app.reset_course()
	app.begin_run()
	check(app.runner.girl == (profile.hero == 1), "switching hero rebuilds selected astronaut")
	for frame in 14000:
		if app.state != "run": break
		autopilot()
		app.simulate(1.0 / 60)
		app._process(1.0 / 60)
		if frame % 60 == 0: await process_frame
	check(app.state == "outro" and app.lives == 3, "other hero can also complete full route without damage")
	profile.hero = original_hero
	app.reset_course()
	app.begin_run()
	for i in 3:
		app.invulnerable = 0
		app.take_hit()
	check(app.state == "results" and app.committed, "three hits end attempt")
	print("INTEGRATION: %d checks, %d failures; full route %.1fs; stars %d" % [checks, failures.size(), elapsed, full_stars])
	app.free()
	await create_timer(0.12).timeout
	quit(0 if failures.is_empty() else 1)

func autopilot() -> void:
	preload("res://tests/route_pilot.gd").drive(app)
