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
const StarPickup=preload("res://scripts/collectible_star.gd")
const Monuments=preload("res://scripts/finish_monuments.gd")
const Tunnel=preload("res://scripts/rocket_tunnel.gd")
const Basement=preload("res://scripts/basement.gd")
const SurfaceStyle=preload("res://scripts/surface_style.gd")
var finish_walk: Node3D
var menu_crew=preload("res://scripts/menu_crew.gd").new()
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
var passage_camera_blend:=0.0
var basement_active:Dictionary={}
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
var support_event:Dictionary={}
var fall_armed:=false
var fall_origin:=0.0
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
var surface_pilot:Node3D
const PlanetVisual=preload("res://scripts/planet_visual.gd")
const Gear=preload("res://scripts/gear_economy.gd")
const GearUI=preload("res://scripts/gear_ui.gd")
const Shops=preload("res://scripts/monument_shops.gd")
var gear_stats:Dictionary=Gear.stats({})
var shield_charges:=0
var rescue_charges:=0
var board_armor:=1
var gear_context:="select"
var shop_category:="suit"
var builder_slot:="torso"
var equipment_preview:Node3D
const NaturalSky=preload("res://scripts/natural_sky.gd")
var step_timer := 0.0
var launch_sounded := false
var pickup_feedback: Node3D
var affection_fx: Node3D
var front_gesture_index:=0
var front_gesture_delay:=0.0

func _ready() -> void:
	if test_mode: Profile.persistence_enabled=false
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
	camera.far = 1600
	camera.near=.1
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
	menu_crew.laugh.connect(func(girl:bool): sound.vocal("laugh",girl))
	apply_quality()
	show_menu()
	get_viewport().size_changed.connect(func(): hud._layout())
	hud._layout()

func make_environment() -> void:
	environment = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat:=NaturalSky.create()
	sky.sky_material=sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("bed0e0")
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled=true; env.fog_light_color=Color("b7d0df"); env.fog_density=.00045; env.fog_sky_affect=.08
	environment.environment = env
	surface_environment = env
	space_environment = env.duplicate(true)
	space_environment.fog_enabled=false
	space_environment.background_mode = Environment.BG_COLOR
	space_environment.background_color = Color("0d1531")
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.name="Sun0"
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
	for i in [1,2]:
		var extra:=DirectionalLight3D.new(); extra.name="Sun%d"%i; extra.light_energy=0; add_child(extra)

func apply_quality() -> void:
	preload("res://scripts/natural_flora.gd").high_quality=Profile.quality
	preload("res://scripts/natural_flora.gd").set_motion(Profile.reduced_motion)
	SurfaceStyle.set_quality(Profile.quality)
	get_viewport().msaa_3d = Viewport.MSAA_2X if Profile.quality else Viewport.MSAA_DISABLED
	Engine.max_fps = 60 if Profile.quality else 30
	for light: Node in get_children():
		if light is DirectionalLight3D and light.light_energy > 0.5: light.shadow_enabled = Profile.quality

func make_finish() -> Node3D:
	var p := Node3D.new()
	p.add_child(preload("res://scripts/finish_city.gd").build(planet))
	var gates:=Monuments.create(5+planet*18)
	p.add_child(gates); gates.position.z=-18; gates.scale=Vector3.ONE*1.5
	for side in [-1,1]:
		var landmark:=Monuments.create([3,0,2,4][Planets.biome(planet)]+planet*18)
		p.add_child(landmark); landmark.scale=Vector3.ONE*0.55
		landmark.position=Vector3(side*23,0,-25)
	p.set_meta("finish_monuments",true)
	p.add_child(preload("res://scripts/finish_arch.gd").build(planet))
	p.add_child(Shops.build())
	return p

