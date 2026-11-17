extends SceneTree
var app:Node
var checks:=0
var errors:=0
func _initialize() -> void: call_deferred("run")
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok: errors+=1; push_error(message)
func run() -> void:
	root.size=Vector2i(540,1188)
	root.get_node("Profile").selected_planet = 0
	root.get_node("Profile").plaza_resume = {}
	app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; await process_frame; app.set_process(false); app.set_physics_process(false)
	app.start_level(); app.test_mode=false
	while app.event_warm_cursor<app.events.size(): app.warm_event_next()
	check(app.scenery.prepare_queue.size()>0,"course chunks wait for prewarm during arrival")
	app.scenery.prepare_all()
	check(app.scenery.prepare_queue.is_empty() and app.scenery.prepared.size()>60,"course geometry is prepared before the run")
	check(app.finish.get_meta("cached_collision_shapes").size()>=19,"finish collision shapes are prepared before the finish")
	check(app.get_viewport()==root and app.hud.get_viewport()==root,"Android renders the UI and the 3D pass directly into the window")
	var prepared_events: Array[Dictionary] = []
	for kind in ["arch","space_car","glove","stairs","tunnel"]:
		var found:=false
		for event:Dictionary in app.events:
			if event.kind!=kind or event.s < 200.: continue
			var prepared:Node3D=event.get("prepared_node",null)
			check(is_instance_valid(prepared) and not prepared.is_inside_tree(),"detached visual prewarm: "+kind)
			prepared_events.append({"event": event, "visual": prepared})
			found=true; break
		check(found,"representative visual exists: "+kind)
	prepared_events.sort_custom(func(a, b): return a.event.s < b.event.s)
	for sample in prepared_events:
		var event: Dictionary = sample.event
		app.distance = event.s
		app.spawn_and_update()
		check(event.node == sample.visual and is_instance_valid(event.node) and event.node.is_inside_tree(),
			"run reuses prepared visual: " + str(event.kind))
	app.test_mode=true; app.reset_course()
	check(app.event_warm_cursor==0,"restart resets the preparation queue")
	print("MOBILE PREPARATION: %d checks, %d failures"%[checks,errors])
	app.free(); await process_frame; quit(1 if errors else 0)
