extends SceneTree
const U=preload("res://scripts/upper_route.gd")
const H=preload("res://scripts/hover_support.gd")
var app:Node
var failures:Array[String]=[]
var checks:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label_value:String) -> void:
	checks+=1
	if not ok:failures.append(label_value);push_error(label_value)
func shot(label_value:String) -> void:
	if DisplayServer.get_name()=="headless":return
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/upper-"+label_value+".png")
func run() -> void:
	root.size=Vector2i(540,1188);app=load("res://scenes/main.tscn").instantiate();app.test_mode=true;root.add_child(app)
	await process_frame;app.set_process(false);app.set_physics_process(false)
	var profile=root.get_node("Profile");profile.first_person=false
	for world in 10:
		app.planet=world;app.reset_course();app.begin_run();var decks:Array=app.events.filter(func(e):return e.kind=="upper_deck")
		check(decks.size()==6,"six elevated gardens world"+str(world))
		check(app.events.any(func(e):return e.kind=="upper_deck" and e.top==9.6),"fourth floor world"+str(world))
		for e:Dictionary in app.events:
			if H.suspended(e) and e.kind!="upper_crate":
				var model:Node3D=app.build_event_visual(e);check(model.get_meta("hover_engine_count",0)==4,"four engines "+e.kind);model.free()
		app.distance=U.START-3.;app.lane=0;app.x=-2.6;app.height=0.;app.support=0.;var max_height:=0.
		for frame in 5000:
			for e:Dictionary in app.events:
				if e.kind=="upper_crate" and e.s-app.distance>0. and e.s-app.distance<app.speed*.43:app.jump()
			app.simulate(1./60.);app._process(1./60.);max_height=maxf(max_height,app.height)
			if world==0 and frame in [300,600]:await shot("route-"+str(frame))
			if app.distance>U.END+10.:break
		check(app.lives==3,"elevated garden can be completed without losing a heart world"+str(world))
		check(max_height>9.5,"runner reaches fourth floor world"+str(world))
		check(app.height<.2,"continuous stairs return to the ground world"+str(world))
		print("UPPER WORLD ",world," max=",max_height," lives=",app.lives)
	app.planet=0;app.reset_course();app.begin_run();app.distance=1170.;app.lane=0;app.x=-2.6;app.height=9.6;app.support=9.6;app.support_event=app.events.filter(func(e):return e.kind=="upper_deck" and e.top==9.6)[0]
	var before_charges:Dictionary=profile.charges.duplicate(true)
	app.vertical_gesture("down");check(app.auto_landing and app.lane==1 and app.vertical_speed>0.,"down hops off the edge and starts automatic jet landing")
	for i in 240:app.simulate(1./60.);app._process(1./60.)
	check(not app.auto_landing and app.height<.2 and app.lives==3,"automatic landing reaches the ground unharmed")
	check(profile.charges==before_charges,"safety landing consumes no purchased booster")
	var e:Dictionary=app.events.filter(func(item):return item.kind=="upper_deck")[0]
	check(absf(H.offset(e,1.)-H.offset(e,2.))>.01,"platform sway changes its support height")
	H.set_motion(true);check(H.offset(e,2.)==0. and H.roll(e,2.)==0.,"reduced motion stops physical sway");H.set_motion(false)
	print("UPPER GARDENS: %d checks, %d failures"%[checks,failures.size()])
	app.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)
