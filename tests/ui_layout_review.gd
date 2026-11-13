extends SceneTree
const OutfitShop = preload("res://scripts/outfit_shop_ui.gd")
const Gear = preload("res://scripts/gear_ui.gd")
const SCREENS := ["boot","menu","select","planets","settings","pause","results","flight_result",
	"shop","builder","skin_picker","cinematic","countdown","play","flight","explore"]
const VARIANTS := ["retry","retry_start","last_win","flight_skipped","boost","owned","details","gear_shop","aurora_arrival",
	"launch","flight_loading","flight_countdown","flight_replay","settings_pause"]
var failures:Array[String]=[]
var checks:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures.append(message)

func open_screen(app: Node, profile: Node, page: String) -> void:
	var ui: Node = app.hud
	match page:
		"boot": ui.boot_splash()
		"menu": ui.menu()
		"select": ui.selection(0,9)
		"planets": ui.planets(9,9)
		"settings", "settings_pause": ui.settings("pause" if page=="settings_pause" else "menu")
		"pause": ui.paused()
		"results", "retry", "retry_start", "last_win":
			var success := page not in ["retry","retry_start"]
			ui.results(success,1250 if success else 7,20000,20000,10 if page=="last_win" else 7 if page=="retry_start" else 8)
		"flight_result", "flight_skipped": ui.flight_results(1,8,9,page=="flight_skipped")
		"shop", "owned", "details", "boost":
			OutfitShop.show(ui,profile,0,"boost" if page=="boost" else "suit",
				"owned" if page=="owned" else "galaxy","","",true,true,page=="details")
		"gear_shop": Gear.shop(ui,"pack",profile)
		"builder": Gear.builder(ui,profile)
		"skin_picker": Gear.skins(ui,profile,"torso")
		"cinematic", "aurora_arrival": ui.arrival(0 if page=="aurora_arrival" else 9)
		"launch": ui.cinematic("Держись, космос!","Продолжаем приключение")
		"flight_loading": ui.cinematic("Готовимся к перелёту","Сингулярность → Зеркалия",false,false)
		"countdown", "flight_countdown": ui.countdown(3,page=="flight_countdown")
		"play":
			ui.playing()
			ui.update_hud(3,999,.3,"СИНГУЛЯРНОСТЬ","board",4.8,"Лист поднимается — выбирай свободную полосу!",1250)
		"flight", "flight_replay":
			ui.flight_playing(page=="flight_replay")
			ui.update_flight(2,.45,"Сингулярность → Зеркалия",3.,12)
		"explore":
			ui.exploring("Сингулярность")
			ui.shop_button.show()

func run() -> void:
	var app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; app.set_process(false); app.set_physics_process(false)
	var profile:=root.get_node("Profile")
	profile.persistence_enabled=false
	profile.bank=1000000
	profile.unlocked=9
	profile.retry_points[str(profile.hero)+":8"]={"distance":900.}
	var classified: Array = app.hud.PLAY_SCREENS+app.hud.MENU_SCREENS
	check(classified.size()==SCREENS.size() and SCREENS.all(func(page):return classified.count(page)==1),"Screen inventory")
	app.show_menu()
	app._process(.016)
	for size_value in [Vector2i(540,960),Vector2i(540,1200),Vector2i(720,960)]:
		root.size=size_value; await process_frame
		for screen in SCREENS+VARIANTS:
			open_screen(app,profile,screen)
			await process_frame; app.hud._layout(); await process_frame
			var bounds:=Rect2(Vector2.ZERO,root.get_visible_rect().size)
			var context:String=screen+" "+str(size_value)
			if screen in SCREENS: check(app.hud.current==screen,context+" route")
			if screen in ["cinematic","aurora_arrival","flight_loading","launch"]:
				var title: Label = app.hud.screen.get_node("CinematicTitle")
				check(title.get_line_count()==1 and absf(title.get_global_rect().get_center().x-bounds.get_center().x)<=1.,context+" centered cinematic title")
			if screen in ["retry","retry_start"]:
				var title: Label = app.hud.screen.get_node("ScreenTitle")
				var actions: Array[Node] = app.hud.screen.find_children("*","Button",true,false)
				check(title.text=="Попробуем снова!" and actions.size()==2,context+" retry actions")
				check(actions[0].text.begins_with("С середины") if screen=="retry" else actions[0].text=="Ещё раз",context+" correct retry entry")
			if screen in ["results","retry","retry_start","last_win"]:
				var summary: Panel = app.hud.screen.get_node("RunSummary")
				var actions: Array[Node] = app.hud.screen.find_children("*","Button",true,false)
				var hero: Label = summary.get_child(0)
				var stats: HBoxContainer = summary.get_child(1)
				var star: TextureRect = stats.get_child(0)
				var total: Label = stats.get_child(1)
				var group := star.get_global_rect().merge(total.get_global_rect())
				check(hero.text==preload("res://scripts/crew.gd").NAMES[profile.hero],context+" hero name")
				check(absf(group.get_center().x-bounds.get_center().x)<=1.,context+" star and totals grouped at center")
				check(actions[0].get_global_rect().position.y-summary.get_global_rect().end.y>=32.,context+" results and action spacing")
			if screen in ["play","flight","flight_replay"]:
				var hint: Label = app.hud.hint_label
				check(is_equal_approx(hint.get_global_rect().get_center().x,bounds.get_center().x),context+" lower HUD centered")
				if screen=="play":
					var booster: Button = app.hud.charge_buttons.board.button
					check(hint.get_global_rect().end.x<booster.get_global_rect().position.x,context+" lower HUD clear of boosters")
			for label:Label in app.hud.root.find_children("*","Label",true,false):
				if not label.is_visible_in_tree() or label.text.is_empty(): continue
				check(label.get_theme_color("font_shadow_color").a>0.,context+" missing shadow "+label.text)
				if label.get_parent()==app.hud.screen or label.get_parent()==app.hud.hud:
					check(bounds.encloses(label.get_global_rect()),context+" label outside "+label.text)
			if DisplayServer.get_name()!="headless" and size_value in [Vector2i(540,960),Vector2i(540,1200)]:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://build/ui-review-%s-%d.png"%[screen,size_value.y])
			var buttons:Array[Node]=app.hud.screen.find_children("*","BaseButton",true,false)
			buttons.append_array(app.hud.hud.find_children("*","BaseButton",true,false))
			for button:BaseButton in buttons:
				if not button.is_visible_in_tree(): continue
				var parent:=button.get_parent()
				while parent!=null:
					if parent is ScrollContainer: parent.ensure_control_visible(button)
					parent=parent.get_parent()
				await process_frame
				check(bounds.encloses(button.get_global_rect()),context+" control outside "+button.text)
				check(button.size.y>=44.,context+" short touch target "+button.text)
				var font:=button.get_theme_font("font")
				var font_size:=button.get_theme_font_size("font_size")
				var style:=button.get_theme_stylebox("normal")
				var available:=button.size.x-style.get_margin(SIDE_LEFT)-style.get_margin(SIDE_RIGHT)
				if not button.text.is_empty() and button.autowrap_mode==TextServer.AUTOWRAP_OFF:
					for line in button.text.split("\n"):
						check(font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x<=available,context+" clipped button "+line)
	var file:=FileAccess.open("res://build/ui-layout-review.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures},"  ")); file.close()
	print("UI LAYOUT: %d checks, %d failures"%[checks,failures.size()])
	for failure in failures: push_error(failure)
	app.free(); await create_timer(.1).timeout; quit(0 if failures.is_empty() else 1)
