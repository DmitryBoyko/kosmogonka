extends SceneTree
const Cargo=preload("res://scripts/cargo_containers.gd")
const Hero=preload("res://scripts/hero.gd")
var app: Node
func _initialize() -> void: call_deferred("run")
func shot(name_value: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name_value+".png")
func run() -> void:
	root.size=Vector2i(1000,700)
	var stage:=Node3D.new(); root.add_child(stage)
	var world:=WorldEnvironment.new(); stage.add_child(world); world.environment=Environment.new()
	world.environment.background_mode=Environment.BG_COLOR; world.environment.background_color=Color("131b30")
	world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; world.environment.ambient_light_color=Color.WHITE; world.environment.ambient_light_energy=0.65
	var light:=DirectionalLight3D.new(); stage.add_child(light); light.rotation_degrees=Vector3(-50,-35,0); light.light_energy=1.2
	var camera:=Camera3D.new(); stage.add_child(camera); camera.position=Vector3(4,6,10); camera.look_at(Vector3(0,1.2,-1.5)); camera.fov=40
	for i in 10:
		var c:=Cargo.fitted(i+4,Vector3(1.6,1.9,1.4)); stage.add_child(c)
		c.position=Vector3((i%5-2)*2.4,0,-(i/5)*3.0)
	await shot("cargo-ten-new")
	stage.free()
	root.size=Vector2i(540,960)
	app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; app.set_process(false); app.set_physics_process(false)
	app.planet=0; app.start_level(); app.begin_run(); app.toast_timer=0
	for distance_value in [615.0,644.0,663.0,2088.0]:
		app.distance=distance_value; app.lane=1; app.x=0
		app.height=3.35 if distance_value in [644.0,663.0] else 0.0
		app.runner.position=Vector3(0,app.height,0)
		app.tunnel_active={}
		app.tunnel_camera_blend=1.0 if app.height>0 else 0.0
		app.spawn_and_update(); app._process(0.016)
		await shot("salvage-track-"+str(int(distance_value)))
	# Close-up animated gestures, both heroes; game camera captures follow separately.
	app.show_menu(); app.hud.screen.visible=false
	for girl in [false,true]:
		for h in app.previews: h.visible=false
		var kid=app.previews[1 if girl else 0]
		kid.affection.connect(func(kind,source): app.affection_fx.emit_hearts(source,app.camera,kind=="heart"))
		kid.visible=true; kid.position=Vector3.ZERO; kid.rotation=Vector3.ZERO
		app.camera.position=Vector3(0,2.4,4.5); app.camera.look_at(Vector3(0,1.6,0)); app.camera.fov=40
		for gesture in ["wave","tap","heart"]:
			app.affection_fx.clear()
			kid.begin_front_gesture(gesture)
			for i in (70 if gesture=="heart" else 40):
				kid.animate(1.0/60,"run",6)
				app.affection_fx.advance(1.0/60,app.camera,true)
			await shot("gesture-"+str(int(girl))+"-"+gesture)
	app.free(); await create_timer(0.15).timeout; quit()
