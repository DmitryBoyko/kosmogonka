extends SceneTree
const Catalog=preload("res://scripts/outfit_catalog.gd")
var app:Node
var checks:=0
var errors:Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok:bool,label_value:String) -> void:
	checks+=1
	if not ok: errors.append(label_value);push_error(label_value)
func shot(name_value:String) -> void:
	if DisplayServer.get_name()=="headless": return
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/update-"+name_value+".png")
func tap_version() -> void:
	var at:Vector2=app.hud.version_button.get_global_rect().get_center()
	var event:=InputEventMouseButton.new();event.position=at;event.global_position=at;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true;root.push_input(event,true)
	await process_frame
	event=InputEventMouseButton.new();event.position=at;event.global_position=at;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=false;root.push_input(event,true);await process_frame
func clean(world:int=0) -> void:
	app.planet=world;app.reset_course();app.begin_run()
	for preview:Node3D in app.previews:preview.hide()
func native_down() -> void:
	var press:=InputEventScreenTouch.new();press.index=0;press.position=Vector2(270,400);press.pressed=true;app._unhandled_input(press)
	var drag:=InputEventScreenDrag.new();drag.index=0;drag.position=Vector2(270,650);app._unhandled_input(drag)
	var release:=InputEventScreenTouch.new();release.index=0;release.position=drag.position;release.pressed=false;app._unhandled_input(release)
func run() -> void:
	root.size=Vector2i(540,960)
	app=load("res://scenes/main.tscn").instantiate();app.test_mode=true;root.add_child(app)
	await process_frame;app.set_process(false);app.set_physics_process(false)
	var p=root.get_node("Profile");p.hero=0;p.wallets={"0":100,"1":77};p.unlocked=0
	app.on_action("settings");check(app.hud.version_button.text.contains(str(ProjectSettings.get_setting("application/config/version"))),"version shown in settings")
	check(app.hud.version_button is Label and app.hud.version_button.focus_mode==Control.FOCUS_NONE and app.hud.version_button.mouse_default_cursor_shape==Control.CURSOR_ARROW,"version is static-looking text without button feedback")
	for i in 6:await tap_version()
	check(p.bank==100 and p.unlocked==0,"six taps do not unlock or grant")
	await tap_version();check(p.bank==1000100 and p.unlocked==9,"seven native clicks unlock ten worlds and add a million")
	await tap_version();check(p.bank==1000100,"eighth click starts a fresh sequence")
	p.hero=1;check(p.bank==77,"other hero wallet untouched");p.hero=0
	app.version_last_tap=0
	for i in 7:await tap_version()
	check(p.bank==2000100,"a fresh seven-tap sequence can be repeated")
	await shot("version")
	app.on_action("close_settings")
	p.outfits=[Catalog.legacy({"suit":5,"pack":5,"board":5}),{}]
	clean();app.events.clear();app.pickups.clear();app.distance=610.;app.height=3.2;app.support=0.;app.activate_booster("jet")
	app.vertical_gesture("down")
	check(app.booster.is_empty() and app.forced_landing and app.lives==3,"down switches off jet; damage waits until landing")
	check(not app.use_charge("jet"),"cannot cancel the forced descent with another boost")
	for i in 120:app.simulate(1./60.)
	check(app.lives==2 and not app.forced_landing and app.height==0.,"forced jet landing loses exactly one heart")
	for i in 60:app.simulate(1./60.)
	check(app.lives==2,"landing damage is not repeated")
	clean();app.events.clear();app.pickups.clear();app.distance=610.;app.height=3.2;app.activate_booster("jet");app.booster_timer=.001
	for i in 120:app.simulate(1./60.)
	check(app.lives==3 and app.height==0.,"ordinary boost expiry still lands harmlessly")
	root.size=Vector2i(540,1188);await process_frame
	for kind in ["jet","board"]:
		clean(2);p.charges["0"]={"jet":3,"board":3}
		var route:Dictionary=app.loop_routes.routes[0 if kind=="jet" else 1]
		app.distance=route.start-.2;app.lane=route.lane;app.x=(route.lane-1)*2.6;app.height=0.;app.use_charge(kind);app.simulate(.016)
		for i in 90:app.simulate(1./60.);app._process(1./60.)
		check(app.runner.jet_fx.power>1.5 and app.runner.jet_fx.jets[0].scale.y>1.5,"loop has larger, stronger fire "+kind)
		check(app.loop_trail.live_count>0 and app.loop_trail.live_count<=48,"bounded loop trail "+kind)
		check(app.loop_trail.particles.any(func(item):return item.star and item.age<item.life),"five-point stars are in the trail "+kind)
		await shot("loop-"+kind)
		p.reduced_motion=true;app._process(.016);check(app.loop_trail.live_count==0,"reduced motion suppresses particles");p.reduced_motion=false
		native_down()
		check(app.touch_id==-1 and not app.touch_active,"fatal swipe releases its pointer before the next run "+kind)
		check(app.state=="loop_fall" and app.lives==0 and app.booster.is_empty(),"down on loop is fatal despite full equipment "+kind)
		check(not app.sound.loop_engine.get_meta("active",true),"fall cuts the loop jet sound")
		app._process(.016);await shot("loop-fall-"+kind)
		app.pause_game();var t:float=app.loop_fall_time;app._physics_process(.5);check(app.loop_fall_time==t,"pause freezes fatal fall")
		app.resume_game();check(app.state=="loop_fall","fatal fall resumes correctly")
		app._physics_process(1.2);check(app.state=="results" and not app.success_result,"fatal loop fall opens retry screen")
		app.on_action("restart");check(app.planet==2 and app.state=="intro" and app.distance==0. and app.lives==3,"retry restarts the same planet")
	clean();app.distance=2100.;app.spawn_and_update();app.finish_level()
	var old_count:int=app.sound.action_counts.get("firework_burst",0)
	for i in 7:app._process(.5)
	check(app.victory_fx.celebrating and app.victory_fx.next_salvo==4,"victory has four staggered salvos")
	check(app.victory_fx.live_count>0 and app.victory_fx.live_count<=192,"fireworks use fixed particle budget")
	check(app.sound.action_counts.get("firework_burst",0)==old_count+4,"each salvo has its own sound")
	await shot("victory")
	app.pause_game();var victory_age:float=app.victory_fx.age;app._process(.5);check(app.victory_fx.age==victory_age,"pause freezes fireworks")
	app.resume_game();app._process(2.);check(not app.victory_fx.celebrating,"celebration finishes without blocking exploration")
	print("CONTROLS / LOOP FX / VICTORY: %d checks, %d failures"%[checks,errors.size()])
	app.queue_free();await process_frame;await process_frame;await create_timer(.15).timeout;quit(0 if errors.is_empty() else 1)
