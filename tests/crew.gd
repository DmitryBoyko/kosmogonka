extends SceneTree

const Crew = preload("res://scripts/crew.gd")
const Avatar = preload("res://scripts/crew_avatar.gd")
const Hair = preload("res://scripts/crew_hair.gd")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func swipe(from: Vector2, to: Vector2) -> void:
	for pressed in [true,false]:
		var event := InputEventScreenTouch.new()
		event.index = 0
		event.position = from if pressed else to
		event.pressed = pressed
		root.push_input(event,true)
		await process_frame
		if pressed:
			var drag := InputEventScreenDrag.new()
			drag.index = 0
			drag.position = (from+to)*.5
			drag.relative = drag.position-from
			root.push_input(drag,true)
			await process_frame

func capture(file: String) -> void:
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/" + file)

func sprint_rise(actor: Node3D, clip: String) -> float:
	var player: AnimationPlayer = actor.animation
	var skeleton: Skeleton3D = actor.skeleton
	var root_bone := skeleton.find_bone("root")
	var length := player.get_animation(clip).length
	var low := INF
	var high := -INF
	player.play(clip)
	for sample in 61:
		player.seek(length * sample / 60.,true)
		var y := skeleton.get_bone_pose_position(root_bone).y
		low = minf(low,y)
		high = maxf(high,y)
	return (high-low) * actor.rig.scale.y

