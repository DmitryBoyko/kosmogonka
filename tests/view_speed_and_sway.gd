extends SceneTree
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label_value:String) -> void:
	checks+=1
	if not ok:failures.append(label_value);push_error(label_value)
func run() -> void:
	root.size=Vector2i(540,1188)
	var app=load("res://scenes/main.tscn").instantiate();app.test_mode=true;root.add_child(app)
	await process_frame;app.set_process(false);app.set_physics_process(false)
	var p=root.get_node("Profile");p.persistence_enabled=false;p.reduced_motion=false
	for world in 10:
		app.planet=world;app.reset_course();app.begin_run();app.events.clear();app.pickups.clear()
		for mode:String in ["","jet","board"]:
			var reference:Array=[]
			for view:bool in [false,true]:
				p.first_person=view;app.distance=1000.;app.speed=16.;app.height=0.;app.support=0.;app.support_event={};app.x=0.;app.lane=1;app.vertical_speed=0.;app.invulnerable=0.;app.auto_landing=false;app.forced_landing=false;app.rescue_origin=0.;app.booster=mode;app.booster_timer=30.
				for frame in 120:
					app.simulate(1./60.);app.update_camera()
					if not view:reference.append(Vector2(app.distance,app.speed))
					else:check(Vector2(app.distance,app.speed).distance_to(reference[frame])<.00001,"same speed and distance world%d %s frame%d"%[world,mode,frame])
		for variant:float in [0.,1.,2.]:
			app.camera_variant=variant;app.booster="";app.board_camera_blend=0.;app.distance=500.
			p.first_person=false;app.update_camera();var fov:float=app.camera.fov
			p.first_person=true;app.update_camera();check(is_equal_approx(fov,app.camera.fov),"same lens in both views")
		for view:bool in [false,true]:
			p.first_person=view;app.booster="board";app.board_camera_blend=1.;app.clock=0.;app.update_camera();var a:Basis=app.camera.basis;var at:Vector3=app.camera.position
			app.clock=.65;app.update_camera();check(not a.is_equal_approx(app.camera.basis),"board camera sways in both views")
			check(at.is_equal_approx(app.camera.position),"sway keeps camera collision-safe position")
			p.reduced_motion=true;app.update_camera();a=app.camera.basis;app.clock=2.;app.update_camera();check(a.is_equal_approx(app.camera.basis),"reduced motion disables sway")
			p.reduced_motion=false
	print("VIEW SPEED / SWAY: %d checks, %d failures"%[checks,failures.size()])
	app.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)
