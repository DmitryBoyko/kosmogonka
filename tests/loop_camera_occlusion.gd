extends SceneTree
const Loops=preload("res://scripts/loop_routes.gd")
var failures:=0
var checks:=0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(540,1188)
	var app=load("res://scenes/main.tscn").instantiate();app.test_mode=true;root.add_child(app)
	await process_frame;app.set_process(false);app.set_physics_process(false)
	var profile=root.get_node("Profile");profile.charges["0"]={"jet":9,"board":9}
	for kind in ["jet","board"]:
		app.planet=2;app.reset_course();app.begin_run()
		var route:Dictionary=app.loop_routes.routes[0 if kind=="jet" else 1]
		app.distance=route.start-.2;app.lane=route.lane;app.x=(route.lane-1)*2.6;app.use_charge(kind);app.simulate(.016)
		var faces:PackedVector3Array=Loops.ribbon(kind,false).get_faces()
		var arcs:PackedFloat32Array=Loops.arcs(kind)
		for index in range(1,159):
			app.loop_routes.travelled=arcs[index];app.simulate_loop(0.);app.update_camera()
			var offset:=Vector3((route.lane-1)*2.6,0,app.distance-route.start)
			for h in [1.5,2.7]:
				var target:Vector3=app.runner.position+app.loop_pose.up*h
				var blocked:=false
				for face in range(0,faces.size(),3):
					if Geometry3D.segment_intersects_triangle(app.camera.position,target,faces[face]+offset,faces[face+1]+offset,faces[face+2]+offset)!=null:
						blocked=true;break
				checks+=1
				if blocked:
					failures+=1;push_error("Loop road hides hero: %s u=%.3f height=%.1f"%[kind,index/160.,h])
	print("LOOP CAMERA OCCLUSION: %d checks, %d failures"%[checks,failures])
	app.queue_free();await process_frame;await process_frame;quit(0 if failures==0 else 1)
