extends Node
## Debug APK only, activated by an explicit local QA marker. No normal-game overhead.
const MARKER="user://mobile_probe.json"
const COMMAND="user://mobile_command.json"
const OUTPUT="user://mobile_metrics.json"
var app:Node
var pilot:bool=false
var auto_flight:bool=false
var last_command:=-1
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
			last_command=int(command.get("id",0)); execute(command)
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
	var profile=get_tree().root.get_node("Profile")
	result["owned_items"]=profile.owned_items
	result["outfits"]=profile.outfits
	result["shop_mode"]=app.shop_mode
	result["selected_item"]=app.selected_item
	var file:=FileAccess.open(OUTPUT,FileAccess.WRITE); file.store_string(JSON.stringify(result)); file.close()
func execute(command:Dictionary) -> void:
	var action:String=command.get("action","")
	match action:
		"pilot": pilot=bool(command.get("enabled",true))
		"flight_pilot": auto_flight=bool(command.get("enabled",true))
		"reset_metrics": samples.clear(); transitions.clear()
		"run":
			app.planet=clampi(int(command.get("planet",0)),0,9); app.start_level(); app.begin_run(); pilot=true
		"flight": app.start_flight(clampi(int(command.get("source",0)),0,8)); auto_flight=true
		"plaza":
			app.planet=clampi(int(command.get("planet",0)),0,9); app.start_level(); app.begin_run(); app.distance=2100.; app.spawn_and_update(); app.finish_level()
		"approach_shop":
			if app.state=="explore": app.finish_walk.avatar.position=preload("res://scripts/monument_shops.gd").POSITIONS[clampi(int(command.get("index",0)),0,2)]+Vector3(0,0,3)
		"action": app.on_action(str(command.get("command","")))
