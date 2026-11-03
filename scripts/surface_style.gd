extends RefCounted
const Planets=preload("res://scripts/planets.gd")
const SHADER=preload("res://assets/surfaces/surface.gdshader")
const GLOBE_SHADER=preload("res://assets/planet.gdshader")
const GROUND := [preload("res://assets/surfaces/aurora_ground_v1.png"),preload("res://assets/surfaces/flora_ground_v1.png"),preload("res://assets/surfaces/amber_ground_v1.png"),preload("res://assets/surfaces/neon_ground_v1.png")]
const ROAD=preload("res://assets/surfaces/magnetic_road_v1.png")
static var cache: Dictionary={}
static var high_quality:=true

static func ground(planet: int, hill: bool = false) -> ShaderMaterial:
	var key:="ground%d_%s" % [planet,str(hill)]
	if cache.has(key): return cache[key]
	var mat:=ShaderMaterial.new()
	mat.shader=SHADER
	mat.set_shader_parameter("surface_texture",GROUND[planet])
	# Integer repeats along a 30 m chunk keep neighbouring sections in phase.
	mat.set_shader_parameter("repeats",Vector2(4,2) if hill else Vector2(18,5))
	mat.set_shader_parameter("relief",0.12 if high_quality else 0.0)
	cache[key]=mat
	return mat

static func road(planet: int, lane_count: int) -> ShaderMaterial:
	var key:="road%d_%d" % [planet,lane_count]
	if cache.has(key): return cache[key]
	var mat:=ShaderMaterial.new()
	mat.shader=SHADER
	mat.set_shader_parameter("surface_texture",ROAD)
	mat.set_shader_parameter("road",true)
	mat.set_shader_parameter("road_color",Color(["26304c","244348","504050","1c2945"][planet]))
	mat.set_shader_parameter("accent_color",Color(Planets.get_data(planet).accent))
	mat.set_shader_parameter("repeats",Vector2(lane_count,6))
	mat.set_shader_parameter("relief",0.12 if high_quality else 0.0)
	cache[key]=mat
	return mat

static func set_quality(enabled: bool) -> void:
	high_quality=enabled
	for key: String in cache:
		if not key.begins_with("globe") and not key.begins_with("edge"): cache[key].set_shader_parameter("relief",0.12 if enabled else 0.0)

static func globe(planet: int) -> ShaderMaterial:
	var key:="globe%d" % planet
	if cache.has(key): return cache[key]
	var mat:=ShaderMaterial.new()
	mat.shader=GLOBE_SHADER
	mat.set_shader_parameter("ocean_color",Planets.get_data(planet).ocean)
	mat.set_shader_parameter("land_color",Planets.get_data(planet).land)
	mat.set_shader_parameter("surface_texture",GROUND[planet])
	cache[key]=mat
	return mat

static func edge(planet: int) -> ShaderMaterial:
	var key:="edge%d" % planet
	if cache.has(key): return cache[key]
	var mat:=ShaderMaterial.new(); mat.shader=preload("res://assets/surfaces/road_edge.gdshader")
	mat.set_shader_parameter("tint",Color(Planets.get_data(planet).accent).lightened(0.2))
	mat.set_shader_parameter("palette_offset",float(planet))
	cache[key]=mat
	return mat

static func animate_edges(distance: float, clock: float, reduced: bool) -> void:
	for key: String in cache:
		if not key.begins_with("edge"): continue
		cache[key].set_shader_parameter("flow_time",clock)
		cache[key].set_shader_parameter("track_distance",distance)
		cache[key].set_shader_parameter("reduced_motion",reduced)
