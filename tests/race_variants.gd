extends SceneTree
const Driver=preload("res://scripts/qa_route_driver.gd")
var failures:Array[String]=[]
var runs:Array=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var app=load("res://scenes/main.tscn").instantiate();app.test_mode=true;root.add_child(app)
	await process_frame;app.set_process(false);app.set_physics_process(false)
	var p=root.get_node("Profile");p.first_person=true;app.set_meta("qa_take_loops",true)
	for variant in 4:
		for world in 10:
			app.test_layout_seed=variant
			var tier:=preload("res://scripts/gear_economy.gd").recommended(world)
			var outfit:=preload("res://scripts/outfit_catalog.gd").legacy({"suit":tier,"pack":tier,"board":tier});p.outfits[p.hero]=outfit
			for id:String in outfit.values():
				if not p.owned_items.has(id):p.owned_items.append(id)
			app.planet=world;app.start_level();app.begin_run()
			for i in 22000:
				if app.state!="run":break
				Driver.drive(app);app.simulate(1./60.)
				if i%4==0:app._process(4./60.)
				if i%360==0:await process_frame
			var result:Dictionary={"world":world,"variant":variant,"finished":app.state=="explore","lives":app.lives,"length":app.distance,"loops":app.loop_routes.routes.filter(func(r):return r.taken).size()}
			if not result.finished:failures.append("not finished "+str(result))
			if result.loops!=app.loop_routes.routes.size():failures.append("loop skipped "+str(result))
			runs.append(result);print("VARIANT RUN ",result)
	var file:=FileAccess.open("res://build/race-variants-report.json",FileAccess.WRITE);file.store_string(JSON.stringify({"runs":runs,"failures":failures},"  "));file.close()
	print("RACE VARIANTS: %d runs, %d failures"%[runs.size(),failures.size()])
	app.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)