func run() -> void:
	root.size = Vector2i(540,1188)
	var app = load("res://scenes/main.tscn").instantiate()
	app.test_mode = true
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app.set_physics_process(false)
	var profile = root.get_node("Profile")
	profile.persistence_enabled = false
	profile.hero = 0
	profile.bank = 125
	profile.retry_points.clear()
	app.show_menu()
	app._process(.5)
	await capture("crew-menu.png")
	await swipe(Vector2(345,500),Vector2(175,500))
	check(profile.hero == 1,"left swipe selects the next model")
	await swipe(Vector2(175,500),Vector2(345,500))
	check(profile.hero == 0,"right swipe selects the previous model")
	await swipe(Vector2(175,500),Vector2(345,500))
	check(profile.hero == Crew.MODELS.size()-1,"the roster wraps")
	check(profile.bank == 0 and profile.wallets.get("0") == 125,"new character has a separate wallet")
	app.on_action("select")
	app._process(.5)
	await capture("crew-selection.png")
	check(app.previews.all(func(actor): return not actor.visible),"original pair is retained and hidden")
	for index in Crew.MODELS.size():
		var actor := Avatar.new()
		root.add_child(actor)
		actor.build(index,true)
		var head: MeshInstance3D = actor.rig.find_children("*head-mesh*","MeshInstance3D",true,false)[0]
		var skin := head.mesh.surface_get_material(0) as ShaderMaterial
		check(skin!=null and skin.shader.resource_path.ends_with("crew_skin.gdshader"),"head atlas keeps its details under the skin palette")
		if Crew.MODELS[index] in ["alien","zombie"]:
			check(skin.get_shader_parameter("extra_skin_cell") in [Vector2i(5,1),Vector2i(9,2)],"colored source skin is mapped to a natural tone")
		var hair_surfaces := 0
		for surface in head.mesh.get_surface_count():
			var material := head.mesh.surface_get_material(surface) as StandardMaterial3D
			if material and material.vertex_color_use_as_albedo: hair_surfaces += 1
		check(hair_surfaces == int(Hair.STYLES.has(Crew.MODELS[index])),"hair is painted separately from face and headgear")
		for side in ["left","right"]:
			for chain in [["elbow-","arm-"],["knee-","leg-"],["ankle-","knee-"]]:
				var joint: int = actor.skeleton.find_bone(chain[0] + side)
				check(joint >= 0 and actor.skeleton.get_bone_parent(joint) == actor.skeleton.find_bone(chain[1] + side),"articulated limb " + Crew.MODELS[index])
		for pair in [["run",Avatar.SPRINT],["jump","crew/jump"],["slide","crew/crouch"],["jet","crew/fall"],["pilot","crew/sit"]]:
			actor.pose(pair[0],17.)
			check(actor.animation.assigned_animation == pair[1],"animation loads: %s %s" % [Crew.MODELS[index],pair[1]])
		var original := sprint_rise(actor,"sprint")
		var adapted := sprint_rise(actor,Avatar.SPRINT)
		check(adapted > 0.06 and adapted < 0.14 and adapted < original * .25,"run retains a shallow stride: " + Crew.MODELS[index])
		var cycle: AnimationPlayer = actor.animation
		var skeleton: Skeleton3D = actor.skeleton
		cycle.play("crew/idle")
		cycle.seek(0.,true)
		var ankle := skeleton.get_bone_global_pose(skeleton.find_bone("ankle-left"))
		check(absf((ankle * Vector3(0,-.027,0)).y) < .01,"longer legs still plant the boots on the ground")
		var head_bone := skeleton.find_bone("head")
		check(skeleton.get_bone_pose_scale(head_bone).is_equal_approx(Vector3.ONE*.90),"head, face and visor share the ten-percent reduction")
		check(skeleton.get_bone_global_pose(head_bone).origin.y > skeleton.get_bone_global_rest(head_bone).origin.y + .10,"body height increases below the unchanged head")
		cycle.play(Avatar.SPRINT)
		var length := cycle.get_animation(Avatar.SPRINT).length
		cycle.seek(length * .125,true)
		var knee_left := skeleton.get_bone_pose_rotation(skeleton.find_bone("knee-left")).get_angle()
		var elbow_left := skeleton.get_bone_pose_rotation(skeleton.find_bone("elbow-left")).get_angle()
		cycle.seek(length * .625,true)
		check(absf(knee_left - skeleton.get_bone_pose_rotation(skeleton.find_bone("knee-left")).get_angle()) > .6,"knee flex alternates during sprint")
		check(absf(elbow_left - skeleton.get_bone_pose_rotation(skeleton.find_bone("elbow-left")).get_angle()) > .25,"elbow flex alternates during sprint")
		var max_blink := 0.
		for frame in 250:
			actor.update_expression(.016,.2)
			max_blink = maxf(max_blink,actor.expression.get_shader_parameter("blink"))
		check(max_blink > .95,"eyes close fully")
		actor.grin()
		actor.update_expression(.4,.2)
		check(actor.expression.get_shader_parameter("smile") > .9,"collectible triggers a grin")
		actor.free()
	app.on_action("start")
	check(app.runner.crew_index == profile.hero and app.surface_pilot.crew_index == profile.hero,"last roster slot is used in the race and cockpit")
	app.begin_run()
	app._process(.016)
	check(app.roadside_billboards.character == profile.hero and app.roadside_billboards.signs.size() == 2,"road signs use the selected astronaut")
	app.roadside_billboards.advance(.1,true,app.roadside_billboards.marks[0]-40.,false)
	check(app.roadside_billboards.signs[0].visible and not app.roadside_billboards.signs[1].visible,"only nearby roadside signs are rendered")
	check(app.runner.crew_avatar.animation.assigned_animation == Avatar.SPRINT,"race runs the adapted sprint animation")
	var pack: Node3D = app.runner.pack
	check(pack.get_parent() == app.runner.crew_avatar.chest,"the jetpack follows the Kenney torso")
	check(pack.find_children("*","MeshInstance3D",true,false).any(func(piece):
		return piece.get_meta("suit_slot","") == "backpack" and piece.is_visible_in_tree()
	),"the actual race backpack is visible")
	app.runner.crew_avatar.animation.advance(.24)
	await capture("crew-rear-fit.png")
	app.runner.set_first_person(true)
	check(app.runner.first_person_geometry.any(func(entry): return app.runner.crew_avatar.is_ancestor_of(entry.node)),"first-person visibility includes the imported model")
	print("CREW: %d models, %d failures" % [Crew.MODELS.size(),failures.size()])
	app.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)
