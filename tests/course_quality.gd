extends SceneTree
const Course = preload("res://scripts/course.gd")
var checks := 0
var failures: Array[String] = []
var app: Node
var metrics: Array = []

func _initialize() -> void: call_deferred("run")
func check(ok: bool, label_value: String) -> void:
	checks += 1
	if not ok: failures.append(label_value); push_error(label_value)

func isolated_arch() -> Dictionary:
	app.reset_course()
	app.begin_run()
	for e in app.events+app.pickups:
		if is_instance_valid(e.node): e.node.free()
	app.events.clear()
	app.pickups.clear()
	var arch := Course.make_event(10,1,"arch",0,"challenge")
	app.events.append(arch)
	Course.add_star(app.pickups,10,1,0.68,1,arch,"duck")
	Course.add_star(app.pickups,22,1,1.0,3,arch,"cleared")
	app.distance = 9.7
	app.lane = 1
	app.x = 0
	return arch

func run() -> void:
	for planet in 4:
		var obstacles := Course.events(planet)
		var stars := Course.stars(planet,obstacles)
		var solid := 0
		var arches := 0
		var aliens := 0
		for e in obstacles:
			if e.kind in ["jet","board"]: continue
			solid += 1
			check(not Course.transitioning(e.origin),"no obstacles during camera rotation")
			check(Course.lanes_at(e.origin,planet).has(e.lane),"obstacle lies on an open lane")
			if e.kind == "arch":
				arches += 1
				var under := 0
				var behind := 0
				var bonus := 0
				for p in stars:
					if p.lane != e.lane or not p.has("anchor") or p.anchor != e: continue
					if absf(p.s-e.s)<3 and p.y<0.9: under += 1
					if p.s>e.s+3 and p.s<=e.s+14: behind += 1; bonus += int(p.value)
				check(under>=2 and behind>=3 and bonus>=5,"every arch rewards the underpass AND its exit")
			if e.kind == "alien":
				aliens += 1
				check(absf(Course.event_x(e,e.s-70))>4 and absf(Course.event_x(e,e.s+70))>4,"courier crosses the full width")
				var last_x := Course.event_x(e,e.s-70)
				var smooth := true
				for offset in range(-70,71):
					var current := Course.event_x(e,e.s+offset)
					smooth = smooth and (current-last_x)*float(e.get("cross_direction",1.))>=0 and absf(current-last_x)<(1.0 if e.get("surprise",false) else .23)
					last_x = current
				check(smooth,"courier never teleports between lanes")
		check(solid>=90,"planet has a substantially denser course")
		check(arches>=10 and aliens>=6,"ducks and comedy crossings recur throughout the level")
		var value := 0
		for p in stars: value += int(p.value)
		metrics.append({"planet":planet,"obstacles":solid,"arches":arches,"couriers":aliens,"pickups":stars.size(),"star_value":value})
	app = load("res://scenes/main.tscn").instantiate()
	app.test_mode = true
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app.set_physics_process(false)
	isolated_arch()
	app.check_contacts()
	app.distance = 22
	app.check_contacts()
	check(app.lives==2 and app.stars==0,"hitting an arch cannot buy its exit jackpot")
	var arch := isolated_arch()
	app.slide()
	app.check_contacts()
	app.distance = 22
	app.slide_timer = 0
	app.check_contacts()
	check(app.lives==3 and app.stars==4 and arch.cleared,"clean slide earns low star and +3 exit bonus")
	var paid: int = app.stars
	app.check_contacts()
	check(app.stars==paid,"bonus cannot be collected twice")
	isolated_arch()
	app.x = -2.6
	app.lane = 0
	app.check_contacts()
	app.distance = 22
	app.x = 0
	app.lane = 1
	app.check_contacts()
	check(app.stars==0 and app.lives==3,"sidestepping the arch and returning behind it cannot farm the jackpot")
	app.spawn_and_update()
	check(app.pickups.all(func(p): return p.done),"missed performance rewards disappear instead of remaining uncollectible ghosts")
	arch = isolated_arch()
	app.invulnerable = 2
	app.check_contacts()
	app.distance = 22
	app.check_contacts()
	check(app.stars==0 and arch.failed,"invulnerability does not count as a clean underpass")
	arch = isolated_arch()
	app.slide()
	app.check_contacts()
	app.slide_timer = 0
	app.distance = 10.1
	app.check_contacts()
	app.distance = 22
	app.check_contacts()
	check(arch.failed and not arch.cleared and app.stars<3,"a late collision cancels an earlier clean-contact flag")
	# A far convoy must stay in its authored slot until the approach starts.
	app.reset_course()
	app.begin_run()
	var ramp: Dictionary = {}
	var carrier: Dictionary = {}
	for e in app.events:
		if e.kind=="ramp" and ramp.is_empty(): ramp=e
		if e.kind=="carrier" and carrier.is_empty(): carrier=e
	var original: float = ramp.s
	for i in 60: app.simulate(1.0/60)
	check(ramp.s==original,"distant moving obstacles do not drift into unrelated encounters")
	app.distance = ramp.motion_trigger-154
	for i in 10: app.simulate(1.0/60)
	check(absf(carrier.s-ramp.s-9)<0.001,"moving ramp stays connected to its carrier")
	check(app.pickups.any(func(p): return p.has("anchor") and p.anchor==carrier and is_equal_approx(p.s,carrier.s+p.offset)),"roof rewards move with their platform")
	var out := FileAccess.open("res://build/course-quality.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"checks":checks,"failures":failures,"planets":metrics},"  "))
	out.close()
	print("COURSE QUALITY: ",checks," checks, ",failures.size()," failures; ",metrics)
	app.free()
	await process_frame
	quit(1 if not failures.is_empty() else 0)