func reset_course() -> void:
	gear_stats=Gear.stats(Profile.gear_owned); shield_charges=gear_stats.shields; rescue_charges=gear_stats.rescues
	sound.reset_pickups()
	clear_finish_walk()
	Course.layout_seed=0 if test_mode else int(Time.get_ticks_usec())^randi()
	for event in events + pickups:
		if is_instance_valid(event.node): event.node.free()
	configure_planet()
	events = Course.events(planet)
	pickups = Course.stars(planet,events)
	scenery.clear()
	scenery.configure_openings(events)
	distance = 0
	speed = 13
	lane = 1
	x = 0
	tunnel_active={}
	basement_active={}
	tunnel_camera_blend=0
	passage_camera_blend=0
	front_gesture_index=0
	front_gesture_delay=0
	if is_instance_valid(affection_fx): affection_fx.clear()
	if is_instance_valid(runner): runner.cancel_front_gesture()
	height = 0
	vertical_speed = 0
	support = 0
	support_event={}; fall_armed=false; fall_origin=0
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
	orbit.ship.seat_pilot(cinematic_hero)
	if is_instance_valid(surface_pilot): surface_pilot.free()
	surface_pilot=ship.make_pilot(Profile.hero==1,Profile.suits[Profile.hero])
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
	menu_crew.reset(previews,true)
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
	menu_crew.reset(previews,false)
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
	if command.begins_with("buy_"):
		if state!="shop": return
		var parts:=command.split("_"); var result:Dictionary=Profile.buy_gear(parts[1],int(parts[2]))
		if result.ok: refresh_equipment(); sound.sfx("pickup_mega")
		GearUI.shop(hud,shop_category,Profile,result.message); return
	if command.begins_with("slot_"):
		if state!="builder": return
		builder_slot=command.trim_prefix("slot_"); state="skin_picker"; GearUI.skins(hud,Profile,builder_slot); return
	if command.begins_with("skin_"):
		if state!="skin_picker": return
		var id:=command.trim_prefix("skin_")
		if not GearUI.allowed_skins(Profile).has(id): return
		var loadout:Dictionary=preload("res://scripts/suit.gd").normalize(Profile.suits[Profile.hero],Profile.hero==1)
		loadout.slots[builder_slot]=id; Profile.suits[Profile.hero]=loadout; Profile.save(); refresh_equipment()
		state="builder"; GearUI.builder(hud,Profile); return
	clear_gesture()
	if command != "preferences": sound.sfx("click")
	if command.begins_with("planet_"):
		var choice := int(command.trim_prefix("planet_"))
		if choice <= Profile.unlocked and choice>=0 and choice<Planets.count():
			planet = choice
			Profile.selected_planet = planet
			if not test_mode: Profile.save()
			configure_planet()
			state="select"
			hud.selection(Profile.hero,planet)
		return
	match command:
		"shop_nearest":
			if state!="explore": return
			var category:=Shops.nearest(finish_walk.avatar.position)
			if category.is_empty(): return
			gear_context="explore"; shop_category=category; finish_walk.stop(); equipment_preview=runner; state="shop"
			GearUI.shop(hud,category,Profile)
		"builder":
			if state not in ["select","shop","builder","skin_picker"]: return
			if state=="select":
				gear_context="select"; equipment_preview=previews[Profile.hero]
				for i in previews.size(): previews[i].visible=i==Profile.hero
				equipment_preview.position=Vector3(0,.45,0)
			state="builder"; GearUI.builder(hud,Profile)
		"close_gear":
			if state not in ["shop","builder","skin_picker"]: return
			if gear_context=="explore":
				state="explore"; show_walk_hud()
			else:
				menu_crew.reset(previews,false)
				for kid in previews: kid.visible=true
				state="select"; hud.selection(Profile.hero,planet)
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
	if state in ["shop","builder","skin_picker"] and event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		on_action("close_gear"); return
	if state=="explore":
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode==KEY_SPACE: finish_walk.jump_pending=true; return
			if event.keycode==KEY_ENTER: on_action("leave_finish"); return
			if event.keycode==KEY_E: on_action("shop_nearest"); return
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
	if not can_act() or not tunnel_active.is_empty() or not basement_active.is_empty(): return
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
	if is_instance_valid(finish) and finish.visible:
		finish.get_node("FinishCity/RunningResidents").advance(dt)
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
	var sun_directions:=NaturalSky.advance(surface_environment.sky.sky_material,planet,clock,Profile.reduced_motion)
	for i in 3: (get_node("Sun%d"%i) as DirectionalLight3D).look_at_from_position(Vector3.ZERO,-sun_directions[i],Vector3.UP)
	hud.root.set_meta("daylight",environment.environment==surface_environment)
	sound.advance(dt,state in ["run","flight"])
	if state in ["menu", "select", "results", "planets"]:
		if state=="menu" and hud.current=="menu": menu_crew.advance(dt,previews,Profile.reduced_motion)
		else:
			if menu_crew.active: menu_crew.reset(previews,false)
			for i in previews.size():
				var kid := previews[i]
				kid.animate(dt, "win" if state == "results" and Profile.completed else "idle")
				kid.scale = Vector3.ONE * menu_crew.PREVIEW_SCALE
		var z := 7.8
		camera.fov = 57
		camera.position = Vector3(0, 2.9, z)
		camera.look_at(Vector3(0, 1.5, 0))
	elif state in ["shop","builder","skin_picker"]:
		if is_instance_valid(equipment_preview):
			equipment_preview.animate(dt,"board" if state=="shop" and shop_category=="board" else "idle")
			var viewing_yaw:float=PI*.5 if gear_context=="explore" else 0.
			equipment_preview.rotation.y=viewing_yaw+(PI if state=="shop" and shop_category=="pack" else .15)
			camera.position=equipment_preview.position+Vector3(sin(viewing_yaw)*5.8,1.9,cos(viewing_yaw)*5.8); camera.look_at(equipment_preview.position+Vector3(0,1.35,0)); camera.fov=57
	elif state=="explore":
		var near_shop:=Shops.nearest(finish_walk.avatar.position)
		if is_instance_valid(hud.shop_button):
			hud.shop_button.visible=not near_shop.is_empty()
			if not near_shop.is_empty(): hud.shop_button.text="Магазин: "+Gear.TITLES[near_shop]
		scenery.sync(Course.LENGTH,dt,clock)
		finish_walk.present(dt,runner,camera,Profile.reduced_motion)
		for piece: MeshInstance3D in finish.find_children("*","MeshInstance3D",true,false):
			if piece.material_override.get_meta("ancient_energy",false): piece.material_override.set_shader_parameter("energy_time",clock)
	elif state in ["intro", "outro"]:
		ship.advance(dt); orbit.ship.advance(dt)
		advance_cinematic(dt)
	elif state == "run":
		tunnel_camera_blend=move_toward(tunnel_camera_blend,0.0 if tunnel_active.is_empty() else 1.0,dt*3.0)
		passage_camera_blend=move_toward(passage_camera_blend,1.0 if height<-.2 else 0.0,dt*8)

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
		runner.front_smile=Course.front_at(distance)
		runner.trick_phase = clampf(flip_elapsed/0.85,0,1)
		update_front_gestures(dt,action_value)
		runner.animate(dt, action_value, speed, (lane - 1) * 2.6 - x)
		runner.visible = invulnerable <= 0 or fmod(clock, 0.16) < 0.11
		scenery.sync(distance, dt, clock)
		for event in events:
			if is_instance_valid(event.node) and event.kind=="tunnel": Tunnel.advance(event.node,dt,Profile.reduced_motion)
			if is_instance_valid(event.node) and event.kind in ["jet", "board"]:
				event.node.rotation.y = clock * 1.5
		for pickup in pickups:
			if is_instance_valid(pickup.node): pickup.node.rotation.y = clock * 2.0
		update_hud()
	elif state in ["flight","flight_result"]:
		var pose: Dictionary = flight.camera_pose()
		camera.position=pose.position
		camera.fov=lerpf(camera.fov,float(pose.get("fov",57.)),minf(1.,dt*3.))
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
	var base_speed := lerpf(13.0,18.5,clampf(distance/Course.LENGTH,0,1))*Course.speed_scale(planet)*float(gear_stats.tempo)
	var multiplier := 1.25 if booster == "jet" else (1.2 if booster == "board" else 1.0)
	var desired := base_speed * multiplier * (0.7 if invulnerable > 1.3 else 1.0)
	desired = lerpf(desired, 6.0, Course.front_at(distance))
	speed = move_toward(speed, desired, dt * 9)
	distance = minf(Course.LENGTH, distance + speed * dt)
	x = move_toward(x, (lane - 1) * Course.LANE_WIDTH, dt * float(gear_stats.lane_speed))
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
	if not basement_active.is_empty() and distance>basement_active.s+basement_active.length*.5:
		basement_active={}
		fall_armed=false
	support = find_support()
	if not support_event.is_empty() and support_event.kind=="basement" and height<-.25:
		basement_active=support_event
		fall_armed=false
	if not tunnel_active.is_empty():
		height=Course.TUNNEL_FLOOR
		vertical_speed=0
	elif booster == "jet":
		var altitude:=3.2
		for e:Dictionary in events:
			if e.kind in ["stairs","stairs_down","skycarrier","passage"] and absf(x-Course.event_x(e,distance))<1.1 and absf(distance-e.s)<e.length*.5+18:
				altitude=maxf(altitude,e.top+1)
		height = move_toward(height, altitude, dt * 6)
		vertical_speed = 0
		fall_armed=false
	elif not support_event.is_empty() and support_event.kind=="basement" and height<=old_support+.1 and vertical_speed<=0 and absf(support-old_support)<.75:
		# Feet follow descending treads, while a deliberate jump remains airborne.
		height=support
		vertical_speed=0
		fall_armed=false
	elif height <= old_support + 0.1 and vertical_speed <= 0 and support > old_support:
		height = support
		vertical_speed = 0
	else:
		vertical_speed -= 23.0 * dt
		height += vertical_speed * dt
		if height <= support:
			var rising_step:bool=vertical_speed>0 and not support_event.is_empty() and support_event.kind in ["stairs","stairs_down"] and support-height<.3
			if vertical_speed < -3: sound.sfx("land")
			height = support
			# A small ascending stair lip must not cancel an already-started jump.
			if not rising_step:
				vertical_speed = 0
				flip_used = false
			if support<.01:
				if fall_armed and fall_origin>1.1:
					var before:=lives; take_hit()
					if lives<before: toast("Падение с высоты: −♥ · ищи платформу или спуск",2.5)
				fall_armed=false
	if support>0 and height<=support+.025 and vertical_speed<=0:
		fall_armed=not support_event.is_empty() and support_event.kind in ["stairs","stairs_down","skycarrier"] and support>1.1
		fall_origin=support
	if not basement_active.is_empty() and absf(distance-basement_active.s)<basement_active.length*.5-Basement.STAIRS:
		# A real low ceiling prevents jumping above the punch or through the road.
		if height>Basement.FLOOR+.45:
			height=Basement.FLOOR+.45
			vertical_speed=minf(0,vertical_speed)
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
	support_event={}
	if not tunnel_active.is_empty(): return Course.TUNNEL_FLOOR
	var result := 0.0
	for event:Dictionary in events:
		if event.kind!="basement" or absf(x-Course.event_x(event,distance))>1.15 or absf(distance-event.s)>event.length*.5: continue
		var below:bool=height<-.25 or basement_active==event
		var opening:=false
		for span:Vector2 in Basement.openings(event):
			if distance>=span.x and distance<=span.y: opening=true
		if below or opening:
			support_event=event
			return Basement.floor_height(event,distance)
	for event in events:
		if event.done or absf(x - Course.event_x(event,distance)) > 0.95: continue
		var rel: float = distance - event.s
		if event.kind == "ramp" and rel >= -3 and rel <= 3:
			result = maxf(result, (rel + 3) / 6.0 * 1.48)
		elif event.kind in ["stairs","stairs_down"]:
			if absf(rel)<=event.length*.5+.02:
				var step:float=Course.step_height(event,rel)
				if step<=height+.3 and step>result: result=step; support_event=event
		else:
			var deck: float=Course.event_deck(event)
			if deck>0 and absf(rel)<=event.length*.5+.02 and height>=deck-.13:
				if deck>result: result=deck; support_event=event
	return result

