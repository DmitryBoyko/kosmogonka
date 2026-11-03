extends SceneTree
var app: Node
var checks:=0
var failures: Array[String]=[]

func _initialize() -> void: call_deferred("run")
func check(ok: bool, name_value: String) -> void:
	checks+=1
	if not ok: failures.append(name_value); push_error(name_value)
func step(n: int) -> void:
	for i in n:
		app.simulate(1.0/60)
		app._process(1.0/60)
func touch(pressed: bool, at: Vector2) -> void:
	var e:=InputEventScreenTouch.new()
	e.index=0
	e.pressed=pressed
	e.position=at
	app._unhandled_input(e)
func drag(at: Vector2) -> void:
	var e:=InputEventScreenDrag.new()
	e.index=0
	e.position=at
	app._unhandled_input(e)

func run() -> void:
	root.size=Vector2i(540,1200 if OS.get_cmdline_user_args().has("--tall") else 960)
	app=load("res://scenes/main.tscn").instantiate()
	app.test_mode=true
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app.set_physics_process(false)
	app.planet=0
	app.start_level()
	app.begin_run()
	touch(true,Vector2(270,700))
	drag(Vector2(270,620))
	step(8)
	drag(Vector2(270,450))
	check(not app.flip_used,"one long touch cannot double jump")
	touch(false,Vector2(270,450))
	touch(true,Vector2(270,700))
	drag(Vector2(270,610))
	touch(false,Vector2(270,610))
	check(app.flip_used,"two independent native swipes trigger flip")
	step(120)
	app.clear_gesture()
	app.vertical_gesture("up")
	step(30)
	app.vertical_gesture("up")
	check(not app.flip_used,"late second gesture does not upgrade")
	step(50)
	app.vertical_gesture("up")
	step(8)
	app.vertical_gesture("down")
	app.vertical_gesture("up")
	check(not app.flip_used,"mixed directions break pair")
	app.reset_course()
	app.begin_run()
	app.vertical_gesture("down")
	step(6)
	app.vertical_gesture("down")
	app.events.clear()
	app.events.append({"s":app.distance,"lane":1,"kind":"arch","speed":0.0,"length":1.0,"source_lane":1,"done":false,"node":null})
	app.invulnerable=0
	app.check_contacts()
	check(app.lives==3,"back roll clears overhead beam")
	app.events[0].kind="wall"
	app.check_contacts()
	check(app.lives==2,"back roll cannot pass through solid wall")
	app.reset_course()
	app.begin_run()
	var sizes: Array=[]
	for variant in [1.0,1.5,2.0]:
		app.camera_variant=variant
		app.update_camera()
		var top: Vector2=app.camera.unproject_position(Vector3(0,2.5,0))
		var foot: Vector2=app.camera.unproject_position(Vector3.ZERO)
		sizes.append(absf(foot.y-top.y)/root.get_visible_rect().size.y)
	check(sizes[2]>sizes[0]*1.7,"camera enlarges hero without scaling model")
	check(sizes[2]>=0.18 and sizes[2]<=0.22,"hero target height %.3f" % sizes[2])
	for s in [400,900]:
		app.distance=s
		for lane in 3:
			app.x=(lane-1)*2.6
			for h in [0.0,1.48,3.2,6.5,10.5]:
				app.height=h
				app.update_camera()
				# Include the taller animated quiff, not just the face/helmet height.
				for y in [0.0,2.97]:
					var pixel: Vector2=app.camera.unproject_position(Vector3(app.x,h+y,0))
					var rect:=root.get_visible_rect()
					check(rect.grow(-4).has_point(pixel),"hero visible s%d lane%d h%.1f y%.1f" % [s,lane,h,y])
	print("TRICKS/CAMERA: %d checks, %d failures; height fractions %s" % [checks,failures.size(),str(sizes)])
	app.free()
	await create_timer(0.15).timeout
	quit(0 if failures.is_empty() else 1)
