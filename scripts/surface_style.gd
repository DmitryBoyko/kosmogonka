extends RefCounted
const Planets=preload("res://scripts/planets.gd")
const SHADER=preload("res://assets/surfaces/surface.gdshader")
const GLOBE_SHADER=preload("res://assets/planet.gdshader")
const GROUND := [preload("res://assets/surfaces/aurora_ground_v1.png"),preload("res://assets/surfaces/flora_ground_v1.png"),preload("res://assets/surfaces/amber_ground_v1.png"),preload("res://assets/surfaces/neon_ground_v1.png")]
const ROAD_PALETTES := ["303c57","514632","7b5635","19224b","315866","98774a","53405b","687f91","493336","2c233f","3b536c"]
const ROAD=preload("res://assets/surfaces/magnetic_road_v1.png")
static var cache: Dictionary={}
static var high_quality:=true

static func ground(planet: int, hill: bool = false) -> ShaderMaterial:
	var key:="ground%d_%s" % [planet,str(hill)]
	if cache.has(key): return cache[key]
	var mat:=ShaderMaterial.new()
	if planet==4 and not hill:
		mat.shader=preload("res://assets/terrain_kit/ocean.gdshader")
		mat.set_shader_parameter("waves",preload("res://assets/terrain_kit/ocean_wave.tres"))
		mat.set_shader_parameter("wave_detail",1. if high_quality else 0.)
		cache[key]=mat
		return mat
	mat.shader=preload("res://assets/surfaces/natural_ground.gdshader")
	mat.set_shader_parameter("grass_map",preload("res://assets/surfaces/leafy_grass_diff_1k.jpg"))
	mat.set_shader_parameter("tint",[Color("cad7b4"),Color("c1e2ac"),Color("ddcca0"),Color("a4c9bb")][Planets.biome(planet)])
	mat.set_shader_parameter("planet_index",planet);mat.set_shader_parameter("hill",hill)

	cache[key]=mat
	return mat

static func distant_ground(planet: int) -> ShaderMaterial:
	var key := "ground%d_horizon" % planet
	if not cache.has(key):
		var material := ground(planet).duplicate() as ShaderMaterial
		if planet!=4: material.set_shader_parameter("distant_terrain",true)
		cache[key] = material
	return cache[key]

static func road_style(planet:int) -> int:
	return [0,1,2,0,0,1,1,2,2,0,2][planet]

static func road_texture(planet:int) -> Texture2D:
	if road_style(planet)==0: return ROAD
	return GROUND[planet%GROUND.size()]

static func road(planet: int, lane_count: int) -> ShaderMaterial:
	var key:="road%d_%d" % [planet,lane_count]
	if cache.has(key): return cache[key]
	var mat:=ShaderMaterial.new()
	mat.shader=SHADER
	mat.set_shader_parameter("surface_texture",road_texture(planet))
	mat.set_shader_parameter("road_style",road_style(planet))
	mat.set_shader_parameter("road",true)
	mat.set_shader_parameter("road_color",Color(ROAD_PALETTES[planet]))
	mat.set_shader_parameter("accent_color",Color(Planets.get_data(planet).accent))
	mat.set_shader_parameter("repeats",Vector2(lane_count,6))
	mat.set_shader_parameter("relief",0.12 if high_quality else 0.0)
	cache[key]=mat
	return mat

static func set_quality(enabled: bool) -> void:
	high_quality=enabled
	for key: String in cache:
		if key.begins_with("road"): cache[key].set_shader_parameter("relief",0.12 if enabled else 0.0)
		if key in ["ground4_false","ground4_horizon"]: cache[key].set_shader_parameter("wave_detail",1. if enabled else 0.)

static func globe(planet:int) -> ShaderMaterial:
	return preload("res://scripts/planet_visual.gd").surface(planet)

static func edge(planet: int) -> ShaderMaterial:
	var key:="edge%d" % planet
	if cache.has(key): return cache[key]
	var mat:=ShaderMaterial.new(); mat.shader=preload("res://assets/surfaces/road_edge.gdshader")
	mat.set_shader_parameter("tint",Color(Planets.get_data(planet).accent).lightened(0.2))
	mat.set_shader_parameter("palette_offset",float(planet))
	cache[key]=mat
	return mat

static func animate_edges(distance: float, clock: float, reduced: bool, heading: float=0., lateral: float=0.) -> void:
	var rotation:=Vector2(cos(heading),sin(heading))
	for key: String in cache:
		if key.begins_with("ground"):
			cache[key].set_shader_parameter("track_distance",distance)
			cache[key].set_shader_parameter("track_rotation",rotation)
			cache[key].set_shader_parameter("track_lateral",lateral)
			if key in ["ground4_false","ground4_horizon"]: cache[key].set_shader_parameter("wave_time",0. if reduced else clock)
			continue
		if not key.begins_with("edge"): continue
		cache[key].set_shader_parameter("flow_time",clock)
		cache[key].set_shader_parameter("track_distance",distance)
		cache[key].set_shader_parameter("track_rotation",rotation)
		cache[key].set_shader_parameter("reduced_motion",reduced)
