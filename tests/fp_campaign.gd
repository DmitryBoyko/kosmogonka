extends SceneTree
const Driver=preload("res://scripts/qa_route_driver.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var app=load("res://scenes/main.tscn").instantiate();app.test_mode=true;root.add_child(app)
	await process_frame;app.set_process(false);app.set_physics_process(false)
	var p=root.get_node("Profile");p.first_person=true;app.set_meta("qa_take_loops",true)
	for world in 10:
		var tier:=preload("res://scripts/gear_economy.gd").recommended(world)
		var outfit:=preload("res://scripts/outfit_catalog.gd").legacy({"suit":tier,"pack":tier,"board":tier});p.outfits[p.hero]=outfit
		for id:String in outfit.values():
			if not p.owned_items.has(id):p.owned_items.append(id)
		app.planet=world;app.start_level();app.begin_run()
		for i in 18000:
			if app.state!="run":break
			Driver.drive(app);app.simulate(1./60.)
			if i%4==0:app._process(4./60.)
			if i%240==0:await process_frame
		var gloves:=0;var failed_gloves:=0
		for e:Dictionary in app.events:
			if e.kind=="glove":gloves+=int(e.get("cleared",false));failed_gloves+=int(e.get("failed",false))
		var loops:=0
		for route:Dictionary in app.loop_routes.routes:
			loops+=int(route.taken)
			if not route.taken:failures.append("loop skipped world "+str(world)+route.kind)
		if app.state!="explore":failures.append("not finished world "+str(world))
		if failed_gloves>0:failures.append("failed glove world "+str(world))
		print("FP WORLD %d: state=%s loops=%d gloves=%d failed=%d lives=%d"%[world,app.state,loops,gloves,failed_gloves,app.lives])
	print("FP CAMPAIGN: ",failures)
	app.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)
