extends Node3D
const G = preload("res://scripts/geometry.gd")
const Hero = preload("res://scripts/hero.gd")
const Crew = preload("res://scripts/crew.gd")
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
var transition_costs:Dictionary={}
var run_hero:=0
var flight_hero:=0
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
var basement_jump:Dictionary={}
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
var carousel: Node3D
var crew_arrows: Node3D
var crew_pointer := -2
var crew_origin := Vector2.ZERO
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
var slide_timer := 0.0
var invulnerable := 0.0
var lives := 3
var stars := 0
var score := 0
var booster := ""
var booster_timer := 0.0
var board_camera_blend := 0.0
var forced_landing:=false
var loop_fall_time:=0.
var loop_fall_velocity:=Vector3.ZERO
var loop_fall_camera_offset:=Vector3.ZERO
var loop_fall_camera_up:=Vector3.UP
var events: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var countdown_time := 0.0
var last_count := -1
var toast_timer := 0.0
var flash_timer := 0.0
var minor_damage:=0.
var field_contact:=false
var suit_fx:=0.
const HORIZONTAL_SWIPE := 16.
const VERTICAL_DRAG := 42.
const VERTICAL_RELEASE := 24.
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
var finish_energy_materials:Array[ShaderMaterial]=[]
var sky_update_wait:=0.0
var mobile_presentation:Control
var perf_sections:Dictionary={}
var probe_active:=false
var city_horizon:Node3D
var hero_fill: DirectionalLight3D
var bypass_camera_blend:=0.
var foot_sparks:MultiMeshInstance3D
var loop_trail:MultiMeshInstance3D
var victory_fx:MultiMeshInstance3D
var start_zone:Node3D
var roadside_billboards:Node3D
var roadside_settlements:Node3D
const TurnTrack=preload("res://scripts/turn_track.gd")
var turn_track:=TurnTrack.new()
var mirror_portals:Node3D
var checkpoint_marker:Node3D
var shop_visitors:Node3D
var furthest_distance:=0.
var configured_planet:=-1
var event_warm_cursor:=0
const OutfitCatalog=preload("res://scripts/outfit_catalog.gd")
const OutfitShop=preload("res://scripts/outfit_shop_ui.gd")
var fitting_room:Node3D
var shop_mode:="local"
var selected_item:=""
var trying_item:=true
var shop_details:=false
var shop_selections:Dictionary={}
const PlanetCache=preload("res://scripts/planet_cache.gd")
var course_ready:=true
var course_generation:=0
var beginning_run:=false
var prepared_flight:Node3D
var prepared_flight_ready:=false
var flight_starting:=false
var preparing:=false
var gpu_warm_queue:Node
var staged_finish:Node3D
var staged_finish_world:=-1
var staged_chunks:Dictionary={}
var staged_chunk_world:=-1
const LoopRoutes=preload("res://scripts/loop_routes.gd")
const Boosters=preload("res://scripts/booster_catalog.gd")
const BoosterStars=preload("res://scripts/booster_stars.gd")
var loop_routes:Node3D
var loop_pose:Dictionary={}
var charge_drops:Array[Dictionary]=[]
var booster_stars: Array[Dictionary] = []
var booster_star_jump := false
var drops_collected:=0
var loop_drop_available:=false
var loop_drop_kind:="jet"
var training_awarded:=false
var version_taps:=0
var version_last_tap:=0
var version_control_id:=0
var alien_scan_wait:=0.
const UpperRoute=preload("res://scripts/upper_route.gd")
const HoverSupport=preload("res://scripts/hover_support.gd")
var auto_landing:=false
var rescue_origin:=0.
var upper_drop_until:=0.
var previous_layout:Dictionary={}
var test_layout_seed:=-1

func prepare_planet_resources(world:int) -> void:
	if test_mode or not preload("res://scripts/mobile_render.gd").enabled(): return
	PlanetCache.request(world)
	while not PlanetCache.ready(world): await get_tree().process_frame
	var collect_stamp:int=Time.get_ticks_usec()
	PlanetCache.collect(world)
	transition_costs["collect_ms"]=(Time.get_ticks_usec()-collect_stamp)/1000.
	transition_costs["cached_world"]=world
	transition_costs["has_finish_cache"]=PlanetCache.finishes.has(world)
	if world!=configured_planet and PlanetCache.finishes.has(world):
		if is_instance_valid(staged_finish): SceneDisposal.retire(staged_finish)
		staged_finish=PlanetCache.finishes[world].instantiate(); staged_finish.hide(); staged_finish_world=world
		await get_tree().process_frame
		await stage_initial_chunks(world)
	if world<Planets.count()-1: PlanetCache.request(world+1)

func stage_initial_chunks(world:int) -> void:
	if staged_chunk_world==world and not staged_chunks.is_empty(): return
	for chunk:Node3D in staged_chunks.values(): SceneDisposal.retire(chunk)
	staged_chunks.clear(); staged_chunk_world=world
	var builder:=Scenery.new(); add_child(builder); builder.hide(); builder.planet=world
	builder.route=TurnTrack.new()
	builder.route.build(world,0,[])
	for index in range(-2,6):
		staged_chunks[index]=builder.make_chunk(index,false)
		await get_tree().process_frame
	builder.free()

func install_staged_chunks() -> void:
	if staged_chunk_world!=planet: return
	for index in staged_chunks:
		var chunk:Node3D=staged_chunks[index]; scenery.prepared[index]=chunk
	staged_chunks.clear(); staged_chunk_world=-1
func _exit_tree() -> void:
	if is_instance_valid(staged_finish): SceneDisposal.retire(staged_finish)
	for chunk:Node3D in staged_chunks.values(): SceneDisposal.retire(chunk)
	PlanetCache.finish_pending()
	for event:Dictionary in events:
		var prepared:Node3D=event.get("prepared_node",null)
		if is_instance_valid(prepared): prepared.free()

func warm_event_next() -> void:
	if test_mode or not preload("res://scripts/mobile_render.gd").enabled(): return
	if event_warm_cursor>=events.size(): return
	var event:Dictionary=events[event_warm_cursor]; event_warm_cursor+=1
	if not is_instance_valid(event.node):
		event.prepared_node=build_event_visual(event)
		warm_geometry_gpu(event.prepared_node,false)

func warm_finish_gpu() -> void:
	warm_geometry_gpu(finish,true)

func warm_geometry_gpu(source:Node3D,city:bool=false,in_room:bool=false) -> void:
	if DisplayServer.get_name()=="headless" or not preload("res://scripts/mobile_render.gd").enabled(): return
	if not is_instance_valid(source): return
	if not is_instance_valid(gpu_warm_queue):
		gpu_warm_queue=preload("res://scripts/gpu_warm_queue.gd").new(); add_child(gpu_warm_queue)
		gpu_warm_queue.setup(surface_environment,[get_node("Sun0"),get_node("Sun1"),get_node("Sun2")],fitting_room.environment)
	gpu_warm_queue.enqueue(source,city,in_room)

func warm_feedback_gpu() -> void:
	if DisplayServer.get_name()=="headless" or not preload("res://scripts/mobile_render.gd").enabled(): return
	var preview_root:=Node3D.new()
	StarPickup.build(preview_root,2,true)
	warm_geometry_gpu(preview_root); preview_root.free()
	if not booster_stars.is_empty():
		var preview := BoosterStars.visual(booster_stars[0].kind,6.)
		warm_geometry_gpu(preview)
		preview.free()
	warm_geometry_gpu(pickup_feedback)
	warm_geometry_gpu(foot_sparks)

func _ready() -> void:
	if preload("res://scripts/mobile_render.gd").enabled(): call_deferred("install_mobile_render")
	else: initialize_game()

func initialize_game() -> void:
	if test_mode: Profile.persistence_enabled=false
	seed(24)
	planet = Profile.selected_planet
	make_environment()
	track_root = Node3D.new()
	add_child(track_root)
	scenery = Scenery.new()
	track_root.add_child(scenery)
	scenery.route=turn_track
	runner = Hero.new()
	track_root.add_child(runner)
	runner.build(Crew.is_female(Profile.hero),Profile.suits[Profile.hero],Profile.hero)
	runner.rotation.y = PI
	finish = Node3D.new() # configure_planet builds the actual city once.
	track_root.add_child(finish)
	sky_planet = Node3D.new()
	track_root.add_child(sky_planet)
	ship = Props.ship()
	track_root.add_child(ship)
	start_zone=preload("res://scripts/start_zone.gd").new(); track_root.add_child(start_zone); start_zone.build()
	roadside_billboards=preload("res://scripts/roadside_billboards.gd").new()
	track_root.add_child(roadside_billboards)
	roadside_settlements=preload("res://scripts/roadside_settlements.gd").new()
	track_root.add_child(roadside_settlements)
	ship.visible = false
	for i in 2:
		var kid := Hero.new()
		track_root.add_child(kid)
		kid.build(i == 1,Profile.suits[i])
		kid.position = Vector3(-0.95 if i == 0 else 0.95, 0.45, 0)
		kid.rotation.y = 0.12 if i == 0 else -0.12
		kid.hide()
		previews.append(kid)
	carousel = preload("res://scripts/crew_carousel.gd").new()
	track_root.add_child(carousel)
	carousel.reset(Profile.hero)
	carousel.hide()
	crew_arrows=preload("res://scripts/crew_arrows.gd").new()
	track_root.add_child(crew_arrows)
	crew_arrows.hide()
	orbit = Orbit.new()
	add_child(orbit)
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
	if is_instance_valid(mobile_presentation): mobile_presentation.add_child(hud)
	else: add_child(hud)
	pickup_feedback=PickupFeedback.new()
	track_root.add_child(pickup_feedback)
	pickup_feedback.build(hud.hud,hud.score_label)
	affection_fx=AffectionFx.new()
	track_root.add_child(affection_fx)
	affection_fx.build()
	foot_sparks=preload("res://scripts/foot_sparks.gd").new(); track_root.add_child(foot_sparks)
	loop_trail=preload("res://scripts/loop_trail.gd").new();track_root.add_child(loop_trail)
	victory_fx=preload("res://scripts/victory_fireworks.gd").new();track_root.add_child(victory_fx)
	victory_fx.salvo.connect(func():sound.sfx("firework_burst"))
	fitting_room=preload("res://scripts/fitting_room.gd").new(); add_child(fitting_room); fitting_room.build(); fitting_room.hide()
	runner.affection.connect(on_affection)
	hud.action.connect(on_action)
	sound = Sound.new()
	add_child(sound)
	menu_crew.laugh.connect(func(girl:bool): sound.vocal("laugh",girl))
	carousel.showcase.laugh.connect(func(girl:bool): sound.vocal("laugh",girl))
	apply_quality()
	set_process(false); set_physics_process(false)
	hud.boot_splash()
	preparing=true
	await prepare_planet_resources(planet)
	preparing=false
	configure_planet()
	install_staged_chunks()
	fitting_room.show_outfit(Crew.is_female(Profile.hero),Profile.current_outfit(),Profile.suits[Profile.hero],Profile.hero)
	warm_geometry_gpu(fitting_room,false,true)
	set_process(true); set_physics_process(true)
	show_menu()
	get_viewport().size_changed.connect(func(): hud._layout())
	hud._layout()
	if OS.is_debug_build() and FileAccess.file_exists("user://mobile_probe.json"):
		probe_active=true
		var probe=load("res://scripts/mobile_probe.gd").new(); probe.app=self; add_child(probe)

func install_mobile_render() -> void:
	mobile_presentation=preload("res://scripts/mobile_render.gd").install(self)
	initialize_game()

func make_environment() -> void:
	environment = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat:=NaturalSky.create()
	sky.sky_material=sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("d5e2ef")
	env.ambient_light_energy = 0.46
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
	hero_fill=DirectionalLight3D.new()
	hero_fill.name="CameraFill"
	hero_fill.light_color=Color("d7edff")
	hero_fill.light_energy=.42
	hero_fill.shadow_enabled=false
	hero_fill.light_cull_mask=1<<9
	hero_fill.light_specular=.35
	add_child(hero_fill)
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
	HoverSupport.set_motion(Profile.reduced_motion)
	preload("res://scripts/flying_platforms.gd").set_motion(Profile.reduced_motion)
	if is_instance_valid(scenery): preload("res://scripts/roadside_biology.gd").set_quality(scenery,Profile.quality)
	if is_instance_valid(scenery): preload("res://scripts/plant_kit.gd").set_quality(scenery,Profile.quality)
	if is_instance_valid(roadside_settlements): preload("res://scripts/plant_kit.gd").set_quality(roadside_settlements,Profile.quality)
	if is_instance_valid(finish): preload("res://scripts/plant_kit.gd").set_quality(finish,Profile.quality)
	var mobile:=preload("res://scripts/mobile_render.gd").enabled()
	get_viewport().msaa_3d = Viewport.MSAA_2X if Profile.quality and not mobile else Viewport.MSAA_DISABLED
	Engine.max_fps = 60
	if is_instance_valid(fitting_room) and is_instance_valid(fitting_room.key_light): fitting_room.key_light.shadow_enabled=Profile.quality
	for light: Node in get_children():
		if light is DirectionalLight3D and light.name=="Sun0":
			light.shadow_enabled = Profile.quality
			if mobile:
				light.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL
				light.directional_shadow_max_distance=22

