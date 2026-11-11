extends SceneTree

const Track = preload("res://scripts/turn_track.gd")
const Course = preload("res://scripts/course.gd")
const Rocks = preload("res://scripts/rock_terrain.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func run() -> void:
	root.size = Vector2i(540,960)
	for world in 11:
		for seed_value in [0,101,217537,-30189]:
			Course.layout_seed = seed_value
			var route := Track.new()
			route.build(world,seed_value,Course.events(world))
			check(not route.grades.is_empty(),"at least one hill on planet %d seed %d"%[world,seed_value])
			for hill in route.grades:
				var width: float = hill.y-hill.x
				check(route.grade(hill.x).is_zero_approx() and route.grade(hill.y).is_zero_approx(),"grade and slope join flat sections")
				check(absf(route.grade(hill.x+width*.25).y)<=Track.MAX_GRADE+.001,"grade respects the driving slope cap")
				check(route.grade(hill.x+width*.25).y*route.grade(hill.x+width*.75).y<0.,"hill contains both ascent and descent")
				route.set_distance(hill.x+width*.25)
				check(route.map(Vector3.ZERO).length()<.001 and absf(route.view_height(0.))<.001,"runner stays on its local support plane")
				check(absf(route.view_height(-9.)-route.map(Vector3(0.,0.,-9.)).y)<.001,"camera and props share elevation")
				check(is_zero_approx(route.terrain_height(hill.x+width*.5,64.)),"terrain joins its outer horizon")
				if world==4: check(route.map_ground(Vector3(8.,0.,0.),true).y<=.001,"sea level stays below the causeway")
	for asset in ["spire","massif","rounded-range","boulder","ledge","strata","scree","rock-spikes","snow-shelf","snow-range","valley","block-outcrop"]:
		var rock := Rocks.mesh(asset)
		check(rock.get_surface_count()==1 and rock.get_aabb().has_volume(),"rock geometry is batched: "+asset)
	var app = load("res://scenes/main.tscn").instantiate()
	app.test_mode = true
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app.set_physics_process(false)
	var profile = root.get_node("Profile")
	profile.retry_points.clear()
	for world in 11:
		app.planet = world
		app.test_layout_seed = 531+world
		app.reset_course()
		app.begin_run()
		var route: Track = app.turn_track
		var hill: Vector3 = route.grades[0]
		var sample_s: float = lerpf(hill.x,hill.y,.26)
		app.distance = sample_s
		app.height = 0.
		app.x = 0.
		app.runner.position = Vector3.ZERO
		app.spawn_and_update()
		profile.first_person = true
		app._process(.016)
		var flat: Vector3 = Vector3(0,-.8,-18.).normalized()
		var direction: Vector3 = -app.camera.basis.z
		check(direction.y>flat.y and direction.y<.25,"first person looks up the climb")
		check(app.scenery.find_children("TerrainFormation*","MeshInstance3D",true,false).size()>0,"rock formations appear on planet %d"%world)
		if world==4:
			check(preload("res://scripts/surface_style.gd").ground(4).shader.resource_path.ends_with("ocean.gdshader"),"mobile ocean material active")
		profile.first_person = false
		app._process(.016)
		if DisplayServer.get_name()!="headless" and world in [0,1,2,4,7,8,10]:
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://build/terrain-world-%d.png"%world)
		await process_frame
	print("TERRAIN: %d checks, %d failures"%[checks,failures])
	if is_instance_valid(app.mobile_presentation): app.mobile_presentation.free()
	else: app.free()
	await process_frame
	quit(1 if failures else 0)
