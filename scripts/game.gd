extends Node3D
const G = preload("res://scripts/geometry.gd")
const Hero = preload("res://scripts/hero.gd")
const Course = preload("res://scripts/course.gd")
const Scenery = preload("res://scripts/scenery.gd")
const Props = preload("res://scripts/props.gd")
const Orbit = preload("res://scripts/orbit.gd")
const UI = preload("res://scripts/ui.gd")
const Sound = preload("res://scripts/audio.gd")
const Planets = preload("res://scripts/planets.gd")
const Flight = preload("res://scripts/flight.gd")
const AffectionFx=preload("res://scripts/affection_fx.gd")
const PickupFeedback = preload("res://scripts/pickup_feedback.gd")
const Monuments=preload("res://scripts/finish_monuments.gd")
const Tunnel=preload("res://scripts/rocket_tunnel.gd")
const SurfaceStyle=preload("res://scripts/surface_style.gd")
var finish_walk: Node3D
var planet := 0
var success_result := false
var flight: Node3D
var flight_target := 1
var flight_paid := false
var flight_reward := 0
var flight_id := 0
var countdown_target := "run"
var gesture_direction := ""
var gesture_age := 100.0
const DOUBLE_WINDOW := 0.42
var flip_used := false
var flip_elapsed := 0.0
var roll_timer := 0.0
var camera_variant := 2.0
var tunnel_active: Dictionary = {}
var tunnel_camera_blend := 0.0
var launch_landmark: Node3D
var camera: Camera3D
var environment: WorldEnvironment
var surface_environment: Environment
var space_environment: Environment
var track_root: Node3D
var orbit: Node3D
var scenery: Node3D
var runner: Node3D
var previews: Array[Node3D] = []
var finish: Node3D
var hud: CanvasLayer
var sound: Node
var state := "menu"
var return_state := "run"
var clock := 0.0
var cinema_time := 0.0
var distance := 0.0
var speed := 13.0
var lane := 1
var x := 0.0
var height := 0.0
var vertical_speed := 0.0
var support := 0.0
var slide_timer := 0.0
var invulnerable := 0.0
var lives := 3
var stars := 0
var score := 0
var booster := ""
var booster_timer := 0.0
var events: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var countdown_time := 0.0
var last_count := -1
var toast_timer := 0.0
var flash_timer := 0.0
var touch_start := Vector2.ZERO
var touch_active := false
var touch_id := -1
var warned_front := false
var committed := false
var test_mode := false
var burst_root: Node3D
var sparks: Array[Dictionary] = []
var ship: Node3D
var sky_planet: Node3D
var cinematic_hero: Node3D
var step_timer := 0.0
var launch_sounded := false
var pickup_feedback: Node3D
var affection_fx: Node3D
var front_gesture_index:=0
var front_gesture_delay:=0.0

func _ready() -> void:
	seed(24)
	planet = Profile.selected_planet
	make_environment()
	track_root = Node3D.new()
	add_child(track_root)
	scenery = Scenery.new()
	track_root.add_child(scenery)
	scenery.sync(0, 0, 0)
	runner = Hero.new()
	track_root.add_child(runner)
	runner.build(Profile.hero == 1,Profile.suits[Profile.hero])
	runner.rotation.y = PI
	finish = make_finish()
	track_root.add_child(finish)
	sky_planet = Node3D.new()
	track_root.add_child(sky_planet)
	sky_planet.position = Vector3(-37, 24, -110)
	G.ball(sky_planet, Vector3.ONE * 16, Vector3.ZERO, "bc9edc")
	var sky_ring := G.ring(sky_planet, 10, 12, Vector3.ZERO, "ecd4f1")
	sky_ring.rotation_degrees = Vector3(23, 0, 27)
	sky_ring.scale.y = 0.06
	ship = Props.ship()
	track_root.add_child(ship)
	ship.visible = false
	for i in 2:
		var kid := Hero.new()
		track_root.add_child(kid)
		kid.build(i == 1,Profile.suits[i])
		kid.position = Vector3(-0.95 if i == 0 else 0.95, 0.45, 0)
		kid.rotation.y = 0.12 if i == 0 else -0.12
		previews.append(kid)
	orbit = Orbit.new()
	add_child(orbit)
	configure_planet()
	burst_root = Node3D.new()
	track_root.add_child(burst_root)
	camera = Camera3D.new()
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.fov = 57
	camera.far = 250
	add_child(camera)
	camera.current = true
	hud = UI.new()
	add_child(hud)
	pickup_feedback=PickupFeedback.new()
	track_root.add_child(pickup_feedback)
	pickup_feedback.build(hud.hud,hud.score_label)
	affection_fx=AffectionFx.new()
	track_root.add_child(affection_fx)
	affection_fx.build()
	runner.affection.connect(on_affection)
	hud.action.connect(on_action)
	sound = Sound.new()
	add_child(sound)
	apply_quality()
	show_menu()
	get_viewport().size_changed.connect(func(): hud._layout())
	hud._layout()

func make_environment() -> void:
	environment = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("49418c")
	sky_mat.sky_horizon_color = Color("b7b7e5")
	sky_mat.ground_horizon_color = Color("b7b7e5")
	sky_mat.ground_bottom_color = Color("7463a1")
	sky_mat.sky_curve = 0.28
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c2c3f0")
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.environment = env
	surface_environment = env
	space_environment = env.duplicate(true)
	space_environment.background_mode = Environment.BG_COLOR
	space_environment.background_color = Color("0d1531")
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-36, -28, 0)
	sun.light_color = Color("ffefd9")
	sun.light_energy = 0.8
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25, 145, 0)
	fill.light_color = Color("a9c5ff")
	fill.light_energy = 0.2
	add_child(fill)

func apply_quality() -> void:
	SurfaceStyle.set_quality(Profile.quality)
	get_viewport().msaa_3d = Viewport.MSAA_2X if Profile.quality else Viewport.MSAA_DISABLED
	Engine.max_fps = 60 if Profile.quality else 30
	for light: Node in get_children():
		if light is DirectionalLight3D and light.light_energy > 0.5: light.shadow_enabled = Profile.quality