func make_finish() -> Node3D:
	var p := Node3D.new()
	p.add_child(preload("res://scripts/finish_city.gd").build(planet))
	var gates:=Monuments.create(5+planet*18)
	p.add_child(gates); gates.position.z=-18; gates.scale=Vector3.ONE*1.5
	var bounds:=AABB(); var first_mesh:=true
	for piece:MeshInstance3D in gates.find_children("*","MeshInstance3D",true,false):
		var transform:=piece.transform; var parent:=piece.get_parent()
		while parent!=gates: transform=(parent as Node3D).transform*transform; parent=parent.get_parent()
		var box:AABB=transform*piece.mesh.get_aabb(); bounds=box if first_mesh else bounds.merge(box); first_mesh=false
	var title:=G.label(gates,Planets.get_data(planet).name.to_upper()+" / ФИНИШ",Vector3(0,bounds.end.y+1.1,0),48)
	title.name="MonumentTitle"; title.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	var title_width:float=title.font.get_string_size(title.text,HORIZONTAL_ALIGNMENT_LEFT,-1,48).x
	title.pixel_size=clampf(maxf(6.,minf(11.,bounds.size.x*.9))/maxf(1.,title_width),.008,.022)
	p.set_meta("finish_monuments",true)
	p.add_child(Shops.build())
	if preload("res://scripts/mobile_render.gd").enabled():
		var city:Node3D=p.get_node("FinishCity")
		p.set_meta("city_collision_boxes",city.get_meta("collision_boxes",[]))
		for piece:MeshInstance3D in city.find_children("*","MeshInstance3D",true,false): piece.set_meta("architecture_solid",false)
		G.merge_static(p)
	return p

func reset_course() -> void:
	furthest_distance=0.
	booster_star_jump=false
	sound.set_engine(false)
	touch_active=false;touch_id=-1
	forced_landing=false; loop_fall_time=0.
	auto_landing=false;rescue_origin=0.;upper_drop_until=0.
	loop_trail.clear();victory_fx.stop();runner.loop_power=0.
	course_generation+=1; course_ready=true; beginning_run=false
	var stamp:int=Time.get_ticks_usec()
	run_hero=Profile.hero
	suit_fx=float(OutfitCatalog.levels(Profile.current_outfit()).suit)/5.
	gear_stats=OutfitCatalog.stats(Profile.current_outfit()); shield_charges=gear_stats.shields; rescue_charges=gear_stats.rescues
	sound.reset_pickups()
	call_deferred("warm_feedback_gpu")
	clear_finish_walk()
	Course.layout_seed=0 if test_mode else int(Time.get_ticks_usec())^randi()
	if test_mode and test_layout_seed>=0:Course.layout_seed=test_layout_seed
	if not test_mode:
		if Course.variant()==int(previous_layout.get(planet,-1)):Course.layout_seed+=1
		previous_layout[planet]=Course.variant()
	var retry:Dictionary=Profile.retry_points.get(str(Profile.hero)+":"+str(planet),{})
	if not retry.is_empty() and float(retry.get("distance",0.))>0.:Course.layout_seed=int(retry.get("seed",Course.layout_seed))
	preload("res://scripts/loop_layout.gd").route_seed=Course.layout_seed
	for event in events + pickups:
		if is_instance_valid(event.node): SceneDisposal.retire(event.node)
		var prepared:Node3D=event.get("prepared_node",null)
		if is_instance_valid(prepared): SceneDisposal.retire(prepared)
	transition_costs["cleanup"]=(Time.get_ticks_usec()-stamp)/1000.; stamp=Time.get_ticks_usec()
	configure_planet()
	roadside_billboards.configure(planet,run_hero,Profile.current_outfit(),Course.length_for(planet))
	roadside_settlements.configure(planet,Course.layout_seed,roadside_billboards.marks)
	scenery.settlement_clearings=roadside_settlements.clearings
	transition_costs["configure"]=(Time.get_ticks_usec()-stamp)/1000.; stamp=Time.get_ticks_usec()
	events = Course.events(planet)
	event_warm_cursor=0
	transition_costs["events"]=(Time.get_ticks_usec()-stamp)/1000.; stamp=Time.get_ticks_usec()
	pickups = Course.stars(planet,events)
	if not is_instance_valid(loop_routes):
		loop_routes=LoopRoutes.new(); track_root.add_child(loop_routes)
	loop_routes.setup(planet,Course.layout_seed); loop_routes.reserve(events,pickups)
	UpperRoute.install(events,pickups,planet)
	var middle:float=Course.length_for(planet)*.5
	for i in range(events.size()-1,-1,-1):
		if not events[i].kind.begins_with("upper_") and absf(events[i].s-middle)<events[i].length*.5+28.:events.remove_at(i)
	if not is_instance_valid(mirror_portals):mirror_portals=preload("res://scripts/mirror_portals.gd").new();track_root.add_child(mirror_portals)
	mirror_portals.setup(planet,events)
	Course.reserve_stair_traffic(events)
	turn_track.build(planet,Course.layout_seed,events)
	warm_geometry_gpu(mirror_portals,true)
	if not is_instance_valid(checkpoint_marker):checkpoint_marker=preload("res://scripts/checkpoint_marker.gd").new();track_root.add_child(checkpoint_marker)
	warm_geometry_gpu(loop_routes,true)
	warm_geometry_gpu(loop_trail);warm_geometry_gpu(victory_fx)
	loop_pose={}; drops_collected=0
	for drop:Dictionary in charge_drops:
		if is_instance_valid(drop.node): SceneDisposal.retire(drop.node)
	charge_drops=Boosters.drops(Course.layout_seed,planet)
	var drop_rng:=RandomNumberGenerator.new(); drop_rng.seed=Course.layout_seed+planet*53+113
	loop_drop_available=drop_rng.randf()<Boosters.DROP_CHANCE
	loop_drop_kind=loop_routes.routes[drop_rng.randi_range(0,loop_routes.routes.size()-1)].booster
	if loop_drop_available: loop_routes.install_drop(loop_drop_kind)
	# Share the two-drop cap between the level and its optional routes.
	if loop_drop_available and charge_drops.size()>=2: charge_drops.resize(1)
	for index in range(charge_drops.size()-1,-1,-1):
		var drop:Dictionary=charge_drops[index]
		var safe_lane:=-1
		for candidate_lane in Course.lanes_at(drop.s,planet):
			var safe:=true
			for event:Dictionary in events:
				if absf(event.s-drop.s)>event.length*.5+14.: continue
				if event.kind=="alien" or event.lane==candidate_lane: safe=false; break
			if safe: safe_lane=candidate_lane; break
		if safe_lane<0: charge_drops.remove_at(index)
		else: drop.lane=safe_lane
	for star in booster_stars:
		if is_instance_valid(star.node): SceneDisposal.retire(star.node)
	booster_stars.clear()
	if Profile.booster_stars_enabled(run_hero,planet):
		booster_stars=BoosterStars.place(planet,float(retry.get("distance",0.)),Course.layout_seed,events,loop_routes.routes,mirror_portals.gates,charge_drops)
	training_awarded=Profile.grant_booster_training() if planet==0 else false
	transition_costs["pickups"]=(Time.get_ticks_usec()-stamp)/1000.; stamp=Time.get_ticks_usec()
	scenery.clear()
	scenery.configure_openings(events)
	scenery.prepare_course()
	distance = 0
	speed = 13
	lane = 1
	x = 0
	tunnel_active={}
	basement_active={}
	basement_jump={}
	tunnel_camera_blend=0
	bypass_camera_blend=0
	passage_camera_blend=0
	front_gesture_index=0
	front_gesture_delay=0
	if is_instance_valid(affection_fx): affection_fx.clear()
	if is_instance_valid(runner): runner.cancel_front_gesture()
	height = 0
	vertical_speed = 0
	support = 0
	support_event={}
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
	board_camera_blend=0.
	warned_front = false
	committed = false
	step_timer = 0
	launch_sounded = false
	for spark in sparks:
		if is_instance_valid(spark.node): spark.node.free()
	sparks.clear()
	ship.visible = false
	hud.transition.color.a = 0
	flash_timer = 0.
	minor_damage=0.
	field_contact=false
	hud.flash.color.a = 0.
	transition_costs["reset"]=(Time.get_ticks_usec()-stamp)/1000.; stamp=Time.get_ticks_usec()
	if is_instance_valid(cinematic_hero): cinematic_hero.free()
	cinematic_hero = Hero.new()
	orbit.ship.add_child(cinematic_hero)
	cinematic_hero.build(Crew.is_female(Profile.hero),Profile.suits[Profile.hero],Profile.hero)
	orbit.ship.seat_pilot(cinematic_hero)
	transition_costs["cinematic_hero"]=(Time.get_ticks_usec()-stamp)/1000.; stamp=Time.get_ticks_usec()
	if is_instance_valid(surface_pilot): surface_pilot.free()
	surface_pilot=ship.make_pilot(Crew.is_female(Profile.hero),Profile.suits[Profile.hero],Profile.hero)
	transition_costs["surface_pilot"]=(Time.get_ticks_usec()-stamp)/1000.; stamp=Time.get_ticks_usec()
	finish.visible = true
	if runner.crew_index != Profile.hero:
		runner.free()
		runner = Hero.new()
		track_root.add_child(runner)
		runner.build(Crew.is_female(Profile.hero),Profile.suits[Profile.hero],Profile.hero)
		runner.rotation.y = PI
		runner.affection.connect(on_affection)
	runner.apply_outfit(Profile.current_outfit())
	runner.visible = true
	runner.position = Vector3.ZERO
	runner.rotation=Vector3(0,PI,0)
	transition_costs["runner"]=(Time.get_ticks_usec()-stamp)/1000.; stamp=Time.get_ticks_usec()
	install_staged_chunks(); scenery.sync(0, 0, clock)
	finish.position.z = -Course.length_for(planet)
	transition_costs["initial_chunks"]=(Time.get_ticks_usec()-stamp)/1000.

func show_menu() -> void:
	course_generation+=1; beginning_run=false
	clear_finish_walk()
	carousel.reset(Profile.hero)
	crew_pointer = -2
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
	for kid in previews: kid.hide()
	for i in previews.size(): previews[i].position = Vector3(-0.95 if i == 0 else 0.95, 0.45, 0)
	distance = 0
	scenery.sync(0, 0, clock)
	for event in events + pickups:
		if is_instance_valid(event.node): event.node.visible = false
	hud.menu()

func start_level() -> void:
	course_generation+=1; beginning_run=false; course_ready=true
	if not test_mode and preload("res://scripts/mobile_render.gd").enabled():
		preparing=true; await stage_initial_chunks(planet); preparing=false
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
	hud.arrival(planet)
	sound.sfx("whoosh")
	if not test_mode and preload("res://scripts/mobile_render.gd").enabled(): prepare_course_async()

func prepare_course_async() -> void:
	var generation:int=course_generation
	course_ready=false
	while generation==course_generation and (not scenery.prepare_queue.is_empty() or event_warm_cursor<events.size()):
		if not scenery.prepare_queue.is_empty(): scenery.warm_next()
		else: warm_event_next()
		await get_tree().process_frame
	while generation==course_generation and is_instance_valid(gpu_warm_queue) and not gpu_warm_queue.jobs.is_empty():
		await get_tree().process_frame
	if generation==course_generation: course_ready=true

func begin_run() -> void:
	if beginning_run: return
	beginning_run=true
	var generation:int=course_generation
	if not test_mode and preload("res://scripts/mobile_render.gd").enabled():
		while not course_ready and generation==course_generation: await get_tree().process_frame
		if generation!=course_generation: return
	else: scenery.prepare_all()
	beginning_run=false
	state = "run"
	track_root.visible = true
	orbit.visible = false
	runner.visible = true
	runner.rotation.y = PI
	ship.visible = false
	if is_instance_valid(launch_landmark): launch_landmark.visible = false
	clear_gesture()
	hud.playing()
	hud.update_charges(Profile,booster)
	toast("Учебный подарок: по одному заряду огня и энергии. Кнопки внизу!" if training_awarded else "Добро пожаловать! "+Planets.get_data(planet).name, 5 if training_awarded else 3)
	var retry:Dictionary=Profile.retry_points.get(str(Profile.hero)+":"+str(planet),{})
	if float(retry.get("distance",0.))>0.:
		distance=Course.length_for(planet)*.5;furthest_distance=distance;lane=1;x=0.;height=0.;support=0.;vertical_speed=0.;lives=3;invulnerable=2.5
		for pickup:Dictionary in pickups:
			if pickup.s<distance:pickup.done=true
		for route:Dictionary in loop_routes.routes:
			if route.start<distance:
				route.passed=true;route.taken=true
				for reward:Dictionary in route.rewards:reward.done=true;reward.node.hide()
		spawn_and_update();scenery.sync(distance,0.,clock);update_camera();toast("Продолжаем с середины · 3 сердца",3.)
	if not booster_stars.is_empty():
		toast("На трассе %d звезды бустеров · прыгай у неоновой метки"%booster_stars.size(),3.5)

