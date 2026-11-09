extends SceneTree
const Pilot=preload("res://tests/route_pilot.gd")
var app:Node
var reports:Array=[]
func _initialize() -> void: call_deferred("run")
func sample(label_value:String) -> void:
	var times:Array[float]=[]; var draws:Array[float]=[]
	for i in 180:
		var stamp:=Time.get_ticks_usec()
		if app.state=="run":
			if app.loop_routes.active.is_empty(): Pilot.drive(app)
			app.simulate(1./60.)
		app._process(1./60.)
		await process_frame
		if i>=60:
			times.append((Time.get_ticks_usec()-stamp)/1000.)
			draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	times.sort(); draws.sort()
	reports.append({"stage":label_value,"frames":120,"frame_p50_ms":times[60],"frame_p95_ms":times[114],"frame_p99_ms":times[118],"frame_max_ms":times[-1],"draw_calls_p95":draws[114]})
	print(reports[-1])
func run() -> void:
	root.size=Vector2i(540,1188); DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED); Engine.max_fps=0
	app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; app.set_process(false); app.set_physics_process(false)
	var p=root.get_node("Profile"); p.persistence_enabled=false; p.hero=0; p.unlocked=9
	var outfit=preload("res://scripts/outfit_catalog.gd").legacy({"suit":5,"pack":5,"board":5}); p.outfits[0]=outfit
	app.planet=9; app.reset_course(); app.begin_run(); app.distance=1790.; await sample("planet-10-run")
	for kind:String in ["jet","board"]:
		app.planet=2; app.reset_course(); app.begin_run()
		var route:Dictionary=app.loop_routes.routes[0 if kind=="jet" else 1]
		app.distance=route.start-.2; app.lane=route.lane; app.x=(route.lane-1)*2.6; p.charges["0"]={"jet":3,"board":3}; app.use_charge(kind); app.simulate(.016)
		await sample(kind+"-loop")
	app.shop_category="suit"; app.shop_mode="galaxy"; app.gear_context="explore"; app.show_outfit_shop(); await sample("fitting-room")
	var report:={"environment":"Windows OpenGL desktop, mobile render target; not a phone FPS claim","stages":reports}
	var file:=FileAccess.open("res://build/desktop-frame-budget.json",FileAccess.WRITE); file.store_string(JSON.stringify(report,"  ")); file.close()
	if is_instance_valid(app.mobile_presentation): app.mobile_presentation.free()
	else: app.free()
	await process_frame; quit()