func make_finish() -> Node3D:
	var p := Node3D.new()
	var gates:=Monuments.create(5+planet*18)
	p.add_child(gates); gates.position.z=-18; gates.scale=Vector3.ONE*1.5
	for side in [-1,1]:
		var landmark:=Monuments.create([3,0,2,4][planet]+planet*18)
		p.add_child(landmark); landmark.scale=Vector3.ONE*0.55
		landmark.position=Vector3(side*23,0,-25)
	p.set_meta("finish_monuments",true)
	for s in [-1.0, 1.0]:
		G.box(p, Vector3(0.6, 5.8, 0.8), Vector3(s * 4.7, 2.9, 0), "a98acb")
		G.box(p, Vector3(0.14, 5.2, 0.85), Vector3(s * 4.7, 2.9, 0), "7ef7dd", 0.7)
	G.box(p, Vector3(10, 1.0, 0.9), Vector3(0, 5.7, 0), "565482")
	G.label(p, Planets.get_data(planet).name.to_upper()+"  /  ФИНИШ", Vector3(0, 5.65, 0.49), 44)
	for i in 7: G.star(p, 0.28, Vector3((i - 3) * 1.1, 4.7, 0.1))
	return p

func reset_course() -> void:
	clear_finish_walk()
	for event in events + pickups:
		if is_instance_valid(event.node): event.node.free()
	configure_planet()
	events = Course.events(planet)
	pickups = Course.stars(planet,events)
	scenery.clear()
	distance = 0
	speed = 13
	lane = 1
	x = 0
	tunnel_active={}
	tunnel_camera_blend=0
	front_gesture_index=0
	front_gesture_delay=0
	if is_instance_valid(affection_fx): affection_fx.clear()
	if is_instance_valid(runner): runner.cancel_front_gesture()
	height = 0
	vertical_speed = 0
	support = 0
	slide_timer = 0
	roll_timer = 0
	flip_used = false
	flip_elapsed = 0
	clear_gesture()
	invulnerable = 0
	lives = 3
	stars = 0
	if is_instance_valid(pickup_feedback): pickup_feedback.reset()
	score = 0
	booster = ""
	booster_timer = 0
	warned_front = false
	committed = false
	step_timer = 0
	launch_sounded = false
	for spark in sparks:
		if is_instance_valid(spark.node): spark.node.free()
	sparks.clear()
	ship.visible = false
	hud.transition.color.a = 0
	if is_instance_valid(cinematic_hero): cinematic_hero.free()
	cinematic_hero = Hero.new()
	orbit.ship.add_child(cinematic_hero)
	cinematic_hero.build(Profile.hero == 1,Profile.suits[Profile.hero])
	cinematic_hero.scale = Vector3.ONE * 0.65
	cinematic_hero.position = Vector3(0, 1.0, 0.85)
	cinematic_hero.rotation.y = PI
	finish.visible = true
	if runner.girl != (Profile.hero == 1):
		runner.free()
		runner = Hero.new()
		track_root.add_child(runner)
		runner.build(Profile.hero == 1,Profile.suits[Profile.hero])
		runner.rotation.y = PI
		runner.affection.connect(on_affection)
	runner.apply_suit(Profile.suits[Profile.hero])
	runner.visible = true
	runner.position = Vector3.ZERO
	scenery.sync(0, 0, clock)
	finish.position.z = -Course.LENGTH

func show_menu() -> void:
	clear_finish_walk()
	state = "menu"
	clear_gesture()
	if is_instance_valid(flight): flight.visible = false
	sound.set_paused(false)
	sound.set_engine(false)
	track_root.visible = true
	orbit.visible = false
	runner.visible = false
	ship.visible = false
	finish.visible = false
	for kid in previews: kid.visible = true
	for i in previews.size(): previews[i].position = Vector3(-0.95 if i == 0 else 0.95, 0.45, 0)
	distance = 0
	scenery.sync(0, 0, clock)
	for event in events + pickups:
		if is_instance_valid(event.node): event.node.visible = false
	hud.menu()
	if not Profile.pending_trip.is_empty():
		hud.button(hud.screen,"Продолжить перелёт  →","continue_trip",530,false,80,380,53)

func start_level() -> void:
	sound.set_paused(false)
	reset_course()
	if is_instance_valid(flight): flight.visible = false
	for kid in previews: kid.visible = false
	camera.fov = 57
	state = "intro"
	cinema_time = 0
	track_root.visible = false
	orbit.visible = true
	hud.cinematic("ПЛАНЕТА "+Planets.get_data(planet).name.to_upper(), Planets.get_data(planet).subtitle)
	sound.sfx("whoosh")

func begin_run() -> void:
	state = "run"
	track_root.visible = true
	orbit.visible = false
	runner.visible = true
	runner.rotation.y = PI
	ship.visible = false
	if is_instance_valid(launch_landmark): launch_landmark.visible = false
	clear_gesture()
	hud.playing()
	toast("Добро пожаловать! "+Planets.get_data(planet).name, 3)

func on_action(command: String) -> void:
	clear_gesture()
	if command != "preferences": sound.sfx("click")
	if command.begins_with("planet_"):
		var choice := int(command.trim_prefix("planet_"))
		if choice <= Profile.unlocked and choice>=0 and choice<4:
			planet = choice
			Profile.selected_planet = planet
			if not test_mode: Profile.save()
			configure_planet()
			state="select"
			hud.selection(Profile.hero,planet)
		return
	match command:
		"planets":
			state="planets"
			hud.planets(planet,Profile.unlocked)
		"leave_finish":
			if state=="explore": begin_departure()
		"walk_jump":
			if state=="explore": finish_walk.jump_pending=true
		"next": start_flight(planet)
		"continue_trip": start_flight(int(Profile.pending_trip.get("source",planet)),true)
		"arrive": arrive_at_planet()
		"skip_flight":
			if state=="flight" and Profile.flown_routes.has(flight.source): complete_flight(true)
		"select":
			state = "select"
			hud.selection(Profile.hero,planet)
		"boy", "girl":
			Profile.hero = 1 if command == "girl" else 0
			Profile.save()
			hud.selection(Profile.hero,planet)
		"start", "restart": start_level()
		"menu": show_menu()
		"pause": pause_game()
		"resume": resume_game()
		"settings":
			var previous: String = hud.current
			if previous in ["play","explore"]: pause_game(); previous = "pause"
			hud.settings(previous)
		"close_settings":
			if hud.settings_return == "pause": hud.paused()
			elif hud.settings_return == "select": hud.selection(Profile.hero,planet)
			elif hud.settings_return == "planets": hud.planets(planet,Profile.unlocked)
			else: hud.menu()
		"preferences": apply_quality()
		"skip":
			if state == "intro": begin_run()
			elif state == "outro": show_results(true)

