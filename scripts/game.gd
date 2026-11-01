extends Node3D
const G = preload("res://scripts/geometry.gd")
const Hero = preload("res://scripts/hero.gd")
const Course = preload("res://scripts/course.gd")
const Scenery = preload("res://scripts/scenery.gd")
const Props = preload("res://scripts/props.gd")
const Orbit = preload("res://scripts/orbit.gd")
const UI = preload("res://scripts/ui.gd")
const Sound = preload("res://scripts/audio.gd")
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

func _ready() -> void:
	seed(24)
	make_environment()
	track_root = Node3D.new()
	add_child(track_root)
	scenery = Scenery.new()
	track_root.add_child(scenery)
	scenery.sync(0, 0, 0)
	runner = Hero.new()
	track_root.add_child(runner)
	runner.build(Profile.hero == 1)
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
		kid.build(i == 1)
		kid.position = Vector3(-0.95 if i == 0 else 0.95, 0.45, 0)
		kid.rotation.y = 0.12 if i == 0 else -0.12
		previews.append(kid)
	orbit = Orbit.new()
	add_child(orbit)
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
	get_viewport().msaa_3d = Viewport.MSAA_2X if Profile.quality else Viewport.MSAA_DISABLED
	Engine.max_fps = 60 if Profile.quality else 30
	for light: Node in get_children():
		if light is DirectionalLight3D and light.light_energy > 0.5: light.shadow_enabled = Profile.quality

func make_finish() -> Node3D:
	var p := Node3D.new()
	for s in [-1.0, 1.0]:
		G.box(p, Vector3(0.6, 5.8, 0.8), Vector3(s * 4.7, 2.9, 0), "a98acb")
		G.box(p, Vector3(0.14, 5.2, 0.85), Vector3(s * 4.7, 2.9, 0), "7ef7dd", 0.7)
	G.box(p, Vector3(10, 1.0, 0.9), Vector3(0, 5.7, 0), "565482")
	G.label(p, "АВРОРА  /  ФИНИШ", Vector3(0, 5.65, 0.49), 44)
	for i in 7: G.star(p, 0.28, Vector3((i - 3) * 1.1, 4.7, 0.1))
	return p

func reset_course() -> void:
	for event in events + pickups:
		if is_instance_valid(event.node): event.node.free()
	events = Course.events()
	pickups = Course.stars()
	for carrier in events:
		if carrier.kind != "carrier": continue
		for offset in [-3.0, 0.0, 3.0]:
			pickups.append({"s": carrier.s + offset, "lane": carrier.lane, "y": 2.48, "done": false, "node": null, "carrier": carrier, "offset": offset})
	scenery.clear()
	distance = 0
	speed = 13
	lane = 1
	x = 0
	height = 0
	vertical_speed = 0
	support = 0
	slide_timer = 0
	invulnerable = 0
	lives = 3
	stars = 0
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
	cinematic_hero.build(Profile.hero == 1)
	cinematic_hero.scale = Vector3.ONE * 0.65
	cinematic_hero.position = Vector3(0, 1.0, 0.85)
	cinematic_hero.rotation.y = PI
	finish.visible = true
	if runner.girl != (Profile.hero == 1):
		runner.free()
		runner = Hero.new()
		track_root.add_child(runner)
		runner.build(Profile.hero == 1)
		runner.rotation.y = PI
	runner.visible = true
	runner.position = Vector3.ZERO
	scenery.sync(0, 0, clock)
	finish.position.z = -Course.LENGTH

func show_menu() -> void:
	state = "menu"
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

func start_level() -> void:
	sound.set_paused(false)
	reset_course()
	for kid in previews: kid.visible = false
	camera.fov = 57
	state = "intro"
	cinema_time = 0
	track_root.visible = false
	orbit.visible = true
	hud.cinematic("ПЛАНЕТА АВРОРА", "Кристальные сады ждут своих героев")
	sound.sfx("whoosh")

func begin_run() -> void:
	state = "run"
	track_root.visible = true
	orbit.visible = false
	runner.visible = true
	runner.rotation.y = PI
	ship.visible = false
	hud.playing()
	toast("Добро пожаловать на Аврору!", 3)