func spawn_and_update() -> void:
	for event in events:
		var rel: float = distance - event.s
		if rel < -155 or rel > maxf(35,event.length*.5+5) or event.done:
			if is_instance_valid(event.node): event.node.queue_free(); event.node = null
			continue
		if not is_instance_valid(event.node):
			var variant:int=posmod(int(event.get("encounter",0))*7+event.lane*3+planet,14)
			if event.kind=="basement": event.node=Basement.build(event,variant,planet)
			elif event.kind=="glove": event.node=Basement.glove(planet)
			elif event.kind in ["stairs","stairs_down","skycarrier","passage"]: event.node=preload("res://scripts/course_features.gd").build(event,variant)
			elif event.kind=="tunnel": event.node=Tunnel.build(variant,planet)
			else: event.node = Props.obstacle(event.kind,variant,planet)
			track_root.add_child(event.node)
			G.recolor(event.node,Planets.get_data(planet).palette)
			if event.kind == "wall":
				var alien := Props.alien()
				event.node.add_child(alien)
				alien.position = Vector3(1.4, 0, -0.4)
				alien.rotation.y = -0.3
			event.node.set_meta("kind", event.kind)
		event.node.position = Vector3(Course.event_x(event,distance), 0, rel)
		if event.kind=="glove": Basement.animate_glove(event.node,rel)
		if event.kind=="skycarrier": event.node.position.y=event.top-1.48*event.node.scale.y
		if event.kind=="passage": preload("res://scripts/course_features.gd").animate(event.node,clock,Profile.reduced_motion)
		if event.kind == "alien":
			Props.animate_alien(event.node,clock)
			if event.get("surprise",false):
				event.node.get_node("AlienBody").rotation.y=PI*.5*float(event.get("cross_direction",1.))
				event.node.visible=rel> -float(event.warning_distance)-7
			event.node.get_node("Crossing").position.x = -Course.event_x(event,distance)
			event.node.get_node("Crossing").visible = rel > -55 and rel < 8
		if event.kind in ["leaf","gardener","traffic","alien"]:
			var phase := smoothstep(-45,-18,rel)
			if event.kind=="leaf": event.node.get_node("Leaf").rotation.x=lerpf(-1.25,0,phase)
			var warning: Node3D = event.node.get_node("Warning")
			var warning_distance:float=event.get("warning_distance",60.)
			warning.visible=rel> -warning_distance and rel<0
			warning.scale=Vector3.ONE*(1.0+0.12*sin(clock*16))
			if rel> -warning_distance+5 and not event.get("warned",false):
				event.warned=true
				if absf(x - Course.event_x(event,distance)) < 1.0:
					sound.vocal("surprise", Profile.hero == 1)
				sound.sfx("warning",0.9 if event.kind=="leaf" else 1.1)
				if event.kind == "alien":
					sound.sfx("honk1",1.2)
					toast("Курьер опаздывает! Обойди или перепрыгни",2.4)
		# Walkable decks stay aligned with their collision/support plane.
	for pickup in pickups:
		var rel: float = distance - pickup.s
		if pickup.has("anchor") and pickup.get("requirement","") in ["duck","cleared","roof"]:
			if pickup.anchor.get("failed",false) or pickup.anchor.get("reward_missed",false): pickup.done=true
		if rel < -155 or rel > 5 or pickup.done:
			if is_instance_valid(pickup.node): pickup.node.queue_free(); pickup.node = null
			continue
		if not is_instance_valid(pickup.node):
			pickup.node=StarPickup.build(track_root,int(pickup.get("value",1)),pickup.get("mega",false))
		pickup.node.position=Vector3((pickup.lane-1)*2.6,pickup.y+.22,rel)
		# Near-contact shrink keeps large rewards from covering the runner's face.
		pickup.node.scale=Vector3.ONE*(.45+.55*smoothstep(0.,2.8,-rel))
		pickup.node.visible=rel<1.05
		StarPickup.animate(pickup.node,clock,pickup.s*.09,Profile.reduced_motion)

	finish.position.z = distance - Course.LENGTH