func pause_game() -> void:
	if state not in ["run", "flight", "intro", "outro", "countdown", "explore"]: return
	if state=="explore":
		finish_walk.stop()
		if is_instance_valid(hud.walk_stick): hud.walk_stick.reset()
	return_state = state if state != "countdown" else countdown_target
	state = "paused"
	touch_active = false
	touch_id = -1
	clear_gesture()
	sound.set_paused(true)
	hud.paused()

func resume_game() -> void:
	if state != "paused": return
	if return_state=="explore":
		state="explore"; sound.set_paused(false); show_walk_hud()
	elif return_state in ["run","flight"]:
		countdown_target = return_state
		state = "countdown"
		countdown_time = 3.0
		last_count = -1
	else:
		state = return_state
		sound.set_paused(false)
		hud.cinematic("ПЛАНЕТА "+Planets.get_data(planet).name.to_upper() if state == "intro" else "ДЕРЖИСЬ, КОСМОС!", "Продолжаем приключение")

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(hud) and not test_mode:
		pause_game()

func _unhandled_input(event: InputEvent) -> void:
	if state=="explore":
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode==KEY_SPACE: finish_walk.jump_pending=true; return
			if event.keycode==KEY_ENTER: on_action("leave_finish"); return
		finish_walk.pointer_event(event)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE, KEY_P:
				if state == "paused": resume_game()
				else: pause_game()
			KEY_LEFT, KEY_A: move_screen(-1)
			KEY_RIGHT, KEY_D: move_screen(1)
			KEY_UP, KEY_W, KEY_SPACE: vertical_gesture("up")
			KEY_DOWN, KEY_S: vertical_gesture("down")
			KEY_ENTER:
				if state == "menu": on_action("select")
				elif state == "select": start_level()
				elif state in ["intro", "outro"]: on_action("skip")
		return
	if state not in ["run","flight"]: return
	var pressed := false
	var released := false
	var pos := Vector2.ZERO
	if event is InputEventScreenTouch:
		if event.pressed and touch_id>=0: return
		if not event.pressed and event.index != touch_id: return
		pressed = event.pressed
		released = not event.pressed
		pos = event.position
		touch_id = event.index if event.pressed else -1
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.device == InputEvent.DEVICE_ID_EMULATION: return
		pressed = event.pressed
		released = not event.pressed
		pos = event.position
	if pressed:
		touch_start = pos
		touch_active = true
	elif released and touch_active:
		touch_active = false
		swipe(pos - touch_start)
	elif event is InputEventScreenDrag and event.index == touch_id and touch_active:
		var delta: Vector2 = event.position - touch_start
		if delta.length() > 42:
			touch_active = false
			swipe(delta)

func swipe(delta: Vector2) -> void:
	if delta.length() < 24: return
	if absf(delta.x) > absf(delta.y): move_screen(1 if delta.x > 0 else -1)
	elif delta.y < 0: vertical_gesture("up")
	else: vertical_gesture("down")

func can_act() -> bool:
	return state == "run" and not Course.transitioning(distance)

func move_screen(direction: int) -> void:
	if state == "flight": flight.steer(direction); return
	if not can_act() or not tunnel_active.is_empty(): return
	var mapped := -direction if Course.front_at(distance) > 0.5 else direction
	var target := lane + mapped
	if Course.lanes_at(distance,planet).has(target): lane = target

func jump() -> void:
	if not can_act() or booster == "jet" or not tunnel_active.is_empty(): return
	if height <= support + 0.10:
		vertical_speed = 9.2
		slide_timer = 0
		roll_timer = 0
		sound.sfx("jump")
		sound.vocal("jump", Profile.hero == 1)

func slide() -> void:
	if not can_act() or booster == "jet" or not tunnel_active.is_empty() or height > support + 0.12: return
	if slide_timer>0: return
	slide_timer = 0.85
	sound.sfx("slide")

func clear_gesture() -> void:
	gesture_direction=""
	gesture_age=100

func vertical_gesture(direction: String) -> void:
	if not can_act() or booster=="jet" or not tunnel_active.is_empty(): clear_gesture(); return
	var paired := gesture_direction==direction and gesture_age<=DOUBLE_WINDOW
	if paired:
		clear_gesture()
		if direction=="up" and not flip_used and height>support+0.02:
			flip_used=true
			flip_elapsed=0
			vertical_speed=14.5
			roll_timer=0
			slide_timer=0
			sound.vocal("laugh",Profile.hero==1,true)
			sound.sfx("boost",1.15)
		elif direction=="down" and height<=support+0.12 and roll_timer<=0:
			roll_timer=1.2
			slide_timer=1.2
			sound.sfx("slide",0.8)
		return
	clear_gesture()
	if direction=="up":
		if height>support+0.1: return
		jump()
	else:
		if height>support+0.12 or slide_timer>0: return
		slide()
	gesture_direction=direction
	gesture_age=0

