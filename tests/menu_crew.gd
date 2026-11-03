extends SceneTree
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok:bool,label_value:String) -> void:
	checks+=1
	if not ok: failures.append(label_value); push_error(label_value)
func run() -> void:
	var app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; app.set_process(false); app.set_physics_process(false)
	app.show_menu(); app.menu_crew.rng.seed=12
	for kid in app.previews: check(is_equal_approx(kid.scale.x,1.15),"menu hero grows exactly fifteen percent")
	for initiator in 2:
		app.menu_crew.start("greet",initiator)
		for i in 50: app._process(1./60)
		check(app.previews[initiator].face.smile>.9 and app.previews[initiator].face.opening>.6,"random greeting smiles broadly")
		check(app.previews[initiator].hands[1].global_position.y>app.previews[initiator].head.global_position.y-.25,"greeting raises a hand beside the face")
		app.menu_crew.start("duel",initiator)
		var outward:=false; var first_jet:=false; var second_jet:=false; var returned:=false
		var max_offset:=0.0
		var last_roll:Vector2=Vector2.ZERO
		var largest_roll_step:=0.0
		for i in 389:
			app._process(1./60)
			var roll:=Vector2(app.previews[0].rotation.z,app.previews[1].rotation.z)
			if i>0: largest_roll_step=maxf(largest_roll_step,maxf(absf(roll.x-last_roll.x),absf(roll.y-last_roll.y)))
			last_roll=roll
			var victim=app.previews[1-initiator]
			var actor=app.previews[initiator]
			var home:=.95 if victim.girl else -.95
			max_offset=maxf(max_offset,absf(victim.position.x-home))
			if i>70 and i<110 and absf(victim.position.x-home)>.5: outward=true
			if i>85 and i<150 and victim.jet_fx.power>.95 and victim.jet_fx.jets[0].visible: first_jet=true
			if i>260 and i<310 and actor.jet_fx.power>.95: second_jet=true
			if i>180 and i<195 and absf(victim.position.x-home)<.12: returned=true
		check(largest_roll_step<.08,"braking and return have no sudden roll reversal")
		check(outward and max_offset<1.05,"push produces a bounded outward drift")
		check(first_jet,"victim ignites existing full-power animated exhaust")
		check(returned,"jet braking brings victim back to partner")
		check(second_jet and app.menu_crew.contact_count==2,"counterpush sends first child flying in return")
		check(app.menu_crew.mode=="idle","scene settles after exchange")
		for kid in app.previews:
			check(absf(absf(kid.position.x)-.95)<.05 and absf(kid.position.y-.45)<.05,"both return to starting positions")
			check(not kid.jet_fx.jets[0].visible,"exhaust stops after return")
	app.on_action("select"); app._process(.02)
	check(not app.menu_crew.active and app.previews.all(func(k):return not k.menu_jet and k.menu_expression<0),"selection exits play and resets expression/engines")
	check(app.previews[0].scale.x<1.1 and app.previews[1].scale.x<1.1,"selection uses its own scale")
	app.start_level(); app.begin_run(); app._process(.02)
	check(not app.runner.menu_jet and app.runner.menu_expression<0,"actual runner never inherits menu performance")
	var out:=FileAccess.open("res://build/menu-crew-report.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"checks":checks,"failures":failures},"  ")); out.close()
	print("MENU CREW: %d checks, %d failures"%[checks,failures.size()])
	app.free(); await create_timer(.15).timeout; quit(0 if failures.is_empty() else 1)
