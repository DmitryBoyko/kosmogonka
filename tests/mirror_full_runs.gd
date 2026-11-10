extends SceneTree
const Driver=preload("res://scripts/qa_route_driver.gd")
var failures:Array=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var app=load("res://scenes/main.tscn").instantiate();app.test_mode=true;root.add_child(app)
	await process_frame;app.set_process(false);app.set_physics_process(false)
	var p=root.get_node("Profile");p.persistence_enabled=false;p.reserve_hearts.clear();p.outfits[p.hero]=preload("res://scripts/outfit_catalog.gd").legacy({"suit":5,"pack":5,"board":5})
	for id:String in p.outfits[p.hero].values():
		if not p.owned_items.has(id):p.owned_items.append(id)
	app.set_meta("qa_take_loops",true)
	for layout in 4:
		for view:bool in [false,true]:
			p.retry_points.clear();p.first_person=view;app.test_layout_seed=layout;app.planet=10;app.start_level();app.begin_run();p.charges[str(p.hero)]={"jet":9,"board":9}
			# Portals are checked individually in mirror_campaign; this covers every metre.
			for gate:Dictionary in app.mirror_portals.gates:gate.used=true
			for frame in 36000:
				if app.state!="run":break
				Driver.drive(app);app.simulate(1./60.)
				if frame%4==0:app._process(4./60.)
				if frame%600==0:await process_frame
			var count:int=app.loop_routes.routes.filter(func(r):return r.taken).size()
			var result:Dictionary={"layout":layout,"first_person":view,"finished":app.state=="explore","lives":app.lives,"loops":count,"stars":app.stars}
			print("MIRROR RUN ",result)
			if not result.finished or count!=7:failures.append(result)
	print("MIRROR FULL RUNS: 8 runs, ",failures.size()," failures")
	var file:=FileAccess.open("res://build/mirror-full-report.json",FileAccess.WRITE);file.store_string(JSON.stringify({"failures":failures},"  "));file.close()
	app.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)
