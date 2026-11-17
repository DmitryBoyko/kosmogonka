extends SceneTree

const Course = preload("res://scripts/course.gd")
const Planets = preload("res://scripts/planets.gd")
const Route = preload("res://scripts/expedition_course.gd")
const Loops = preload("res://scripts/loop_layout.gd")
var failures := 0
var app: Node

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var profile := root.get_node("Profile")
	profile.persistence_enabled = false
	profile.selected_planet = 0
	profile.unlocked = 10
	profile.retry_points.clear()
	profile.reserve_hearts.clear()
	profile.outfits = [{}, {}]
	profile.hero = 0
	app = load("res://scenes/main.tscn").instantiate()
	app.test_mode = true
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app.set_physics_process(false)
	for world in [10, 11, 12]:
		app.planet = world
		app.committed = false
		app.commit_result(true)
		check(profile.unlocked == world + 1, "Finishing opens the next destination")
		await app.start_flight(world)
		check(app.state == "flight" and app.flight_target == world + 1, "Flight starts for %s" % Planets.route_name(world))
		for frame in 2000:
			if app.state != "flight": break
			app._physics_process(1. / 30.)
		check(app.state == "flight_result" and app.flight_reward >= 5, "Flight finishes and pays its reward")
		await app.arrive_at_planet()
		check(app.planet == world + 1 and app.state == "intro", "Flight lands on the new world")
	var used: Dictionary = {}
	for world in range(11, 111):
		var data := Planets.get_data(world)
		check(data.name != "" and Planets.destination(world) != "", "Generated display names exist")
		check(not used.has(data.name) or world - int(used.get(data.name, world)) > 20, "Names have a 20-world repeat buffer")
		used[data.name] = world
		if world >= 13:
			var style := Planets.style_index(world)
			check(style != Planets.style_index(world - 1) and style != Planets.style_index(world - 2), "Nearby biomes differ")
	check(Planets.get_data(100000).name != "", "Distant world has a name")
	for seed_value in [3, 23, 4129]:
		for world in [11, 12, 13, 27, 80]:
			var layout := Route.layout(world, seed_value)
			check(layout == Route.layout(world, seed_value), "Route seed reproduces exact layout")
			var hazard_lanes: Dictionary = {}
			for piece: Dictionary in layout.pieces:
				if not piece.has("action"):
					continue
				var mask: int = int(hazard_lanes.get(piece.s, 0)) | (1 << piece.lane)
				hazard_lanes[piece.s] = mask
				check(mask != 7, "Every gate group leaves a ground bypass")
	for world in range(11,35):
		check(Course.speed_scale(world)>Course.speed_scale(world-1),"Speed grows past planet "+str(world-1))
		var route := Route.layout(world,83)
		var waves := {}
		var verbs := {}
		for piece: Dictionary in route.pieces:
			if not piece.has("action"): continue
			waves[piece.s]=true
			verbs[piece.action]=true
		check(waves.size()>64 and verbs.size()==3,"Dense mixed encounters on planet "+str(world))
		check(route.pieces.any(func(piece:Dictionary):return piece.kind=="exp_ufo"),"UFO patrols on planet "+str(world))
		var starts: Array[float] = []
		for kind: String in Loops.kinds(world):
			starts.append(Loops.start(kind,world))
		starts.sort()
		check(starts.size()>=7 and starts.back()+55.<Route.length_for(world),"All expedition loops fit on planet "+str(world))
		for i in range(1,starts.size()):
			check(starts[i]-starts[i-1]>115.,"Loop approaches are separate on planet "+str(world))
	for world in [11, 12]:
		app.planet = world
		app.test_layout_seed = 83
		await app.start_level()
		check(app.launch_landmark.get_node_or_null("ExpeditionLandmark")==null,"No finish monument at the starting grid")
		check(app.finish.get_node_or_null("ExpeditionLandmark")!=null,"Expedition monument is attached to the finish")
		app.advance_cinematic(15.)
		check(app.state=="countdown","Landing cinematic proceeds to countdown")
		app._process(3.1)
		check(app.state=="run" and not app.launch_landmark.visible,"Normal countdown hides the cinematic scenery")
		await sprint(world, false)
		check(app.state == "explore", "Mixed main route finishes on %s"%Planets.get_data(world).name)
		var kinds: Dictionary={}
		for event: Dictionary in app.events: kinds[event.kind]=true
		check(kinds.has("exp_ufo") and kinds.has("basement") and kinds.has("upper_deck") and kinds.has("tunnel"),"Expedition preserves traffic and multi-level routes")
		await app.start_level()
		app.begin_run()
		for kind: String in ["jet","board"]:
			var loop: Dictionary=app.loop_routes.routes.filter(func(entry:Dictionary):return entry.kind==kind)[0]
			app.distance=loop.start-.3
			app.lane=loop.lane
			app.x=(app.lane-1)*Course.LANE_WIDTH
			app.height=0.
			app.activate_booster(loop.booster)
			app.simulate(1./60.)
			check(loop.taken and not app.loop_routes.active.is_empty(),"Enter "+kind+" loop on "+str(world))
			for frame in 1600:
				if app.loop_routes.active.is_empty(): break
				app.simulate(1./60.)
			check(app.loop_routes.active.is_empty() and absf(app.distance-loop.start-55.)<.01,"Reach loop merge without interruption")
		app.planet = world
		await app.start_level()
		app.begin_run()
		app.distance = Course.length_for(world) * .5 + 10.
		app.record_progress()
		var signature: Array = app.events.map(func(e: Dictionary): return [e.s, e.lane, e.kind])
		app.test_layout_seed = 913
		await app.start_level()
		app.begin_run()
		check(app.distance == Course.length_for(world) * .5, "Retry starts at midpoint")
		check(signature == app.events.map(func(e: Dictionary): return [e.s, e.lane, e.kind]), "Checkpoint restores same obstacles")
		profile.retry_points.clear()
	var path := "user://expedition-test-profile.cfg"
	var cfg := ConfigFile.new()
	check(profile.save(path) == OK and cfg.load(path) == OK, "Expedition profile can be read from disk")
	check(cfg.get_value("campaign", "unlocked", 0) >= 13, "Profile preserves progress beyond the initial catalog")
	check(cfg.get_value("campaign", "records", []).size() >= 14, "New planets have persistent record slots")
	DirAccess.remove_absolute(path)
	app.free()
	await create_timer(.2).timeout
	print("EXPEDITION: ", failures, " failures")
	quit(0 if failures == 0 else 1)

func sprint(_world: int, _bonus: bool) -> int:
	for frame in 22000:
		if app.state!="run": break
		preload("res://scripts/qa_route_driver.gd").drive(app)
		app.simulate(1./60.)
		if frame%240==0: await process_frame
	return 0
