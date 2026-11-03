extends SceneTree
const Course=preload("res://scripts/course.gd")
var app:Node
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok:bool,label_value:String) -> void:
	checks+=1
	if not ok: failures.append(label_value); push_error(label_value)
func isolated(kind:String) -> Dictionary:
	app.reset_course(); app.begin_run()
	for e in app.events+app.pickups:
		if is_instance_valid(e.node): e.node.free()
	app.events.clear(); app.pickups.clear()
	var e:=Course.make_event(510,1,kind); e.speed=0; app.events.append(e)
	app.distance=e.s-e.length*.5-.1; app.height=Course.top_of(kind); app.vertical_speed=0
	return e
func run() -> void:
	app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; app.set_process(false); app.set_physics_process(false)
	for hero in 2:
		root.get_node("Profile").hero=hero
		for kind in ["carrier","cargo"]:
			var e:=isolated(kind); var deck:float=Course.top_of(kind)
			var contact_frames:=0
			for i in 160:
				app.simulate(1./60); app._process(1./60)
				if absf(app.distance-e.s)<e.length*.5-.3:
					contact_frames+=1
					check(absf(app.height-deck)<.02,"stable support along "+kind)
				if app.distance>e.s+e.length*.5+1: break
			check(contact_frames>25 and app.lives==3 and not e.failed,"full roof traversal and edge exit are harmless")
			e=isolated(kind); app.height=0; app.support=0; app.distance=e.s-e.length*.5-.1
			app.simulate(1./60)
			check(app.lives==2 and e.failed,"ground approach still hits solid body")
			e=isolated(kind); app.distance=e.s; app.height=deck; app.support=deck; app.vertical_speed=0
			app.jump(); check(app.vertical_speed>9,"jump available from roof")
			e=isolated(kind); app.distance=e.s; app.height=deck+.12; app.vertical_speed=-8
			app.simulate(1./60); check(app.lives==3 and app.height>=deck,"descending landing catches deck before damage")
			e=isolated(kind); app.distance=e.s; app.height=deck; app.support=deck; app.invulnerable=0
			app.activate_booster("board"); app.simulate(1./60)
			check(app.booster=="board" and app.lives==3,"roof does not consume protective ride")
	# The actual authored Amber convoy must be traversable without an edge jump.
	app.planet=2; app.reset_course(); app.begin_run()
	var ramp:Dictionary={}
	for e in app.events:
		if e.kind=="ramp": ramp=e; break
	app.distance=ramp.s-3; app.lane=ramp.lane; app.x=(ramp.lane-1)*2.6
	var platform_end:float=0
	for e in app.events:
		if e.encounter==ramp.encounter and e.kind=="carrier": platform_end=maxf(platform_end,e.s+6)
	for i in 300:
		app.simulate(1./60); app._process(1./60)
		if app.distance>platform_end+1: break
	check(app.distance>platform_end and app.lives==3,"joined authored convoy needs no jump and takes no health")
	var out:=FileAccess.open("res://build/walkable-roofs-report.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"checks":checks,"failures":failures},"  ")); out.close()
	print("WALKABLE ROOFS: %d checks, %d failures"%[checks,failures.size()])
	app.free(); await create_timer(.15).timeout; quit(0 if failures.is_empty() else 1)