func _process(dt: float) -> void:
	if state == "paused": return
	if state == "countdown":
		countdown_time -= dt
		var value := maxi(1, int(ceil(countdown_time)))
		if value != last_count:
			last_count = value
			hud.countdown(value)
		if countdown_time <= 0:
			state = countdown_target
			if state=="flight": hud.flight_playing(Profile.flown_routes.has(flight.source))
			else: hud.playing()
			sound.set_paused(false)
		return
	clock += dt
	environment.environment = space_environment if orbit.visible or state in ["flight","flight_result"] else surface_environment
	sound.advance(dt)
	if state in ["menu", "select", "results", "planets"]:
		for i in previews.size():
			var kid := previews[i]
			kid.animate(dt, "win" if state == "results" and Profile.completed else "idle")
			kid.scale = Vector3.ONE * (1.06 if i == Profile.hero and state == "select" else 1.0)
		var z := 7.8
		camera.fov = 57
		camera.position = Vector3(0, 2.9, z)
		camera.look_at(Vector3(0, 1.5, 0))
	elif state=="explore":
		finish_walk.present(dt,runner,camera,Profile.reduced_motion)
		for piece: MeshInstance3D in finish.find_children("*","MeshInstance3D",true,false):
			if piece.material_override.get_meta("ancient_energy",false): piece.material_override.set_shader_parameter("energy_time",clock)
	elif state in ["intro", "outro"]:
		advance_cinematic(dt)
	elif state == "run":
		tunnel_camera_blend=move_toward(tunnel_camera_blend,0.0 if tunnel_active.is_empty() else 1.0,dt*3.0)
		update_camera()
		for piece: MeshInstance3D in finish.find_children("*","MeshInstance3D",true,false):
			if piece.material_override.get_meta("ancient_energy",false):
				piece.material_override.set_shader_parameter("activation",smoothstep(1940,2100,distance))
				piece.material_override.set_shader_parameter("energy_time",clock)
				piece.material_override.set_shader_parameter("reduced_motion",Profile.reduced_motion)
		var action_value := "run"
		if booster == "jet": action_value = "jet"
		elif flip_used and height>support+0.1: action_value = "flip"
		elif roll_timer>0: action_value = "roll"
		elif slide_timer > 0: action_value = "slide"
		elif height > support + 0.15: action_value = "jump"
		elif booster == "board": action_value = "board"
		runner.set_meta("riding",booster=="board")
		runner.trick_phase = clampf(flip_elapsed/0.85,0,1)
		update_front_gestures(dt,action_value)
		runner.animate(dt, action_value, speed, (lane - 1) * 2.6 - x)
		runner.visible = invulnerable <= 0 or fmod(clock, 0.16) < 0.11
		scenery.sync(distance, dt, clock)
		for event in events:
			if is_instance_valid(event.node) and event.kind=="tunnel": Tunnel.advance(event.node,dt)
			if is_instance_valid(event.node) and event.kind in ["jet", "board"]:
				event.node.rotation.y = clock * 1.5
		for pickup in pickups:
			if is_instance_valid(pickup.node): pickup.node.rotation.y = clock * 2.0
		update_hud()
	elif state in ["flight","flight_result"]:
		var pose: Dictionary = flight.camera_pose()
		camera.position=pose.position
		camera.fov=57
		camera.look_at(pose.target)
		if state=="flight": hud.update_flight(flight.place,flight.distance/flight.LENGTH,Planets.route_name(flight.source),flight.boost,flight.energy)
	affection_fx.reduced_motion=Profile.reduced_motion
	affection_fx.advance(dt,camera,state=="run" and Course.front_at(distance)>0.8)
	update_sparks(dt)
	pickup_feedback.reduced_motion=Profile.reduced_motion
	pickup_feedback.high_quality=Profile.quality
	var receipt_at:=runner.global_position+Vector3(0,3.0,0)
	if runner.mood in ["slide","roll"]: receipt_at=runner.head.global_position+Vector3(0,0.9,0)
	pickup_feedback.advance(dt,runner.position,camera,state=="run",receipt_at)
	toast_timer = maxf(0, toast_timer - dt)
	hud.toast_label.visible = toast_timer > 0 and state == "run"
	flash_timer = maxf(0, flash_timer - dt)
	hud.flash.color.a = flash_timer * 0.6

func on_affection(kind: String, source: Vector3) -> void:
	if state!="run" or Course.front_at(distance)<0.88 or runner.mood!="run": return
	affection_fx.emit_hearts(source,camera,kind=="heart")

func update_front_gestures(dt: float, action_value: String) -> void:
	front_gesture_delay=maxf(0,front_gesture_delay-dt)
	var eligible:=Course.front_at(distance)>0.88 and action_value=="run" and invulnerable<=0 and tunnel_active.is_empty()
	var gap:=INF
	for e: Dictionary in events:
		if e.done or e.kind in ["jet","board","tunnel"]: continue
		var delta: float=e.s-distance
		if delta>=-12 and delta<12: eligible=false
		if delta>0: gap=minf(gap,delta)
	if not eligible:
		runner.cancel_front_gesture()
		return
	if not runner.front_gesture.is_empty() or front_gesture_index>=3 or front_gesture_delay>0: return
	var duration: float=[1.35,1.6,1.4][front_gesture_index]
	if gap<duration*speed+12: return
	runner.begin_front_gesture(["wave","tap","heart"][front_gesture_index])
	front_gesture_index+=1
	front_gesture_delay=duration+0.2

func _physics_process(dt: float) -> void:
	if state=="explore": finish_walk.advance(dt); return
	if state=="flight":
		flight.advance(dt)
		if flight.done: complete_flight(false)
		return
	if state != "run": return
	simulate(dt)

func simulate(dt: float) -> void:
	gesture_age += dt
	roll_timer = maxf(0,roll_timer-dt)
	if flip_used: flip_elapsed+=dt
	if Course.transitioning(distance): clear_gesture()
	var base_speed := lerpf(13.0, 18.5, clampf(distance / Course.LENGTH, 0, 1))
	var multiplier := 1.25 if booster == "jet" else (1.2 if booster == "board" else 1.0)
	var desired := base_speed * multiplier * (0.7 if invulnerable > 1.3 else 1.0)
	desired = lerpf(desired, 6.0, Course.front_at(distance))
	speed = move_toward(speed, desired, dt * 9)
	distance = minf(Course.LENGTH, distance + speed * dt)
	x = move_toward(x, (lane - 1) * Course.LANE_WIDTH, dt * 13)
	slide_timer = maxf(0, slide_timer - dt)
	invulnerable = maxf(0, invulnerable - dt)
	for event in events:
		if distance >= float(event.get("motion_trigger",event.s))-155:
			event.s += event.speed * dt
	step_timer -= dt
	if step_timer <= 0 and booster.is_empty() and height < support + 0.05 and slide_timer <= 0:
		sound.sfx("step", randf_range(0.93, 1.07))
		step_timer = 0.34
	for pickup in pickups:
		if pickup.has("anchor"): pickup.s = pickup.anchor.s + pickup.offset
	var old_support := support
	support = find_support()
	if not tunnel_active.is_empty():
		height=Course.TUNNEL_FLOOR
		vertical_speed=0
	elif booster == "jet":
		height = move_toward(height, 3.2, dt * 6)
		vertical_speed = 0
	elif height <= old_support + 0.1 and vertical_speed <= 0 and support > old_support:
		height = support
		vertical_speed = 0
	else:
		vertical_speed -= 23.0 * dt
		height += vertical_speed * dt
		if height <= support:
			if vertical_speed < -3: sound.sfx("land")
			height = support
			vertical_speed = 0
			flip_used = false
	update_tunnel()
	if not booster.is_empty():
		booster_timer -= dt
		if booster_timer <= 0: end_booster()
	runner.position = Vector3(x, height + (0.25 if booster == "board" else 0), 0)
	spawn_and_update()
	check_contacts()
	if not warned_front and distance > 780:
		warned_front = true
		toast("Дрон впереди! Скоро вид спереди", 4)
		sound.sfx("warning")
		sound.vocal("surprise", Profile.hero == 1)
	if distance >= Course.LENGTH and state == "run": finish_level()

