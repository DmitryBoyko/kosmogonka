extends SceneTree
var app: Node
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures.append(message); push_error(message)
func steps(count: int) -> void:
	for i in count:
		await physics_frame
		app.finish_walk.advance(1./60,false); app._process(1./60)
func run() -> void:
	app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; app.set_process(false); app.set_physics_process(false)
	for planet in 4:
		app.planet=planet; app.start_level(); app.begin_run(); app.distance=2100; app.stars=42; app.spawn_and_update()
		var bank: int=root.get_node("Profile").bank
		app.finish_level()
		check(app.state=="explore" and app.committed,"finish grants manual exploration")
		check(root.get_node("Profile").bank==bank+42,"stars saved immediately")
		check(app.hud.current=="explore" and app.hud.walk_stick.visible,"mobile controls shown")
		await steps(4)
		check(absf(app.finish_walk.avatar.position.y-.2)<.03,"actual ground supports feet on planet "+str(planet))
		app.finish_walk.stick=Vector2(1,0); await steps(20)
		check(app.finish_walk.avatar.position.x>1.8,"continuous free movement, beyond a lane")
		app.pause_game(); var pos: Vector3=app.finish_walk.avatar.position
		for i in 5: app._process(.5)
		check(app.finish_walk.avatar.position==pos and app.finish_walk.stick==Vector2.ZERO,"pause freezes walk and releases stick")
		app.resume_game(); check(app.state=="explore" and app.hud.current=="explore","resume restores free controls")
		app.finish_walk.jump_pending=true; await steps(8)
		check(app.finish_walk.avatar.position.y>.8,"jump works without runner mode")
		app.finish_walk.stick=Vector2.ZERO; await steps(60)
		app.finish_walk.orbit_drag(Vector2(120,50))
		check(app.finish_walk.yaw<-.9 and app.finish_walk.pitch>.4,"drag orbits camera")
		app._process(1000)
		check(app.state=="explore" and root.get_node("Profile").bank==bank+42,"no timer and no duplicate reward")
		if planet==0:
			app.finish_walk.yaw=0
			app.finish_walk.avatar.position=Vector3(6.3,.21,-10)
			app.finish_walk.stick=Vector2(0,-1); await steps(90)
			check(app.finish_walk.avatar.position.z> -16,"solid gate pillar prevents walking through stone")
			app.finish_walk.avatar.position=Vector3(0,.21,-10); app.finish_walk.avatar.velocity=Vector3.ZERO
			await steps(150)
			check(app.finish_walk.avatar.position.z< -23,"open gate can be crossed")
			# Full loop around the complete monument group, including its back.
			for target in [Vector2(0,-45),Vector2(40,-45),Vector2(40,5),Vector2(-40,5),Vector2(-40,-45),Vector2(0,-45)]:
				for frame in 1000:
					var at:=Vector2(app.finish_walk.avatar.position.x,app.finish_walk.avatar.position.z)
					if at.distance_to(target)<.3: break
					app.finish_walk.stick=(target-at).normalized(); app.finish_walk.jump_pending=true; await steps(1)
				check(Vector2(app.finish_walk.avatar.position.x,app.finish_walk.avatar.position.z).distance_to(target)<.4,"walk around monument waypoint "+str(target)+" actual "+str(app.finish_walk.avatar.position))
			app.finish_walk.avatar.position=Vector3(1500,.3,-1500); app.finish_walk.stick=Vector2(1,0); await steps(15)
			check(app.finish_walk.avatar.position.x>1501 and app.finish_walk.avatar.position.y>.18,"no perimeter clamp, ground follows distant player")
		app.on_action("leave_finish")
		check(app.state=="outro" and not is_instance_valid(app.finish_walk),"explicit exit starts cinematic and removes exploration physics")
		app.on_action("skip"); check(app.state=="results","departure still reaches results")
		check(root.get_node("Profile").bank==bank+42,"departure never awards stars twice")
	app.show_menu(); check(app.scenery.visible and app.state=="menu","menu restored")
	var out:=FileAccess.open("res://build/finish-walk-report.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"checks":checks,"failures":failures},"  ")); out.close()
	print("FINISH WALK: %d checks, %d failures"%[checks,failures.size()])
	app.free(); await create_timer(.15).timeout; quit(0 if failures.is_empty() else 1)
