extends SceneTree
func _initialize() -> void: call_deferred("run")
func shot(app:Node,name_value:String) -> void:
	await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/menu-crew-"+name_value+".png")
func run() -> void:
	root.size=Vector2i(540,960)
	var app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; app.set_process(false); app.set_physics_process(false)
	app.show_menu(); app.menu_crew.start("greet",1)
	for i in 50: app._process(1./60)
	await shot(app,"greeting")
	app.menu_crew.start("duel",0)
	for i in 380:
		app._process(1./60)
		if i in [38,90,160,215,275,375]: await shot(app,str(i))
	app.free(); await create_timer(.15).timeout; quit()