func check_contacts() -> void:
	for event in events:
		if event.done or event.kind in ["tunnel","basement"]: continue
		if not tunnel_active.is_empty(): continue
		var rel: float = distance - event.s
		if event.kind in ["arch","barrier"] and rel>event.length*0.5+0.25 and not event.get("cleared",false):
			event.reward_missed=true
		if absf(x - Course.event_x(event,distance)) > (0.78 if event.kind == "alien" else 0.95): continue
		if event.kind in ["jet", "board"]:
			if absf(rel) < 1.0 and height < 2: activate_booster(event.kind); event.done = true
			continue
		if absf(rel) > event.length * 0.5 + 0.25: continue
		if event.kind=="glove":
			if height>-.5: continue
			if roll_timer>0 and height<=Basement.FLOOR+.12:
				event.cleared=true; continue
			event.failed=true; event.done=true; take_hit(); continue
		if height< -1.0: continue
		if event.kind == "ramp": continue
		var deck: float=Course.event_deck(event)
		if deck>0 and (height>=deck-.13 or (rel>event.length*.5 and event.get("roof_passed",false))):
			if absf(rel)<=event.length*.5+.02 and height>=deck-.13: event.roof_passed=true
			event.cleared = not bool(event.get("failed",false))
			continue
		if booster == "jet": continue
		if event.kind=="skycarrier":
			var scale_y:float=minf(1,event.top/1.48)
			var underside:float=event.top-.94*scale_y
			if height+(1.45 if slide_timer>0 else 2.97)<underside-.08:
				event.cleared=not bool(event.get("failed",false)); continue
		if event.kind in ["stairs","stairs_down"]:
			if height>=Course.step_height(event,rel)-.3:
				event.cleared=not bool(event.get("failed",false)); continue
		if event.kind=="passage" and height<.18:
			event.cleared=not bool(event.get("failed",false)); continue
		var clean := height >= float(event.get("top",Course.top_of(event.kind)))
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
		var magnet:float=gear_stats.magnet+(gear_stats.board_magnet if booster=="board" else 0.)
		if absf(distance-pickup.s)<1.0+magnet and absf(x-(pickup.lane-1)*2.6)<0.85+magnet and absf(height+1.0-pickup.y)<1.0+magnet:
			pickup.done = true
			var value := int(pickup.get("value",1))
			stars += value
			if value >= 3: toast("Чисто! +3 ★",0.9)
			sound.star_pickup(value,pickup.get("mega",false))
			pickup_feedback.notify(value,Vector3((pickup.lane-1)*2.6,pickup.y+.22,distance-pickup.s),pickup.get("mega",false))
			if is_instance_valid(pickup.node): pickup.node.visible=false

