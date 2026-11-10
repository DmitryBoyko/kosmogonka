extends SceneTree
const Planets=preload("res://scripts/planets.gd")
const Course=preload("res://scripts/course.gd")
const Pilot=preload("res://tests/route_pilot.gd")
var app:Node
var checks:=0
var failures:Array[String]=[]
var runs:Array=[]
func _initialize() -> void: call_deferred("run")
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok: failures.append(message); push_error(message)
func run() -> void:
	app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; app.set_process(false); app.set_physics_process(false)
	if OS.get_cmdline_user_args().has("--equipped"):
		var p=root.get_node("Profile"); var outfit=preload("res://scripts/outfit_catalog.gd").legacy({"suit":5,"pack":5,"board":5})
		p.outfits=[outfit.duplicate(),outfit.duplicate()]
		for id:String in outfit.values(): p.owned_items.append(id)
	check(Planets.count()==11,"eleven worlds defined")
	check(root.get_node("Profile").records.size()==Planets.count(),"records migrated to all worlds")
	for planet in Planets.count():
		var args:=OS.get_cmdline_user_args()
		if args.has("--world") and planet!=int(args[args.find("--world")+1]): continue
		if args.has("--recommended"):
			var tier:=preload("res://scripts/gear_economy.gd").recommended(planet)
			var p=root.get_node("Profile")
			var outfit=preload("res://scripts/outfit_catalog.gd").legacy({"suit":tier,"pack":tier,"board":tier})
			p.outfits[p.hero]=outfit
			for id:String in outfit.values():
				if not p.owned_items.has(id): p.owned_items.append(id)
		app.planet=planet; app.start_level(); app.begin_run()
		var aliens:=0; var surprises:=0
		for event:Dictionary in app.events:
			if event.kind=="alien": aliens+=1
			if event.get("surprise",false):
				surprises+=1
				check(event.warning_distance>=24 and event.cross_span>=9,"surprise crossing retains a readable warning")
		check(aliens>=6,"more runners on world "+str(planet))
		check(not app.finish.has_node("FinishArch") and not app.finish.find_children("MonumentTitle","Label3D",true,false).is_empty(),"victory title is above the monument without a finish arch")
		for frame in 36000:
			if app.state!="run": break
			Pilot.drive(app); app.simulate(1./60)
			if frame%4==0: app._process(4./60)
			if frame%240==0: await process_frame
		var result:Dictionary={"planet":planet,"name":Planets.get_data(planet).name,"finished":app.state=="explore","lives":app.lives,"distance":app.distance,"aliens":aliens,"surprises":surprises,"stars":app.stars,"end_speed":18.5*Course.speed_scale(planet)}
		runs.append(result); print("WORLD ",result)
		check(app.state=="explore","perfect-input route can finish world "+str(planet))
		if planet<9: check(root.get_node("Profile").unlocked>=planet+1,"next world unlocks")
		# All nine interplanetary routes must load and end at the correct destination.
		if planet<9:
			app.start_flight(planet); check(app.state=="flight" and app.flight_target==planet+1,"flight route exists")
			app.complete_flight(true); app.arrive_at_planet(); check(app.planet==planet+1,"arrival selects the destination")
	var file:=FileAccess.open("res://build/ten-worlds-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"runs":runs},"  ")); file.close()
	print("TEN WORLDS: %d checks, %d failures"%[checks,failures.size()])
	app.free(); await create_timer(.15).timeout; quit(0 if failures.is_empty() else 1)
