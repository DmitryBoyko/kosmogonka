extends SceneTree
const Course=preload("res://scripts/course.gd")
const Basement=preload("res://scripts/basement.gd")
var app:Node
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok: failures.append(message); push_error(message)
func isolate(planet:int=0,index:int=0) -> Dictionary:
	app.planet=planet; app.reset_course(); app.begin_run()
	for event in app.events+app.pickups:
		if is_instance_valid(event.node): event.node.free()
	var candidates:Array=Course.events(planet); var route:Dictionary={}; var found:=0
	for event:Dictionary in candidates:
		if event.kind=="basement":
			if found==index: route=event; break
			found+=1
	app.events.clear(); app.pickups.clear()
	for event:Dictionary in candidates:
		if event.encounter==route.encounter: app.events.append(event)
	for pickup:Dictionary in Course.stars(planet,app.events):
		if pickup.has("anchor") and pickup.anchor==route: app.pickups.append(pickup)
	app.scenery.clear(); app.scenery.configure_openings(app.events)
	app.distance=route.s-route.length*.5-3; app.lane=route.lane; app.x=(route.lane-1)*2.6; app.speed=17
	app.height=0; app.support=0; app.vertical_speed=0; app.basement_active={}
	return route
func run() -> void:
	check(Basement.glove_offset(-25.,25.)>2.5,"glove stays raised during approach warning")
	check(Basement.glove_offset(0.,25.)<.01,"downstroke reaches the visible contact position")
	check(not Basement.glove_hits(-20.,25.,Basement.FLOOR,2.97),"raised fist cannot cause invisible damage")
	check(Basement.glove_hits(0.,25.,Basement.FLOOR,1.45) and not Basement.glove_hits(0.,25.,Basement.FLOOR,.78),"contact geometry distinguishes crouch and back slide")
	check(Basement.glove_offset(20.,25.)>2.5,"piston recovers after player passes")
	app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; app.set_process(false); app.set_physics_process(false)
	for planet in 4:
		for index in 2:
			var route:=isolate(planet,index); var below:=false; var camera_below:=false; var feet_on_stairs:=true
			for frame in 400:
				for event:Dictionary in app.events:
					if event.kind=="glove" and event.s-app.distance<3 and event.s-app.distance>1.3 and app.roll_timer<=0:
						app.vertical_gesture("down"); app.vertical_gesture("down")
				app.simulate(1./60); app._process(1./60)
				var entry_along:float=app.distance-route.s+route.length*.5
				if entry_along>1 and entry_along<Basement.STAIRS:
					feet_on_stairs=feet_on_stairs and absf(app.height-Basement.floor_height(route,app.distance))<.02
				below=below or app.height< -4.7
				if absf(app.distance-route.s)<10: camera_below=camera_below or app.camera.position.y< -1
				if app.distance>route.s+route.length*.5+3: break
				if frame%120==0: await process_frame
			check(below and camera_below,"stairs descend below the opaque road with an interior camera")
			check(feet_on_stairs,"runner follows the descending stair treads without free-falling")
			check(app.height>=-.01 and app.basement_active.is_empty(),"exit stairs return to the road")
			check(app.lives==3 and app.stars>=30,"back slide clears both gloves and earns the rich star route: planet%d index%d lives%d stars%d"%[planet,index,app.lives,app.stars])
	var route:=isolate()
	for frame in 300:
		app.simulate(1./60)
		if app.distance>route.s: break
	check(app.lives<3,"standing runner is hit by the ceiling glove")
	route=isolate()
	for frame in 300:
		app.slide(); app.simulate(1./60)
		if app.distance>route.s: break
	check(app.lives<3,"ordinary crouch cannot replace lying on the back")
	route=isolate()
	for frame in 300:
		if app.height< -4.6: app.jump()
		app.simulate(1./60)
		if app.distance>route.s: break
	check(app.lives<3,"ceiling prevents jumping over the glove")
	route=isolate(); var begin:float=route.s-route.length*.5
	app.distance=begin-1; app.jump()
	var fell:=false
	for frame in 100:
		app.simulate(1./60); fell=fell or app.height<-.25
		if app.distance>begin+Basement.STAIRS+2: break
	check(not fell and app.basement_active.is_empty(),"one jump clears the entrance hole onto the surface roof")
	check(app.stars==0,"surface bypass cannot collect underground stars")
	app.distance=route.s+route.length*.5-Basement.STAIRS-1
	app.height=0; app.support=0; app.vertical_speed=0; app.jump(); fell=false
	for frame in 100:
		app.simulate(1./60); fell=fell or app.height<-.25
		if app.distance>route.s+route.length*.5+2: break
	check(not fell,"surface runner can jump the exit opening as well")
	# Test the actual slab generator: no ground, foundation or asphalt over the hole.
	var at_s:float=begin+6; var chunk:int=floori(at_s/30)
	for y in [-.55,-.15,.025]:
		var slabs:=Node3D.new()
		app.scenery.slab(slabs,chunk,Vector3(8.9,.05,30),Vector3(0,y,-15),"ffffff")
		var blocked:=false; var neighbor:=false
		for mesh:MeshInstance3D in slabs.get_children():
			var bounds:AABB=mesh.transform*mesh.mesh.get_aabb()
			blocked=blocked or bounds.has_point(Vector3(app.x,y,chunk*30-at_s))
			neighbor=neighbor or bounds.has_point(Vector3(app.x+(2.6 if app.lane<2 else -2.6),y,chunk*30-at_s))
		check(not blocked and neighbor,"hole removes a slab while the neighboring lane remains intact")
		slabs.free()
	var out:=FileAccess.open("res://build/basement-report.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"checks":checks,"failures":failures},"  ")); out.close()
	print("BASEMENT: %d checks, %d failures"%[checks,failures.size()])
	app.free(); await create_timer(.1).timeout; quit(0 if failures.is_empty() else 1)