func on_action(command: String) -> void:
	if preparing: return
	if command=="camera_view":
		Profile.first_person=not Profile.first_person
		if Profile.save()!=OK: Profile.first_person=not Profile.first_person
		hud.refresh_view_switch()
		if state=="run": update_camera()
		return
	if command=="version_tap":
		if hud.current!="settings" or not is_instance_valid(hud.version_button): return
		var now:=Time.get_ticks_msec();var control_id:int=hud.version_button.get_instance_id()
		if now-version_last_tap>2000 or control_id!=version_control_id: version_taps=0
		version_last_tap=now;version_control_id=control_id;version_taps+=1
		if version_taps>=7:
			version_taps=0
			if Profile.debug_unlock():
				hud.version_button.text="Все планеты · +1 000 000 ★";sound.sfx("purchase_confirm")
			else: hud.version_button.text="Не удалось сохранить бонус"
		return
	if command=="flight_fire" and state=="flight": flight.fire(); return
	if command.begins_with("use_charge_"):
		use_charge(command.trim_prefix("use_charge_")); return
	if command.begins_with("buy_charge_"):
		if state=="shop" and gear_context=="explore":
			var result:Dictionary=Profile.buy_charge(command.trim_prefix("buy_charge_"),planet)
			if result.ok: sound.sfx("purchase_confirm")
			show_outfit_shop(result.message)
		return
	if command.begins_with("shop_mode_") and state=="shop":
		shop_mode=command.trim_prefix("shop_mode_"); selected_item=shop_selections.get(str(Profile.hero)+":"+shop_category+":"+shop_mode,""); trying_item=true; show_outfit_shop(); return
	if command=="buy_heart":
		if state=="shop" and gear_context=="explore":
			var result:Dictionary=Profile.buy_heart(planet)
			if result.ok:sound.sfx("purchase_confirm")
			show_outfit_shop(result.message)
		return
	if command.begins_with("shop_cat_") and state=="shop":
		shop_category=command.trim_prefix("shop_cat_"); selected_item=shop_selections.get(str(Profile.hero)+":"+shop_category+":"+shop_mode,""); trying_item=true; fitting_room.face_category(shop_category); show_outfit_shop(); return
	if command.begins_with("preview_item_") and state=="shop":
		selected_item=command.trim_prefix("preview_item_"); trying_item=true; show_outfit_shop(); return
	if command=="shop_details" and state=="shop":
		shop_details=not shop_details; show_outfit_shop(); return
	if command=="fit_reset" and state=="shop":
		fitting_room.zoom=1.; fitting_room.face_category(shop_category); return
	if command in ["purchase_item","wear_item","remove_item","restore_outfit","try_item","fit_zoom_in","fit_zoom_out"] and state=="shop":
		var message:=""
		match command:
			"purchase_item":
				if gear_context=="explore":
					var result:Dictionary=Profile.buy_item(selected_item,planet); message=result.message
					if result.ok: sound.sfx("purchase_confirm")
			"wear_item":
				if Profile.wear_item(selected_item): message="Надето. Характеристики применены"; refresh_equipment()
			"remove_item":
				var item:=OutfitCatalog.get_item(selected_item)
				if not item.is_empty() and Profile.remove_item(item.group): trying_item=false; message="Снято. Вещь осталась в гардеробе"; refresh_equipment()
			"restore_outfit": trying_item=false; message="Показана надетая экипировка"
			"try_item": trying_item=true
			"fit_zoom_in": fitting_room.zoom=clampf(fitting_room.zoom+.1,.8,1.25)
			"fit_zoom_out": fitting_room.zoom=clampf(fitting_room.zoom-.1,.8,1.25)
		show_outfit_shop(message); return
	if command.begins_with("buy_"):
		if state!="shop": return
		var parts:=command.split("_"); var result:Dictionary=Profile.buy_gear(parts[1],int(parts[2]))
		if result.ok: refresh_equipment(); sound.sfx("purchase_confirm")
		GearUI.shop(hud,shop_category,Profile,result.message); return
	if command.begins_with("slot_"):
		if state!="builder": return
		builder_slot=command.trim_prefix("slot_"); state="skin_picker"; GearUI.skins(hud,Profile,builder_slot); return
	if command.begins_with("skin_"):
		if state!="skin_picker": return
		var id:=command.trim_prefix("skin_")
		if not GearUI.allowed_skins(Profile).has(id): return
		var loadout:Dictionary=preload("res://scripts/suit.gd").normalize(Profile.suits[Profile.hero],Crew.is_female(Profile.hero))
		loadout.slots[builder_slot]=id; Profile.suits[Profile.hero]=loadout; Profile.save(); refresh_equipment()
		state="builder"; GearUI.builder(hud,Profile); return
	clear_gesture()
	if command != "preferences": sound.sfx("click")
	if command.begins_with("planet_"):
		var choice := int(command.trim_prefix("planet_"))
		if choice <= Profile.unlocked and choice>=0 and choice<Planets.count():
			if preparing: return
			preparing=true
			if not test_mode:
				state="select"; hud.selection(Profile.hero,choice)
				for button:Button in hud.screen.find_children("*","Button",true,false):
					if button.get_meta("command","")=="start": button.disabled=true; button.text="Подготовка…"
			await prepare_planet_resources(choice)
			preparing=false
			planet = choice
			Profile.selected_planet = planet
			if not test_mode: Profile.save()
			configure_planet()
			install_staged_chunks(); scenery.sync(0,0,clock)
			state="select"
			hud.selection(Profile.hero,planet)
		return
	match command:
		"shop_nearest":
			if state!="explore": return
			var category:=Shops.nearest(finish_walk.avatar.position)
			if category.is_empty(): return
			gear_context="explore"; shop_category=category; finish_walk.stop(); equipment_preview=runner; state="shop"
			shop_mode="local"; selected_item=""; trying_item=true; fitting_room.face_category(category); show_outfit_shop()
		"builder":
			if state not in ["shop","builder","skin_picker"] or gear_context!="explore":return
			selected_item=""; trying_item=true; state="shop"; fitting_room.face_category(shop_category); show_outfit_shop()
		"close_gear":
			if state not in ["shop","builder","skin_picker"]: return
			fitting_room.hide(); track_root.visible=true; camera.h_offset=0.; camera.v_offset=0.
			if gear_context=="explore":
				state="explore"; show_walk_hud()
			else:
				menu_crew.reset(previews,false)
				for kid in previews: kid.hide()
				state="select"; hud.selection(Profile.hero,planet)
		"planets":
			state="planets"
			hud.planets(planet,Profile.unlocked)
		"leave_finish":
			if state=="explore": begin_departure()
		"next": await start_flight(planet)
		"continue_trip": start_flight(int(Profile.pending_trip.get("source",planet)),true)
		"arrive": await arrive_at_planet()
		"skip_flight":
			if state=="flight" and Profile.flown_routes.has(flight.source): complete_flight(true)
		"select":
			state = "select"
			hud.selection(Profile.hero,planet)
		"start", "restart": await start_level()
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
	if state not in ["run", "flight", "intro", "outro", "countdown", "explore","loop_fall"]: return
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
	elif return_state=="loop_fall":
		state="loop_fall"; sound.set_paused(false); hud.playing()
	elif return_state in ["run","flight"]:
		countdown_target = return_state
		state = "countdown"
		countdown_time = 3.0
		last_count = -1
	else:
		state = return_state
		sound.set_paused(false)
		if state == "intro": hud.arrival(planet)
		else: hud.cinematic("Держись, космос!","Продолжаем приключение")

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(hud) and not test_mode:
		pause_game()

func read_crew_input(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_LEFT,KEY_A,KEY_RIGHT,KEY_D]:
			step_crew(-1 if event.keycode in [KEY_LEFT,KEY_A] else 1)
			return true
	if event is InputEventScreenDrag and event.index == crew_pointer:
		carousel.drag = clampf((crew_origin.x-event.position.x)/170.,-2.,2.)
		return true
	if event is InputEventMouseMotion and crew_pointer == -1:
		carousel.drag = clampf((crew_origin.x-event.position.x)/170.,-2.,2.)
		return true
	var pointer: int
	var pressed: bool
	var at: Vector2
	if event is InputEventScreenTouch:
		pointer=event.index
		pressed=event.pressed
		at=event.position
	elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION:
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			step_crew(-1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1)
			return true
		if event.button_index != MOUSE_BUTTON_LEFT: return false
		pointer=-1
		pressed=event.pressed
		at=event.position
	else:
		return false
	if pressed:
		if crew_pointer != -2 or at.y < 268. or at.y > hud.root.size.y-300.:
			return false
		crew_pointer=pointer
		crew_origin=at
		return true
	if pointer != crew_pointer: return false
	crew_pointer=-2
	var delta := at-crew_origin
	var direction := 0
	if absf(delta.x) >= 35. and absf(delta.x) > absf(delta.y):
		direction = -signi(roundi(delta.x)) * clampi(roundi(absf(delta.x)/170.),1,2)
	elif delta.length() < 20.:
		var fraction: float = at.x / hud.root.size.x
		if fraction < .32: direction=-1
		elif fraction > .68: direction=1
	if direction != 0: step_crew(direction)
	else: carousel.drag=0.
	return true

func step_crew(direction: int) -> void:
	var previous: int = Profile.hero
	Profile.hero = carousel.step(direction)
	if Profile.save()!=OK:
		Profile.hero=previous
		carousel.reset(previous)
	hud.update_crew_caption(Profile.hero)

func _input(event: InputEvent) -> void:
	if not is_instance_valid(mobile_presentation) and (forward_crew_drag(event) or forward_play_drag(event)):
		get_viewport().set_input_as_handled()

func forward_crew_drag(event: InputEvent) -> bool:
	return crew_pointer != -2 and is_instance_valid(hud) and hud.current in ["menu","select"] and read_crew_input(event)

func forward_play_drag(event: InputEvent) -> bool:
	# A gesture started on the track keeps its pointer when it crosses a HUD button.
	if touch_id < 0 or not (event is InputEventScreenTouch or event is InputEventScreenDrag):
		return false
	if event.index != touch_id:
		return false
	if event is InputEventScreenTouch:
		if event.pressed:
			return false
		var pending := touch_active
		touch_active = false
		touch_id = -1
		if pending and not event.canceled and not preparing and state in ["run","flight"]:
			swipe(event.position-touch_start)
	elif touch_active and not preparing and state in ["run","flight"]:
		read_swipe_drag(event.position-touch_start)
	return true

func _unhandled_input(event: InputEvent) -> void:
	if forward_play_drag(event): return
	if preparing: return
	if hud.current in ["menu","select"] and read_crew_input(event): return
	if state=="shop":
		if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE: on_action("close_gear")
		else: fitting_room.input(event)
		return
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
			KEY_1: use_charge("jet")
			KEY_2: use_charge("board")
			KEY_ESCAPE, KEY_P:
				if state == "paused": resume_game()
				else: pause_game()
			KEY_LEFT, KEY_A: move_screen(-1)
			KEY_RIGHT, KEY_D: move_screen(1)
			KEY_UP, KEY_W, KEY_SPACE:
				if state=="flight": flight.fire()
				else: vertical_gesture("up")
			KEY_DOWN, KEY_S: vertical_gesture("down")
			KEY_ENTER:
				if state == "menu": on_action("select")
				elif state == "select": start_level()
				elif state in ["intro", "outro"]: on_action("skip")
		return
	if state not in ["run","flight"]: return
	if event is InputEventScreenTouch:
		if event.pressed and touch_id < 0:
			touch_id = event.index
			touch_start = event.position
			touch_active = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.device == InputEvent.DEVICE_ID_EMULATION or touch_id >= 0: return
		if event.pressed:
			touch_start = event.position
			touch_active = true
		elif touch_active:
			touch_active = false
			swipe(event.position-touch_start)
	elif event is InputEventMouseMotion and touch_id < 0 and touch_active:
		read_swipe_drag(event.position-touch_start)

func read_swipe_drag(delta: Vector2) -> void:
	var horizontal := absf(delta.x)
	var vertical := absf(delta.y)
	if (horizontal >= HORIZONTAL_SWIPE and horizontal >= vertical*1.16) or (vertical >= VERTICAL_DRAG and vertical >= horizontal):
		touch_active = false
		swipe(delta)

func swipe(delta: Vector2) -> void:
	if absf(delta.x) > absf(delta.y):
		if absf(delta.x) >= HORIZONTAL_SWIPE: move_screen(1 if delta.x > 0 else -1)
	elif absf(delta.y) >= VERTICAL_RELEASE:
		vertical_gesture("up" if delta.y < 0 else "down")

func can_act() -> bool:
	return state == "run" and not Course.transitioning(distance) and (not is_instance_valid(loop_routes) or loop_routes.active.is_empty())

func move_screen(direction: int) -> void:
	if state == "flight": flight.steer(direction); return
	if not can_act() or not tunnel_active.is_empty() or not basement_active.is_empty(): return
	var mapped := -direction if Course.front_at(distance) > 0.5 else direction
	var target := lane + mapped
	if Course.lanes_at(distance,planet).has(target):
		lane = target
		x = (lane-1)*Course.LANE_WIDTH
		runner.position.x = x

func jump() -> void:
	if not can_act() or booster == "jet" or not tunnel_active.is_empty(): return
	if height <= support + 0.10:
		vertical_speed = 9.2
		basement_jump={}
		if basement_active.is_empty() and height>=-.12:
			for event:Dictionary in events:
				if event.kind!="basement" or event.lane!=lane: continue
				for opening:Vector2 in Basement.openings(event):
					if distance>=opening.x-2.3 and distance<=opening.x+.7:
						basement_jump={"span":opening,"lane":lane}
						break
		booster_star_jump = true
		slide_timer = 0
		roll_timer = 0
		sound.sfx("jump")
		sound.vocal("jump", Crew.is_female(Profile.hero))