func update_tunnel() -> void:
	if not tunnel_active.is_empty():
		if distance-tunnel_active.s>Course.TUNNEL_LENGTH*0.5:
			tunnel_active={}
			support=0
			invulnerable=maxf(invulnerable,1.2)
			clear_gesture()
		return
	if not flip_used or booster=="jet": return
	for e: Dictionary in events:
		if e.kind!="tunnel" or e.get("entered",false): continue
		var rel: float=distance-e.s
		if rel>=-26 and rel<=-16 and absf(x-(e.lane-1)*Course.LANE_WIDTH)<0.8 and height>=Course.TUNNEL_FLOOR-0.25 and height<Course.TUNNEL_FLOOR+1.6:
			e.entered=true
			if booster=="board": end_booster()
			tunnel_active=e
			lane=e.lane
			x=(lane-1)*Course.LANE_WIDTH
			height=Course.TUNNEL_FLOOR
			support=height
			vertical_speed=0
			flip_used=false
			slide_timer=0
			roll_timer=0
			clear_gesture()
			toast("Мегазвёзды! Внутри безопасно · ×2",2.4)
			sound.sfx("boost",1.1)
			break

func find_support() -> float:
	if not tunnel_active.is_empty(): return Course.TUNNEL_FLOOR
	var result := 0.0
	for event in events:
		if absf(x - (event.lane - 1) * 2.6) > 0.95: continue
		var rel: float = distance - event.s
		if event.kind == "ramp" and rel >= -3 and rel <= 3:
			result = maxf(result, (rel + 3) / 6.0 * 1.48)
		elif event.kind == "carrier" and absf(rel) < 6:
			if height >= 1.35: result = maxf(result, 1.48)
	return result

func spawn_and_update() -> void:
	for event in events:
		var rel: float = distance - event.s
		if rel < -155 or rel > 35 or event.done:
			if is_instance_valid(event.node): event.node.queue_free(); event.node = null
			continue
		if not is_instance_valid(event.node):
			event.node = Props.obstacle(event.kind,posmod(int(event.get("encounter",0))*7+event.lane*3+planet,14))
			track_root.add_child(event.node)
			G.recolor(event.node,Planets.get_data(planet).palette)
			if event.kind == "wall":
				var alien := Props.alien()
				event.node.add_child(alien)
				alien.position = Vector3(1.4, 0, -0.4)
				alien.rotation.y = -0.3
			event.node.set_meta("kind", event.kind)
		event.node.position = Vector3(Course.event_x(event,distance), 0, rel)
		if event.kind == "alien":
			Props.animate_alien(event.node,clock)
			event.node.get_node("Crossing").position.x = -Course.event_x(event,distance)
			event.node.get_node("Crossing").visible = rel > -55 and rel < 8
		if event.kind in ["leaf","gardener","traffic","alien"]:
			var phase := smoothstep(-45,-18,rel)
			if event.kind=="leaf": event.node.get_node("Leaf").rotation.x=lerpf(-1.25,0,phase)
			var warning: Node3D = event.node.get_node("Warning")
			warning.visible=rel>-60 and rel<0
			warning.scale=Vector3.ONE*(1.0+0.12*sin(clock*16))
			if rel>-55 and not event.get("warned",false):
				event.warned=true
				if absf(x - Course.event_x(event,distance)) < 1.0:
					sound.vocal("surprise", Profile.hero == 1)
				sound.sfx("warning",0.9 if event.kind=="leaf" else 1.1)
				if event.kind == "alien":
					sound.sfx("honk1",1.2)
					toast("Курьер опаздывает! Обойди или перепрыгни",2.4)
		if event.kind == "carrier":
			event.node.position.y = sin(clock * 2) * 0.04
	for pickup in pickups:
		var rel: float = distance - pickup.s
		if pickup.has("anchor") and pickup.get("requirement","") in ["duck","cleared","roof"]:
			if pickup.anchor.get("failed",false) or pickup.anchor.get("reward_missed",false): pickup.done=true
		if rel < -155 or rel > 5 or pickup.done:
			if is_instance_valid(pickup.node): pickup.node.queue_free(); pickup.node = null
			continue
		if not is_instance_valid(pickup.node):
			pickup.node = G.star(track_root, 0.54 if pickup.get("mega",false) else 0.39 if int(pickup.get("value",1)) > 1 else 0.27, Vector3.ZERO)
			if pickup.get("mega",false):
				pickup.node.material_override=G.material("fff0a6",1.4)
			if int(pickup.get("value",1)) > 1 and not pickup.get("mega",false):
				G.ring(pickup.node,0.46,0.5,Vector3.ZERO,"ffe295",0.4).rotation.x = PI*0.5
				var amount := G.label(pickup.node,"+%d" % int(pickup.value),Vector3(0,0.65,0),28)
				amount.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		pickup.node.position = Vector3((pickup.lane - 1) * 2.6, pickup.y, rel)
	finish.position.z = distance - Course.LENGTH

