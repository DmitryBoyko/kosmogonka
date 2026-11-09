extends SceneTree
const C=preload("res://scripts/course.gd")
const B=preload("res://scripts/basement.gd")
var checks:=0
var errors:Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok:bool,label_value:String) -> void:
	checks+=1
	if not ok: errors.append(label_value); push_error(label_value)
func run() -> void:
	var app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; app.set_process(false); app.set_physics_process(false)
	var sound=app.sound; sound.enabled=true
	for key in ["glove_extend","purchase_confirm","loop_jet"]:
		var stream:AudioStream=sound.get_clip(key)
		check(stream!=null and stream.get_length()>.5,"distinct imported cue "+key)
	check(sound.loop_engine.bus=="Effects" and sound.loop_engine.stream.loop_end==48000 and sound.loop_engine.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD,"gap-free two-second loop on Effects bus")
	var p=root.get_node("Profile"); p.hero=0; p.owned_items.clear(); p.outfits=[{},{}]; p.bank=10000; p.unlocked=9
	app.planet=0; app.gear_context="explore"; app.shop_category="pack"; app.shop_mode="local"; app.selected_item="pack_world_0"; app.show_outfit_shop()
	app.on_action("purchase_item"); check(sound.last_sfx=="purchase_confirm","successful equipment purchase confirms")
	var serial:int=sound.sfx_serial; app.on_action("purchase_item"); check(sound.sfx_serial==serial,"duplicate rejected purchase stays silent")
	p.charges["0"]={"jet":0,"board":0}; app.on_action("buy_charge_board"); check(sound.last_sfx=="purchase_confirm" and p.charge_count("board")==1,"successful charge purchase confirms")
	p.bank=0; serial=sound.sfx_serial; app.on_action("buy_charge_board"); check(sound.sfx_serial==serial,"insufficient funds do not play success")
	app.reset_course(); app.begin_run(); app.events.assign([C.make_event(610.,1,"glove")]); app.pickups.clear(); app.distance=601.5; app.height=B.FLOOR; app.speed=17.; app.lane=1; app.x=0.
	app.spawn_and_update(); check(sound.last_sfx=="glove_extend","piston cue starts with physical downstroke")
	serial=sound.sfx_serial; app.spawn_and_update(); check(sound.sfx_serial==serial,"piston sound fires once per attack")
	app.reset_course(); app.begin_run(); app.distance=399.8; app.x=-2.6; app.lane=0; app.height=0.; p.charges["0"]={"jet":2,"board":2}
	app.use_charge("jet"); app.simulate(.016)
	check(sound.loop_engine.playing and sound.loop_engine.get_meta("active",false),"entering loop starts dedicated jet sound")
	app.pause_game(); check(sound.loop_engine.stream_paused,"pause freezes jet sound")
	app.on_action("resume"); app._process(3.1); check(not sound.loop_engine.stream_paused,"resume restores jet sound")
	app.start_level(); check(not sound.loop_engine.playing and not sound.loop_engine.get_meta("active",true),"restart stops the previous loop sound")
	app.begin_run(); app.distance=399.8; app.x=-2.6; app.lane=0; app.height=0.; app.use_charge("jet"); app.simulate(.016)
	app.show_menu(); check(not sound.loop_engine.playing and not sound.loop_engine.get_meta("active",true),"leaving stops jet sound")
	print("ACTION AUDIO: %d checks, %d failures"%[checks,errors.size()])
	app.queue_free(); await process_frame; await process_frame
	await create_timer(.25).timeout; quit(0 if errors.is_empty() else 1)
