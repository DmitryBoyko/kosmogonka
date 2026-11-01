extends SceneTree
const Hero=preload("res://scripts/hero.gd")
const G=preload("res://scripts/geometry.gd")
func _initialize() -> void: call_deferred("run")
func capture(label_value: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+label_value+".png")
func run() -> void:
	root.size=Vector2i(720,900)
	var world:=Node3D.new()
	root.add_child(world)
	var env:=WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color("0d142a")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color("d8e9ff")
	env.environment.ambient_light_energy=0.35
	world.add_child(env)
	var floor_piece:=G.box(world,Vector3(12,0.08,12),Vector3(0,-0.08,0),"293b56")
	var light:=DirectionalLight3D.new()
	world.add_child(light)
	light.rotation_degrees=Vector3(-30,-35,0)
	light.light_energy=0.8
	var camera:=Camera3D.new()
	world.add_child(camera)
	camera.position=Vector3(3.4,2.4,6.2)
	camera.look_at(Vector3(0,1.55,0))
	camera.fov=34
	var hero=Hero.new()
	world.add_child(hero)
	hero.build(false)
	hero.position.y=0.85
	hero.rotation.y=PI
	for i in 45: hero.animate(1.0/60,"jet")
	await capture("jetpack-dark")
	for i in 24:
		hero.animate(1.0/30,"jet")
		await capture("jetpack-frame-%02d" % i)
	env.environment.background_color=Color("b8c8db")
	floor_piece.material_override=G.material("899fb9")
	await capture("jetpack-light")
	hero.animate(1.0/60,"idle")
	await capture("jetpack-off")
	world.free()
	quit()
