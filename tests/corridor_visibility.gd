extends SceneTree
const C=preload("res://scripts/course.gd")
const Guard=preload("res://scripts/runner_camera_guard.gd")
var checks:=0
var errors:Array[String]=[]
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; app.set_process(false); app.set_physics_process(false)
	for size_value in [Vector2i(540,960),Vector2i(540,1188)]:
		root.size=size_value; await process_frame
		for front in [false,true]:
			app.distance=890. if front else 660.
			for rel in range(-44,45,4):
				var e:=C.make_event(app.distance-rel,1,"tunnel"); app.events.assign([e])
				for hx in [-2.6,2.6]:
					for hy in [0.,1.4,2.8,4.8,7.2]:
						app.x=hx; app.height=hy; app.tunnel_active={}; app.tunnel_camera_blend=0.; app.passage_camera_blend=0.; app.update_camera(.016)
						var eye:=Vector3(hx,hy+1.65,0)
						checks+=1
						if not Guard.clear_view(eye,app.camera.position,Guard.shells(app.events,app.distance)): errors.append("occluded "+str([size_value,front,rel,hx,hy]))
						for y in [0.,2.97]:
							checks+=1
							if not Rect2(Vector2.ZERO,Vector2(size_value)).grow(-4).has_point(app.camera.unproject_position(Vector3(hx,hy+y,0))): errors.append("off-screen "+str([size_value,front,rel,hx,hy,y]))
	print("CORRIDOR VISIBILITY: %d checks, %d failures"%[checks,errors.size()])
	for error:String in errors.slice(0,8): push_error(error)
	app.free(); await process_frame; quit(0 if errors.is_empty() else 1)
