extends SceneTree

const Crew = preload("res://scripts/crew.gd")
const Avatar = preload("res://scripts/crew_avatar.gd")
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
		check(actor.skeleton.get_bone_count() >= 7,"model has its skeleton: " + Crew.MODELS[index])
		for pair in [["run",Avatar.SPRINT],["jump","jump"],["slide","crouch"],["jet","fall"],["pilot","sit"]]:
			actor.pose(pair[0],17.)
			check(actor.animation.assigned_animation == pair[1],"animation loads: %s %s" % [Crew.MODELS[index],pair[1]])
		var original := sprint_rise(actor,"sprint")
		var adapted := sprint_rise(actor,Avatar.SPRINT)
		check(adapted > 0.06 and adapted < 0.14 and adapted < original * .25,"run retains a shallow stride: " + Crew.MODELS[index])
		actor.free()
	app.on_action("start")
	check(app.runner.crew_index == profile.hero and app.surface_pilot.crew_index == profile.hero,"last roster slot is used in the race and cockpit")
	app.begin_run()
	app._process(.016)
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
