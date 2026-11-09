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
	for world in 10:
		for kind in ["truck","traffic","broken"]:
			var event:=C.make_event(500.,1,kind)
			C.advance_event(event,400.,20.,world,.016); var old:float=event.s
			C.advance_event(event,420.,20.,world,1.)
			check(event.s<old-6. and event.speed< -6.,"visible oncoming motion "+kind+str(world))
			var moving:float=event.s;C.advance_event(event,420.,20.,world,.5)
			check(event.s<moving-10.,"vehicle advances with elapsed time even with runner coordinates frozen")
			C.advance_event(event,500.,20.,world,.016)
			check(is_equal_approx(event.s,500.),"meeting stays at authored encounter "+kind+str(world))
	for marker in [-52.,-42.,-24.,-14.]: check(Cabin.approach_flash(marker)>.99,"every approach has a flash "+str(marker))
	check(Cabin.approach_flash(-130.)==0. and Cabin.approach_flash(10.)==0.,"no distant or rear flash")
	check(Cabin.double_flash(.1)>.99 and Cabin.double_flash(.36)>.99 and Cabin.double_flash(.7)==0.,"two readable headlight pulses and a dark pause")
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
	check(cabin.headlight.visible and cabin.led.get_shader_parameter("power")>1.5 and cabin.beams.visible,"modern LEDs, beam and real illumination flash together")
	await shot("front")
	cabin.advance(2.52,-14.,false,false); check(cabin.beams.visible,"flash is visible from the adjacent lane")
	cabin.advance(2.,-14.,true,true); check(not cabin.beams.visible and cabin.led.get_shader_parameter("power")<1.,"reduced-motion mode uses steady lamps")
	camera.position=Vector3(5,6,-7); camera.look_at(Vector3(0,1,-.5)); await shot("empty-bed")
	stage.free()
	var app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; app.set_process(false); app.set_physics_process(false)
	root.get_node("Profile").outfits=[{},{}]; app.reset_course(); app.begin_run()
	for preview:Node3D in app.previews: preview.hide()
	app.events.assign([C.make_event(314.,1,"truck")]); app.pickups.clear()
	app.distance=314.-14./1.35; C.advance_event(app.events[0],app.distance,15.,0,.016)
	app.x=0.; app.lane=1; app.height=0.; app.runner.position=Vector3.ZERO; app.spawn_and_update(); app._process(.016); await shot("approach")
	app.distance=315.8; app.height=1.6; app.events[0].s=314.; app.check_contacts()
	check(app.lives==3 and is_equal_approx(app.find_support(),1.1),"open rear has a matching low support surface")
	app.distance=312.2; app.invulnerable=0; app.check_contacts(); check(app.lives==2,"cabin still blocks a low jump")
	print("ONCOMING TRAFFIC: %d checks, %d failures"%[checks,errors.size()])
	app.free(); await process_frame; quit(0 if errors.is_empty() else 1)
