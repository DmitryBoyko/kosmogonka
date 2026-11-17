extends SceneTree
func _initialize():call_deferred("run")
func run():
	var profile=root.get_node("Profile");profile.persistence_enabled=false;profile.retry_points.clear()
	var app=load("res://scenes/main.tscn").instantiate();app.test_mode=true;root.add_child(app)
	while not is_instance_valid(app.hud) or app.hud.current!="menu":
		await process_frame
	app.set_process(false);app.set_physics_process(false)
	var mobile: Control=app.mobile_presentation
	var planets := preload("res://scripts/planets.gd")
	var cache := preload("res://scripts/planet_cache.gd")
	var shop_count := 0
	for world in range(planets.count()):
		cache.request(world)
		app.planet=world;await app.start_level();await app.begin_run()
		app.distance=preload("res://scripts/course.gd").length_for(world);app.spawn_and_update();app.finish_level()
		for i in 3:
			app.finish_walk.avatar.position=preload("res://scripts/monument_shops.gd").POSITIONS[i]+Vector3(0,0,3)
			app._process(.016)
			assert(app.hud.shop_button.visible,"Shop entry missing on planet %d, terminal %d" % [world,i])
			app.test_mode=false
			app.hud.shop_button.pressed.emit()
			assert(app.state=="shop","Shop must open inside the button action, before any ad callback")
			assert(app.fitting_room.visible and not app.track_root.visible and not app.orbit.visible)
			assert(app.fitting_camera.global_position.distance_to(app.fitting_room.global_position)<15.)
			if is_instance_valid(mobile):
				assert(mobile.preview.find_world_3d()!=mobile.world.find_world_3d())
				assert(mobile.world.render_target_update_mode==SubViewport.UPDATE_DISABLED)
				assert(mobile.preview.render_target_update_mode==SubViewport.UPDATE_ALWAYS)
				assert(mobile.world_image.texture==mobile.preview.get_texture())
			else:
				assert(app.environment.environment==app.fitting_room.environment)
			var ads=root.get_node("CosmoAds")
			ads.active="shop";ads.presentation_started=true
			app.test_mode=false
			var before: float=app.fitting_room.pose_clock
			app._process(.1)
			assert(app.fitting_room.pose_clock>before,"ad state must not freeze shop rendering")
			ads.active="";ads.presentation_started=false;app.test_mode=true
			await app.on_action("close_gear")
			assert(app.state=="explore")
			shop_count += 1
			if is_instance_valid(mobile):
				assert(mobile.world.render_target_update_mode==SubViewport.UPDATE_ALWAYS)
				assert(mobile.preview.render_target_update_mode==SubViewport.UPDATE_DISABLED)
				assert(mobile.world_image.texture==mobile.world.get_texture())
	print("SHOP FIRST FRAME: %d shops on %d planets passed, including stale advertisement state" % [shop_count,planets.count()])
	app.free()
	var disposal := root.get_node("SceneDisposal")
	while not disposal.pending.is_empty():
		await process_frame
	await process_frame
	quit()