func on_action(command: String) -> void:
	if command != "preferences": sound.sfx("click")
	match command:
		"select":
			state = "select"
			hud.selection(Profile.hero)
		"boy", "girl":
			Profile.hero = 1 if command == "girl" else 0
			Profile.save()
			hud.selection(Profile.hero)
		"start", "restart": start_level()
		"menu": show_menu()
		"pause": pause_game()
		"resume": resume_game()
		"settings":
			var previous: String = hud.current
			if previous == "play": pause_game(); previous = "pause"
			hud.settings(previous)
		"close_settings":
			if hud.settings_return == "pause": hud.paused()
			elif hud.settings_return == "select": hud.selection(Profile.hero)
			else: hud.menu()
		"preferences": apply_quality()
		"skip":
			if state == "intro": begin_run()
			elif state == "outro": show_results(true)

func pause_game() -> void:
	if state not in ["run", "intro", "outro", "countdown"]: return
	return_state = state if state != "countdown" else "run"
	state = "paused"
	touch_active = false
	sound.set_paused(true)
	hud.paused()

func resume_game() -> void:
	if state != "paused": return
	if return_state == "run":
		state = "countdown"
		countdown_time = 3.0
		last_count = -1
	else:
		state = return_state
		sound.set_paused(false)
		hud.cinematic("ПЛАНЕТА АВРОРА" if state == "intro" else "ДЕРЖИСЬ, КОСМОС!", "Продолжаем приключение")

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(hud) and not test_mode:
		pause_game()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE, KEY_P:
				if state == "paused": resume_game()
				else: pause_game()
			KEY_LEFT, KEY_A: move_screen(-1)
			KEY_RIGHT, KEY_D: move_screen(1)
			KEY_UP, KEY_W, KEY_SPACE: jump()
			KEY_DOWN, KEY_S: slide()
			KEY_ENTER:
				if state == "menu": on_action("select")
				elif state == "select": start_level()
				elif state in ["intro", "outro"]: on_action("skip")
		return
	if state != "run": return
	var pressed := false
	var released := false
	var pos := Vector2.ZERO
	if event is InputEventScreenTouch:
		if event.pressed and touch_active: return
		if not event.pressed and event.index != touch_id: return
		pressed = event.pressed
		released = not event.pressed
		pos = event.position
		touch_id = event.index
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
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
	elif delta.y < 0: jump()
	else: slide()

func can_act() -> bool:
	return state == "run" and not Course.transitioning(distance)

func move_screen(direction: int) -> void:
	if not can_act(): return
	var mapped := -direction if Course.front_at(distance) > 0.5 else direction
	var target := lane + mapped
	if Course.lanes_at(distance).has(target): lane = target

func jump() -> void:
	if not can_act() or booster == "jet": return
	if height <= support + 0.10:
		vertical_speed = 9.2
		slide_timer = 0
		sound.sfx("jump")
		sound.vocal("jump", Profile.hero == 1)

func slide() -> void:
	if not can_act() or booster == "jet" or height > support + 0.12: return
	slide_timer = 0.85
	sound.sfx("slide")

