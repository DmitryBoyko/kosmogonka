extends SceneTree
var failures:Array[String]=[]
var checks:=0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; app.set_process(false); app.set_physics_process(false)
	for size_value in [Vector2i(540,960),Vector2i(540,1200),Vector2i(720,960)]:
		root.size=size_value; await process_frame
		for screen in ["menu","select","settings","planets","pause","results","flight_result","shop","builder","skin_picker"]:
			match screen:
				"menu": app.hud.menu()
				"select": app.hud.selection(0,9)
				"settings": app.hud.settings("menu")
				"planets": app.hud.planets(9,9)
				"pause": app.hud.paused()
				"results": app.hud.results(true,400,20000,20000,8)
				"flight_result": app.hud.flight_results(1,8,9,false)
				"shop": preload("res://scripts/gear_ui.gd").shop(app.hud,"suit",root.get_node("Profile"))
				"builder": preload("res://scripts/gear_ui.gd").builder(app.hud,root.get_node("Profile"))
				"skin_picker": preload("res://scripts/gear_ui.gd").skins(app.hud,root.get_node("Profile"),"torso")
			await process_frame; app.hud._layout(); await process_frame
			for button:Button in app.hud.screen.find_children("*","Button",true,false):
				var parent:=button.get_parent()
				while parent!=null:
					if parent is ScrollContainer: parent.ensure_control_visible(button)
					parent=parent.get_parent()
				await process_frame
				checks+=1
				if not Rect2(Vector2.ZERO,size_value).encloses(button.get_global_rect()): failures.append(screen+" "+str(size_value)+" "+button.text)
			if DisplayServer.get_name()!="headless" and size_value==Vector2i(540,960) and screen in ["settings","planets"]:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://build/ui-review-"+screen+".png")
	var file:=FileAccess.open("res://build/ui-layout-review.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures},"  ")); file.close()
	print("UI LAYOUT: %d checks, %d failures"%[checks,failures.size()])
	app.free(); await create_timer(.1).timeout; quit(0 if failures.is_empty() else 1)
