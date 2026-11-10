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
var region_samples:Dictionary={}
var coverage:Dictionary={}
var vehicle_evidence:Dictionary={"moving_frames":0,"flash_on_frames":0,"flash_off_frames":0,"min_speed":0.,"kinds":{}}
var camera_audit:Node
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
	if key=="run":
		var region:String="front_camera" if app.first_person_mix()<=0. and app.get_tree().root.get_node("Profile").first_person else "view_transition" if app.first_person_mix()<.999 else "loop_"+app.loop_routes.active.kind if not app.loop_routes.active.is_empty() else "basement" if app.height<-.5 else "elevated" if not app.tunnel_active.is_empty() else "road"
		if app.distance>865. and app.distance<945. and not app.runner.first_person:coverage["front_camera"]={"seen":true}
		if app.distance>995. and app.runner.first_person:coverage["fp_restored"]={"seen":true}
		if not region_samples.has(region):region_samples[region]=[]
		if region_samples[region].size()<18000:region_samples[region].append(ms)
		for event:Dictionary in app.events:
			if event.kind=="glove" and event.get("cleared",false):coverage[str(event.origin)]={"kind":"glove","cleared":true}
			if event.kind in ["truck","traffic","broken"] and is_instance_valid(event.node) and app.distance-event.s< -5. and app.distance-event.s> -110.:
				var model:Node3D=event.node.get_child(0) if event.kind=="traffic" else event.node
				var cabin:Node3D=model.get_meta("cabin",null)
				if event.speed< -1.:vehicle_evidence.moving_frames+=1;vehicle_evidence.min_speed=minf(vehicle_evidence.min_speed,event.speed);vehicle_evidence.kinds[event.kind]=true
				if cabin:
					if cabin.led.get_shader_parameter("power")>1.:vehicle_evidence.flash_on_frames+=1
					else:vehicle_evidence.flash_off_frames+=1
		for route:Dictionary in app.loop_routes.routes:
			if route.taken:coverage[route.kind]={"kind":route.kind,"completed":app.distance>=route.start+54.9,"rewards":route.rewards.filter(func(r):return r.done).size()}
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
	result["regions"]={}
	for region:String in region_samples:
		var values:Array=region_samples[region].duplicate();values.sort();var total:=0.
		for v:float in values:total+=v
		result.regions[region]={"frames":values.size(),"fps":1000.*values.size()/maxf(1.,total),"p95_ms":values[int((values.size()-1)*.95)],"p99_ms":values[int((values.size()-1)*.99)],"max_ms":values[-1]}
	result["coverage"]=coverage
	result["vehicle_evidence"]=vehicle_evidence
	result["camera_audit"]=camera_audit.report if is_instance_valid(camera_audit) else {}
	var file:=FileAccess.open(OUTPUT,FileAccess.WRITE); file.store_string(JSON.stringify(result)); file.close()
func execute_and_ack(command:Dictionary) -> void:
	await execute(command)
	completed_command=int(command.id)
func execute(command:Dictionary) -> void:
	var action:String=command.get("action","")
	match action:
		"campaign_run":
			var profile=get_tree().root.get_node("Profile");profile.first_person=true
			var tier:=preload("res://scripts/gear_economy.gd").recommended(int(command.get("planet",0)))
			var outfit:=preload("res://scripts/outfit_catalog.gd").legacy({"suit":tier,"pack":tier,"board":tier})
			profile.outfits[profile.hero]=outfit
			for id:String in outfit.values():
				if not profile.owned_items.has(id):profile.owned_items.append(id)
			app.set_meta("qa_take_loops",true)
			await execute({"action":"run","planet":command.get("planet",0)})
			region_samples.clear();samples.clear();coverage.clear();transitions.clear()
			vehicle_evidence={"moving_frames":0,"flash_on_frames":0,"flash_off_frames":0,"min_speed":0.,"kinds":{}}
		"audit":
			if is_instance_valid(camera_audit):camera_audit.queue_free();camera_audit=null
			if command.get("enabled",true):
				camera_audit=preload("res://scripts/first_person_audit.gd").new();camera_audit.app=app;add_child(camera_audit)
		"feature":
			await execute({"action":"run","planet":int(command.get("planet",0))})
			pilot=false
			var kind:String=command.get("kind","truck")
			if kind in ["jet_loop","board_loop","spiral_loop"]:
				var booster_kind:=kind.trim_suffix("_loop")
				for route:Dictionary in app.loop_routes.routes:
					if route.kind!=booster_kind: continue
					app.distance=route.start-35.; app.lane=route.lane; app.x=(app.lane-1)*2.6
					var profile=get_tree().root.get_node("Profile")
					if profile.charge_count(route.booster)==0: profile.change_charge(route.booster,1)
				pilot=bool(command.get("pilot",false))
			else:
				var matching_index:=0
				for event:Dictionary in app.events:
					if event.kind!=kind: continue
					if matching_index<int(command.get("index",0)):matching_index+=1;continue
					app.distance=event.origin-(event.length*.5+6. if kind=="basement" else 22. if kind=="glove" else 65.); app.lane=event.lane; app.x=(app.lane-1)*2.6
					if kind=="glove": app.height=preload("res://scripts/basement.gd").FLOOR; app.support=app.height; app.basement_active=event.anchor
					if kind=="tunnel":app.distance=event.origin-25.;app.height=3.35;app.support=0.;app.flip_used=true
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
			app.planet=clampi(int(command.get("planet",0)),0,preload("res://scripts/planets.gd").count()-1); await app.prepare_planet_resources(app.planet); await app.start_level(); await app.begin_run(); pilot=true
		"flight": await app.start_flight(clampi(int(command.get("source",0)),0,8)); auto_flight=true
		"plaza":
			app.planet=clampi(int(command.get("planet",0)),0,preload("res://scripts/planets.gd").count()-1); await app.prepare_planet_resources(app.planet); await app.start_level(); await app.begin_run(); app.distance=preload("res://scripts/course.gd").length_for(app.planet); app.spawn_and_update(); app.finish_level()
		"approach_shop":
			if app.state=="explore": app.finish_walk.avatar.position=preload("res://scripts/monument_shops.gd").POSITIONS[clampi(int(command.get("index",0)),0,2)]+Vector3(0,0,3)
		"action": await app.on_action(str(command.get("command","")))
