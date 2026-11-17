extends SceneTree
var failures: Array[String]=[]
func _initialize():call_deferred("run")
func check(ok: bool,message: String):
	if not ok:failures.append(message);push_error(message)
func run():
	var profile=root.get_node("Profile");profile.persistence_enabled=false;profile.unlocked=40;profile.retry_points.clear();profile.pending_trip={};profile.flown_routes.clear()
	var app=load("res://scenes/main.tscn").instantiate();app.test_mode=true;root.add_child(app)
	await process_frame;app.set_process(false);app.set_physics_process(false)
	var routes: Array=[]
	for i in 20:routes.append([i,i+1])
	routes.append_array([[19,0],[0,19],[12,4],[7,2]])
	for route in routes:
		app.planet=route[0];app.state="planets"
		await app.on_action("planet_"+str(route[1]))
		check(app.state=="flight","selection starts race "+str(route))
		check(app.flight.source==route[0] and app.flight.destination_index==route[1] and app.flight_target==route[1],"correct source/destination")
		check(int(profile.pending_trip.target)==route[1],"resume remembers actual destination")
		var skip=false
		for button in app.hud.screen.find_children("*","Button",true,false):
			if button.get_meta("command","")=="skip_flight":skip=true
		check(skip,"first-time route can be skipped")
		var bank=profile.bank;var hearts=profile.heart_count()
		await app.on_action("skip_flight")
		check(app.state=="flight_result" and profile.selected_planet==route[1],"skip reaches chosen world")
		check(profile.bank==bank and profile.heart_count()==hearts,"skip does not award stars or hearts")
	app.planet=5;app.state="planets";await app.on_action("planet_5")
	check(app.state=="select","same world does not start a trip")
	profile.pending_trip={"source":19,"target":2,"id":123,"hero":profile.hero}
	await app.start_flight(19,true)
	check(app.flight_target==2 and app.flight.destination_index==2,"resume retains backward route")
	app.complete_flight(true)
	var ads=root.get_node("CosmoAds")
	ads.active="shop";ads.presentation_started=false
	check(not ads.is_presenting(),"pending ad does not freeze shop")
	ads.mark_presented();check(ads.is_presenting(),"shown ad suspends scene")
	# A bridge is absent on desktop; exercise the real timeout through an open ad.
	ads.active="open";ads.presentation_started=false;ads.focus_was_lost=false
	await ads.watch_ad_focus()
	check(ads.active.is_empty(),"missing native show callback releases gate")
	ads.active="open";ads.presentation_started=true;ads.focus_was_lost=true
	await ads.finish_after_focus_return(ads.focus_watch,"open")
	check(not ads.is_presenting() and ads.active.is_empty(),"focus return releases a lost dismiss callback")
	app.free();await process_frame
	print("TRAVEL AND ADS: ",failures.size()," failures, ",routes.size()," routes")
	quit(0 if failures.is_empty() else 1)
