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
	await click("select"); await click("girl"); check(profile.hero==1,"girl selection")
	await click("boy"); check(profile.hero==0,"boy selection")
	await click("builder"); check(app.state=="builder","constructor opens")
	for slot in preload("res://scripts/suit.gd").SLOTS:
		await click("slot_"+slot); await click("skin_explorer_mint")
		check(app.state=="builder","material returns to constructor: "+slot)
	await click("close_gear"); check(app.state=="select","constructor closes")
	await click("planets"); check(app.hud.current=="planets","planet list opens")
	var count:=0
	for node:Node in app.hud.screen.find_children("*","Button",true,false):
		if str(node.get_meta("command","")).begins_with("planet_"): count+=1
	check(count==10,"all ten planet buttons exist in scroll list")
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
	await click("pause"); check(app.state=="paused","HUD pause button")
	await click("settings"); await click("close_settings"); check(app.hud.current=="pause","settings returns to pause")
	await click("resume"); app._process(3.1); check(app.state=="run","resume countdown")
	await click("pause"); await click("restart"); check(app.state=="intro","pause restart begins a fresh arrival")
	await click("skip"); await click("pause"); await click("menu"); check(app.state=="menu","pause menu returns safely")
	app.planet=0; app.start_level(); app.begin_run(); app.distance=2100; app.spawn_and_update(); app.finish_level()
	profile.bank=5000; profile.gear_owned=preload("res://scripts/gear_economy.gd").normalized({})
	for i in 3:
		app.finish_walk.avatar.position=preload("res://scripts/monument_shops.gd").POSITIONS[i]+Vector3(0,0,3)
		app._process(.016); await click("shop_nearest")
		var category:String=preload("res://scripts/gear_economy.gd").CATEGORIES[i]
		await click("buy_"+category+"_1"); check(profile.gear_owned[category]==1,"shop purchase: "+category)
		await click("builder"); await click("close_gear"); check(app.state=="explore","shop constructor returns to plaza")
	await click("walk_jump"); check(app.finish_walk.jump_pending,"exploration jump button")
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
	app.planet=9; app.show_results(true); check(find("next")==null,"last world has no invalid eleventh planet")
	await click("restart"); check(app.state=="intro","final world retry")
	app.show_results(true); await click("menu"); check(app.state=="menu","final world menu")
	var file:=FileAccess.open("res://build/button-audit.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"visited":visited},"  ")); file.close()
	print("BUTTON AUDIT: %d checks, %d failures, %d controls exercised"%[checks,failures.size(),visited.size()])
	app.free(); await create_timer(.15).timeout; quit(0 if failures.is_empty() else 1)
