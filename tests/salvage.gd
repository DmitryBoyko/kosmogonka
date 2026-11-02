extends SceneTree
const Cargo=preload("res://scripts/cargo_containers.gd")
const Course=preload("res://scripts/course.gd")
var app: Node
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok: bool, title: String) -> void:
	checks+=1
	if not ok: failures.append(title); push_error(title)
func step(frames: int) -> void:
	for i in frames: app.simulate(1.0/60); app._process(1.0/60)
func isolated() -> void:
	app.planet=0; app.reset_course(); app.begin_run()
	for e in app.events+app.pickups:
		if is_instance_valid(e.node): e.node.free()
	app.events.clear(); app.pickups.clear()
	var tunnel:=Course.make_event(100,1,"tunnel")
	app.events.append(tunnel)
	for offset in range(-17,19,3):
		Course.add_star(app.pickups,100+offset,1,Course.TUNNEL_FLOOR+1,2,tunnel,"tunnel"); app.pickups.back().mega=true
	app.distance=68; app.speed=15
func run() -> void:
	var geometries:Dictionary={}
	for i in 14:
		var c:=Cargo.fitted(i,Vector3(2.1,2.9,1.7)); root.add_child(c)
		check(c.get_meta("container_variant")==i,"stable variant id")
		check(c.find_children("*","Sprite3D",true,false).is_empty(),"containers are real 3D geometry")
		var vertices:=0
		for m: MeshInstance3D in c.find_children("*","MeshInstance3D",true,false): vertices+=m.mesh.surface_get_array_len(0)
		geometries[vertices]=true
		check(vertices>300,"detailed chamfers, latches and handles")
		c.free()
	check(geometries.size()>=10,"at least ten distinct container constructions")
	var finishes:Dictionary={}
	for i in range(4,14): finishes[Cargo.coating(i).get_shader_parameter("finish_pattern")]=true
	check(finishes.size()==10,"ten distinct surface patterns")
	app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; app.set_process(false); app.set_physics_process(false)
	for planet in 4:
		var count:=0
		for e in Course.events(planet):
			if e.kind=="tunnel": count+=1; check(not Course.transitioning(e.s),"tunnel outside camera turn")
		check(count==2,"two optional sky routes per planet")
	isolated(); app.vertical_gesture("up"); step(200)
	check(app.tunnel_active.is_empty() and app.stars==0 and app.lives==3,"single jump passes underneath without damage or megastars")
	for delay in [5,12,24]:
		isolated(); app.vertical_gesture("up"); step(delay); app.vertical_gesture("up")
		for frame in 80:
			step(1)
			if not app.tunnel_active.is_empty(): break
		check(not app.tunnel_active.is_empty(),"double swipe enters aperture; delay "+str(delay))
		if app.tunnel_active.is_empty(): continue
		var entered_lane: int=app.lane
		app.move_screen(1); app.vertical_gesture("down"); app.jump()
		check(app.lane==entered_lane and app.vertical_speed==0,"safe guided interior ignores lane/vertical exit input")
		var wall:=Course.make_event(app.distance,1,"wall"); app.events.append(wall)
		app.check_contacts(); check(app.lives==3,"ground obstacles cannot injure inside the tube")
		app.events.erase(wall)
		for frame in 400:
			step(1)
			if app.tunnel_active.is_empty(): break
		check(app.stars==24,"twelve mega stars each count twice")
		check(app.tunnel_active.is_empty() and app.invulnerable>0,"exit has protected descent")
	isolated(); app.activate_booster("board"); app.vertical_gesture("up"); step(8); app.vertical_gesture("up")
	for frame in 100:
		step(1)
		if not app.tunnel_active.is_empty(): break
	check(not app.tunnel_active.is_empty() and app.booster.is_empty(),"board ride transfers safely into tunnel")
	# Exercise the real front-camera schedule using ordinary route inputs.
	app.reset_course(); app.begin_run(); app.distance=832; app.lane=2; app.x=2.6
	var front_signals:Array=[]
	app.runner.affection.connect(func(kind,source): front_signals.append(kind))
	for frame in 1400:
		preload("res://tests/route_pilot.gd").drive(app); step(1)
		if app.distance>978: break
	check(app.front_gesture_index==3 and front_signals.size()==3,"all three affection gestures run between front-camera hazards")
	# Gesture timing, hand contact and bounded effects.
	var kid=app.runner
	var signals:Array=[]
	kid.affection.connect(func(kind,source): signals.append([kind,source]))
	for gesture in ["wave","tap","heart"]:
		kid.begin_front_gesture(gesture)
		for i in 110: kid.animate(1.0/60,"run",6)
		check(kid.front_gesture.is_empty(),"gesture completes "+gesture)
	check(signals.size()==3,"two heart taps and one heart send")
	check(signals[0][0]=="tap" and signals[2][0]=="heart","signals correspond to contact/send")
	kid.begin_front_gesture("tap"); kid.animate(0.1,"jump",6)
	check(kid.front_gesture.is_empty(),"jump cancels affection gesture")
	check(app.affection_fx.pool.size()==12,"bounded heart pool")
	check(app.finish.get_meta("finish_monuments",false),"finish uses source monument architecture")
	print("SALVAGE / GESTURES: ",checks," checks, ",failures.size()," failures; ",failures)
	app.free(); await create_timer(0.15).timeout; quit(1 if not failures.is_empty() else 0)