func pickup_allowed(pickup: Dictionary) -> bool:
	var requirement: String = pickup.get("requirement","")
	if requirement == "basement": return basement_active==pickup.anchor and height< -1.0
	if requirement == "tunnel": return not tunnel_active.is_empty() and tunnel_active==pickup.anchor
	if requirement == "passage": return height<.18 and not bool(pickup.anchor.get("failed",false))
	if requirement == "duck":
		return slide_timer>0 and height<0.15 and not bool(pickup.anchor.get("failed",false))
	if requirement == "cleared": return bool(pickup.anchor.get("cleared",false)) and not bool(pickup.anchor.get("failed",false))
	if requirement == "roof": return height>=Course.event_deck(pickup.anchor)-.13 and not bool(pickup.anchor.get("failed",false))
	return true

func take_hit() -> void:
	if state != "run" or invulnerable > 0 or not tunnel_active.is_empty(): return
	if test_mode and OS.get_cmdline_user_args().has("--trace-hits"):
		print("HIT DETAIL: s=",snappedf(distance,.01)," y=",snappedf(height,.01)," support=",snappedf(support,.01)," roll=",roll_timer," support_kind=",support_event.get("kind","road"))
	if booster == "board":
		board_armor-=1
		if board_armor<=0: end_booster()
		toast("Платформа приняла удар",1.6)
	elif shield_charges>0:
		shield_charges-=1; invulnerable=1.2; sound.sfx("boost"); toast("Щит скафандра: зарядов %d"%shield_charges,1.5); return
	elif lives==1 and rescue_charges>0:
		rescue_charges-=1; invulnerable=2.2
		if basement_active.is_empty():
			activate_booster("jet"); booster_timer=1.5
		toast("Аварийное спасение ранца",1.8); return
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
	booster_timer=float(gear_stats.jet_seconds if kind=="jet" else gear_stats.board_seconds)
	if kind=="board": board_armor=gear_stats.board_armor
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
	var passage_blend:float=passage_camera_blend
	at.x=lerpf(at.x,x,passage_blend)
	at.y=lerpf(at.y,height+2.5,passage_blend)
	at.z=lerpf(at.z,4.0,passage_blend)
	target.x=lerpf(target.x,x,passage_blend)
	target.y=lerpf(target.y,height+1.25,passage_blend)
	target.z=lerpf(target.z,-8.0,passage_blend)
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
	for e:Dictionary in events:
		if e.kind=="stairs" and e.lane==lane and absf(distance-e.s)<e.length*.5+30:
			hint="Лестница: %d эт. · %s к платформе\nПрыжок вниз с высоты отнимает ♥"%[e.floors,"↑" if e.lower else "↑↑"]
		if e.kind=="basement" and e.lane==lane and absf(distance-e.s)<e.length*.5+25:
			hint="Дыра: ↑ перепрыгни или беги по лестнице вниз\nВ подвале перчатки: ↓↓ на спину · ★ ×2"

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
		Profile.unlocked=maxi(Profile.unlocked,mini(Planets.count()-1,planet+1))
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
	runner.front_smile=0
	pickup_feedback.reset(); affection_fx.clear()
	finish.position.z=0; finish.visible=true
	scenery.sync(Course.LENGTH,0,clock); scenery.visible=true
	orbit.visible=false; track_root.visible=true; ship.visible=false
	if is_instance_valid(launch_landmark): launch_landmark.visible=false
	finish_walk=preload("res://scripts/finish_walk.gd").new(); track_root.add_child(finish_walk)
	finish_walk.build(finish,planet,Vector3(x,height,0),scenery)
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
			var disembark := smoothstep(1.4,duration-surface_start,local_time)
			surface_pilot.visible=disembark<.12
			runner.visible=disembark>=.12
			runner.position=Vector3(0,(1-disembark)*(ship.position.y+.24)+sin(disembark*PI)*.45,lerpf(-3.8,0,disembark))
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
			runner.visible=boarding<.88
			surface_pilot.visible=boarding>=.88
			if launch > 0 and not launch_sounded:
				launch_sounded = true
				sound.sfx("whoosh")
			runner.animate(dt, "jump" if boarding > 0 and boarding < 1 else "win")
			var deck := 1.48 if planet==2 else 0.0
			ship.position.y = 0.35+deck+launch*(21 if planet==3 else 8)
			runner.position = Vector3(0,(1-boarding)*deck+boarding*(ship.position.y+.24)+sin(boarding*PI)*.6,-boarding*3.8)
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
			if is_instance_valid(cinematic_hero): cinematic_hero.animate(dt,"pilot")
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
	NaturalSky.configure(surface_environment.sky.sky_material,planet)
	for i in 3:
		var sun:DirectionalLight3D=get_node("Sun%d"%i)
		sun.look_at_from_position(Vector3.ZERO,-NaturalSky.DIRECTIONS[i],Vector3.UP)
		sun.light_energy=([.82,.18,.12][i] if i<NaturalSky.COUNTS[planet] else 0.)
		sun.light_color=[Color("fff0d9"),Color("c7ddff"),Color("ffd2aa")][i]
	orbit.configure(planet)
	if is_instance_valid(finish): finish.free()
	finish=make_finish()
	track_root.add_child(finish)
	if is_instance_valid(launch_landmark): launch_landmark.free()
	launch_landmark=Node3D.new()
	track_root.add_child(launch_landmark)
	launch_landmark.name="PlanetLandmark"
	match Planets.biome(planet):
		1:
			for i in 5: preload("res://scripts/natural_flora.gd").tree(launch_landmark,Vector3((i-2)*3,0,-6-abs(i-2)*2),planet,i)
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
		for child in sky_planet.get_children(): child.free()
		sky_planet.add_child(PlanetVisual.create((planet+1)%Planets.count(),64.,Vector3(-210,170,-1150),true))
		if planet%3==0: sky_planet.add_child(PlanetVisual.create(7,26.,Vector3(340,230,-1300),true))

func start_flight(source: int, continuing: bool = false) -> void:
	if source<0 or source>=Planets.count()-1: return
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

func refresh_equipment() -> void:
	for actor in previews+[runner,cinematic_hero,surface_pilot]:
		if not is_instance_valid(actor): continue
		actor.apply_suit(Profile.suits[1 if actor.girl else 0]); actor.apply_equipment(Profile.gear_owned)
