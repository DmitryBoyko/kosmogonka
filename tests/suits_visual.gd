extends SceneTree
const Hero=preload("res://scripts/hero.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(1000,800)
	var world:=Node3D.new()
	root.add_child(world)
	var env:=WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color("17263b")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color("e2efff")
	env.environment.ambient_light_energy=0.5
	world.add_child(env)
	var light:=DirectionalLight3D.new()
	world.add_child(light)
	light.rotation_degrees=Vector3(-30,-28,0)
	var camera:=Camera3D.new()
	world.add_child(camera)
	camera.position=Vector3(0,2.2,5.7)
	camera.look_at(Vector3(0,1.35,0))
	camera.fov=32
	var heroes: Array=[]
	for i in 2:
		var hero=Hero.new()
		world.add_child(hero)
		hero.build(i==1)
		hero.position.x=-0.82 if i==0 else 0.82
		for frame in 30: hero.animate(1.0/60,"idle")
		heroes.append(hero)
	await capture("suits-default")
	var mixed: Dictionary=heroes[0].suit_loadout.duplicate(true)
	mixed.slots.left_arm="solar_rescue"
	mixed.slots.left_glove="solar_rescue"
	mixed.slots.right_boot="solar_rescue"
	heroes[0].apply_suit(mixed)
	await capture("suits-mixed-slots")
	for hero in heroes: hero.rotation.y=PI
	await capture("suits-back")
	world.free()
	quit()

func capture(label_value: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+label_value+".png")
