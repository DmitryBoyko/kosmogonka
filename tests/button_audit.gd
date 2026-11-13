extends SceneTree
var app:Node
var checks:=0
var failures:Array[String]=[]
var visited:Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok: failures.append(message); push_error(message)
func find(command:String) -> Button:
	for node:Node in app.hud.root.find_children("*","Button",true,false):
		if node.is_visible_in_tree() and node.get_meta("command","")==command: return node
	return null
func tap(control:Control,ratio:Vector2=Vector2(.5,.5)) -> void:
	var rect:=control.get_global_rect(); var center:=rect.position+rect.size*ratio
	var motion:=InputEventMouseMotion.new(); motion.position=center; root.push_input(motion,true)
	var event:=InputEventMouseButton.new(); event.position=center; event.global_position=center; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=true
	root.push_input(event,true); await process_frame
	event=InputEventMouseButton.new(); event.position=center; event.global_position=center; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=false
	root.push_input(event,true); await process_frame
func click(command:String) -> void:
	await process_frame; await process_frame
	var button:=find(command)
	check(button!=null,"visible button exists: "+command)
	if button==null: return
	check(not button.disabled and button.size.y>=44,"enabled touch target: "+command)
	var parent:=button.get_parent()
	while parent!=null:
		if parent is ScrollContainer: parent.ensure_control_visible(button)
		parent=parent.get_parent()
	await process_frame; await process_frame
	parent=button.get_parent()
	while parent!=null:
		if parent is ScrollContainer: parent.ensure_control_visible(button)
		parent=parent.get_parent()
	await process_frame; await process_frame
	var rect:=button.get_global_rect()
	check(Rect2(Vector2.ZERO,root.size).encloses(rect),"button is reachable inside the screen: "+command)
	check(button.focus_mode==Control.FOCUS_ALL,"button supports keyboard focus: "+command)
	visited.append(app.hud.current+":"+command)
	await tap(button)
