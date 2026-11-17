extends RefCounted
const Planets=preload("res://scripts/planets.gd")
const SHADER=preload("res://assets/surfaces/surface.gdshader")
const GLOBE_SHADER=preload("res://assets/planet.gdshader")
enum RoadStyle { CYBER, DIRT, CITY, STONE, FOREST }
const ROAD_TEXTURES := [
	preload("res://assets/surfaces/magnetic_road_v1.png"),
	preload("res://assets/surfaces/dirt_diff_1k.jpg"),
	preload("res://assets/finish_city/downtown/textures/concrete_floor_02_diff.jpg"),
	preload("res://assets/surfaces/stone_floor_diff_1k.jpg"),
	preload("res://assets/surfaces/dirt_floor_diff_1k.jpg"),
]
const ROAD_LEVELS := [Vector2(.17,.43),Vector2(.30,.37),Vector2(.32,.56),Vector2(.29,.51),Vector2(.50,.66)]
const ROAD_IMAGE_REPEATS := [Vector2(1.,1.65),Vector2(1.75,2.45),Vector2(1.75,2.35),Vector2(1.38,2.45),Vector2(1.53,2.25)]
const ROAD_RELIEF := [.004,.005,.004,.005,.005]
const ROAD_SOURCE_COLOR := [.06,.38,.35,.45,.48]
const ROAD_STYLES := [RoadStyle.STONE,RoadStyle.DIRT,RoadStyle.STONE,RoadStyle.CYBER,RoadStyle.CITY,
	RoadStyle.DIRT,RoadStyle.FOREST,RoadStyle.STONE,RoadStyle.STONE,RoadStyle.CYBER,RoadStyle.CITY]
const ROAD_PALETTES := ["52566b","64543f","644e43","584861","505e62","6a593e","53524a","4e6172","615158","514d68","545f6d"]
# First nine expedition palettes, followed by each biome family's default.
const EXPEDITION_ROAD_PALETTES := ["4b5d55","5b514e","495d58","586c78","535860","604d61","5a5142","456067","505f6d"]
const EXPEDITION_MINERALS := ["6ca79f","916ca2","529fa9","9990be","679ca3","a27ca9","a8849a","81ab90","708dba"]
const BIOME_GRAINS := [
	preload("res://assets/surfaces/rock_face_diff_1k.jpg"),
	preload("res://assets/surfaces/leafy_grass_diff_1k.jpg"),
	preload("res://assets/surfaces/amber_ground_v1.png"),
	preload("res://assets/surfaces/neon_ground_v1.png"),
	preload("res://assets/plant_kit/kyle/mycelium.jpg"),
]
const BIOME_TEXTURES := [0,1,2,0,0,2,4,0,0,3,0]
static var cache: Dictionary={}
static var high_quality:=true

static func ground(planet: int, hill: bool = false) -> ShaderMaterial:
	var expedition_index := planet-Planets.Expedition.VETRA
	var local_palette := expedition_index>=0 and expedition_index<EXPEDITION_MINERALS.size()
	var wind := preload("res://scripts/rock_terrain.gd").is_floating_world(planet)
	var storm := Planets.Expedition.is_expedition(planet) and Planets.style_index(planet)==8
	planet = Planets.style_index(planet)
	var key:="ground%d_%s%s%s_%d" % [planet,str(hill),"_wind" if wind else "","_storm" if storm else "",expedition_index if local_palette else -1]
	if cache.has(key): return cache[key]
	var mat:=ShaderMaterial.new()
	if planet==4 and not hill:
		mat.shader=preload("res://assets/terrain_kit/ocean.gdshader")
		mat.set_shader_parameter("waves",preload("res://assets/terrain_kit/ocean_wave.tres"))
		mat.set_shader_parameter("wave_detail",1. if high_quality else 0.)
		cache[key]=mat
		return mat
	mat.shader=preload("res://assets/surfaces/natural_ground.gdshader")
	mat.set_shader_parameter("biome_map",BIOME_GRAINS[BIOME_TEXTURES[planet]])
	mat.set_shader_parameter("tint",[Color("cad7b4"),Color("c1e2ac"),Color("ddcca0"),Color("a4c9bb")][Planets.biome(planet)])
	mat.set_shader_parameter("planet_index",Planets.style_index(planet));mat.set_shader_parameter("hill",hill)
	mat.set_shader_parameter("wind_islands",wind)
	mat.set_shader_parameter("storm_rock",storm)
	if local_palette:
		mat.set_shader_parameter("expedition_mineral",Color(EXPEDITION_MINERALS[expedition_index]))
		mat.set_shader_parameter("expedition_mix",.30 if storm else .48)

	cache[key]=mat
	return mat

