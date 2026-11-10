extends SceneTree
const Loops=preload("res://scripts/loop_routes.gd")
var failures:=0
var checks:=0
func _initialize() -> void:call_deferred("run")
func run() -> void:
	root.size=Vector2i(540,1188)
	var app=load("res://scenes/main.tscn").instantiate();app.test_mode=true;root.add_child(app)
	await process_frame;app.set_process(false);app.set_physics_process(false)
	var p=root.get_node("Profile");p.first_person=false;p.retry_points.clear();app.planet=10;app.reset_course();app.begin_run()
	var audit=preload("res://scripts/first_person_audit.gd").new();audit.app=app;app.add_child(audit);audit.set_process(false)
	for route:Dictionary in app.loop_routes.routes:
		var kind:String=route.kind;app.loop_routes.active=route;app.booster=route.booster
		var faces:PackedVector3Array=Loops.ribbon(kind,false).get_faces();var arcs:PackedFloat32Array=Loops.arcs(kind)
		for view:bool in [false,true]:
			p.first_person=view;audit.previous.clear();audit.report.collisions.clear()
			for index in range(1,159):
				app.loop_routes.travelled=arcs[index];app.simulate_loop(0.);app.update_camera()
				if view:audit.inspect(route.node,"loop_"+kind);continue
				var offset:=Vector3((route.lane-1)*2.6,0,app.distance-route.start)
				for h in [1.5,2.7]:
					var target:Vector3=app.runner.position+app.loop_pose.up*h;var blocked:=false
					for face in range(0,faces.size(),3):
						if Geometry3D.segment_intersects_triangle(app.camera.position,target,faces[face]+offset,faces[face+1]+offset,faces[face+2]+offset)!=null:blocked=true;break
					checks+=1
					if blocked:failures+=1;push_error("Mirror loop hides hero %s u%.3f"%[kind,index/160.])
			if view and not audit.report.collisions.is_empty():failures+=1;push_error("Mirror eye intersects road "+kind+str(audit.report.collisions))
		print("MIRROR CAMERA ",kind)
	print("MIRROR CAMERA: %d checks, %d failures"%[checks,failures])
	app.queue_free();await process_frame;await process_frame;quit(0 if failures==0 else 1)
