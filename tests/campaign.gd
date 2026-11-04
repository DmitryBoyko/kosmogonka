extends SceneTree
const Course=preload("res://scripts/course.gd")
var app: Node
var failures: Array[String]=[]
var checks:=0
var report: Array=[]

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:
		failures.append(message)
		push_error(message)

func step(n: int) -> void:
	for i in n:
		app.simulate(1.0/60)
		app._process(1.0/60)

func pilot() -> void:
	preload("res://tests/route_pilot.gd").drive(app)

func full_planet(index: int, hero: int) -> void:
	root.get_node("Profile").hero=hero
	app.planet=index
	app.start_level()
	app.begin_run()
	var time:=0.0
	var roofs:=false
	for frame in 16000:
		if app.state!="run": break
		pilot()
		step(1)
		time+=1.0/60
		roofs=roofs or app.support>1.4
		if frame%120==0: await process_frame
	check(app.state=="explore","planet %d hero %d reaches finish, distance %.1f" % [index,hero,app.distance])
	check(app.lives==3,"planet %d hero %d no damage, lives %d" % [index,hero,app.lives])
	check(app.stars>15,"planet %d stars" % index)
	check(time>120 and time<180,"planet %d duration %.1f" % [index,time])
	check(roofs,"planet %d roof route" % index)
	check(root.get_node("Profile").unlocked>=mini(9,index+1),"next planet unlocked before flight")
	report.append({"planet":index,"hero":hero,"time":time,"stars":app.stars,"lives":app.lives})
	print("PLANET %d HERO %d: %.1fs, %d stars, %d lives" % [index,hero,time,app.stars,app.lives])

func run() -> void:
	create_timer(120).timeout.connect(func(): push_error("Campaign test timed out"); quit(2))
	app=load("res://scenes/main.tscn").instantiate()
	app.test_mode=true
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app.set_physics_process(false)
	# Flora is checked first, before moving on to production validation of other worlds.
	await full_planet(1,0)
	if OS.get_cmdline_user_args().has("--flora-only"):
		finish_tests()
		return
	for index in [0,2,3]: await full_planet(index,0)
	for index in [0,1,2,3]: await full_planet(index,1)
	app.planet=0
	app.reset_course()
	app.begin_run()
	app.vertical_gesture("up")
	check(app.vertical_speed>0,"first gesture immediate jump")
	step(10)
	app.vertical_gesture("up")
	check(app.flip_used and app.vertical_speed>14,"second gesture amplifies jump")
	var impulse: float=app.vertical_speed
	app.vertical_gesture("up")
	check(app.vertical_speed==impulse,"third gesture cannot add height")
	step(120)
	check(not app.flip_used and app.height==app.support,"landing restores flip")
	app.vertical_gesture("down")
	step(8)
	app.vertical_gesture("down")
	check(app.roll_timer>1 and app.slide_timer>1,"double down back roll")
	step(15)
	check(app.runner.pivot.rotation.x < -1.4,"roll lies on back")
	var timer: float=app.roll_timer
	app.vertical_gesture("down")
	check(app.roll_timer==timer,"third down cannot extend roll")
	step(80)
	app.vertical_gesture("up")
	app.pause_game()
	check(app.gesture_direction.is_empty(),"pause clears gesture pair")
	app.resume_game()
	app._process(3.1)
	app.activate_booster("jet")
	app.vertical_gesture("up")
	app.vertical_gesture("up")
	check(not app.flip_used and app.booster=="jet","jet ignores vertical tricks")
	app.end_booster()
	step(70)
	app.activate_booster("board")
	app.vertical_gesture("down")
	step(6)
	app.vertical_gesture("down")
	check(app.booster=="board" and app.roll_timer>0,"board compatible with roll")
	for kind in ["barrier","wall","plant","leaf","arch","truck","broken","traffic"]:
		app.reset_course()
		app.begin_run()
		app.events.clear()
		app.events.append({"s":10.0,"lane":1,"kind":kind,"speed":0.0,"length":4.0,"done":false,"node":null,"source_lane":1})
		app.vertical_gesture("up")
		step(10)
		app.vertical_gesture("up")
		step(70)
		check(app.lives==3,"flip clears "+kind)
	# A new flight always permits arrival, even when a bot wins.
	for route in 3:
		app.start_flight(route)
		var start_bank: int=root.get_node("Profile").bank
		for frame in 2400:
			if app.state!="flight": break
			var desired:=int(floor(app.flight.distance/105))%3
			if app.flight.lane<desired: app.move_screen(1)
			elif app.flight.lane>desired: app.move_screen(-1)
			app._physics_process(1.0/60)
			if frame%120==0: await process_frame
		check(app.state=="flight_result","flight route %d finishes" % route)
		check(app.flight.elapsed>=20 and app.flight.elapsed<30,"short flight %.1fs" % app.flight.elapsed)
		check(app.flight.order.has(3) and app.flight.place>=1 and app.flight.place<=4,"real finish order")
		check(root.get_node("Profile").bank==start_bank+app.flight_reward,"flight reward paid")
		app.complete_flight(false)
		check(root.get_node("Profile").bank==start_bank+app.flight_reward,"flight reward paid once")
		app.arrive_at_planet()
		check(app.planet==route+1 and app.state=="intro","arrival regardless of place")
	app.start_flight(0)
	app.pause_game()
	var frozen: float=app.flight.distance
	app._physics_process(2)
	check(app.flight.distance==frozen,"flight pause freezes ships")
	app.resume_game()
	app._process(3.1)
	check(app.state=="flight","flight countdown restores correct mode")
	app.complete_flight(true)
	check(app.flight_reward==0,"skip gives no victory or base reward")
	var profile:=root.get_node("Profile")
	profile.save("res://build/test-profile.cfg")
	var cfg:=ConfigFile.new()
	check(cfg.load("res://build/test-profile.cfg")==OK and cfg.get_value("campaign","unlocked")>=4,"campaign saves progress")
	finish_tests()

func finish_tests() -> void:
	var file:=FileAccess.open("res://build/campaign-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"runs":report},"  "))
	file.close()
	print("CAMPAIGN: %d checks, %d failures" % [checks,failures.size()])
	app.free()
	await create_timer(0.15).timeout
	quit(0 if failures.is_empty() else 1)