func check_contacts() -> void:
	for event in events:
		if event.done or event.kind=="tunnel": continue
		if not tunnel_active.is_empty(): continue
		var rel: float = distance - event.s
		if event.kind in ["arch","barrier"] and rel>event.length*0.5+0.25 and not event.get("cleared",false):
			event.reward_missed=true
		if absf(x - Course.event_x(event,distance)) > (0.78 if event.kind == "alien" else 0.95): continue
		if event.kind in ["jet", "board"]:
			if absf(rel) < 1.0 and height < 2: activate_booster(event.kind); event.done = true
			continue
		if absf(rel) > event.length * 0.5 + 0.25: continue
		if event.kind == "ramp": continue
		if event.kind == "carrier" and height >= 1.35:
			event.cleared = not bool(event.get("failed",false))
			continue
		if booster == "jet": continue
		var clean := height >= Course.top_of(event.kind)
		clean = clean or (event.kind == "barrier" and height > 0.93)
		clean = clean or (event.kind == "arch" and slide_timer > 0 and height < 0.15)
		if clean:
			event.cleared = not bool(event.get("failed",false))
			continue
		event.failed = true
		event.cleared = false
		if invulnerable > 0: continue
		event.done = true
		if test_mode and OS.get_cmdline_user_args().has("--trace-hits"):
			print("COURSE HIT: ",event.kind," at ",snappedf(distance,0.1)," lane ",lane," x ",snappedf(x,0.01)," height ",snappedf(height,0.01))
		take_hit()
	for pickup in pickups:
		if pickup.done or not pickup_allowed(pickup): continue
		if absf(distance-pickup.s)<1.0 and absf(x-(pickup.lane-1)*2.6)<0.85 and absf(height+1.0-pickup.y)<1.0:
			pickup.done = true
			var value := int(pickup.get("value",1))
			stars += value
			if value >= 3: toast("Чисто! +3 ★",0.9)
			sound.sfx("star",1+float(stars%5)*0.04)
			pickup_feedback.notify(value)

func pickup_allowed(pickup: Dictionary) -> bool:
	var requirement: String = pickup.get("requirement","")
	if requirement == "tunnel": return not tunnel_active.is_empty() and tunnel_active==pickup.anchor
	if requirement == "duck":
		return slide_timer>0 and height<0.15 and not bool(pickup.anchor.get("failed",false))
	if requirement == "cleared": return bool(pickup.anchor.get("cleared",false)) and not bool(pickup.anchor.get("failed",false))
	if requirement == "roof": return height>=1.35 and not bool(pickup.anchor.get("failed",false))
	return true

func take_hit() -> void:
	if state != "run" or invulnerable > 0 or not tunnel_active.is_empty(): return
	if booster == "board":
		end_booster()
		toast("Платформа защитила тебя!", 2.4)
	else:
		lives -= 1
		sound.vocal("hit", Profile.hero == 1, true)
	invulnerable = 2.2
	flash_timer = 0.45
	sound.sfx("hit")
	burst(Vector3(x, 1, 0), "ffb2cf", 10)
	if Profile.vibration and not test_mode: Input.vibrate_handheld(65)
	if lives <= 0: show_results(false)

func activate_booster(kind: String) -> void:
	if Course.transitioning(distance): return
	booster = kind
	booster_timer = 8.0 if kind == "jet" else 10.0
	slide_timer = 0
	roll_timer=0
	flip_used=false
	clear_gesture()
	sound.sfx("boost")
	sound.vocal("joy", Profile.hero == 1, true)
	sound.set_engine(true)
	toast("Реактивный ранец!" if kind == "jet" else "Попутка! Поехали!", 2.5)
	burst(Vector3(x, 1, 0), "83f9e7", 12)

func end_booster() -> void:
	booster = ""
	booster_timer = 0
	invulnerable = maxf(invulnerable, 2.2)
	sound.set_engine(false)
	# Descent/safe dismount cannot immediately damage the player.

func update_camera() -> void:
	var front := Course.front_at(distance)
	var angle := front * PI
	var framing := pow(clampf(camera_variant-1,0,1),0.65)
	var radius := lerpf(lerpf(11.8,7.2,framing),lerpf(16.5,11.5,framing),front)
	radius+=front*maxf(0,height-1.5)*1.5*framing
	var follow_y := height*lerpf(0.35,1.0,framing)
	var at := Vector3(sin(angle)*radius,lerpf(lerpf(5.7,4.8,framing),lerpf(6.7,5.7,framing),front)+follow_y,cos(angle)*radius)
	var target := Vector3(x*lerpf(0.15,0.45,framing),1.0+follow_y,lerpf(lerpf(-11,-16,framing),lerpf(-5,-4.5,framing),front))
	target.z-=front*minf(4.5,maxf(0,height-1.5))*framing
	var base_fov := lerpf(lerpf(57,50,framing),lerpf(45,36,framing),front)
	base_fov+=front*minf(10,maxf(0,height-1.5)*2)*framing
	var aspect := get_viewport().get_visible_rect().size.x/get_viewport().get_visible_rect().size.y
	var aspect_scale := clampf(aspect/(540.0/960.0),0.78,1.05)
	camera.fov = rad_to_deg(2*atan(tan(deg_to_rad(base_fov)*0.5)*lerpf(1.0,aspect_scale,framing)))
	at.x=lerpf(at.x,x,tunnel_camera_blend)
	at.y=lerpf(at.y,Course.TUNNEL_FLOOR+2.55,tunnel_camera_blend)
	target.x=lerpf(target.x,x,tunnel_camera_blend)
	target.y=lerpf(target.y,Course.TUNNEL_FLOOR+1.35,tunnel_camera_blend)
	camera.position = at
	camera.look_at(target)

func update_hud() -> void:
	hud.toast_label.position.y=410 if Course.front_at(distance)>0.5 else 223
	var hint := ""
	if distance < 85: hint = "Свайп вверх — прыжок\nНа компьютере: ↑ или пробел"
	elif distance < 145: hint = "Свайп вниз — подкат\nНа компьютере: ↓"
	elif distance<180 and planet==0: hint="Впереди развилка\nЗвёзды покажут выгодный маршрут"
	elif distance<220 and planet==0: hint="Открылась вторая полоса\nСвайп влево или вправо — перестроиться"
	elif distance>620 and distance<660: hint="Два быстрых свайпа вверх\nПереворот и смех!"
	elif distance>665 and distance<705: hint="Два свайпа вниз — прокат на спине\nПод аркой ждёт бонус +3"
	elif distance > 500 and distance < 585: hint = "Поднимайся по пандусу\nНа левитирующей платформе можно бежать"
	elif Course.transitioning(distance): hint = "Камера меняет ракурс — безопасный участок"
	elif Course.front_at(distance) > 0.9: hint = "Бежим к тебе!\nСвайпы по-прежнему ведут в сторону экрана"
	elif distance > 2030: hint = "Финиш близко!"
	for event in events:
		if event.kind == "arch" and event.lane == lane and event.s-distance>5 and event.s-distance<36 and not (distance>665 and distance<705):
			hint = "Под аркой — звёзды и бонус +3!"
			break
		if event.kind in ["leaf","gardener","traffic"] and event.s-distance>15 and event.s-distance<55:
			hint="Лист поднимается — выбирай свободную полосу!" if event.kind=="leaf" else "Сигнал! Техника готовится перестроиться"
			break
	for e: Dictionary in events:
		if e.kind=="tunnel" and e.s-distance>22 and e.s-distance<72:
			hint="Тоннель наверху: два свайпа ↑\nМегазвёзды ×2 · внизу можно пробежать"
	if not tunnel_active.is_empty(): hint="Бонусный тоннель · безопасный бег · ★ ×2"
	var data := Planets.get_data(planet)
	var region: String = data.regions[int(distance/90)%3]
	hud.update_hud(lives, stars, distance / Course.LENGTH, data.name.to_upper()+"  /  " + region, booster, booster_timer, hint,Course.star_goal(planet))

