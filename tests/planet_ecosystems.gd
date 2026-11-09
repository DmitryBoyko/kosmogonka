extends SceneTree
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label_value:String) -> void:
	checks+=1
	if not ok:failures.append(label_value);push_error(label_value)
func run() -> void:
	root.size=Vector2i(540,1188);var app=load("res://scenes/main.tscn").instantiate();app.test_mode=true;root.add_child(app)
	await process_frame;app.set_process(false);app.set_physics_process(false)
	root.get_node("Profile").first_person=false
	var previous_length:=0.
	for world in 10:
		app.planet=world;app.reset_course();app.begin_run();app.distance=500.;app.spawn_and_update();app._process(.016)
		var length:float=preload("res://scripts/course.gd").length_for(world)
		check(length>previous_length,"track grows at every world");previous_length=length
		check(app.loop_routes.routes.size()==(3 if world>=8 else 2 if world>=5 else 1 if world in [0,1,3] else 2),"loop count matches difficulty world"+str(world))
		check(app.loop_routes.routes.all(func(r):return r.start+55.<length-150.),"all loops fit before finish")
		for route:Dictionary in app.loop_routes.routes:
			var core:Node3D=route.node.get_node("EnergyCore");core.advance(1.,false);var size_before:Vector3=core.heart.scale;core.advance(1.5,false)
			check(core.heart.scale!=size_before,"GraviCube-inspired heart pulses")
			core.advance(1.,true);size_before=core.heart.scale;core.advance(3.,true);check(core.heart.scale==size_before,"reduced motion stops core pulse")
		var ground:ShaderMaterial=preload("res://scripts/surface_style.gd").ground(world)
		check(ground.get_shader_parameter("planet_index")==world,"planet-specific terrain shader")
		check(app.orbit.get_node("DeepStarfield").get_meta("backdrop_world")==world,"orbital background matches planet")
		if world>=2:check(app.scenery.find_children("NativeBiome","Node3D",true,false).size()>0,"native biome replaces generic forest")
		if DisplayServer.get_name()!="headless":
			await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://build/ecosystem-%02d.png"%world)
	var signatures:Array=[]
	for world in 10:
		signatures.clear()
		for variant in 4:
			preload("res://scripts/course.gd").layout_seed=variant
			var packets:Array=preload("res://scripts/course.gd").encounters(world)
			var signature:String=str(packets.map(func(p):return [p.s,p.lane,p.pattern])).sha256_text()
			check(not signatures.has(signature),"four distinct calculated layouts world"+str(world));signatures.append(signature)
			for packet:Dictionary in packets:check(preload("res://scripts/course.gd").lanes_at(packet.s,world).has(packet.lane),"variant never chooses a nonexistent lane")
	print("PLANET ECOSYSTEMS / VARIANTS: %d checks, %d failures"%[checks,failures.size()])
	app.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)