func _process(dt: float) -> void:
	if state == "paused": return
	if state == "countdown":
		countdown_time -= dt
		var value := maxi(1, int(ceil(countdown_time)))
		if value != last_count:
			last_count = value
			hud.countdown(value)
		if countdown_time <= 0:
			state = "run"
			hud.playing()
			sound.set_paused(false)
		return
	clock += dt
	environment.environment = space_environment if orbit.visible else surface_environment
	sound.advance(dt)
	if state in ["menu", "select", "results"]:
		for i in previews.size():
			var kid := previews[i]
			kid.animate(dt, "win" if state == "results" and Profile.completed else "idle")
			kid.scale = Vector3.ONE * (1.06 if i == Profile.hero and state == "select" else 1.0)
		var z := 7.8
		camera.fov = 57
		camera.position = Vector3(0, 2.9, z)
		camera.look_at(Vector3(0, 1.5, 0))
	elif state in ["intro", "outro"]:
		advance_cinematic(dt)
	elif state == "run":
		update_camera()
		var action_value := "run"
		if booster == "jet": action_value = "jet"
		elif booster == "board": action_value = "board"
		elif slide_timer > 0: action_value = "slide"
		elif height > support + 0.15: action_value = "jump"
		runner.animate(dt, action_value, speed, (lane - 1) * 2.6 - x)
		runner.visible = invulnerable <= 0 or fmod(clock, 0.16) < 0.11
		scenery.sync(distance, dt, clock)
		for event in events:
			if is_instance_valid(event.node) and event.kind in ["jet", "board"]:
				event.node.rotation.y = clock * 1.5
		for pickup in pickups:
			if is_instance_valid(pickup.node): pickup.node.rotation.y = clock * 2.0
		update_hud()
	update_sparks(dt)
	toast_timer = maxf(0, toast_timer - dt)
	hud.toast_label.visible = toast_timer > 0 and state == "run"
	flash_timer = maxf(0, flash_timer - dt)
	hud.flash.color.a = flash_timer * 0.6

func _physics_process(dt: float) -> void:
	if state != "run": return
	simulate(dt)

func simulate(dt: float) -> void:
	var base_speed := lerpf(13.0, 18.5, clampf(distance / Course.LENGTH, 0, 1))
	var multiplier := 1.25 if booster == "jet" else (1.2 if booster == "board" else 1.0)
	var desired := base_speed * multiplier * (0.7 if invulnerable > 1.3 else 1.0)
	desired = lerpf(desired, 8.0, Course.front_at(distance))
	speed = move_toward(speed, desired, dt * 9)
	distance = minf(Course.LENGTH, distance + speed * dt)
	x = move_toward(x, (lane - 1) * Course.LANE_WIDTH, dt * 13)
	slide_timer = maxf(0, slide_timer - dt)
	invulnerable = maxf(0, invulnerable - dt)
	for event in events: event.s += event.speed * dt
	step_timer -= dt
	if step_timer <= 0 and booster.is_empty() and height < support + 0.05 and slide_timer <= 0:
		sound.sfx("step", randf_range(0.93, 1.07))
		step_timer = 0.34
	for pickup in pickups:
		if pickup.has("carrier"): pickup.s = pickup.carrier.s + pickup.offset
	var old_support := support
	support = find_support()
	if booster == "jet":
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
	if distance >= Course.LENGTH and state == "run": finish_level()

func find_support() -> float:
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
			event.node = Props.obstacle(event.kind)
			track_root.add_child(event.node)
			if event.kind == "wall":
				var alien := Props.alien()
				event.node.add_child(alien)
				alien.position = Vector3(1.4, 0, -0.4)
				alien.rotation.y = -0.3
			event.node.set_meta("kind", event.kind)
		event.node.position = Vector3((event.lane - 1) * 2.6, 0, rel)
		if event.kind == "carrier":
			event.node.position.y = sin(clock * 2) * 0.04
	for pickup in pickups:
		var rel: float = distance - pickup.s
		if rel < -155 or rel > 5 or pickup.done:
			if is_instance_valid(pickup.node): pickup.node.queue_free(); pickup.node = null
			continue
		if not is_instance_valid(pickup.node):
			pickup.node = G.star(track_root, 0.32, Vector3.ZERO)
		pickup.node.position = Vector3((pickup.lane - 1) * 2.6, pickup.y, rel)
	finish.position.z = distance - Course.LENGTH

