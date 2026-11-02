extends SceneTree
const Pilot=preload("res://tests/route_pilot.gd")
var app: Node
var failures:Array[String]=[]
var runs:Array=[]
func _initialize(): call_deferred("run")
func run():
	app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; app.set_process(false); app.set_physics_process(false)
	for planet in 4:
		app.planet=planet; app.reset_course(); app.begin_run()
		var captured:=0
		for frame in 16000:
			if app.state!="run": break
			var planned:=false
			for e in app.events:
				if e.kind!="tunnel" or e.get("entered",false): continue
				var gap:float=e.s-app.distance
				if gap<43 and gap>16:
					planned=true
					if app.lane!=1: app.move_screen(1 if app.lane<1 else -1)
					if gap<33 and not e.get("qa_jumped",false): app.vertical_gesture("up"); e.qa_jumped=true
					elif e.get("qa_jumped",false) and not app.flip_used and app.gesture_age>=0.12: app.vertical_gesture("up")
			if not planned and app.tunnel_active.is_empty(): Pilot.drive(app)
			app.simulate(1.0/60); app._process(1.0/60)
			if frame%120==0: await process_frame
		for e in app.events:
			if e.kind=="tunnel" and e.get("entered",false): captured+=1
		var mega:=0
		for pickup in app.pickups:
			if pickup.get("mega",false) and pickup.done: mega+=1
		var result={"planet":planet,"finished":app.state=="outro","lives":app.lives,"tunnels":captured,"mega":mega,"stars":app.stars}
		runs.append(result); print("BONUS ROUTE ",result)
		if app.state!="outro" or app.lives!=3 or captured!=2 or mega!=24: failures.append(str(result))
	var out=FileAccess.open("res://build/salvage-route-results.json",FileAccess.WRITE); out.store_string(JSON.stringify({"runs":runs,"failures":failures},"  ")); out.close()
	print("BONUS ROUTES: ",runs.size()," runs, ",failures.size()," failures")
	app.free(); await create_timer(0.15).timeout; quit(1 if not failures.is_empty() else 0)
