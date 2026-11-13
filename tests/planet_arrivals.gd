extends SceneTree
const Identity=preload("res://scripts/planet_identity.gd")
const Planets=preload("res://scripts/planets.gd")
var checks:=0
var errors:Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok:bool,label_value:String) -> void:
	checks+=1
	if not ok: errors.append(label_value); push_error(label_value)
func run() -> void:
	root.size=Vector2i(540,960)
	var app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; app.set_process(false); app.set_physics_process(false)
	var identities:Array=[]
	for index in Planets.count():
		app.planet=index; app.start_level(); app.cinema_time=2.4; app._process(.016)
		var profile:=Identity.get_profile(index)
		var globe:Node3D=app.orbit.globe
		check(globe.get_meta("planet_index")==index and globe.get_meta("identity")==profile.id,"current world identity "+str(index))
		check(not identities.has(profile.id),"unique visual identity "+str(index)); identities.append(profile.id)
		var surface:ShaderMaterial=globe.get_node("Surface").material_override
		check(surface.get_shader_parameter("identity")==index and is_equal_approx(surface.get_shader_parameter("terrain_seed"),profile.seed),"individual terrain "+str(index))
		check(is_equal_approx(globe.get_node("Clouds").material_override.get_shader_parameter("coverage"),profile.coverage),"individual cloud cover "+str(index))
		check(app.orbit.moons.get_child_count()==profile.moons,"correct moons, no leftovers "+str(index))
		var rings:=0
		for child in globe.get_node("Signature").get_children():
			if str(child.name).begins_with("Ring"):
				rings+=1
				check(child.mesh is PlaneMesh and child.material_override.get_shader_parameter("opacity")<1.,"thin translucent ring "+str(index))
		check(rings==profile.rings,"correct rings, no leftovers "+str(index))
		check(app.state=="intro" and app.hud.skip.visible,"intro and skip button preserved "+str(index))
		var title:Label=app.hud.screen.get_node("CinematicTitle")
		check(title.get_line_count()==1 and title.text==Planets.get_data(index).name,"planet name fits above subtitle "+str(index))
		await process_frame
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://build/arrival-%02d.png"%index)
		app.on_action("skip"); check(app.state=="run","skip still enters level "+str(index))
	app.orbit.configure(0); check(app.orbit.globe.get_meta("identity")=="crystal" and app.orbit.moons.get_child_count()==1,"return to original world restores identity")
	print("PLANET ARRIVALS: %d checks, %d failures"%[checks,errors.size()])
	app.free(); await process_frame; quit(0 if errors.is_empty() else 1)
