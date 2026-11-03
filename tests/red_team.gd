extends SceneTree
const Course = preload("res://scripts/course.gd")
const Pilot = preload("res://tests/route_pilot.gd")
var app: Node
var runs: Array = []
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")
func ordinary_vertical() -> void:
	for e in app.events:
		if e.done or e.lane!=app.lane: continue
		var time_to: float = (e.s-app.distance)/maxf(1,app.speed-e.speed)
		if time_to>0 and time_to<0.36:
			if e.kind=="barrier": app.jump()
			elif e.kind=="arch": app.slide()

func attack(planet: int, policy: String, input_frames: int = 1) -> void:
	app.planet=planet
	app.reset_course()
	app.begin_run()
	for frame in 16000:
		if app.state!="run": break
		if frame%input_frames==0:
			if policy=="reward": Pilot.drive(app)
			elif policy.begins_with("fixed"):
				var desired:=int(policy.right(1))
				if Course.lanes_at(app.distance,planet).has(desired) and app.lane!=desired:
					var dir:=1 if desired>app.lane else -1
					app.move_screen(-dir if Course.front_at(app.distance)>0.5 else dir)
				ordinary_vertical()
			elif policy=="jump_spam": app.vertical_gesture("up")
		app.simulate(1.0/60)
		app._process(1.0/60)
		if frame%120==0: await process_frame
	var finished: bool = app.state=="explore"
	var result: Dictionary = {"planet":planet,"policy":policy,"input_ms":int(input_frames*1000/60.0),"finished":finished,"distance":snappedf(app.distance,0.1),"stars":app.stars,"lives":app.lives}
	runs.append(result)
	print("RED TEAM ",result)
	if policy=="reward" and (not finished or app.lives!=3): failures.append("delayed reward route failed on planet "+str(planet))
	if policy.begins_with("fixed") and finished: failures.append("fixed lane can finish without steering: "+policy)
	if policy=="idle" and (finished or app.distance>350): failures.append("idle play progresses too far")

func run() -> void:
	app=load("res://scenes/main.tscn").instantiate()
	app.test_mode=true
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app.set_physics_process(false)
	await attack(0,"idle")
	for lane in 3: await attack(0,"fixed"+str(lane))
	await attack(0,"jump_spam",10)
	for planet in 4: await attack(planet,"reward",12)
	var profile:=root.get_node("Profile")
	profile.save("res://build/red-team-profile.cfg")
	var cfg:=ConfigFile.new()
	if cfg.load("res://build/red-team-profile.cfg")!=OK or cfg.get_value("campaign","star_records",[]).size()!=4: failures.append("star records do not persist")
	var out:=FileAccess.open("res://build/red-team-results.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"runs":runs,"failures":failures},"  "))
	out.close()
	print("RED TEAM: ",runs.size()," scenarios, ",failures.size()," failures; ",failures)
	app.free()
	await process_frame
	quit(1 if not failures.is_empty() else 0)