func slide() -> void:
	if not can_act() or booster == "jet" or not tunnel_active.is_empty() or height > support + 0.12: return
	if slide_timer>0: return
	slide_timer = 0.85
	sound.sfx("slide")

func clear_gesture() -> void:
	gesture_direction=""
	gesture_age=100

func vertical_gesture(direction: String) -> void:
	if state=="run" and auto_landing:return
	if state=="run" and direction=="down" and height>2.5 and not support_event.is_empty() and support_event.kind.begins_with("upper_") and booster!="jet":
		upper_drop_until=distance+55.;lane=1;begin_auto_landing();vertical_speed=2.2;return
	if direction=="down" and state=="run":
		if is_instance_valid(loop_routes) and not loop_routes.active.is_empty():
			begin_loop_fall(); return
		if booster=="jet":
			booster=""; booster_timer=0.; forced_landing=true; vertical_speed=-1.5
			invulnerable=maxf(invulnerable,1.2); clear_gesture(); sound.set_engine(false)
			sound.sfx("whoosh",.75); toast("Ранец выключен · жёсткая посадка −♥",2.5)
			hud.update_charges(Profile,"fall"); return
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
			sound.vocal("laugh",Crew.is_female(Profile.hero),true)
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
	PlanetCache.poll()
	var perf_start:int=Time.get_ticks_usec() if probe_active else 0
	if state == "paused": return
	turn_track.set_distance(distance if state in ["run","loop_fall"] else 0.)
	if state!="explore": runner.set_first_person(state in ["run","loop_fall"] and first_person_mix()>=.8)
	runner.loop_power=0.
	if is_instance_valid(loop_routes): loop_routes.visible=state in ["run","loop_fall"]
	start_zone.advance(state,distance,countdown_time)
	roadside_billboards.advance(dt,state=="run",distance,Profile.reduced_motion,turn_track)
	roadside_settlements.advance(state in ["run","loop_fall"],distance,turn_track)
	if is_instance_valid(mirror_portals):mirror_portals.visible=state=="run" and planet==10;mirror_portals.present(distance,turn_track,clock,Profile.reduced_motion)
	if is_instance_valid(checkpoint_marker):
		checkpoint_marker.position=turn_track.map(Vector3(0,0,distance-Course.length_for(planet)*.5))
		checkpoint_marker.rotation.y=turn_track.heading(Course.length_for(planet)*.5)
		checkpoint_marker.visible=state=="run" and absf(checkpoint_marker.position.z)<150.
	fitting_room.visible=state=="shop"
	if state!="shop": camera.h_offset=0.; camera.v_offset=0.
	for light:Node in get_children():
		if light is DirectionalLight3D: light.visible=state!="shop"
	if is_instance_valid(city_horizon):
		city_horizon.visible=state=="run" and distance<Course.length_for(planet)-330.
		city_horizon.position=turn_track.map(Vector3(0,0,distance-Course.length_for(planet)))
		city_horizon.rotation.y=turn_track.heading(Course.length_for(planet))
		if state=="run": finish.visible=not city_horizon.visible
	if is_instance_valid(finish) and finish.visible and (state!="run" or distance>1900):
		finish.get_node("FinishCity/RunningResidents").advance(dt)
	if is_instance_valid(shop_visitors) and state=="explore":shop_visitors.advance(dt)
	if state == "countdown":
		countdown_time -= dt
		var value := maxi(1, int(ceil(countdown_time)))
		if value != last_count:
			last_count = value
			hud.countdown(value,countdown_target=="flight")
		if countdown_time <= 0:
			state = countdown_target
			if state=="flight": hud.flight_playing(Profile.flown_routes.has(flight.source))
			else: hud.playing()
			sound.set_paused(false)
		return
	clock += dt
	environment.environment = space_environment if orbit.visible or state in ["flight","flight_result"] else surface_environment
	sky_update_wait-=dt
	if sky_update_wait<=0:
		sky_update_wait=.1
		var sun_directions:=NaturalSky.advance(surface_environment.sky.sky_material,planet,clock,Profile.reduced_motion)
		for i in 3:
			var light:DirectionalLight3D=get_node("Sun%d"%i)
			var direction:Vector3=sun_directions[i]
			if i==0 and state in ["menu","select","planets","results"]:
				direction=Vector3(-.52,.88,.65)
			if i==0: light.light_energy=.72 if state in ["menu","select","planets","results"] else 1.12
			light.look_at_from_position(Vector3.ZERO,-direction,Vector3.UP)
	hud.root.set_meta("daylight",environment.environment==surface_environment)
	var portrait:=state in ["menu","select","planets","results"]
	hero_fill.rotation=camera.rotation+Vector3(-.34,.27,0.)
	hero_fill.light_color=Color("ffe7c9") if portrait else Color("d6ebff")
	hero_fill.light_energy=.58 if portrait else lerpf(.76,.98,Course.front_at(distance)) if state=="run" else .76
	hero_fill.visible=environment.environment==surface_environment and state!="shop"
	sound.advance(dt,state in ["run","flight"],state in ["run","explore"])
	alien_scan_wait-=dt
	if state=="explore" and alien_scan_wait<=0.:
		alien_scan_wait=.4
		var closest:Node3D;var closest_distance:=22.
		for resident:Node3D in finish.get_node("FinishCity/RunningResidents").residents:
			var separation:float=resident.global_position.distance_to(runner.global_position)
			if separation<closest_distance: closest_distance=separation;closest=resident
		if closest: sound.try_alien(closest.global_position+Vector3.UP,closest.get_index()+planet)
	var show_carousel: bool = state == "results" or hud.current in ["menu","select"]
	crew_arrows.visible=hud.current=="select"
	if carousel.visible and not show_carousel: carousel.suspend()
	carousel.visible = show_carousel
	carousel.process_mode = Node.PROCESS_MODE_INHERIT if carousel.visible else Node.PROCESS_MODE_DISABLED
	if not carousel.visible:
		crew_pointer = -2
		carousel.drag = 0.
	if state in ["menu", "select", "results", "planets"]:
		if carousel.visible:
			carousel.present(dt,Profile,state == "results",crew_pointer != -2)
		camera.fov = 57
		camera.position = Vector3(0, 2.9, 7.8)
		camera.look_at(Vector3(0, 1.5, 0))
		if crew_arrows.visible: crew_arrows.present(camera,dt,Profile.reduced_motion)
	elif state=="shop":
		track_root.visible=false; orbit.visible=false; fitting_room.visible=true
		environment.environment=fitting_room.environment
		fitting_room.advance(dt,camera,hud.root.size,shop_category)
	elif state in ["builder","skin_picker"]:
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
		scenery.sync(Course.length_for(planet),dt,clock)
		finish_walk.present(dt,runner,camera,Profile.reduced_motion)
		for material in finish_energy_materials: material.set_shader_parameter("energy_time",clock)
	elif state=="loop_fall":
		loop_routes.present(distance,clock,Profile.reduced_motion,turn_track)
		runner.visible=true; runner.animate(dt,"jump",0.,0.)
		runner.quaternion=runner.quaternion.slerp(Quaternion(Vector3.UP,PI),minf(1.,dt*4.))
		camera.position=runner.position+loop_fall_camera_offset
		camera.look_at(runner.position+Vector3.UP*1.35,loop_fall_camera_up)
		hud.update_hud(0,stars,distance/Course.length_for(planet),Planets.get_data(planet).name,"",0.,"Срыв с петли · повтори этот уровень",Course.star_goal(planet))
		hud.update_charges(Profile,"fall")
	elif state in ["intro", "outro"]:
		pass # Preparation is spread across frames by prepare_course_async().
		ship.advance(dt); orbit.ship.advance(dt)
		advance_cinematic(dt)
	elif state == "run":
		if is_instance_valid(loop_routes): loop_routes.present(distance,clock,Profile.reduced_motion,turn_track)
		tunnel_camera_blend=move_toward(tunnel_camera_blend,0.0 if tunnel_active.is_empty() else 1.0,dt*3.0)
		passage_camera_blend=move_toward(passage_camera_blend,1.0 if height<-.2 else 0.0,dt*8)

		update_camera(dt)
		if distance>1900:
			for material in finish_energy_materials:
				material.set_shader_parameter("activation",smoothstep(Course.length_for(planet)-160.,Course.length_for(planet),distance))
				material.set_shader_parameter("energy_time",clock)
				material.set_shader_parameter("reduced_motion",Profile.reduced_motion)
		var action_value := "run"
		if booster == "jet" or auto_landing: action_value = "jet"
		elif flip_used and height>support+0.1: action_value = "flip"
		elif roll_timer>0: action_value = "roll"
		elif slide_timer > 0: action_value = "slide"
		elif height > support + 0.15: action_value = "jump"
		elif booster == "board": action_value = "board"
		runner.set_meta("riding",booster=="board")
		runner.front_smile=Course.front_at(distance)
		runner.trick_phase = clampf(flip_elapsed/0.85,0,1)
		runner.shadow_ground=support
		update_front_gestures(dt,action_value)
		runner.loop_power=(1.3 if Profile.reduced_motion else 1.85) if booster=="jet" and not loop_routes.active.is_empty() else 0.
		if loop_routes.active.is_empty():
			runner.rotation.x=-atan(turn_track.grade(distance).y)*.65
		runner.animate(dt, action_value, speed, (lane - 1) * 2.6 - x)
		if probe_active: perf_sections["until_hero_ms"]=(Time.get_ticks_usec()-perf_start)/1000.
		var section_start:int=Time.get_ticks_usec() if probe_active else 0
		runner.visible = invulnerable <= 0 or fmod(clock, 0.16) < 0.11
		scenery.sync(distance, dt, clock)
		if probe_active: perf_sections["scenery_ms"]=(Time.get_ticks_usec()-section_start)/1000.
		section_start=Time.get_ticks_usec() if probe_active else 0
		for event in events:
			if is_instance_valid(event.node) and event.kind=="tunnel": Tunnel.advance(event.node,dt,Profile.reduced_motion)
			if is_instance_valid(event.node) and event.kind in ["jet", "board"]:
				event.node.rotation.y = turn_track.heading(event.s)+clock * 1.5
		for pickup in pickups:
			if is_instance_valid(pickup.node): pickup.node.rotation.y = clock * 2.0
		update_hud()
		if probe_active: perf_sections["hud_ms"]=(Time.get_ticks_usec()-section_start)/1000.
	elif state=="flight_loading":
		var pose:Dictionary=orbit.stage(clock,"outro"); camera.position=pose.position; camera.look_at(pose.target)
	elif state in ["flight","flight_result"]:
		var pose: Dictionary = flight.camera_pose()
		camera.position=pose.position
		camera.fov=lerpf(camera.fov,float(pose.get("fov",57.)),minf(1.,dt*3.))
		camera.look_at(pose.target)
		if not Profile.reduced_motion: camera.rotate_object_local(Vector3.BACK,float(pose.get("roll",0.)))
		if state=="flight": hud.update_flight(flight.place,flight.distance/flight.LENGTH,Planets.route_name(flight.source),flight.boost,flight.energy)
	affection_fx.reduced_motion=Profile.reduced_motion
	affection_fx.advance(dt,camera,state=="run" and Course.front_at(distance)>0.8)
	update_sparks(dt)
	pickup_feedback.reduced_motion=Profile.reduced_motion
	pickup_feedback.high_quality=Profile.quality
	pickup_feedback.suit_fx=suit_fx
	var receipt_at:=runner.global_position+Vector3(0,3.0,0)
	if runner.mood in ["slide","roll"]: receipt_at=runner.head.global_position+Vector3(0,0.9,0)
	pickup_feedback.advance(dt,runner.position,camera,state=="run",receipt_at)
	toast_timer = maxf(0, toast_timer - dt)
	hud.toast_label.visible = toast_timer > 0 and state == "run"
	flash_timer = maxf(0, flash_timer - dt)
	hud.flash.color.a = flash_timer * 0.6
	foot_sparks.advance(dt,Vector3(x,support,0),speed,state=="run" and runner.mood=="run" and height<support+.1,Profile.reduced_motion)
	if state in ["run","loop_fall"]: loop_trail.advance(dt,runner,loop_pose,distance,state=="run" and (booster=="jet" or auto_landing),Profile.reduced_motion,Profile.quality,suit_fx)
	else: loop_trail.clear()
	if state=="explore": victory_fx.advance(dt,Profile.reduced_motion,Profile.quality)
	elif victory_fx.celebrating: victory_fx.stop()
	if probe_active: perf_sections["present_ms"]=(Time.get_ticks_usec()-perf_start)/1000.

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
	if state=="loop_fall":
		loop_fall_time+=dt; loop_fall_velocity.y-=24.*dt; runner.position+=loop_fall_velocity*dt
		height=runner.position.y; x=runner.position.x
		if loop_fall_time>=1.05 or height<=.05: show_results(false)
		return
	if state=="explore": finish_walk.advance(dt); return
	if state=="flight":
		flight.advance(dt)
		if flight.done: complete_flight(false)
		return
	if state != "run": return
	simulate(dt)