func run() -> void:
	root.size=Vector2i(540,960)
	app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; app.set_process(false); app.set_physics_process(false)
	var profile=root.get_node("Profile")
	profile.charges[str(profile.hero)]={"jet":2,"board":2}
	await click("settings"); check(app.hud.current=="settings","menu settings opens")
	for control in app.hud.screen.get_children():
		if control is CheckButton:
			var old:bool=control.button_pressed
			await tap(control); check(control.button_pressed!=old,"toggle responds to an actual pointer click")
			await tap(control); check(control.button_pressed==old,"toggle returns to its original state")
			visited.append("settings:"+control.text); check(control.get_signal_connection_list("toggled").size()>0,"setting toggle is connected")
		if control is HSlider:
			var old:float=control.value; await tap(control,Vector2(.25,.5))
			check(absf(control.value-old)>.05,"volume slider responds to pointer input")
			check(is_equal_approx(float(profile.volumes[control.get_meta("audio_bus")]),control.value),"slider updates its own audio bus")
			control.value=old
			visited.append("settings:volume")
	await click("close_settings"); check(app.hud.current=="menu","done returns to menu")
	check(find("select").size==find("settings").size and find("select").position.x==find("settings").position.x,"main menu actions share the same size and centreline")
	check(find("select").get_theme_font_size("font_size")==find("settings").get_theme_font_size("font_size"),"main menu actions share the same font size")
	check(find("camera_view")==null,"the title screen has no race camera control")
	profile.hero=0
	app.carousel.reset(0)
	await click("select");app.step_crew(1);check(profile.hero==1,"next crew model")
	app.step_crew(-1);check(profile.hero==0,"previous crew model")
	check(find("boy")==null and find("girl")==null and find("builder")==null,"selection uses actors and has no pre-run shop")
	app.on_action("builder");check(app.state=="select","pre-run shop action rejected")
	await click("planets"); check(app.hud.current=="planets","planet list opens")
	var count:=0
	for node:Node in app.hud.screen.find_children("*","Button",true,false):
		if str(node.get_meta("command","")).begins_with("planet_"): count+=1
	check(count==preload("res://scripts/planets.gd").count(),"all planet buttons exist in scroll list")
	var list: ScrollContainer = app.hud.screen.get_node("PlanetList")
	var first: Button = find("planet_0")
	var from := first.get_global_rect().get_center()
	var down:=InputEventScreenTouch.new(); down.index=0; down.position=from; down.pressed=true
	root.push_input(down,true); await process_frame
	var list_drag:=InputEventScreenDrag.new(); list_drag.index=0; list_drag.position=from-Vector2(0.,124.)
	list_drag.relative=Vector2(0.,-124.); root.push_input(list_drag,true); await process_frame
	var up:=InputEventScreenTouch.new(); up.index=0; up.position=list_drag.position; up.pressed=false
	root.push_input(up,true); await process_frame
	check(list.position.y<=205. and list.size.y>=565. and list.scroll_vertical>100 and app.hud.current=="planets","vertical swipe on a planet button scrolls the raised list without activating the planet")
	list.scroll_vertical=0; await process_frame
	down.position=first.get_global_rect().get_center(); up.position=down.position
	root.push_input(down,true); await process_frame
	root.push_input(up,true); await process_frame
	check(app.hud.current=="select","a short tap on the same planet button selects it")
	app.on_action("planets")
	profile.unlocked=0; app.hud.planets(0,0); await process_frame
	check(find("planet_9").disabled,"locked final planet cannot be selected")
	profile.unlocked=9
	for i in 10:
		app.on_action("planets"); await click("planet_"+str(i))
		check(app.planet==i and app.state=="select","planet button opens correct world "+str(i))
	app.on_action("planets"); await click("select"); check(app.state=="select","planet list back button")
	await click("menu"); check(app.state=="menu","crew back button")
	await click("select"); await click("start"); check(app.state=="intro","start begins arrival")
	await click("skip"); check(app.state=="run","arrival skip starts race")
	var fire_button:Button=find("use_charge_jet");var energy_button:Button=find("use_charge_board")
	check(fire_button.position.x>=440. and energy_button.position.x>=440.,"boosters leave central swipe zone free")
	check(is_equal_approx(fire_button.position.y,658.) and is_equal_approx(energy_button.position.y,744.) and find("run_jump")==null,"boosters keep their positions without a jump button")
	app.distance=350.;app.lane=1;app.x=0.
	var start_pos:Vector2=app.hud.root.get_global_transform_with_canvas()*Vector2(280,875)
	var end_pos:Vector2=app.hud.root.get_global_transform_with_canvas()*Vector2(262,875)
	var touch:=InputEventScreenTouch.new();touch.index=0;touch.position=start_pos;touch.pressed=true;root.push_input(touch,true);await process_frame
	var drag:=InputEventScreenDrag.new();drag.index=0;drag.position=end_pos;drag.relative=end_pos-start_pos;root.push_input(drag,true);await process_frame
	check(app.lane==0 and is_equal_approx(app.runner.position.x,-2.6),"short left swipe changes lanes before release")
	touch=InputEventScreenTouch.new();touch.index=0;touch.position=end_pos;touch.pressed=false;root.push_input(touch,true);await process_frame
	check(app.lane==0,"bottom-center touch swipe reaches game without activating boosters")
	start_pos=app.hud.root.get_global_transform_with_canvas()*Vector2(402,875)
	end_pos=app.hud.root.get_global_transform_with_canvas()*Vector2(460,875)
	touch=InputEventScreenTouch.new();touch.index=0;touch.position=start_pos;touch.pressed=true;root.push_input(touch,true);await process_frame
	drag=InputEventScreenDrag.new();drag.index=0;drag.position=end_pos;drag.relative=end_pos-start_pos;root.push_input(drag,true);await process_frame
	check(app.lane==1 and is_zero_approx(app.runner.position.x),"right swipe stays active across the HUD")
	touch=InputEventScreenTouch.new();touch.index=0;touch.position=end_pos;touch.pressed=false;root.push_input(touch,true);await process_frame
	check(app.lane==1 and app.touch_id==-1,"release does not repeat an already consumed swipe")
	app.swipe(Vector2(0,-80)); check(app.vertical_speed>0,"an upwards swipe jumps during the run")
	var charges_before:int=profile.charge_count("jet")
	await click("use_charge_jet"); check(profile.charge_count("jet")==charges_before-1 and app.booster=="jet","fire button spends and activates one charge")
	check(app.hud.stock_labels.jet.text==str(charges_before-1) and app.hud.wallet_label.text=="Банк %d"%profile.bank,"top HUD reflects the hero's charge inventory and wallet")
	check(find("use_charge_board").disabled,"cannot stack a second boost")
	await click("pause"); check(app.state=="paused","HUD pause button")
	await click("settings"); await click("close_settings"); check(app.hud.current=="pause","settings returns to pause")
	await click("resume"); app._process(3.1); check(app.state=="run","resume countdown")
	await click("pause"); await click("restart"); check(app.state=="intro","pause restart begins a fresh arrival")
	await click("skip"); await click("pause"); await click("menu"); check(app.state=="menu","pause menu returns safely")
	app.planet=0; app.start_level(); app.begin_run(); app.distance=2100; app.spawn_and_update(); app.finish_level()
	profile.bank=25000; profile.owned_items.clear(); profile.outfits=[{},{}]
	for i in 3:
		app.finish_walk.avatar.position=preload("res://scripts/monument_shops.gd").POSITIONS[i]+Vector3(0,0,3)
		app._process(.016); await click("shop_nearest")
		var category:String=preload("res://scripts/gear_economy.gd").CATEGORIES[i]
		var id:String=app.selected_item; var before:int=profile.bank
		await click("purchase_item"); check(profile.owned_items.has(id) and profile.bank<before,"shop purchase: "+category)
		await click("wear_item"); check(profile.current_outfit().values().has(id),"equip owned purchase")
		await click("remove_item"); check(not profile.current_outfit().values().has(id),"remove without losing item")
		await click("wear_item"); await click("shop_mode_owned"); await click("shop_mode_local")
		if i==0:
			await click("shop_mode_galaxy");await click("preview_item_helmet_1");await click("shop_details");await click("shop_details");await click("fit_reset")
			await click("shop_cat_pack");await click("shop_cat_board");await click("shop_cat_suit")
			await click("shop_cat_boost"); await click("preview_item_board")
			var stock:int=profile.charge_count("board"); var wallet:int=profile.bank
			await click("buy_charge_board"); check(profile.charge_count("board")==stock+1 and profile.bank==wallet-20,"real shop click buys energy for its hero")
			await click("preview_item_heart");wallet=profile.bank;stock=profile.heart_count();await click("buy_heart");check(profile.heart_count()==stock+1 and profile.bank==wallet-profile.HEART_PRICE,"native shop click buys a reserve heart")
		await click("close_gear"); check(app.state=="explore","shop returns to plaza")
	check(find("walk_jump")==null,"plaza has no jump button")
	await click("pause"); await click("resume"); check(app.state=="explore","exploration resumes without race countdown")
	await click("leave_finish"); check(app.state=="outro","ship button starts departure")
	await click("skip"); check(app.state=="results","departure skip shows results")
	await click("next"); check(app.state=="flight","next planet starts flight")
	await click("pause"); await click("resume"); app._process(3.1); check(app.state=="flight","flight pause/resume")
	var pending_id:int=app.flight_id
	await click("pause"); await click("menu"); await click("continue_trip")
	check(app.state=="flight" and app.flight_id==pending_id,"conditional continue-flight button resumes the same trip")
	profile.flown_routes.append(app.flight.source); app.hud.flight_playing(true)
	await click("skip_flight"); check(app.state=="flight_result" and app.flight_reward==0,"flight skip has no unearned reward")
	await click("arrive"); check(app.state=="intro" and app.planet==1,"arrival starts the destination world")
	app.show_results(false); await click("restart"); check(app.state=="intro","failed result retry")
	app.show_results(false); await click("menu"); check(app.state=="menu","failed result menu")
	app.planet=preload("res://scripts/planets.gd").count()-1; app.show_results(true); check(find("next")==null,"last world has no out-of-range next planet")
	await click("restart"); check(app.state=="intro","final world retry")
	app.show_results(true); await click("menu"); check(app.state=="menu","final world menu")
	var file:=FileAccess.open("res://build/button-audit.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"visited":visited},"  ")); file.close()
	print("BUTTON AUDIT: %d checks, %d failures, %d controls exercised"%[checks,failures.size(),visited.size()])
	app.free(); await create_timer(.15).timeout; quit(0 if failures.is_empty() else 1)
