extends SceneTree

const Course = preload("res://scripts/course.gd")
const Planets = preload("res://scripts/planets.gd")
const Arcade = preload("res://scripts/arcade_track.gd")
var app: Node

func _initialize() -> void:
	run.call_deferred()

func encounter(kind: String, at: float, lane: int = 1) -> Dictionary:
	var event := Course.make_event(350., 1, kind)
	event.length = 24. if kind == "arc_rail" else 10. if kind == "arc_pulse" else 4.
	var events: Array[Dictionary] = [event]
	app.events = events
	app.distance = event.s + at
	app.x = (lane - 1) * 2.6
	app.lane = lane
	app.height = 0.
	app.support = 0.
	app.vertical_speed = 0.
	app.slide_timer = 0.
	app.booster = ""
	app.invulnerable = 0.
	app.lives = 3
	app.shield_charges = 0
	app.minor_damage = 0.
	return event

func run() -> void:
	var profile = root.get_node("Profile")
	profile.persistence_enabled = false
	profile.plaza_resume.clear()
	profile.retry_points.clear()
	app = load("res://scenes/main.tscn").instantiate()
	app.test_mode = true
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app.set_physics_process(false)
	await app.start_level()
	await app.begin_run()
	app.pickups.clear()
	var event := encounter("arc_break", 0.)
	app.check_contacts()
	assert(event.failed, "Walking into the opened hatch must register a hit")
	event = encounter("arc_break", 0., 0)
	app.check_contacts()
	assert(not event.failed, "The adjacent lane must stay free")
	event = encounter("arc_beam", 0.)
	app.slide_timer = .5
	app.check_contacts()
	assert(not event.failed, "Slide clears the high beam")
	event = encounter("arc_beam", 0.)
	app.check_contacts()
	assert(event.failed, "The beam hits a standing runner")
	event = encounter("arc_pulse", 0.)
	app.height = 1.4
	app.check_contacts()
	assert(not event.failed, "The raised piston can be jumped")
	event = encounter("arc_pulse", 0.)
	app.check_contacts()
	assert(event.failed, "The raised piston blocks the lane")
	event = encounter("arc_spring", 0.)
	app.check_contacts()
	assert(event.triggered and app.vertical_speed > 10.)
	app.check_contacts()
	assert(not event.failed)
	encounter("arc_rail", 0.)
	app.height = Arcade.rail_height(0.)
	assert(is_equal_approx(app.find_support(), app.height), "Rail supports the runner above ground")
	for action in ["jump", "duck"]:
		event = encounter("arc_bio", 0.)
		event.action = action
		if action == "jump":
			app.height = 1.45
		else:
			app.slide_timer = .55
		app.check_contacts()
		assert(not event.failed)
	var species_names := {}
	for world in Planets.count():
		species_names[Arcade.species(world)[0]] = true
	assert(species_names.size() == Planets.count())
	print("ARCADE HAZARDS PASS: rail support, spring launch, hatch and bypass, laser slide, piston jump, both biology actions")
	quit()
