extends SceneTree
const Transport=preload("res://scripts/hover_transport.gd")
func _initialize() -> void: call_deferred("run")
func shot(file: String) -> void:
	await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+file+".png")
func run() -> void:
	root.size=Vector2i(1200,760)
	var stage:=Node3D.new(); root.add_child(stage)
	var world:=WorldEnvironment.new(); stage.add_child(world); world.environment=Environment.new()
	world.environment.background_mode=Environment.BG_COLOR; world.environment.background_color=Color("182338")
	world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; world.environment.ambient_light_color=Color("c2dded"); world.environment.ambient_light_energy=.8
	var light:=DirectionalLight3D.new(); stage.add_child(light); light.rotation_degrees=Vector3(-48,-28,0); light.light_energy=1.5
	var camera:=Camera3D.new(); stage.add_child(camera); camera.position=Vector3(8,6,-10); camera.look_at(Vector3(0,.6,.5)); camera.fov=44
	var deck:=Transport.build("carrier"); stage.add_child(deck); deck.position.x=-2.3
	var truck:=Transport.build("truck",1); stage.add_child(truck); truck.position=Vector3(1,0,1.7)
	var board:=Transport.build("board",2); stage.add_child(board); board.position=Vector3(3.3,1,-2)
	await shot("transports-0.4.2")
	stage.free()
	root.size=Vector2i(540,960)
	var app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; app.set_process(false); app.set_physics_process(false)
	app.planet=0; app.start_level(); app.begin_run(); app.toast_timer=0
	var target: Dictionary={}
	for e in app.events:
		if e.kind=="carrier": target=e; break
	for dist in [target.s-18,target.s]:
		app.distance=dist; app.lane=target.lane; app.x=(target.lane-1)*2.6
		app.height=1.48 if dist==target.s else 0
		app.runner.position=Vector3(app.x,app.height,0)
		app.spawn_and_update(); app._process(.016)
		await shot("transport-track-"+str(int(dist)))
	app.free()
	Transport.prototypes.clear()
	await create_timer(.15).timeout; quit()