func toast(value: String, duration: float = 2.5) -> void:
	hud.toast_label.text = value
	toast_timer = duration

func burst(at: Vector3, color: String, count: int) -> void:
	if not Profile.quality: count = mini(count, 4)
	for i in count:
		var node := G.box(burst_root, Vector3(0.024,0.08,0.024), at, color, 0.4)
		node.rotation=Vector3(randf()*PI,randf()*PI,randf()*PI)
		sparks.append({"node": node, "v": Vector3(randf_range(-2, 2), randf_range(1, 3), randf_range(-2, 2)), "life": 0.28})

func update_sparks(dt: float) -> void:
	for i in range(sparks.size() - 1, -1, -1):
		var spark: Dictionary = sparks[i]
		spark.life -= dt
		if spark.life <= 0:
			spark.node.queue_free()
			sparks.remove_at(i)
		else:
			spark.node.position += spark.v * dt
			spark.v.y -= dt * 5
			spark.node.scale = Vector3.ONE * minf(1, spark.life * 3)

func commit_result(success: bool) -> void:
	if committed: return
	committed = true
	score = int(distance) + stars * 25 + (1000 if success else 0)
	Profile.best = maxi(Profile.best, score)
	Profile.records[planet]=maxi(Profile.records[planet],score)
	Profile.star_records[planet]=maxi(Profile.star_records[planet],stars)
	Profile.bank+=stars
	if success:
		Profile.completed = true
		Profile.unlocked=maxi(Profile.unlocked,mini(3,planet+1))
	if not test_mode: Profile.save()

func clear_finish_walk() -> void:
	if is_instance_valid(finish_walk):
		finish_walk.free(); finish_walk=null
	if is_instance_valid(scenery): scenery.visible=true

func show_walk_hud() -> void:
	hud.exploring(Planets.get_data(planet).name)
	hud.walk_stick.moved.connect(func(value):
		if state=="explore" and is_instance_valid(finish_walk): finish_walk.stick=value)

func finish_level() -> void:
	if state!="run": return
	commit_result(true)
	state="explore"
	clear_gesture(); touch_active=false; touch_id=-1
	booster=""; booster_timer=0; slide_timer=0; roll_timer=0; flip_used=false
	tunnel_active={}; tunnel_camera_blend=0
	runner.cancel_front_gesture(); runner.set_meta("riding",false); runner.visible=true
	pickup_feedback.reset(); affection_fx.clear()
	for event in events+pickups:
		if is_instance_valid(event.node): event.node.visible=false
	finish.position.z=0; finish.visible=true
	scenery.visible=false; orbit.visible=false; track_root.visible=true; ship.visible=false
	if is_instance_valid(launch_landmark): launch_landmark.visible=false
	finish_walk=preload("res://scripts/finish_walk.gd").new(); track_root.add_child(finish_walk)
	finish_walk.build(finish,planet,Vector3(x,0,0))
	for piece: MeshInstance3D in finish.find_children("*","MeshInstance3D",true,false):
		if piece.material_override.get_meta("ancient_energy",false): piece.material_override.set_shader_parameter("activation",1.0)
	show_walk_hud()
	sound.set_engine(false); sound.sfx("win"); sound.vocal("win",Profile.hero==1,true)

func begin_departure() -> void:
	clear_finish_walk()
	runner.position=Vector3.ZERO
	state = "outro"
	launch_sounded = false
	cinema_time = 0
	sound.set_engine(false)
	booster = ""
	runner.visible = true
	runner.rotation.y = 0
	ship.visible = true
	if is_instance_valid(launch_landmark): launch_landmark.visible=true
	ship.position = Vector3(0, 0.35+(1.48 if planet==2 else 0), -4)
	hud.cinematic("ДЕРЖИСЬ, КОСМОС!", Planets.get_data(planet).name+" покорена — пора к звёздам")