func simulate(dt: float) -> void:
	if is_instance_valid(loop_routes) and not loop_routes.active.is_empty():
		simulate_loop(dt); return
	if planet==10 and is_instance_valid(mirror_portals) and mirror_portals.advance(self,dt):return
	var perf_start:int=Time.get_ticks_usec() if probe_active else 0
	gesture_age += dt
	roll_timer = maxf(0,roll_timer-dt)
	if flip_used: flip_elapsed+=dt
	if Course.transitioning(distance): clear_gesture()
	var base_speed := lerpf(13.0,18.5,clampf(distance/Course.length_for(planet),0,1))*Course.speed_scale(planet)*float(gear_stats.tempo)
	var multiplier := 1.25 if booster == "jet" else (1.2 if booster == "board" else 1.0)
	var desired := base_speed * multiplier * (0.7 if invulnerable > 1.3 else 1.0)
	desired = lerpf(desired, 6.0, Course.front_at(distance))
	speed = move_toward(speed, desired, dt * 9)
	distance = minf(Course.length_for(planet), distance + speed * dt)
	if not basement_jump.is_empty():
		if lane!=basement_jump.lane or distance>basement_jump.span.y: basement_jump={}
		else:
			# Hold the horizontal jump long enough to bridge the full stairwell
			# even on the slowest planet with a fully equipped suit.
			var span:Vector2=basement_jump.span
			if distance>=span.x and height<.42 and vertical_speed<0.:
				height=.42
				vertical_speed=0.
	record_progress()
	x = move_toward(x, (lane - 1) * Course.LANE_WIDTH, dt * float(gear_stats.lane_speed))
	if is_instance_valid(loop_routes) and loop_routes.try_enter(distance,x,height,booster,lane):
		booster_star_jump=false
		lane=loop_routes.active.lane;auto_landing=false;rescue_origin=0.;vertical_speed=0.;clear_gesture();simulate_loop(0.);return
	slide_timer = maxf(0, slide_timer - dt)
	invulnerable = maxf(0, invulnerable - dt)
	for event in events:
		Course.advance_event(event,distance,speed,planet,dt)
	step_timer -= dt
	if step_timer <= 0 and booster.is_empty() and height < support + 0.05 and slide_timer <= 0:
		sound.sfx("step", randf_range(0.93, 1.07))
		step_timer = 0.34
	for pickup in pickups:
		if pickup.has("anchor"):
			pickup.s = pickup.anchor.s + pickup.offset
			if HoverSupport.suspended(pickup.anchor):
				if not pickup.has("motion_base_y"):pickup.motion_base_y=pickup.y
				pickup.y=pickup.motion_base_y+HoverSupport.offset(pickup.anchor,clock)
	var old_support := support
	var was_underground:=not basement_active.is_empty()
	if not basement_active.is_empty() and distance>basement_active.s+basement_active.length*.5:
		basement_active={}
	support = find_support()
	if (not support_event.is_empty() and HoverSupport.suspended(support_event) or not tunnel_active.is_empty()) and height<=support+.16 and vertical_speed<=0.:
		rescue_origin=support
	if not auto_landing and not forced_landing and booster!="jet" and rescue_origin>2.5 and support<rescue_origin-1.0 and height>support+1.0 and vertical_speed<=0.:
		begin_auto_landing()
	if not support_event.is_empty() and support_event.kind=="basement" and height<-.25:
		basement_active=support_event
	if not tunnel_active.is_empty():
		height=Course.TUNNEL_FLOOR+HoverSupport.offset(tunnel_active,clock)
		vertical_speed=0
	elif auto_landing:
		invulnerable=maxf(invulnerable,.4);vertical_speed=maxf(-3.8,vertical_speed-dt*8.);height+=vertical_speed*dt
		if height<=support:
			height=support;vertical_speed=0.;auto_landing=false;rescue_origin=0.;flip_used=false;invulnerable=maxf(invulnerable,1.);sound.set_engine(false);sound.sfx("land")
	elif booster == "jet":
		var altitude:=3.2
		for e:Dictionary in events:
			if e.kind in ["stairs","stairs_down","skycarrier","passage"] and absf(x-Course.event_x(e,distance))<1.1 and absf(distance-e.s)<e.length*.5+18:
				altitude=maxf(altitude,e.top+1)
		height = move_toward(height, altitude, dt * 6)
		vertical_speed = 0
	elif not support_event.is_empty() and (support_event.kind=="basement" or HoverSupport.suspended(support_event)) and height<=old_support+.16 and vertical_speed<=0 and absf(support-old_support)<.75:
		# Feet follow descending treads, while a deliberate jump remains airborne.
		height=support
		vertical_speed=0
	elif height <= old_support + 0.1 and vertical_speed <= 0 and support > old_support:
		height = support
		vertical_speed = 0
		if was_underground and basement_active.is_empty(): sound.sfx("land")
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
				booster_star_jump = false
			if forced_landing:
				forced_landing=false; lives=maxi(0,lives-1); flash_timer=.4; invulnerable=maxf(invulnerable,1.)
				sound.sfx("hit"); sound.vocal("hit",Crew.is_female(Profile.hero),true)
				if lives==0: show_results(false); return
	if not basement_active.is_empty() and absf(distance-basement_active.s)<basement_active.length*.5-Basement.STAIRS:
		# A real low ceiling prevents jumping above the punch or through the road.
		if height>Basement.FLOOR+.45:
			height=Basement.FLOOR+.45
			vertical_speed=minf(0,vertical_speed)
	update_basement_fields()
	if state!="run": return
	update_tunnel()
	if not booster.is_empty():
		booster_timer -= dt
		if booster_timer <= 0: end_booster()
	runner.position = Vector3(x, height + (0.25 if booster == "board" else 0), 0)
	if probe_active: perf_sections["physics_logic_ms"]=(Time.get_ticks_usec()-perf_start)/1000.
	perf_start=Time.get_ticks_usec() if probe_active else 0
	spawn_and_update()
	if probe_active: perf_sections["spawn_ms"]=(Time.get_ticks_usec()-perf_start)/1000.
	perf_start=Time.get_ticks_usec() if probe_active else 0
	check_contacts()
	update_charge_drops()
	update_booster_stars()
	if probe_active: perf_sections["contacts_ms"]=(Time.get_ticks_usec()-perf_start)/1000.
	if not warned_front and distance > 780:
		warned_front = true
		toast("Дрон впереди! Скоро вид спереди", 4)
		sound.sfx("warning")
		sound.vocal("surprise", Crew.is_female(Profile.hero))
	if distance >= Course.length_for(planet) and state == "run": finish_level()

func simulate_loop(dt:float) -> void:
	sound.set_loop_jet(true,float(loop_routes.active.get("u",0.)))
	speed=move_toward(speed,Course.expected_speed(distance,planet)*float(gear_stats.tempo)*(1.25 if booster=="jet" else 1.2),dt*9.)
	loop_pose=loop_routes.step(speed*dt)
	distance=loop_pose.distance; x=loop_pose.position.x; height=loop_pose.position.y
	record_progress()
	support=height; vertical_speed=0.; slide_timer=0.; roll_timer=0.
	booster_timer=maxf(.35,booster_timer-dt)
	invulnerable=maxf(0.,invulnerable-dt)
	runner.position=loop_pose.position+loop_pose.up*(.25 if booster=="board" else 0.)
	runner.basis=Basis.looking_at(-loop_pose.forward,loop_pose.up)
	for reward:Dictionary in loop_pose.rewards:
		stars+=reward.value
		loop_routes.active.visit_reward+=reward.value
		sound.star_pickup(reward.value,reward.mega)
		pickup_feedback.notify(reward.value,runner.position+loop_pose.up*1.5,reward.mega)
		if reward.value >= 2 and is_instance_valid(runner.crew_avatar): runner.crew_avatar.grin()
	if loop_drop_available and loop_routes.active.booster==loop_drop_kind and loop_routes.active.u>.5 and drops_collected<Boosters.MAX_DROPS:
		loop_drop_available=false
		loop_routes.hide_drops()
		if Profile.change_charge(booster,1): drops_collected+=1; toast("Редкая находка: +1 заряд",1.8)
	spawn_and_update()
	if loop_pose.finished:
		lane=int(loop_routes.active.exit_lane)
		x=(lane-1)*Course.LANE_WIDTH
		loop_routes.active={}; loop_pose={}
		runner.rotation=Vector3(0,PI,0); runner.position=Vector3(x,0,0)
		height=0.; support=0.; vertical_speed=0.; invulnerable=maxf(invulnerable,.7)
		# A safe dismount onto the main road; no immediate altitude jump.
		end_booster();toast("Петля пройдена!",1.8)

func update_charge_drops() -> void:
	for drop:Dictionary in charge_drops:
		var rel:float=distance-drop.s
		if drop.done or rel>3. or drops_collected>=Boosters.MAX_DROPS:
			if is_instance_valid(drop.node): drop.node.hide()
			continue
		if rel< -90.: continue
		if not is_instance_valid(drop.node):
			var icon:=Sprite3D.new(); icon.texture=preload("res://assets/ui/boost-fire.svg") if drop.kind=="jet" else preload("res://assets/ui/boost-energy.svg")
			icon.pixel_size=.018; icon.billboard=BaseMaterial3D.BILLBOARD_ENABLED; track_root.add_child(icon); drop.node=icon
		drop.node.position=turn_track.map(Vector3((drop.lane-1)*2.6,1.6,rel))
		if absf(rel)<1.2 and absf(x-(drop.lane-1)*2.6)<.85 and absf(height)<1.:
			if Profile.change_charge(drop.kind,1):
				drop.done=true; drop.node.hide(); drops_collected+=1; sound.sfx("boost"); toast("+1 "+Boosters.TITLES[drop.kind],1.8)

func update_booster_stars() -> void:
	if state!="run":
		return
	for star in booster_stars:
		var rel: float = distance-star.s
		if star.done or rel>BoosterStars.HIT_DEPTH or rel< -95.:
			if is_instance_valid(star.node): star.node.hide()
			continue
		if not is_instance_valid(star.node):
			var pace := Course.expected_speed(star.s,planet)*float(gear_stats.tempo)
			star.node = BoosterStars.visual(star.kind,pace*.31)
			track_root.add_child(star.node)
		var lane_x: float = (star.lane-1)*Course.LANE_WIDTH
		star.node.position = turn_track.map(Vector3(lane_x,0.,rel))
		star.node.rotation.y = turn_track.heading(star.s)
		star.node.show()
		BoosterStars.animate(star.node,clock,Profile.reduced_motion)
		var jumped := booster_star_jump and height-support>=BoosterStars.MIN_JUMP and absf(height+1.5-BoosterStars.HEIGHT)<.70
		if absf(rel)>BoosterStars.HIT_DEPTH or absf(x-lane_x)>.90 or not jumped or booster=="jet" or auto_landing or forced_landing or not tunnel_active.is_empty() or not basement_active.is_empty():
			continue
		if Profile.change_charge(star.kind,1):
			star.done = true
			star.node.hide()
			sound.sfx("boost")
			burst(star.node.position+Vector3.UP*BoosterStars.HEIGHT,"ff649c" if star.kind=="jet" else "54ffed",8)
			toast("+1 "+Boosters.TITLES[star.kind],2.)

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
	if not tunnel_active.is_empty(): return Course.TUNNEL_FLOOR+HoverSupport.offset(tunnel_active,clock)
	var result := 0.0
	for event:Dictionary in events:
		if event.kind!="basement" or absf(x-Course.event_x(event,distance))>1.15 or absf(distance-event.s)>event.length*.5: continue
		# A basement opening must not override a suspended deck above it.
		if (height>.3 or not basement_jump.is_empty()) and basement_active!=event:continue
		var below:bool=height<-.25 or basement_active==event
		var opening:=false
		for span:Vector2 in Basement.openings(event):
			if distance>=span.x and distance<=span.y: opening=true
		if below or opening:
			support_event=event
			return Basement.floor_height(event,distance)
	for event in events:
		if event.done or absf(distance-event.s)>event.length*.5+4. or not Course.traffic_on_road(event): continue
		if absf(x - Course.event_x(event,distance)) > 0.95: continue
		var rel: float = distance - event.s
		if event.kind.begins_with("upper_"):
			if distance<upper_drop_until or absf(rel)>event.length*.5+.02:continue
			if not UpperRoute.has_floor(event,rel):continue
			var upper_height:=UpperRoute.floor_at(event,rel,clock,x-Course.event_x(event,distance))
			if upper_height<=height+.30 and upper_height>result:result=upper_height;support_event=event
			continue
		if event.kind == "ramp" and rel >= -3 and rel <= 3:
			result = maxf(result, (rel + 3) / 6.0 * 1.48)
		elif event.kind in ["stairs","stairs_down"]:
			if absf(rel)<=event.length*.5+.02:
				var step:float=Course.step_height(event,rel)+HoverSupport.floor_delta(event,clock,x-Course.event_x(event,distance))
				if step<=height+.3 and step>result: result=step; support_event=event
		else:
			var deck:float=maxf(Course.event_deck(event),Course.vehicle_deck(event,rel))
			if event.kind=="skycarrier":deck+=HoverSupport.floor_delta(event,clock,x-Course.event_x(event,distance))
			if deck>0 and absf(rel)<=event.length*.5+.02 and height>=deck-.13:
				if deck>result: result=deck; support_event=event
	return result

