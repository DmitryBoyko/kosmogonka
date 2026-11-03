extends SceneTree
const Course=preload("res://scripts/course.gd")
const Pilot=preload("res://tests/route_pilot.gd")
var app:Node
var checks:=0
var failures:Array[String]=[]
var runs:Array=[]
func _initialize() -> void: call_deferred("run")
func check(ok:bool,label_value:String) -> void:
	checks+=1
	if not ok: failures.append(label_value); push_error(label_value)
func isolate(seed_value:int,planet:int,kind:String,index:int=0) -> Dictionary:
	app.planet=planet; app.reset_course(); app.begin_run()
	for e in app.events+app.pickups:
		if is_instance_valid(e.node): e.node.free()
	app.events.clear(); app.pickups.clear()
	Course.layout_seed=seed_value
	var candidates: Array[Dictionary]=Course.events(planet)
	var target:Dictionary={}; var count:=0
	for e in candidates:
		if e.kind==kind:
			if count==index: target=e; break
			count+=1
	for e in candidates:
		if e.encounter==target.encounter: app.events.append(e)
	for p in Course.stars(planet,app.events):
		if p.has("anchor") and p.anchor.get("encounter",-1)==target.encounter: app.pickups.append(p)
	app.distance=target.s-target.length*.5-15; app.lane=target.lane; app.x=(target.lane-1)*2.6
	app.speed=18.5
	return target
func run() -> void:
	root.size=Vector2i(540,960)
	app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; app.set_process(false); app.set_physics_process(false)
	var floors:Dictionary={}; var bonuses:Dictionary={}; var heights:Dictionary={}
	for seed_value in 40:
		Course.layout_seed=seed_value
		for planet in 4:
			for packet in Course.encounters(planet):
				if packet.pattern=="stairs": floors[packet.floors]=true; heights[packet.lower]=true
				if packet.pattern=="passage": bonuses[packet.bonus]=true
	check(floors.size()==3 and heights.size()==2,"random plans cover one to three floors and both platform heights")
	check(bonuses.size()==5,"tunnel rewards include doubled, regular and absent variants")
	for seed_value in 8:
		root.get_node("Profile").hero=seed_value%2
		for planet in 4:
			for index in 2:
				var stair:=isolate(seed_value,planet,"stairs",index)
				var exit:Dictionary=app.events.back()
				var roof_seen:=false
				for frame in 700:
					Pilot.drive(app); app.simulate(1./60)
					roof_seen=roof_seen or (not app.support_event.is_empty() and app.support_event.kind=="skycarrier")
					if app.distance>exit.s+exit.length*.5+5: break
					if frame%180==0: await process_frame
				var ok:bool=app.lives==3 and roof_seen and app.distance>exit.s+exit.length*.5
				check(ok,"balanced stair route seed%d planet%d index%d lives%d roof%s"%[seed_value,planet,index,app.lives,roof_seen])
				runs.append({"seed":seed_value,"planet":planet,"index":index,"floors":stair.floors,"lower":stair.lower,"lives":app.lives,"roof":roof_seen})
	for bonus in [0,1,4]:
		var passage:=isolate(0,0,"passage"); passage.bonus=bonus; app.pickups.clear()
		for offset in [-4.,0.,4.]:
			if bonus>0: Course.add_star(app.pickups,passage.s+offset,passage.lane,1,2 if bonus==4 else 1,passage,"passage")
		for frame in 240:
			app.simulate(1./60); app._process(1./60)
			if absf(app.distance-passage.s)<3:
				check(app.camera.position.y<3.2,"camera remains below tunnel roof")
			if app.distance>passage.s+passage.length*.5+2: break
		check(app.lives==3 and app.stars==(6 if bonus==4 else 3 if bonus==1 else 0),"running through tunnel keeps health and collects the actual reward")
	var passage:=isolate(0,0,"passage")
	app.distance=passage.s-passage.length*.5-12; app.vertical_gesture("up")
	for i in 8: app.simulate(1./60)
	app.vertical_gesture("up")
	var roof_seen:=false
	for frame in 220:
		app.simulate(1./60)
		roof_seen=roof_seen or (not app.support_event.is_empty() and app.support_event.kind=="passage")
		if app.distance>passage.s+passage.length*.5+3: break
	check(app.lives==3 and roof_seen,"double jump clears the entrance and lands safely on tunnel roof")
	for entry in [.05,.3,.6,1.3,1.6]:
		var stair_jump:=isolate(0,0,"stairs")
		app.distance=stair_jump.s+stair_jump.length*.5-entry
		app.height=Course.step_height(stair_jump,app.distance-stair_jump.s); app.support=app.height; app.vertical_speed=0
		app.speed=22.2; app.activate_booster("board"); app.jump()
		for frame in 4: app.simulate(1./60)
		check(app.vertical_speed>7,"fast jump is not cancelled by next stair lip: "+str(entry))
	var stair:=isolate(0,0,"stairs")
	app.distance=stair.s+stair.length*.5-1; app.height=stair.top; app.support=stair.top; app.vertical_speed=0
	app.simulate(1./60); app.jump(); app.move_screen(1 if app.lane<2 else -1)
	for frame in 180: app.simulate(1./60)
	check(app.lives==2,"deliberate jump from a high staircase to road costs one life")
	var out:=FileAccess.open("res://build/course-features-report.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"checks":checks,"failures":failures,"runs":runs},"  ")); out.close()
	print("COURSE FEATURES: %d checks, %d failures, %d seeded routes"%[checks,failures.size(),runs.size()])
	app.free(); await create_timer(.15).timeout; quit(0 if failures.is_empty() else 1)