func advance_cinematic(dt: float) -> void:
	cinema_time += dt
	var short := Profile.reduced_motion
	if is_instance_valid(launch_landmark):
		launch_landmark.visible=true
		if planet==1:
			for petal in launch_landmark.find_children("Petal*","Node3D",true,false):
				petal.rotation.x=lerpf(-0.8,0,smoothstep(0,3,cinema_time)) if state=="outro" else 0.0
	if state == "intro":
		var duration := 4.0 if short else 10.0
		if cinema_time < (1.6 if short else 7.0):
			orbit.visible = true
			track_root.visible = false
			var pose: Dictionary = orbit.stage(cinema_time, "intro")
			camera.position = pose.position
			camera.look_at(pose.target)
		else:
			orbit.visible = false
			track_root.visible = true
			ship.visible = true
			var surface_start := 1.6 if short else 7.0
			var local_time := cinema_time - surface_start
			var landing := smoothstep(0, 1.4, local_time)
			ship.position = Vector3(0, lerpf(12.0, 0.35, landing), -4)
			var disembark := smoothstep(1.0, duration - surface_start, local_time)
			runner.position = Vector3(0, (1 - disembark) * 1.4 + sin(disembark * PI), lerpf(-2.7, 0, disembark))
			runner.rotation.y = 0
			runner.animate(dt, "jump" if disembark > 0 and disembark < 1 else "idle")
			var k := smoothstep(duration - 2.2, duration, cinema_time)
			camera.position = Vector3(4 * (1 - k), lerpf(2.8, 5.7, k), lerpf(5.5, 11.8, k))
			camera.look_at(Vector3(0, 1.4, -k * 11))
			runner.rotation.y = k * PI
		if cinema_time >= duration: begin_run()
	else:
		var launch_time := 2.0 if short else 5.0
		var duration := 5.0 if short else 16.0
		if cinema_time < launch_time:
			var k := cinema_time / launch_time
			var boarding := smoothstep(0.25, 0.6, k)
			var launch := smoothstep(0.6, 1.0, k)
			if launch > 0 and not launch_sounded:
				launch_sounded = true
				sound.sfx("whoosh")
			runner.animate(dt, "jump" if boarding > 0 and boarding < 1 else "win")
			var deck := 1.48 if planet==2 else 0.0
			ship.position.y = 0.35+deck+launch*(21 if planet==3 else 8)
			runner.position = Vector3(0,(1-boarding)*deck+boarding*(ship.position.y+1.1)+sin(boarding*PI)*1.3,-boarding*2.7)
			camera.position = Vector3(sin(k*2.5)*7,3+deck+k*(22 if planet==3 else 7),6-k*11)
			camera.look_at(Vector3(0,1.2+deck+k*(16 if planet==3 else 4),-k*4))
			if cinema_time > launch_time - 0.4: hud.transition.color.a = (cinema_time - launch_time + 0.4) / 0.4
		else:
			hud.transition.color.a = maxf(0, 1 - (cinema_time - launch_time) * 2)
			track_root.visible = false
			orbit.visible = true
			var pose: Dictionary = orbit.stage(cinema_time - launch_time, "outro")
			camera.position = pose.position
			camera.look_at(pose.target)
			if is_instance_valid(cinematic_hero): cinematic_hero.animate(dt, "win")
		if cinema_time >= duration: show_results(true)

func show_results(success: bool) -> void:
	clear_finish_walk()
	commit_result(success)
	state = "results"
	success_result=success
	clear_gesture()
	hud.transition.color.a = 0
	sound.set_engine(false)
	track_root.visible = true
	orbit.visible = false
	runner.visible = false
	ship.visible = false
	finish.visible = false
	for event in events + pickups:
		if is_instance_valid(event.node): event.node.visible = false
	scenery.sync(0, 0, clock)
	for i in previews.size():
		previews[i].visible = i == Profile.hero
		previews[i].position = Vector3(0, 0.45, 0)
	if is_instance_valid(launch_landmark): launch_landmark.visible=false
	hud.results(success, stars, score, maxi(Profile.records[planet], score),planet)

func configure_planet() -> void:
	var data := Planets.get_data(planet)
	scenery.planet=planet
	scenery.clear()
	var sky_mat := surface_environment.sky.sky_material as ProceduralSkyMaterial
	sky_mat.sky_top_color=Color(data.sky)
	sky_mat.sky_horizon_color=Color(data.horizon)
	sky_mat.ground_horizon_color=Color(data.horizon)
	sky_mat.ground_bottom_color=Color(data.sky)
	orbit.configure(planet)
	if is_instance_valid(finish): finish.free()
	finish=make_finish()
	track_root.add_child(finish)
	if is_instance_valid(launch_landmark): launch_landmark.free()
	launch_landmark=Node3D.new()
	track_root.add_child(launch_landmark)
	launch_landmark.name="PlanetLandmark"
	match planet:
		1: Props.flower(launch_landmark,Vector3(0,-4.1,-4),2.1)
		2:
			var freighter := Props.obstacle("carrier")
			launch_landmark.add_child(freighter)
			freighter.scale=Vector3(2,1,3)
			freighter.position=Vector3(0,0,-14)
			Props.arch(launch_landmark,Vector3(0,0,-22))
		3:
			G.box(launch_landmark,Vector3(5,26,5),Vector3(9,13,-9),"393965")
			for y in range(2,28,2): G.box(launch_landmark,Vector3(5.1,0.14,5.1),Vector3(9,y,-9),"ff91dc",0.7)
			G.ring(launch_landmark,3.5,3.8,Vector3(9,27,-9),"87f7dc",0.6)
	launch_landmark.visible=false
	if is_instance_valid(sky_planet):
		sky_planet.get_child(0).material_override=SurfaceStyle.globe((planet+1)%4)
		sky_planet.get_child(1).material_override=G.material(data.accent)

func start_flight(source: int, continuing: bool = false) -> void:
	if source<0 or source>=3: return
	if is_instance_valid(flight): flight.free()
	flight=Flight.new()
	add_child(flight)
	flight_target=source+1
	flight_paid=false
	flight_reward=0
	if continuing and not Profile.pending_trip.is_empty():
		flight_id=int(Profile.pending_trip.id)
	else:
		Profile.trip_serial+=1
		flight_id=Profile.trip_serial
		Profile.pending_trip={"source":source,"target":flight_target,"id":flight_id}
		if not test_mode: Profile.save()
	flight.build(source,flight_id*7919+source*313)
	flight.cue.connect(func(kind):
		if kind=="bump": sound.sfx("hit",1.3)
		elif kind=="boost": sound.sfx("boost")
		else: sound.sfx(kind))
	track_root.visible=false
	orbit.visible=false
	state="flight"
	clear_gesture()
	touch_id=-1
	sound.set_paused(false)
	sound.set_engine(true)
	hud.flight_playing(Profile.flown_routes.has(source))
	environment.environment=space_environment

func complete_flight(skipped: bool) -> void:
	if flight_paid or state!="flight": return
	flight_paid=true
	flight_reward=0 if skipped else (8 if flight.place==1 else 5)
	if flight_id>Profile.last_trip_paid:
		Profile.bank+=flight_reward
		Profile.last_trip_paid=flight_id
	if not Profile.flown_routes.has(flight.source) and not skipped: Profile.flown_routes.append(flight.source)
	Profile.selected_planet=flight_target
	Profile.pending_trip={}
	if not test_mode: Profile.save()
	sound.set_engine(false)
	state="flight_result"
	hud.flight_results(flight.place,flight_reward,flight_target,skipped)

func arrive_at_planet() -> void:
	if state!="flight_result": return
	planet=flight_target
	start_level()