static func distant_ground(planet: int) -> ShaderMaterial:
	var style := Planets.style_index(planet)
	var variant := "_wind" if preload("res://scripts/rock_terrain.gd").is_floating_world(planet) else "_storm" if Planets.Expedition.is_expedition(planet) and style==8 else ""
	var expedition_index := planet-Planets.Expedition.VETRA
	var local_palette := expedition_index>=0 and expedition_index<EXPEDITION_MINERALS.size()
	var key := "ground%d_horizon%s_%d" % [style,variant,expedition_index if local_palette else -1]
	if not cache.has(key):
		var material := ground(planet).duplicate() as ShaderMaterial
		if style!=4: material.set_shader_parameter("distant_terrain",true)
		cache[key] = material
	return cache[key]

static func road_style(planet: int) -> int:
	var style := Planets.style_index(planet)
	if Planets.Expedition.is_expedition(planet) and style==3:
		return RoadStyle.CITY
	return ROAD_STYLES[style]

static func road_palette(planet: int) -> Color:
	var expedition_index := planet-Planets.Expedition.VETRA
	if expedition_index>=0 and expedition_index<EXPEDITION_ROAD_PALETTES.size():
		return Color(EXPEDITION_ROAD_PALETTES[expedition_index])
	if preload("res://scripts/rock_terrain.gd").is_floating_world(planet):
		return Color("4d5e60")
	if Planets.Expedition.is_expedition(planet) and Planets.style_index(planet)==8:
		return Color("586c78")
	if Planets.Expedition.is_expedition(planet) and Planets.style_index(planet)==3:
		return Color("535860")
	return Color(ROAD_PALETTES[Planets.style_index(planet)])

static func lane_marking(planet: int) -> String:
	return ["738699","877659","85837d","827987","8a7b72"][road_style(planet)]

static func apply_road_finish(mat: ShaderMaterial, planet: int) -> void:
	var style := road_style(planet)
	var palette := road_palette(planet)
	mat.set_shader_parameter("surface_texture",ROAD_TEXTURES[style])
	mat.set_shader_parameter("texture_levels",ROAD_LEVELS[style])
	mat.set_shader_parameter("image_repeat",ROAD_IMAGE_REPEATS[style])
	mat.set_shader_parameter("natural_color",ROAD_SOURCE_COLOR[style])
	mat.set_shader_parameter("road_style",style)
	mat.set_shader_parameter("road_color",palette)
	if style==RoadStyle.CYBER:
		var trim := Color("608382") if Planets.style_index(planet)==3 else Color("726889")
		mat.set_shader_parameter("detail_color",trim)

static func road(planet: int, lane_count: int) -> ShaderMaterial:
	var palette := road_palette(planet)
	var key := "road%d_%d_%s" % [road_style(planet),lane_count,palette.to_html()]
	if cache.has(key): return cache[key]
	var mat:=ShaderMaterial.new()
	mat.shader=SHADER
	apply_road_finish(mat,planet)
	mat.set_shader_parameter("repeats",Vector2(lane_count,6))
	mat.set_shader_parameter("relief_depth",ROAD_RELIEF[road_style(planet)])
	cache[key]=mat
	return mat

static func set_quality(enabled: bool) -> void:
	high_quality=enabled
	for key: String in cache:
		if key.begins_with("ground4_false_") or key.begins_with("ground4_horizon_"):
			cache[key].set_shader_parameter("wave_detail",1. if enabled else 0.)

static func globe(planet:int) -> ShaderMaterial:
	return preload("res://scripts/planet_visual.gd").surface(planet)

static func edge(planet: int) -> ShaderMaterial:
	var key:="edge%d_%s" % [Planets.style_index(planet),Planets.get_data(planet).accent]
	if cache.has(key): return cache[key]
	var mat:=ShaderMaterial.new(); mat.shader=preload("res://assets/surfaces/road_edge.gdshader")
	mat.set_shader_parameter("tint",Color(Planets.get_data(planet).accent).lightened(0.2))
	mat.set_shader_parameter("palette_offset",float(Planets.style_index(planet)))
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
