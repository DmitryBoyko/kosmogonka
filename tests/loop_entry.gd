extends SceneTree
var failures:Array[String]=[]
var checks:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label_value:String) -> void:
	checks+=1
	if not ok:failures.append(label_value);push_error(label_value)
func run() -> void:
	var app=load("res://scenes/main.tscn").instantiate();app.test_mode=true;root.add_child(app)
	await process_frame;app.set_process(false);app.set_physics_process(false)
	var p=root.get_node("Profile");p.first_person=true
	for kind:String in ["jet","board","spiral"]:
		for delay:float in [-7.,0.,10.]:
			for first_boost:bool in [false,true]:
				app.planet=9;app.reset_course();app.begin_run();p.charges[str(p.hero)]={"jet":9,"board":9}
				var route:Dictionary=app.loop_routes.routes.filter(func(r):return r.kind==kind)[0]
				app.distance=route.start+delay;app.lane=1 if route.lane!=1 else 0;app.x=(app.lane-1)*2.6;app.height=3.2 if first_boost else 0.
				var before:int=p.charge_count(route.booster)
				if first_boost:check(app.use_charge(route.booster),"booster then swipe activation")
				app.swipe(Vector2(100. if route.lane>app.lane else -100.,0))
				if not first_boost:check(app.use_charge(route.booster),"swipe then booster activation")
				var old_position:=Vector3(app.x,app.height,0)
				app.simulate(.016)
				check(not app.loop_routes.active.is_empty(),"entry accepts %s delay%.1f order%s"%[kind,delay,str(first_boost)])
				check(app.runner.position.distance_to(old_position)<.65,"no entry teleport from lane interpolation or flight")
				check(p.charge_count(route.booster)==before-1,"exactly one charge consumed")
				for i in 1200:
					if app.loop_routes.active.is_empty():break
					app.simulate(.016);app._process(.016)
				check(route.taken and app.loop_routes.active.is_empty() and app.lives==3,"entry finishes loop safely")
		app.planet=9;app.reset_course();app.begin_run()
		var branch:Dictionary=app.loop_routes.routes.filter(func(r):return r.kind==kind)[0]
		check(not app.loop_routes.try_enter(branch.start,0,0,"",branch.lane),"no charge never captures")
		check(not app.loop_routes.try_enter(branch.start,0,0,branch.booster,0 if branch.lane!=0 else 1),"wrong lane bypass remains free")
		check(not app.loop_routes.try_enter(branch.start+13.,0,0,branch.booster,branch.lane),"already missed entry is not pulled backward")
	print("LOOP ENTRY: %d checks, %d failures"%[checks,failures.size()])
	app.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)
