extends RefCounted

const SHADER=preload("res://assets/surfaces/arcade_finish.gdshader")
const ALLOY=preload("res://assets/salvage/hull-ceramic-v1.png")
const EARTH=preload("res://assets/surfaces/leafy_grass_diff_1k.jpg")
const AMBER=preload("res://assets/surfaces/amber_ground_v1.png")
const CRYSTAL=preload("res://assets/surfaces/aurora_ground_v1.png")
const NEON=preload("res://assets/surfaces/neon_ground_v1.png")
const Planets=preload("res://scripts/planets.gd")
const MAPS=[CRYSTAL,EARTH,AMBER,NEON,EARTH,AMBER,EARTH,CRYSTAL,AMBER,NEON,CRYSTAL]
static var cache: Dictionary = {}

static func apply(root: Node3D, planet: int, natural: bool = false) -> void:
	var style := Planets.style_index(planet)
	var accent := Color(Planets.get_data(planet).accent)
	for piece: MeshInstance3D in root.find_children("*","MeshInstance3D",true,false):
		if not piece.mesh: continue
		var replacement := {}
		for surface in piece.mesh.get_surface_count():
			var original := piece.get_active_material(surface) as StandardMaterial3D
			if not original or original.albedo_texture or original.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED:
				continue
			if original.shading_mode==BaseMaterial3D.SHADING_MODE_UNSHADED:
				continue
			replacement[surface]=coating(original.albedo_color,accent,style,natural,original.emission_energy_multiplier if original.emission_enabled else 0.)
		if replacement.is_empty(): continue
		if piece.material_override:
			piece.material_override=replacement[0]
		else:
			for surface: int in replacement:
				piece.set_surface_override_material(surface,replacement[surface])

static func coating(base: Color, accent: Color, style: int, natural: bool = false, glow: float = 0.) -> ShaderMaterial:
	var key := [base,accent,style if natural else -1,glow]
	if not cache.has(key):
		var paint := ShaderMaterial.new()
		paint.shader=SHADER
		paint.set_shader_parameter("surface_map",MAPS[style] if natural else ALLOY)
		paint.set_shader_parameter("base_color",base)
		paint.set_shader_parameter("accent",accent)
		paint.set_shader_parameter("natural",natural)
		paint.set_shader_parameter("glow",glow)
		cache[key]=paint
	return cache[key]