func build_event_visual(event:Dictionary) -> Node3D:
	var variant:int=posmod(int(event.get("encounter",0))*7+event.lane*3+planet,preload("res://scripts/cargo_containers.gd").NAMES.size())
	var node:Node3D
	if event.kind.begins_with("upper_"):node=UpperRoute.build(event,planet)
	elif event.kind=="basement": node=Basement.build(event,variant,planet)
	elif event.kind=="glove": node=Basement.glove(planet)
	elif event.kind in ["stairs","stairs_down","skycarrier","passage"]: node=preload("res://scripts/course_features.gd").build(event,variant)
	elif event.kind=="tunnel": node=Tunnel.build(variant,planet)
	else: node=Props.obstacle(event.kind,variant,planet)
	if HoverSupport.suspended(event) and not event.kind.begins_with("upper_") and event.kind!="skycarrier":
		var length_value:float=event.length/maxf(.01,node.scale.z)
		var from_y:float=event.top if event.kind=="stairs_down" else 3.35 if event.kind=="tunnel" else 0.
		var to_y:float=0. if event.kind=="stairs_down" else event.top if event.kind=="stairs" else from_y
		HoverSupport.mount(node,2.12,length_value,from_y,to_y)
	G.recolor(node,Planets.get_data(planet).palette)
	if event.kind=="wall":
		var alien:=Props.alien(); node.add_child(alien); alien.position=Vector3(1.4,0,-.4); alien.rotation.y=-.3
	node.set_meta("kind",event.kind); return node

func spawn_and_update() -> void:
	turn_track.set_distance(distance)
	for event in events:
		var rel: float = distance - event.s
		if rel < -155 or rel > maxf(35,event.length*.5+5) or event.done or not Course.traffic_on_road(event):
			if is_instance_valid(event.node): event.node.queue_free(); event.node = null
			continue
		if not is_instance_valid(event.node):
			var prepared:Node3D=event.get("prepared_node",null)
			if is_instance_valid(prepared): event.node=prepared; event.erase("prepared_node")
			else: event.node=build_event_visual(event)
			track_root.add_child(event.node)
		event.node.position = turn_track.map(Vector3(Course.event_x(event,distance),0,rel))
		event.node.rotation.y = turn_track.heading(event.s)
		if event.kind in ["truck","broken"]: event.node.rotation.y += PI
		if Course.is_road_vehicle(event):
			event.node.rotation.x=atan(turn_track.grade(event.s).y)*(1. if event.kind=="traffic" else -1.)
		if HoverSupport.suspended(event):event.node.position.y+=HoverSupport.offset(event,clock);event.node.rotation.z=HoverSupport.roll(event,clock)
		var transport:Node3D=event.node.get_child(0) if event.kind=="traffic" else event.node
		var cabin:Node3D=transport.get_meta("cabin") if transport.has_meta("cabin") else null
		if cabin: cabin.advance(clock,rel,absf(x-Course.event_x(event,distance))<1.5,Profile.reduced_motion)
		if event.kind=="basement":
			var field:ShaderMaterial=event.node.get_meta("opening_field")
			field.set_shader_parameter("flow_time",0. if Profile.reduced_motion else clock)
			field.set_shader_parameter("proximity",.55 if field_contact and absf(rel)<event.length*.5+2. else 0.)
		if event.kind in ["stairs","stairs_down","basement","upper_stairs","upper_deck"]: preload("res://scripts/stair_flow.gd").advance(event.node,distance,event,Profile.reduced_motion)
		if event.kind=="glove":
			Basement.animate_glove(event.node,rel,speed)
			if rel>-speed*1.25 and rel<0 and not event.get("warned",false):
				event.warned=true
				if height<-.5 and absf(x-Course.event_x(event,distance))<1.:
					sound.sfx("warning",.85)
			if rel<0 and Basement.glove_offset(rel,speed)<1.93 and not event.get("stroke_sounded",false):
				event.stroke_sounded=true
				if height<-.5 and absf(x-Course.event_x(event,distance))<1.25: sound.sfx("glove_extend")
		if event.kind=="skycarrier": event.node.position.y=event.top+HoverSupport.offset(event,clock)
		if event.kind=="passage": preload("res://scripts/course_features.gd").animate(event.node,clock,Profile.reduced_motion)
		if event.kind == "alien":
			var greeting:float=smoothstep(-52.,-30.,rel)*(1.-smoothstep(3.,12.,rel))
			Props.animate_alien(event.node,clock,greeting,runner.global_position+Vector3(0,1.5,0))
			if state=="run" and rel> -16. and rel<3. and not event.get("chatted",false) and int(event.origin)%3!=1:
				if sound.try_alien(event.node.global_position+Vector3.UP,planet+event.lane): event.chatted=true
			if event.get("surprise",false):
				event.node.get_node("AlienBody").rotation.y=PI*.5*float(event.get("cross_direction",1.))
				event.node.visible=rel> -float(event.warning_distance)-7
			var crossing:MultiMeshInstance3D=event.node.get_node("Crossing")
			var lane_count:int=Course.lanes_at(event.s,planet).size()
			crossing.configure(lane_count*2.6)
			crossing.position.x = (-1.3 if lane_count==2 else 0.)-Course.event_x(event,distance)
			event.node.get_node("Crossing").visible = rel > -55 and rel < 8
		if event.kind in ["leaf","gardener","traffic","alien"] and (not is_instance_valid(loop_routes) or loop_routes.active.is_empty()):
			var phase := smoothstep(-45,-18,rel)
			if event.kind=="leaf": event.node.get_node("Leaf").rotation.x=lerpf(-1.25,0,phase)
			var warning: Node3D = event.node.get_node("Warning")
			var warning_distance:float=event.get("warning_distance",60.)
			warning.visible=rel> -warning_distance and rel<0
			warning.scale=Vector3.ONE*(1.0+0.12*sin(clock*16))
			if rel> -warning_distance+5 and not event.get("warned",false):
				event.warned=true
				if absf(x - Course.event_x(event,distance)) < 1.0:
					sound.vocal("surprise", Crew.is_female(Profile.hero))
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
		pickup.node.position=turn_track.map(Vector3((pickup.lane-1)*2.6,pickup.y+.22,rel))
		# Near-contact shrink keeps large rewards from covering the runner's face.
		pickup.node.scale=Vector3.ONE*(.45+.55*smoothstep(0.,2.8,-rel))
		pickup.node.visible=rel<1.05
		StarPickup.animate(pickup.node,clock,pickup.s*.09,Profile.reduced_motion)

	finish.position=turn_track.map(Vector3(0,0,distance-Course.length_for(planet)))
	finish.rotation.y=turn_track.heading(Course.length_for(planet))

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
		if not Course.traffic_on_road(event): continue
		if event.kind.begins_with("upper_"):
			if event.kind=="upper_crate" and height>event.from_height-.25 and height<UpperRoute.floor_at(event,rel,clock,x-Course.event_x(event,distance))-.12 and not event.get("failed",false):
				event.failed=true;take_hit()
			continue
		if event.kind=="glove":
			if height>-.5: continue
			var body_height:float=.78 if roll_timer>0 else 1.45 if slide_timer>0 else 2.97
			if not event.get("failed",false) and Basement.glove_hits(rel,speed,height,body_height):
				event.failed=true; event.cleared=false; take_hit()
			elif not event.get("failed",false) and (roll_timer>0 or slide_timer>0) and height<=Basement.FLOOR+.12:
				event.cleared=true
			continue
		if height< -1.0: continue
		if event.kind == "ramp": continue
		var deck:float=maxf(Course.event_deck(event),Course.vehicle_deck(event,rel))
		if deck>0 and (height>=deck-.13 or (rel>event.length*.5 and event.get("roof_passed",false))):
			if absf(rel)<=event.length*.5+.02 and height>=deck-.13: event.roof_passed=true
			event.cleared = not bool(event.get("failed",false))
			continue
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
		var magnet:float=gear_stats.magnet+(gear_stats.board_magnet if booster=="board" else 0.)
		if pickup.done or absf(distance-pickup.s)>=1.0+magnet: continue
		if not pickup_allowed(pickup): continue
		if absf(distance-pickup.s)<1.0+magnet and absf(x-(pickup.lane-1)*2.6)<0.85+magnet and absf(height+1.0-pickup.y)<1.0+magnet:
			pickup.done = true
			var value := int(pickup.get("value",1))
			stars += value
			if value >= 3: toast("Чисто! +3 ★",0.9)
			sound.star_pickup(value,pickup.get("mega",false))
			pickup_feedback.notify(value,turn_track.map(Vector3((pickup.lane-1)*2.6,pickup.y+.22,distance-pickup.s)),pickup.get("mega",false))
			if value >= 2 and is_instance_valid(runner.crew_avatar): runner.crew_avatar.grin()
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

func update_basement_fields() -> void:
	var contact:=false
	for event:Dictionary in events:
		if event.kind!="basement" or absf(event.s-distance)>event.length*.5+1.: continue
		if Basement.touches_field(event,distance,x,height):
			contact=true
			break
	if contact and not field_contact:
		sound.sfx("field_hum",.95)
		if invulnerable<=0.: take_minor_hit(.20,false)
	field_contact=contact

func take_minor_hit(amount:float, protect:bool=true) -> void:
	minor_damage+=amount
	if minor_damage>=.999:
		minor_damage=0.
		lives-=1
		if Profile.consume_heart(): lives+=1
		if lives<=0: show_results(false)
	flash_timer=.16
	if protect: invulnerable=maxf(invulnerable,.7)

func take_hit() -> void:
	if state != "run" or invulnerable > 0 or not tunnel_active.is_empty(): return
	if test_mode and OS.get_cmdline_user_args().has("--trace-hits"):
		print("HIT DETAIL: s=",snappedf(distance,.01)," y=",snappedf(height,.01)," support=",snappedf(support,.01)," roll=",roll_timer," support_kind=",support_event.get("kind","road"))
	if booster == "board":
		board_armor-=1
		if board_armor<=0: end_booster()
		toast("Платформа приняла удар",1.6)
		take_minor_hit(.20)
		sound.sfx("hit",.8)
		return
	elif booster=="jet":
		booster_timer=maxf(.1,booster_timer-1.1)
		take_minor_hit(.33)
		sound.sfx("hit",.9)
		return
	elif shield_charges>0:
		shield_charges-=1; invulnerable=1.2; sound.sfx("boost"); toast("Щит скафандра: зарядов %d"%shield_charges,1.5); return
	elif lives==1 and rescue_charges>0:
		rescue_charges-=1; invulnerable=2.2
		if basement_active.is_empty():
			activate_booster("jet"); booster_timer=1.5
		toast("Аварийное спасение ранца",1.8); return
	else:
		lives -= 1
		if Profile.consume_heart():
			lives+=1;sound.sfx("purchase_confirm");toast("Запасное сердце восстановило жизнь · осталось %d"%Profile.heart_count(),2.5)
		sound.vocal("hit", Crew.is_female(Profile.hero), true)
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
	sound.vocal("joy", Crew.is_female(Profile.hero), true)
	sound.set_engine(true)
	toast("Реактивный ранец!" if kind == "jet" else "Летающая доска! Поехали!", 2.5)
	burst(Vector3(x, 1, 0), "83f9e7", 12)

func use_charge(kind:String) -> bool:
	if not can_act() or forced_landing or auto_landing or not booster.is_empty() or not tunnel_active.is_empty() or not basement_active.is_empty(): return false
	if not Profile.change_charge(kind,-1):
		toast("Заряды продаются в магазинах на площади",2.); return false
	activate_booster(kind)
	hud.update_charges(Profile,booster)
	return true

func end_booster() -> void:
	booster = ""
	booster_timer = 0
	invulnerable = maxf(invulnerable, 2.2)
	sound.set_engine(false)
	# Descent/safe dismount cannot immediately damage the player.

func begin_loop_fall() -> void:
	auto_landing=false;rescue_origin=0.
	loop_fall_camera_offset=camera.position-runner.position
	if loop_fall_camera_offset.length()<2.: loop_fall_camera_offset=Vector3(0,4.8,7.2)
	loop_fall_camera_up=camera.basis.y
	loop_fall_velocity=loop_pose.get("forward",Vector3.FORWARD)*speed*.20+loop_pose.get("up",Vector3.UP)*.8
	loop_routes.active={}; loop_pose={}; state="loop_fall"; loop_fall_time=0.; forced_landing=false
	lives=0; booster=""; booster_timer=0.; clear_gesture(); touch_active=false;touch_id=-1;sound.set_engine(false)
	runner.set_meta("riding",false); sound.sfx("whoosh",.7); sound.vocal("hit",Crew.is_female(Profile.hero),true)
	runner.loop_power=0.
	hud.update_charges(Profile,"fall")

func begin_auto_landing() -> void:
	auto_landing=true;forced_landing=false;booster="";booster_timer=0.;vertical_speed=minf(-1.,vertical_speed)
	rescue_origin=0.;clear_gesture();sound.set_engine(true);sound.sfx("boost",.8);toast("Ранец страхует · автоматическая посадка",2.5)

