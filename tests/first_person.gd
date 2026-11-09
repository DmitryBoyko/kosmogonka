extends SceneTree
var app:Node
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok:bool,description:String) -> void:
	checks+=1
	if not ok: failures.append(description);push_error(description)
func shot(name_value:String) -> void:
	if DisplayServer.get_name()=="headless": return
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/first-person-"+name_value+".png")
func tap_view() -> void:
	var button:Button
	for item:Button in app.hud.root.find_children("*","Button",true,false):
		if item.is_visible_in_tree() and item.get_meta("command","")=="camera_view": button=item;break
	check(is_instance_valid(button) and button.get_global_rect().position.y<100.,"view switch is at the top before running")
	var at:Vector2=button.get_global_rect().get_center()
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new();event.position=at;event.global_position=at;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;root.push_input(event,true);await process_frame
func run() -> void:
	root.size=Vector2i(540,1188)
	app=load("res://scenes/main.tscn").instantiate();app.test_mode=true;root.add_child(app)
	await process_frame;app.set_process(false);app.set_physics_process(false)
	var profile=root.get_node("Profile");profile.first_person=false
	app.show_menu();await process_frame;await tap_view()
	check(profile.first_person,"native pre-run tap selects first person")
	var path:="user://first-person-test.cfg";check(profile.save(path)==OK,"view preference saves")
	var cfg:=ConfigFile.new();cfg.load(path);check(cfg.get_value("view","first_person",false),"first-person option is in persisted settings");DirAccess.remove_absolute(path)
	app.on_action("select");await process_frame;await tap_view();check(not profile.first_person,"selection screen can restore third person")
	app.reset_course();app.begin_run();app.distance=610.;app.events.clear();app.pickups.clear()
	for preview:Node3D in app.previews: preview.hide()
	await tap_view();app._process(.016)
	check(profile.first_person and app.runner.first_person,"run uses selected first-person mode")
	check(app.camera.position.distance_to(app.runner.position+Vector3.UP*2.55)<.3,"running camera is at eye height")
	check(app.runner.first_person_geometry.any(func(item):return item.node.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY),"hidden body still casts real shadows")
	check(app.camera.global_basis.z.dot(Vector3.BACK)>.99,"first person looks forward")
	app.roll_timer=1.;app.update_camera();check(app.camera.position.y<.8,"rolling lowers the viewpoint under obstacles")
	app.roll_timer=0.;app.slide_timer=1.;app.update_camera();check(app.camera.position.y<1.3,"crouching lowers the viewpoint")
	app.slide_timer=0.;app.height=-7.1;app.runner.position.y=app.height;app.update_camera();check(app.camera.position.y< -4.,"basement view stays below the road")
	app.distance=900.;app.height=0.;app.runner.position=Vector3.ZERO;app.lane=1;app.x=0.;app.move_screen(1);check(app.lane==2,"first-person right swipe remains right during front-camera sections")
	app.distance=610.;app.scenery.sync(app.distance,0.,0.);app._process(.016);await shot("run")
	await tap_view();app._process(.016);check(not app.runner.first_person and app.runner.first_person_geometry.is_empty(),"switching back restores body geometry")
	profile.first_person=true;profile.charges["0"]={"jet":9,"board":9}
	for kind in ["jet","board"]:
		app.planet=2;app.reset_course();app.begin_run()
		var route:Dictionary=app.loop_routes.routes[0 if kind=="jet" else 1]
		app.distance=route.start-.2;app.x=(route.lane-1)*2.6;app.lane=route.lane;app.use_charge(kind);app.simulate(.016)
		for index in [30,60,90,120]:
			app.loop_routes.travelled=app.loop_routes.arcs(kind)[index];app.simulate_loop(0.);app.update_camera()
			check(app.camera.position.distance_to(app.runner.position)<2.7 and app.camera.global_basis.z.dot(-app.loop_pose.forward)>.98,"first-person loop camera follows the hero "+kind+str(index))
		app._process(.016);await shot("loop-"+kind)
	profile.first_person=false;app.planet=0;app.reset_course();app.begin_run();app.distance=2100.;app.spawn_and_update();app.finish_level()
	var walk:Node3D=app.finish_walk
	var gesture:=InputEventMagnifyGesture.new();gesture.factor=2.;walk.pointer_event(gesture)
	for i in 50:walk.present(1./60.,app.runner,app.camera,false)
	check(walk.zoom==2. and app.runner.first_person,"maximum plaza zoom enters first person")
	check(app.camera.position.distance_to(walk.avatar.position+Vector3.UP*2.55)<.05,"plaza viewpoint converges to eye height")
	var before:Vector3=walk.avatar.position;walk.stick=Vector2(0,-1)
	for i in 20:await physics_frame;walk.advance(1./60.,false)
	check(walk.avatar.position.distance_to(before)>1.,"first-person plaza walking works")
	walk.stick=Vector2.ZERO;walk.orbit_drag(Vector2(80,-150));walk.present(.1,app.runner,app.camera,true)
	check(walk.pitch<0.,"first-person plaza can look upward")
	await shot("plaza")
	gesture.factor=.8;walk.pointer_event(gesture);walk.present(.1,app.runner,app.camera,true)
	check(not app.runner.first_person and walk.zoom<2.,"reverse pinch restores third-person plaza")
	var road_count:=0
	for mesh:MeshInstance3D in app.scenery.find_children("*","MeshInstance3D",true,false):
		if mesh.get_meta("surface_role","")=="road":road_count+=1;check(mesh.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,"road receives shadows without thin-slab self-shadow acne")
	check(road_count>0,"road stability check covers live road geometry")
	var pickup:=preload("res://scripts/collectible_star.gd").build(app,2)
	check(pickup.find_children("*","MeshInstance3D",true,false).all(func(mesh):return mesh.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF),"rotating stars do not project flashing road patches")
	pickup.queue_free()
	print("FIRST PERSON / ROAD: %d checks, %d failures"%[checks,failures.size()])
	app.queue_free();await process_frame;await process_frame;await create_timer(.1).timeout;quit(0 if failures.is_empty() else 1)
