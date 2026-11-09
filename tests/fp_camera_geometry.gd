extends SceneTree
const Driver=preload("res://scripts/qa_route_driver.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var app=load("res://scenes/main.tscn").instantiate();app.test_mode=true;root.add_child(app)
	await process_frame;app.set_process(false);app.set_physics_process(false)
	var p=root.get_node("Profile");p.first_person=true
	var audit=preload("res://scripts/first_person_audit.gd").new();audit.app=app;app.add_child(audit);audit.set_process(false)
	var box_root:=Node3D.new();app.add_child(box_root)
	var box:=preload("res://scripts/geometry.gd").box(box_root,Vector3.ONE,Vector3(0,2,-1.1))
	app.camera.position=Vector3(0,2,0);app.camera.look_at(Vector3(0,2,-1));audit.inspect(box_root,"self_test")
	app.camera.position.z=-1.1;audit.inspect(box_root,"self_test")
	if audit.report.collisions.is_empty():failures.append("audit cannot detect a deliberately penetrated cube")
	box_root.free()
	for world in 10:
		app.planet=world;app.reset_course();app.begin_run();p.charges["0"]={"jet":9,"board":9}
		for route:Dictionary in app.loop_routes.routes:
			audit.report={"samples":0,"triangles":0,"exact_tests":0,"collisions":[],"features":{}};audit.previous.clear()
			app.loop_routes.active=route;app.booster=route.booster
			for i in range(1,159):
				app.loop_routes.travelled=app.loop_routes.arcs(route.kind)[i];app.simulate_loop(0.);app._process(.016)
				audit.inspect(route.node,"loop_"+route.kind)
			if not audit.report.collisions.is_empty():failures.append("loop world%d %s %s"%[world,route.kind,str(audit.report.collisions)])
		app.loop_routes.active={};app.booster="";app.set_meta("qa_take_loops",false)
		for index in 2:
			app.reset_course();app.begin_run();var basements:Array=app.events.filter(func(e):return e.kind=="basement");var basement:Dictionary=basements[index]
			app.distance=basement.s-basement.length*.5-6.;app.lane=basement.lane;app.x=(app.lane-1)*2.6
			audit.report={"samples":0,"triangles":0,"exact_tests":0,"collisions":[],"features":{}};audit.previous.clear()
			for frame in 700:
				Driver.drive(app);app.simulate(1./60.);app._process(1./60.);audit._process(1./60.)
				if app.distance>basement.s+basement.length*.5+6.:break
			if not audit.report.collisions.is_empty():failures.append("basement world%d index%d %s"%[world,index,str(audit.report.collisions)])
		print("GEOMETRY WORLD ",world," checked")
	print("FIRST PERSON GEOMETRY: ",failures)
	app.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)