func first_person_mix() -> float:
	if not Profile.first_person:return 0.
	if distance<Course.FRONT_START:return 1.-smoothstep(Course.FRONT_START-20.,Course.FRONT_START,distance)
	var end:float=Course.FRONT_END+Course.TRANSITION
	return smoothstep(end,end+20.,distance)

func running_camera_fov() -> float:
	if is_instance_valid(loop_routes) and not loop_routes.active.is_empty():return 57.
	var front:float=Course.front_at(distance)
	var framing:float=pow(clampf(camera_variant-1,0,1),0.65)
	var value:float=lerpf(lerpf(57,50,framing),lerpf(45,36,framing),front)
	value+=front*minf(10,maxf(0,height-1.5)*2)*framing
	value+=9.*(1.-smoothstep(0.,28.,distance))
	var aspect:float=get_viewport().get_visible_rect().size.x/get_viewport().get_visible_rect().size.y
	var aspect_scale:float=clampf(aspect/(540.0/960.0),0.78,1.05)
	return rad_to_deg(2*atan(tan(deg_to_rad(value)*0.5)*lerpf(1.0,aspect_scale,framing)))

func apply_first_person_camera(amount:float) -> void:
		var view_up:=Vector3.UP
		var view_forward:=Vector3.FORWARD
		if not loop_routes.active.is_empty() and not loop_pose.is_empty():
			view_up=loop_pose.up;view_forward=loop_pose.forward
		else:
			view_forward=Vector3(0.,turn_track.view_height(-18.)/18.,-1.).normalized()
		var eye_height:=.65 if roll_timer>0 else 1.1 if slide_timer>0 else 2.55
		var eye:Vector3=runner.position+view_up*eye_height+view_forward*.25
		var pose:=Transform3D(Basis.IDENTITY,eye).looking_at(eye+view_forward*18.-view_up*.8,view_up)
		camera.transform=camera.transform.interpolate_with(pose,amount)
		camera.fov=lerpf(camera.fov,running_camera_fov(),amount);camera.near=.06

func update_camera(dt:float=1./60) -> void:
	var first_person_amount:=first_person_mix()
	if first_person_amount>=.999:
		apply_first_person_camera(1.)
		apply_board_camera_sway(dt)
		return
	if is_instance_valid(loop_routes) and not loop_routes.active.is_empty() and not loop_pose.is_empty():
		var forward:Vector3=loop_pose.forward
		var up:Vector3=loop_pose.up
		# An inverted road must never lie between the camera and the hero.
		var board_lift:float=lerpf(3.5,6.5,smoothstep(.3,.42,float(loop_routes.active.u)))
		if preload("res://scripts/loop_layout.gd").turns(loop_routes.active.kind)>1:board_lift=3.3
		var at_loop:Vector3=runner.position-forward*5.+up*5.+Vector3.UP*.6 if loop_routes.active.booster!="board" else runner.position-forward*4.5+up*board_lift+Vector3.UP
		var target_loop:Vector3=runner.position+forward*(3. if loop_routes.active.booster!="board" else 1.5)+up*1.3
		camera.position=at_loop
		# A small constant off-axis up avoids a discontinuous flip at the pole.
		var horizon:=Vector3(.18,1.,0).normalized()
		camera.look_at(target_loop,horizon); camera.fov=running_camera_fov()
		apply_board_camera_sway(dt)
		return
	var front := Course.front_at(distance)
	var angle := front * PI
	var framing := pow(clampf(camera_variant-1,0,1),0.65)
	var radius := lerpf(lerpf(11.8,7.2,framing),lerpf(16.5,11.5,framing),front)
	radius+=front*maxf(0,height-1.5)*1.5*framing
	var follow_y := height*lerpf(0.35,1.0,framing)
	var at := Vector3(sin(angle)*radius,lerpf(lerpf(5.7,4.8,framing),lerpf(4.5,4.0,framing),front)+follow_y,cos(angle)*radius)
	var target := Vector3(x*lerpf(0.15,0.45,framing),lerpf(1.,2.4,front)+follow_y,lerpf(lerpf(-11,-16,framing),lerpf(-4.,-3.5,framing),front))
	target.z-=front*minf(4.5,maxf(0,height-1.5))*framing
	camera.fov = running_camera_fov()
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
	# A neighbouring airborne passage must never swallow the camera.
	var bypass:=false
	if tunnel_active.is_empty() and height>=-.2:
		for event:Dictionary in events:
			if event.kind not in ["tunnel","passage"]: continue
			var rel:float=distance-event.s
			if at.z>rel-event.length*.5-18 and at.z<rel+event.length*.5+18 and absf(x-(event.lane-1)*2.6)>1.45:
				bypass=true; break
	bypass_camera_blend=move_toward(bypass_camera_blend,1. if bypass else 0.,dt*6.)
	at.x=lerpf(at.x,x,bypass_camera_blend); target.x=lerpf(target.x,x,bypass_camera_blend)
	if passage_blend>0:
		at.x=lerpf(at.x,x+.6,passage_blend)
		at.y=lerpf(at.y,height+3.65,passage_blend)
		target.y=lerpf(target.y,height+1.65,passage_blend)
		target.z=lerpf(target.z,-15.,passage_blend)
	var shell_boxes:=preload("res://scripts/runner_camera_guard.gd").shells(events,distance)
	at.y+=turn_track.view_height(at.z)
	target.y+=turn_track.view_height(target.z)
	at=preload("res://scripts/runner_camera_guard.gd").resolve(at,Vector3(x,height,0),shell_boxes)
	camera.position = at
	camera.look_at(target)
	if first_person_amount>0.:apply_first_person_camera(first_person_amount)
	apply_board_camera_sway(dt)

func apply_board_camera_sway(dt:float) -> void:
	if Profile.reduced_motion:
		board_camera_blend=0.;return
	board_camera_blend=move_toward(board_camera_blend,1. if state=="run" and booster=="board" else 0.,dt*3.)
	if board_camera_blend<=0.:return
	# Rotation only: the eye stays inside the camera's collision-safe position.
	camera.rotate_object_local(Vector3.BACK,sin(clock*2.4)*.012*board_camera_blend)
	camera.rotate_object_local(Vector3.RIGHT,sin(clock*1.7+.6)*.004*board_camera_blend)

func update_hud() -> void:
	hud.update_charges(Profile,"fall" if forced_landing or auto_landing else booster)
	hud.toast_label.position.y=410 if Course.front_at(distance)>0.5 else 223
	var hint := ""
	if distance>=12. and distance<52.: hint = "Свайп вверх — прыжок" if OS.has_feature("mobile") else "↑ или пробел — прыжок"
	elif distance>=79. and distance<116.: hint = "Свайп вниз — подкат" if OS.has_feature("mobile") else "↓ — подкат"
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
		if event.kind in ["leaf","gardener","traffic"] and event.s-distance>15 and event.s-distance<55 and Course.traffic_on_road(event):
			hint="Лист поднимается — выбирай свободную полосу!" if event.kind=="leaf" else "Сигнал! Техника готовится перестроиться"
			break
	for e: Dictionary in events:
		if e.kind=="tunnel" and e.s-distance>22 and e.s-distance<72:
			hint="Тоннель наверху: два свайпа ↑\nМегазвёзды ×2 · внизу можно пробежать"
	if not tunnel_active.is_empty(): hint="Бонусный тоннель · безопасный бег · ★ ×2"
	for e:Dictionary in events:
		if e.kind=="upper_stairs" and e.lane==lane and height>2.5:
			var opening:Vector2=UpperRoute.gap(e)
			var ahead:float=e.s+opening.x-distance
			if ahead>0. and ahead<speed*1.8:hint="Разрыв лестницы · свайп вверх\nПерепрыгни к подсвеченному краю"
		if e.kind=="stairs" and e.lane==lane and absf(distance-e.s)<e.length*.5+30:
			hint="Лестница: %d эт. · %s к платформе\nВниз можно спрыгнуть без урона"%[e.floors,"↑" if e.lower else "↑↑"]
		if e.kind=="basement" and e.lane==lane and absf(distance-e.s)<e.length*.5+25:
			hint="↓ Подкат или ↓↓ на спину\nПроедь под перчаткой · ★ ×2" if height< -1. else "Дыра: ↑ перепрыгни\nИли спускайся по лестнице за ★ ×2"

	var suggested_charge:=""
	if is_instance_valid(loop_routes):
		for route:Dictionary in loop_routes.routes:
			var ahead:float=route.start-distance
			if not route.taken and not route.passed and ahead>=-12. and ahead<maxf(80.,speed*5.):
				suggested_charge=route.booster
				var control_name:String="ОГОНЬ" if route.booster=="jet" else "ЭНЕРГИЯ"
				if lane!=route.lane:
					hint="ПЕТЛЯ · свайп %s\nЗатем нажми %s внизу"%["влево" if route.lane<lane else "вправо",control_name]
				elif Profile.charge_count(route.booster)<=0 and booster!=route.booster:
					hint="Для петли нужен заряд %s\nКупи в магазине · прямо можно обойти"%control_name
				elif booster==route.booster:
					hint="ВХОД ГОТОВ · держи эту полосу\nПетля подхватит автоматически · 72 ★"
				else:
					hint="ПОЛОСА ВЕРНА · нажми %s\nАвтоматический вход в петлю · 72 ★"%control_name
		if not loop_routes.active.is_empty(): hint="Бонусная петля\nЗаряд действует до выхода"
	hud.focus_charge(suggested_charge)
	if tunnel_active.is_empty() and basement_active.is_empty() and (not is_instance_valid(loop_routes) or loop_routes.active.is_empty()):
		for star in booster_stars:
			var ahead: float = star.s-distance
			if star.done or ahead< -BoosterStars.HIT_DEPTH or ahead>maxf(24.,speed*1.7):
				continue
			hint = "ЗВЕЗДА БУСТЕРА · %s\n%s"%[Boosters.TITLES[star.kind],"Прыгни у неоновой метки ↑" if lane==star.lane else ("Свайп влево" if star.lane<lane else "Свайп вправо")]
			break
	var data := Planets.get_data(planet)
	hud.update_hud(lives, stars, distance / Course.length_for(planet), data.name.to_upper(), booster, booster_timer, hint,Course.star_goal(planet))
	hud.show_partial_heart(minor_damage,lives)

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
	var retry_key:=str(run_hero)+":"+str(planet)
	if success:Profile.retry_points.erase(retry_key)
	else:
		Profile.retry_points[retry_key]={"distance":Course.length_for(planet)*.5 if maxf(distance,furthest_distance)>=Course.length_for(planet)*.5 else 0.,"seed":Course.layout_seed}
		Profile.record_booster_loss(run_hero,planet)
	score = int(distance) + stars * 25 + (1000 if success else 0)
	Profile.best = maxi(Profile.best, score)
	Profile.records[planet]=maxi(Profile.records[planet],score)
	Profile.star_records[planet]=maxi(Profile.star_records[planet],stars)
	Profile.credit(stars,run_hero)
	if success:
		Profile.completed = true
		if not Profile.cleared_planets.has(planet): Profile.cleared_planets.append(planet)
		Profile.unlocked=maxi(Profile.unlocked,mini(Planets.count()-1,planet+1))
	if not test_mode: Profile.save()

func record_progress() -> void:
	var middle:float=Course.length_for(planet)*.5
	var crossed:bool=furthest_distance<middle and distance>=middle
	furthest_distance=maxf(furthest_distance,distance)
	if crossed:
		Profile.retry_points[str(run_hero)+":"+str(planet)]={"distance":middle,"seed":Course.layout_seed}
		if not test_mode:Profile.save()
		toast("Контрольная точка сохранена · середина трассы",2.2)

func clear_finish_walk() -> void:
	if is_instance_valid(shop_visitors):SceneDisposal.retire(shop_visitors);shop_visitors=null
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
	finish.position=Vector3.ZERO; finish.rotation.y=0.; finish.visible=true
	scenery.sync(Course.length_for(planet),0,clock); scenery.visible=true
	orbit.visible=false; track_root.visible=true; ship.visible=false
	if is_instance_valid(launch_landmark): launch_landmark.visible=false
	finish_walk=preload("res://scripts/finish_walk.gd").new(); track_root.add_child(finish_walk)
	finish_walk.build(finish,planet,Vector3(x,height,0),scenery)
	shop_visitors=preload("res://scripts/shop_visitors.gd").new();finish.add_child(shop_visitors);shop_visitors.populate(randi(),Profile.hero)
	for piece: MeshInstance3D in finish.find_children("*","MeshInstance3D",true,false):
		var material:=piece.material_override as ShaderMaterial
		if material and material.get_meta("ancient_energy",false): material.set_shader_parameter("activation",1.0)
	show_walk_hud()
	victory_fx.start(planet)
	sound.set_engine(false); sound.sfx("win"); sound.vocal("win",Crew.is_female(Profile.hero),true)

func begin_departure() -> void:
	clear_finish_walk()
	if not test_mode and planet<Planets.count()-1: call_deferred("prepare_flight",planet)
	runner.position=Vector3.ZERO
	state = "outro"
	launch_sounded = false
	cinema_time = 0
	sound.set_engine(false)
	booster = ""
	runner.visible = true
	ship.visible = true
	if is_instance_valid(launch_landmark): launch_landmark.visible=true
	ship.position = Vector3(0, 0.35+(1.48 if planet==2 else 0), -4)
	var seat: Vector3 = runner.get_parent().to_local(surface_pilot.global_position)
	runner.rotation = Vector3(0,atan2(seat.x,seat.z),0)
	hud.cinematic("Держись, космос!",Planets.get_data(planet).name+" покорена — пора к звёздам")

