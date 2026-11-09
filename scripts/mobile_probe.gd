extends Node
## Debug APK only, activated by an explicit local QA marker. No normal-game overhead.
const MARKER="user://mobile_probe.json"
const COMMAND="user://mobile_command.json"
const OUTPUT="user://mobile_metrics.json"
var app:Node
var pilot:bool=false
var auto_flight:bool=false
var last_command:=-1
var completed_command:=-1
var last_tick:=0
var wait:=0.
var samples:Dictionary={}
var transitions:Array=[]
func _ready() -> void:
	process_physics_priority=-100
	last_tick=Time.get_ticks_usec()
func _physics_process(_dt:float) -> void:
	if pilot and app.state=="run": preload("res://scripts/qa_route_driver.gd").drive(app)
	if auto_flight and app.state=="flight":
		for charge in app.flight.rings:
			if not charge.taken and charge.s>app.flight.distance:
				app.flight.steer(signi(int(charge.lane)-app.flight.lane)); break
func _process(dt:float) -> void:
	var now:=Time.get_ticks_usec(); var ms:float=(now-last_tick)/1000.; last_tick=now
	var key:String=app.state
	if not samples.has(key): samples[key]={"ms":[],"draws":[],"primitives":[]}; transitions.append(key)
	var group:Dictionary=samples[key]
	if group.ms.size()<18000:
		group.ms.append(ms); group.draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)); group.primitives.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	wait-=dt
	if wait>0: return
	wait=1.
	if FileAccess.file_exists(COMMAND):
		var command=JSON.parse_string(FileAccess.get_file_as_string(COMMAND))
		if command is Dictionary and int(command.get("id",0))!=last_command:
			last_command=int(command.get("id",0)); execute_and_ack(command)
	var states:Dictionary={}
	for state:String in samples:
		var bucket:Dictionary=samples[state]; var values:Array=bucket.ms.duplicate(); values.sort()
		var sum:float=0.; var slow:=0
		for value:float in values: sum+=value; slow+=int(value>25.)
		states[state]={"frames":values.size(),"fps":1000.*values.size()/maxf(1.,sum),"p50_ms":values[int((values.size()-1)*.5)],"p95_ms":values[int((values.size()-1)*.95)],"p99_ms":values[int((values.size()-1)*.99)],"over_25ms":slow,"max_ms":values[-1],"draws":bucket.draws[-1],"primitives":bucket.primitives[-1]}
	var buttons:Array=[]
	for button:Button in app.hud.root.find_children("*","Button",true,false):
		if not button.is_visible_in_tree(): continue
		var rect:=button.get_global_rect()
		buttons.append({"command":button.get_meta("command",""),"text":button.text,"disabled":button.disabled,"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y]})
	var result:Dictionary={"state":app.state,"screen":app.hud.current,"planet":app.planet,"distance":app.distance,"stars":app.stars,"bank":get_tree().root.get_node("Profile").bank,"gear":get_tree().root.get_node("Profile").gear_owned,"states":states,"transitions":transitions,"buttons":buttons,"ui_size":[app.hud.root.size.x,app.hud.root.size.y],"world_size":[app.get_viewport().size.x,app.get_viewport().size.y],"command":last_command}
	result["cpu_process_ms"]=Performance.get_monitor(Performance.TIME_PROCESS)*1000.
	result["cpu_physics_ms"]=Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.
	result["sections"]=app.perf_sections
	result["command"]=completed_command
	result["transition_costs"]=app.transition_costs
	result["gpu_jobs"]=app.gpu_warm_queue.jobs.size() if is_instance_valid(app.gpu_warm_queue) else 0
	var profile=get_tree().root.get_node("Profile")
	result["owned_items"]=profile.owned_items
	result["outfits"]=profile.outfits
	result["hero"]=profile.hero
	result["first_person"]=profile.first_person
	result["plaza_first_person"]=app.finish_walk.zoom>=1.999 if is_instance_valid(app.finish_walk) else false
	result["hero_first_person"]=app.runner.first_person
	result["camera_height"]=app.camera.position.y
	result["plaza_position"]=[app.finish_walk.avatar.position.x,app.finish_walk.avatar.position.y,app.finish_walk.avatar.position.z] if is_instance_valid(app.finish_walk) else []
	result["wallets"]=profile.wallets
	result["inventories"]=profile.inventories
	result["plaza_zoom"]=app.finish_walk.zoom if is_instance_valid(app.finish_walk) else 1.
	result["shop_mode"]=app.shop_mode
	result["selected_item"]=app.selected_item
	result["height"]=app.height
	result["lives"]=app.lives
	result["unlocked"]=profile.unlocked
	result["forced_landing"]=app.forced_landing
	result["loop_particles"]=app.loop_trail.live_count
	result["firework_particles"]=app.victory_fx.live_count
	result["booster"]=app.booster
	result["loop_kind"]=app.loop_routes.active.get("kind","") if is_instance_valid(app.loop_routes) else ""
	result["action_audio"]={"counts":app.sound.action_counts,"jet_playing":app.sound.loop_engine.playing,"jet_active":app.sound.loop_engine.get_meta("active",false),"last_sfx":app.sound.last_sfx}
	var file:=FileAccess.open(OUTPUT,FileAccess.WRITE); file.store_string(JSON.stringify(result)); file.close()
func execute_and_ack(command:Dictionary) -> void:
	await execute(command)
	completed_command=int(command.id)
func execute(command:Dictionary) -> void:
	var action:String=command.get("action","")
	match action:
		"feature":
			await execute({"action":"run","planet":int(command.get("planet",0))})
			pilot=false
			var kind:String=command.get("kind","truck")
			if kind in ["jet_loop","board_loop"]:
				var booster_kind:=kind.trim_suffix("_loop")
				for route:Dictionary in app.loop_routes.routes:
					if route.kind!=booster_kind: continue
					app.distance=route.start-35.; app.lane=route.lane; app.x=(app.lane-1)*2.6
					var profile=get_tree().root.get_node("Profile")
					if profile.charge_count(booster_kind)==0: profile.change_charge(booster_kind,1)
			else:
				for event:Dictionary in app.events:
					if event.kind!=kind: continue
					app.distance=event.origin-(22. if kind=="glove" else 65.); app.lane=event.lane; app.x=(app.lane-1)*2.6
					if kind=="glove": app.height=preload("res://scripts/basement.gd").FLOOR; app.support=app.height; app.basement_active=event.anchor
					pilot=true; break
			for event:Dictionary in app.events: preload("res://scripts/course.gd").advance_event(event,app.distance,app.speed,app.planet,0.)
			app.runner.position=Vector3(app.x,app.height,0); app.spawn_and_update()
		"credit":
			var profile=get_tree().root.get_node("Profile")
			profile.credit(int(command.get("amount",5000)),int(command.get("hero",profile.hero))); profile.save()
		"pinch":
			if app.state=="explore":
				for i in 2:
					var touch:=InputEventScreenTouch.new(); touch.index=i; touch.position=Vector2(180+i*120,400); touch.pressed=true; app._unhandled_input(touch)
				var drag:=InputEventScreenDrag.new(); drag.index=1; drag.position=Vector2(180+120*float(command.get("factor",2.)),400); app._unhandled_input(drag)
				for i in 2:
					var touch:=InputEventScreenTouch.new(); touch.index=i; touch.pressed=false; app._unhandled_input(touch)
		"pilot": pilot=bool(command.get("enabled",true))
		"flight_pilot": auto_flight=bool(command.get("enabled",true))
		"reset_metrics": samples.clear(); transitions.clear()
		"run":
			app.planet=clampi(int(command.get("planet",0)),0,9); await app.prepare_planet_resources(app.planet); await app.start_level(); await app.begin_run(); pilot=true
		"flight": await app.start_flight(clampi(int(command.get("source",0)),0,8)); auto_flight=true
		"plaza":
			app.planet=clampi(int(command.get("planet",0)),0,9); await app.prepare_planet_resources(app.planet); await app.start_level(); await app.begin_run(); app.distance=2100.; app.spawn_and_update(); app.finish_level()
		"approach_shop":
			if app.state=="explore": app.finish_walk.avatar.position=preload("res://scripts/monument_shops.gd").POSITIONS[clampi(int(command.get("index",0)),0,2)]+Vector3(0,0,3)
		"action": await app.on_action(str(command.get("command","")))
