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
	root.get_node("Profile").persistence_enabled=false
	root.get_node("Profile").retry_points.clear()
	for planet in 4:
		app.planet=planet; app.start_level(); app.begin_run(); app.distance=2100; app.stars=42; app.spawn_and_update()
		var bank: int=root.get_node("Profile").bank
		app.finish_level()
		check(app.state=="explore" and app.committed,"finish grants manual exploration")
		check(root.get_node("Profile").bank==bank+42,"stars saved immediately")
		check(app.hud.current=="explore" and app.hud.walk_stick.visible,"mobile controls shown")
		check(app.scenery.visible and app.finish.visible and not app.finish.get_node("FinishCity").has_node("ReturnGate"),"race scenery, finish arch and city stay visible")
		await steps(4)
		check(app.finish_walk.avatar.position.y>=.04 and app.finish_walk.avatar.position.y<.25,"actual ground supports feet on planet "+str(planet))
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
			for point in [Vector2(-60.,-38.),Vector2(56.,-25.),Vector2(32.,30.),Vector2(-40.,50.),Vector2(49.,82.)]:
				var finish_distance: float = preload("res://scripts/course.gd").length_for(planet)
				check(is_zero_approx(app.turn_track.terrain_height(finish_distance+point.y,point.x)),"plaza terrain is level at "+str(point))
			app.finish_walk.avatar.position=Vector3(-27,.05,14)
			app.finish_walk.stick=Vector2(0,-1)
			await steps(58)
			check(app.finish_walk.avatar.position.z>10.5,"shop computer and platform block movement")
			app.finish_walk.avatar.position=Vector3(59,10,-24)
			app.finish_walk.avatar.velocity=Vector3.ZERO
			app.finish_walk.stick=Vector2(1,0)
			await steps(50)
			check(app.finish_walk.avatar.position.x<61.,"force field also blocks an airborne player")
			var visitors: Node3D = app.shop_visitors
			var friendly: Dictionary = visitors.visitors[0]
			visitors.clock=10.
			visitors.advance(.016,friendly.body.position+Vector3.BACK*2.)
			check(friendly.wave_until>visitors.clock and friendly.node.animation.assigned_animation=="crew/wave","friendly visitor waves and smiles")
			check((app.finish_walk.avatar.collision_mask&friendly.body.collision_layer)!=0,"plaza player collides with visitors")
			for girl in [false,true]:
				visitors.say_line(friendly.node.position,girl)
				var first: AudioStream = visitors.speech.stream
				visitors.say_line(friendly.node.position,girl)
				check(first!=null and first!=visitors.speech.stream and first.resource_path.contains("girls" if girl else "boys"),"plaza greeting matches the character and avoids immediate repetition")
			app.finish_walk.yaw=0
			app.finish_walk.avatar.position=Vector3(6.3,.21,-10)
			app.finish_walk.stick=Vector2(0,-1); await steps(90)
			check(app.finish_walk.avatar.position.z> -16,"solid gate pillar prevents walking through stone")
			app.finish_walk.avatar.position=Vector3(0,.21,-10); app.finish_walk.avatar.velocity=Vector3.ZERO
			await steps(150)
			check(app.finish_walk.avatar.position.z< -23,"open gate can be crossed")
			# Full loop around the complete monument group, including its back.
			for target in [Vector2(0,-45),Vector2(40,-45),Vector2(40,0),Vector2(-40,0),Vector2(-40,-45),Vector2(0,-45)]:
				for frame in 1000:
					var at:=Vector2(app.finish_walk.avatar.position.x,app.finish_walk.avatar.position.z)
					if at.distance_to(target)<.3: break
					app.finish_walk.stick=(target-at).normalized(); app.finish_walk.jump_pending=true; await steps(1)
				check(Vector2(app.finish_walk.avatar.position.x,app.finish_walk.avatar.position.z).distance_to(target)<.4,"walk around monument waypoint "+str(target)+" actual "+str(app.finish_walk.avatar.position))
			# The old perimeter must remain open, including its former collider positions.
			for test in [[Vector3(42,.05,-32),Vector2(1,0),"right"],[Vector3(8,.3,-67),Vector2(0,-1),"back"],[Vector3(0,.05,19),Vector2(0,1),"approach"]]:
				app.finish_walk.avatar.position=test[0]; app.finish_walk.avatar.velocity=Vector3.ZERO; app.finish_walk.stick=test[1]
				await steps(35)
				var p:Vector3=app.finish_walk.avatar.position
				check(p.x>44 if test[2]=="right" else p.z< -69 if test[2]=="back" else p.z>22,"former fence line can be crossed: "+test[2])


		app.on_action("leave_finish")
		check(app.state=="outro" and not is_instance_valid(app.finish_walk),"explicit exit starts cinematic and removes exploration physics")
		app.on_action("skip"); check(app.state=="results","departure still reaches results")
		check(root.get_node("Profile").bank==bank+42,"departure never awards stars twice")
	app.show_menu(); check(app.scenery.visible and app.state=="menu","menu restored")
	var out:=FileAccess.open("res://build/finish-walk-report.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"checks":checks,"failures":failures},"  ")); out.close()
	print("FINISH WALK: %d checks, %d failures"%[checks,failures.size()])
	app.free(); await create_timer(.15).timeout; quit(0 if failures.is_empty() else 1)