func advance_cinematic(dt: float) -> void:
	cinema_time += dt
	var short := Profile.reduced_motion
	if is_instance_valid(launch_landmark):
		launch_landmark.visible=true
		if planet==1:
			for petal in launch_landmark.find_children("Petal*","Node3D",true,false):
				petal.rotation.x=lerpf(-0.8,0,smoothstep(0,3,cinema_time)) if state=="outro" else 0.0
	if state == "intro":
		var duration := 7.8 if short else 14.0
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
			var depart:=smoothstep(4.4,6.2,local_time)
			ship.rotation=Vector3(0,0,-depart*.18)
			var pad:Vector3=preload("res://scripts/start_zone.gd").LANDING_PAD
			ship.position=pad+Vector3(depart*17.,lerpf(12.,.30,landing)+depart*4.,depart*4.)
			if landing>.80 and not launch_sounded:
				launch_sounded=true
				sound.sfx("land",.72)
				burst(pad+Vector3.UP*.25,Planets.get_data(planet).accent,15)
			ship.set_canopy(smoothstep(1.35,2.05,local_time)*(1.-depart))
			var disembark := smoothstep(2.05,3.9,local_time)
			var walk_to_start:=smoothstep(3.9,6.2,local_time)
			surface_pilot.visible=local_time<2.10
			runner.visible=local_time>=2.10
			var seat_exit: Vector3 = runner.get_parent().to_local(surface_pilot.global_position)
			var landing_spot:=Vector3(7.0,.02,4.2)
			runner.position=seat_exit.lerp(landing_spot,disembark) if disembark<1. else landing_spot.lerp(Vector3.ZERO,walk_to_start)
			runner.position.y+=sin(disembark*PI)*2.35
			var landing_direction := landing_spot-seat_exit
			var exit_heading := atan2(landing_direction.x,landing_direction.z)
			var start_heading := atan2(-landing_spot.x,-landing_spot.z)
			runner.rotation.y=lerp_angle(lerp_angle(exit_heading,start_heading,smoothstep(.65,1.,disembark)),PI,smoothstep(.75,1.,walk_to_start))
			runner.pivot.rotation.z=0.
			var flying_out := local_time>=2.10 and disembark<1.
			runner.animate(dt,"disembark" if flying_out else "walk" if walk_to_start>0. and walk_to_start<1. else "idle",4.5)
			if flying_out:
				if is_instance_valid(runner.crew_avatar):
					runner.crew_avatar.animation.seek(clampf(local_time-2.05,0.,1.85),true)
				runner.pivot.rotation.z=-sin(disembark*PI)*.13
			var k := smoothstep(3.85,6.2,local_time)
			var hero_angle := smoothstep(1.4,2.8,local_time)*(1.-k)
			camera.position = Vector3(15*(1-k)-hero_angle*10.,lerpf(5.7,4.8,k)+hero_angle*.55,lerpf(17.,7.2,k)-hero_angle*1.9)
			var base_target := Vector3(lerpf(11.,0.,k),1.4,lerpf(6.5,-16.,k))
			camera.look_at(base_target.lerp(runner.position+Vector3.UP*1.35,hero_angle*.65))
			camera.fov=lerpf(57.,running_camera_fov(),k)
		if cinema_time >= duration and course_ready:
			runner.pivot.rotation.z=0.
			runner.position=Vector3.ZERO; runner.animate(dt,"idle")
			countdown_target="run"; countdown_time=3.; last_count=-1; state="countdown"; hud.countdown(3)
			hud.stage_label.text=Planets.get_data(planet).name.to_upper()
	else:
		var launch_time := 2.0 if short else 5.0
		var duration := 5.0 if short else 16.0
		if cinema_time < launch_time:
			var k := cinema_time / launch_time
			var boarding := smoothstep(0.25, 0.6, k)
			var launch := smoothstep(0.6, 1.0, k)
			ship.set_canopy(1.-smoothstep(.35,.65,k))
			runner.visible=boarding<.88
			surface_pilot.visible=boarding>=.88
			if launch > 0 and not launch_sounded:
				launch_sounded = true
				sound.sfx("whoosh")
			runner.animate(dt, "jump" if boarding > 0 and boarding < 1 else "win")
			var deck := 1.48 if planet==2 else 0.0
			ship.position.y = 0.35+deck+launch*(21 if planet==3 else 8)
			var seat_entry: Vector3 = runner.get_parent().to_local(surface_pilot.global_position)
			runner.position = Vector3(0,deck,0).lerp(seat_entry,boarding)
			runner.position.y+=sin(boarding*PI)*.6
			var to_seat: Vector3 = seat_entry-runner.position
			if Vector2(to_seat.x,to_seat.z).length_squared()>.001:
				runner.rotation.y=atan2(to_seat.x,to_seat.z)
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
	for star in booster_stars:
		if is_instance_valid(star.node): star.node.hide()
	state = "results"
	carousel.reset(Profile.hero)
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
		previews[i].hide()
		previews[i].position = Vector3(0, 0.45, 0)
	if is_instance_valid(launch_landmark): launch_landmark.visible=false
	hud.results(success, stars, score, maxi(Profile.records[planet], score),planet)

func configure_planet() -> void:
	if is_instance_valid(start_zone):start_zone.configure(planet)
	if configured_planet==planet and is_instance_valid(finish):
		for material in finish_energy_materials: material.set_shader_parameter("activation",0.)
		return
	configured_planet=planet
	var configure_stamp:int=Time.get_ticks_usec()
	var data := Planets.get_data(planet)
	scenery.planet=planet
	scenery.clear()
	scenery.configure_horizon()
	NaturalSky.configure(surface_environment.sky.sky_material,planet)
	surface_environment.fog_density=.0019 if planet>=9 else .00045
	surface_environment.fog_light_color=Color(["b9c6da","b8d4c1","d8c09b","939cb5","8ec7d3","dec8a0","b3a1c4","c0dce9","a66c55","a8a0c2","a2c6dd"][planet])
	for i in 3:
		var sun:DirectionalLight3D=get_node("Sun%d"%i)
		sun.look_at_from_position(Vector3.ZERO,-NaturalSky.DIRECTIONS[i],Vector3.UP)
		sun.light_energy=([1.12,.18,.12][i] if i<NaturalSky.COUNTS[planet] else 0.)
		sun.light_color=[Color("fff0d9"),Color("c7ddff"),Color("ffd2aa")][i]
	orbit.configure(planet)
	ship.configure(planet)
	transition_costs["orbit_ms"]=(Time.get_ticks_usec()-configure_stamp)/1000.; configure_stamp=Time.get_ticks_usec()
	if is_instance_valid(finish): SceneDisposal.retire(finish)
	if is_instance_valid(staged_finish) and staged_finish_world==planet:
		finish=staged_finish; staged_finish=null; staged_finish_world=-1
	else: finish=PlanetCache.finishes[planet].instantiate() if PlanetCache.finishes.has(planet) else make_finish()
	track_root.add_child(finish)
	finish.hide(); finish.position.z=-Course.length_for(planet)
	preload("res://scripts/monument_garden.gd").install(finish,planet,Profile.quality)
	var district:=preload("res://scripts/space_kit_locations.gd").build(planet,true)
	finish.add_child(district)
	scenery.reserve_districts(start_zone.themes[planet].get_node("LaunchSpaceKit"),district)
	transition_costs["finish_ms"]=(Time.get_ticks_usec()-configure_stamp)/1000.; configure_stamp=Time.get_ticks_usec()
	if is_instance_valid(city_horizon): city_horizon.free()
	if preload("res://scripts/mobile_render.gd").enabled():
		city_horizon=preload("res://scripts/finish_city.gd").horizon(planet); track_root.add_child(city_horizon); city_horizon.visible=false
	finish_energy_materials.clear()
	for piece:MeshInstance3D in finish.find_children("*","MeshInstance3D",true,false):
		var material:=piece.material_override as ShaderMaterial
		if material and material.get_meta("ancient_energy",false) and not finish_energy_materials.has(material): finish_energy_materials.append(material)
	for material:ShaderMaterial in finish_energy_materials: material.set_shader_parameter("activation",0.)
	var walk_script:=preload("res://scripts/finish_walk.gd")
	walk_script.prepare_collisions(finish)
	call_deferred("warm_finish_gpu")
	transition_costs["collision_ms"]=(Time.get_ticks_usec()-configure_stamp)/1000.; configure_stamp=Time.get_ticks_usec()
	if is_instance_valid(launch_landmark): launch_landmark.free()
	launch_landmark=Node3D.new()
	track_root.add_child(launch_landmark)
	launch_landmark.name="PlanetLandmark"
	preload("res://scripts/natural_landmarks.gd").populate(launch_landmark,planet,0)
	launch_landmark.visible=false
	if is_instance_valid(sky_planet):
		for child in sky_planet.get_children(): child.free()
		sky_planet.add_child(PlanetVisual.create((planet+1)%Planets.count(),64.,Vector3(-210,170,-1150),true))
		if planet%3==0: sky_planet.add_child(PlanetVisual.create(7,26.,Vector3(340,230,-1300),true))
	transition_costs["sky_ms"]=(Time.get_ticks_usec()-configure_stamp)/1000.

func prepare_flight(source:int) -> void:
	if is_instance_valid(prepared_flight) and prepared_flight.source==source and prepared_flight.pilot_index==Profile.hero: return
	if is_instance_valid(prepared_flight): SceneDisposal.retire(prepared_flight)
	prepared_flight=Flight.new(); add_child(prepared_flight); prepared_flight.hide(); prepared_flight_ready=false
	var building := prepared_flight
	await building.build(source,(Profile.trip_serial+1)*7919+source*313,true)
	if building != prepared_flight: return
	prepared_flight_ready=true
	warm_geometry_gpu(prepared_flight)

func start_flight(source: int, continuing: bool = false) -> void:
	if source<0 or source>=Planets.count()-1: return
	if flight_starting: return
	flight_starting=true
	if is_instance_valid(flight): SceneDisposal.retire(flight)
	var reusable:bool=not continuing and is_instance_valid(prepared_flight) and prepared_flight.source==source and prepared_flight.pilot_index==Profile.hero
	if reusable:
		while not prepared_flight_ready: await get_tree().process_frame
		flight=prepared_flight; prepared_flight=null
	else:
		flight=Flight.new(); add_child(flight); flight.hide()
	flight_target=source+1
	flight_paid=false
	flight_reward=0
	if continuing and not Profile.pending_trip.is_empty():
		flight_id=int(Profile.pending_trip.id)
		flight_hero=int(Profile.pending_trip.get("hero",Profile.hero))
	else:
		Profile.trip_serial+=1
		flight_id=Profile.trip_serial
		flight_hero=Profile.hero
		Profile.pending_trip={"source":source,"target":flight_target,"id":flight_id,"hero":flight_hero}
		if not test_mode: Profile.save()
	if not reusable:
		if not test_mode:
			state="flight_loading"; orbit.show(); track_root.hide()
			hud.cinematic("Готовимся к перелёту",Planets.route_name(source),false,false)
		await flight.build(source,flight_id*7919+source*313,not test_mode)
		warm_geometry_gpu(flight)
	flight.show()
	if not test_mode and preload("res://scripts/mobile_render.gd").enabled(): PlanetCache.request(source+1)
	flight.cue.connect(func(kind):
		if kind=="bump":
			sound.sfx("hit",1.3)
			sound.vocal("hit",Crew.is_female(Profile.hero))
		elif kind=="laser": sound.sfx("whoosh",1.85)
		elif kind=="explosion": sound.sfx("firework_burst",.86)
		elif kind=="arrival":
			sound.sfx("boost",.8)
			sound.vocal("surprise",Crew.is_female(Profile.hero))
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
	flight_starting=false

func complete_flight(skipped: bool) -> void:
	if flight_paid or state!="flight": return
	flight_paid=true
	flight_reward=0 if skipped else (8 if flight.place==1 else 5)
	if flight_id>Profile.last_trip_paid:
		Profile.credit(flight_reward,flight_hero)
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
	if preparing: return
	preparing=true
	await prepare_planet_resources(flight_target)
	preparing=false
	planet=flight_target
	await start_level()

func refresh_equipment() -> void:
	for actor in previews+[runner,cinematic_hero,surface_pilot]:
		if not is_instance_valid(actor): continue
		var owner:int = actor.crew_index if actor.crew_index >= 0 else (1 if actor.girl else 0)
		actor.apply_suit(Profile.suits[owner]); actor.apply_outfit(Profile.outfits[owner])

func show_outfit_shop(message:String="") -> void:
	state="shop"
	selected_item=OutfitShop.show(hud,Profile,planet,shop_category,shop_mode,selected_item,message,gear_context=="explore",trying_item,shop_details)
	shop_selections[str(Profile.hero)+":"+shop_category+":"+shop_mode]=selected_item
	var trial:Dictionary=OutfitCatalog.preview(Profile.current_outfit(),selected_item) if trying_item and Profile.owned_items.has(selected_item) else Profile.current_outfit()
	fitting_room.show_outfit(Crew.is_female(Profile.hero),trial,Profile.suits[Profile.hero],Profile.hero)