func check_contacts() -> void:
	for pickup in pickups:
		if pickup.done: continue
		if absf(distance - pickup.s) < 1.0 and absf(x - (pickup.lane - 1) * 2.6) < 0.85 and absf(height + 1.0 - pickup.y) < 1.0:
			pickup.done = true
			stars += 1
			sound.sfx("star", 1 + float(stars % 5) * 0.04)
			burst(Vector3(x, height + 1.0, 0), "ffe6aa", 4)
	for event in events:
		if event.done: continue
		var rel: float = distance - event.s
		if absf(x - (event.lane - 1) * 2.6) > 0.95: continue
		if event.kind in ["jet", "board"]:
			if absf(rel) < 1.0 and height < 2: activate_booster(event.kind); event.done = true
			continue
		if absf(rel) > event.length * 0.5 + 0.25: continue
		if event.kind == "ramp": continue
		if event.kind == "carrier" and height >= 1.35: continue
		if booster == "jet": continue
		if event.kind == "barrier" and height > 0.93: continue
		if event.kind == "arch" and slide_timer > 0 and height < 0.15: continue
		if invulnerable > 0: continue
		event.done = true
		take_hit()

func take_hit() -> void:
	if state != "run" or invulnerable > 0: return
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
	var radius := lerpf(11.8, 16.5, front)
	var at := Vector3(sin(angle) * radius, lerpf(5.7, 6.7, front) + minf(height, 2.0) * 0.35, cos(angle) * radius)
	var target := Vector3(x * 0.15, 1.0 + minf(height, 1.5) * 0.3, lerpf(-11.0, -5.0, front))
	camera.fov = lerpf(57, 45, front)
	camera.position = at
	camera.look_at(target)

func update_hud() -> void:
	var hint := ""
	if distance < 85: hint = "Свайп вверх — прыжок\nНа компьютере: ↑ или пробел"
	elif distance < 145: hint = "Свайп вниз — подкат\nНа компьютере: ↓"
	elif distance < 250: hint = "Открылась вторая полоса\nСвайп влево или вправо — перестроиться"
	elif distance > 500 and distance < 585: hint = "Поднимайся по пандусу\nНа левитирующей платформе можно бежать"
	elif Course.transitioning(distance): hint = "Камера меняет ракурс — безопасный участок"
	elif Course.front_at(distance) > 0.9: hint = "Бежим к тебе!\nСвайпы по-прежнему ведут в сторону экрана"
	elif distance > 2030: hint = "Финиш близко!"
	var region := "КРИСТАЛЬНЫЕ САДЫ" if int(distance / 90) % 3 == 0 else ("КОСМИЧЕСКИЙ ПОСТ" if int(distance / 90) % 3 == 1 else "НЕОНОВЫЙ КВАРТАЛ")
	hud.update_hud(lives, stars, distance / Course.LENGTH, "АВРОРА  /  " + region, booster, booster_timer, hint)

func toast(value: String, duration: float = 2.5) -> void:
	hud.toast_label.text = value
	toast_timer = duration

func burst(at: Vector3, color: String, count: int) -> void:
	if not Profile.quality: count = mini(count, 4)
	for i in count:
		var node := G.ball(burst_root, Vector3.ONE * 0.09, at, color, 0.4)
		sparks.append({"node": node, "v": Vector3(randf_range(-2, 2), randf_range(1, 3), randf_range(-2, 2)), "life": 0.6})

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
	if not test_mode:
		Profile.best = maxi(Profile.best, score)
		if success: Profile.completed = true
		Profile.save()

func finish_level() -> void:
	commit_result(true)
	state = "outro"
	launch_sounded = false
	cinema_time = 0
	sound.set_engine(false)
	booster = ""
	runner.visible = true
	runner.rotation.y = 0
	ship.visible = true
	ship.position = Vector3(0, 0.35, -4)
	hud.cinematic("ДЕРЖИСЬ, КОСМОС!", "Аврора покорена — пора к звёздам")
	sound.sfx("win")
	sound.vocal("win", Profile.hero == 1, true)

func advance_cinematic(dt: float) -> void:
	cinema_time += dt
	var short := Profile.reduced_motion
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
			ship.position.y = 0.35 + launch * 8
			runner.position = Vector3(0, boarding * (ship.position.y + 1.1) + sin(boarding * PI) * 1.3, -boarding * 2.7)
			camera.position = Vector3(sin(k * 2.5) * 7, 3 + k * 7, 6 - k * 11)
			camera.look_at(Vector3(0, 1.2 + k * 4, -k * 4))
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
	commit_result(success)
	state = "results"
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
	hud.results(success, stars, score, maxi(Profile.best, score))
