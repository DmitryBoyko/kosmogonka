extends SceneTree
const C=preload("res://scripts/course.gd")
const T=preload("res://scripts/hover_transport.gd")
const Cabin=preload("res://scripts/truck_cabin.gd")
var checks:=0
var errors:Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok:bool,label_value:String) -> void:
	checks+=1
	if not ok: errors.append(label_value); push_error(label_value)
func shot(name_value:String) -> void:
	if DisplayServer.get_name()=="headless": return
	await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/traffic-"+name_value+".png")
func run() -> void:
	var stair:=C.make_event(530.,1,"stairs")
	stair.length=12.
	var truck_route:=C.make_event(500.,1,"truck")
	var bypass:=C.make_event(500.,2,"truck")
	var crossing:=C.make_event(500.,2,"traffic")
	crossing.source_lane=0
	var closures:Array[Dictionary]=[stair,truck_route,bypass,crossing]
	C.reserve_stair_traffic(closures)
	for vehicle in [truck_route,bypass,crossing]:
		C.advance_event(vehicle,458.,20.,0,0.)
	check(not C.traffic_on_road(truck_route) and not C.traffic_on_road(crossing),"traffic cannot approach through a staircase or cross its lane")
	check(C.traffic_on_road(bypass),"an unobstructed lane keeps its oncoming traffic")
	C.advance_event(truck_route,500.,20.,0,0.)
	check(C.traffic_on_road(truck_route),"traffic resumes within its connected road section")
	var descending:=C.make_event(530.,1,"upper_stairs")
	descending.length=40.; descending.from_height=9.6; descending.to_height=0.
	var below:=C.make_event(517.,1,"broken")
	var bottom:=C.make_event(543.,1,"broken")
	C.reserve_stair_traffic([descending,below,bottom])
	check(C.traffic_on_road(below) and not C.traffic_on_road(bottom),"high stairs allow traffic underneath but their ground exit is reserved")
	for world in 10:
		for kind in ["truck","traffic","broken"]:
			var event:=C.make_event(500.,1,kind)
			C.advance_event(event,400.,20.,world,.016); var old:float=event.s
			C.advance_event(event,420.,20.,world,1.)
			check(event.s<old-6. and event.speed<=-12.8 and event.speed>=-14.3,"slower visible oncoming motion "+kind+str(world))
			var moving:float=event.s;C.advance_event(event,420.,20.,world,.5)
			check(event.s<moving-6. and event.s>moving-7.3,"vehicle advances with elapsed time even with runner coordinates frozen")
			C.advance_event(event,500.,20.,world,.016)
			check(is_equal_approx(event.s,500.),"meeting stays at authored encounter "+kind+str(world))
	for marker in [-52.,-42.,-24.,-14.]: check(Cabin.approach_flash(marker)>.99,"every approach has a flash "+str(marker))
	check(Cabin.approach_flash(-130.)==0. and Cabin.approach_flash(10.)==0.,"no distant or rear flash")
	check(Cabin.double_flash(-12.)>.99 and Cabin.double_flash(-24.)>.99 and Cabin.double_flash(-18.)==0.,"two distance-triggered headlight pulses and a dark pause")
	root.size=Vector2i(720,960)
	var stage:=Node3D.new(); root.add_child(stage)
	var env:=WorldEnvironment.new(); env.environment=Environment.new(); stage.add_child(env); env.environment.background_mode=Environment.BG_COLOR; env.environment.background_color=Color("182338"); env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color=Color("b1c6d8"); env.environment.ambient_light_energy=.65
	var light:=DirectionalLight3D.new(); stage.add_child(light); light.rotation_degrees=Vector3(-35,-25,0)
	var camera:=Camera3D.new(); stage.add_child(camera); camera.position=Vector3(6,5,9); camera.look_at(Vector3(0,1,0)); camera.current=true
	preload("res://scripts/geometry.gd").box(stage,Vector3(20,.1,20),Vector3(0,-.05,0),"34445b")
	var truck:=T.build("truck",0); stage.add_child(truck)
	var cabin:Node3D=truck.get_meta("cabin")
	check(truck.get_meta("open_cargo_bed",false),"truck has an empty bed")
	cabin.advance(2.52,-14.,true,false)
	check(cabin.headlight.visible and cabin.led.get_shader_parameter("power")>1.5 and cabin.beams.visible and cabin.halos.visible,"modern LEDs, beam, halo and real illumination flash together")
	await shot("front")
	cabin.advance(2.52,-14.,false,false); check(cabin.beams.visible,"flash is visible from the adjacent lane")
	cabin.advance(2.,-14.,true,true); check(not cabin.beams.visible and cabin.led.get_shader_parameter("power")<1.,"reduced-motion mode uses steady lamps")
	camera.position=Vector3(5,6,-7); camera.look_at(Vector3(0,1,-.5)); await shot("empty-bed")
	stage.free()
	var app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; app.set_process(false); app.set_physics_process(false)
	var profile:=root.get_node("Profile")
	profile.persistence_enabled=false; profile.retry_points.clear(); profile.reserve_hearts.clear(); profile.hero=0
	profile.outfits=[{},{}]; app.reset_course(); app.begin_run()
	for preview:Node3D in app.previews: preview.hide()
	app.events.assign([C.make_event(314.,1,"truck")]); app.pickups.clear()
	app.distance=314.-14./1.64; C.advance_event(app.events[0],app.distance,15.,0,.016)
	app.x=0.; app.lane=1; app.height=0.; app.runner.position=Vector3.ZERO; app.spawn_and_update(); app._process(.016); await shot("approach")
	app.distance=315.8; app.height=1.6; app.events[0].s=314.; app.check_contacts()
	check(app.lives==3 and is_equal_approx(app.find_support(),1.1),"open rear has a matching low support surface")
	app.distance=312.2; app.invulnerable=0; app.check_contacts(); check(app.lives==2,"cabin still blocks a low jump")
	var blocked_car:=C.make_event(314.,1,"truck")
	var road_exit:=C.make_event(314.,1,"stairs_down")
	road_exit.top=3.;road_exit.length=12.
	if is_instance_valid(app.events[0].node): app.events[0].node.queue_free()
	app.events.assign([blocked_car,road_exit])
	C.reserve_stair_traffic(app.events)
	app.distance=312.2; app.spawn_and_update()
	check(not is_instance_valid(blocked_car.node),"a closed lane spawns no vehicle on the staircase")
	app.events.assign([blocked_car])
	app.invulnerable=0;app.height=1.6;app.check_contacts()
	app.distance=315.8
	app.find_support()
	check(app.lives==2 and app.support_event!=blocked_car,"blocked traffic has no invisible collision or roof")
	app.turn_track.turns.assign([Vector4(275.,365.,16.,1.)])
	for kind in ["truck","traffic","broken"]:
		var vehicle:=C.make_event(319.,1,kind)
		app.events.assign([vehicle])
		app.distance=305.; app.spawn_and_update()
		var model: Node3D = vehicle.node.get_child(0) if kind=="traffic" else vehicle.node
		var headlights: Node3D = model.get_meta("cabin")
		var light_direction: Vector3 = -headlights.global_basis.z
		var to_runner: Vector3 = app.runner.global_position-headlights.global_position
		check(light_direction.dot(to_runner.normalized())>.65 and headlights.halos.visible,"oncoming "+kind+" faces the runner and flashes on a turn")
		vehicle.node.free()
	print("ONCOMING TRAFFIC: %d checks, %d failures"%[checks,errors.size()])
	app.free(); await process_frame; quit(0 if errors.is_empty() else 1)
