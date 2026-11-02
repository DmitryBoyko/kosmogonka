extends RefCounted
## Shared immutable materials. Object seeds choose finishes; camera and time never do.
const HULLS := ["hull-titanium","hull-ceramic","hull-salvage"]
const ANCIENT := ["ancient-obsidian","ancient-patina"]
const STARS := ["star-amber","star-blue","star-red"]
static var cache: Dictionary = {}

static func texture_path(key: String) -> String:
	return "res://assets/salvage/%s-v1.png"%key

static func material(key: String, dark: bool=false) -> ShaderMaterial:
	var id := key+("/dark" if dark else "")
	if cache.has(id): return cache[id]
	var m := ShaderMaterial.new()
	m.shader = preload("res://assets/salvage/container_surface.gdshader")
	m.set_shader_parameter("surface_map",load(texture_path(key)))
	m.set_shader_parameter("tint",Color(.38,.43,.48) if dark else Color.WHITE)
	m.set_shader_parameter("tile_scale",.65 if key.begins_with("hull") else .45)
	m.set_shader_parameter("metalness",.22 if key=="hull-ceramic" or key=="ancient-obsidian" else .72)
	m.set_shader_parameter("roughness",.84 if key=="hull-salvage" else .56)
	m.set_meta("texture_key",key)
	cache[id] = m
	return m

static func glow(color: Color) -> StandardMaterial3D:
	var key := "light/"+color.to_html()
	if cache.has(key): return cache[key]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.set_meta("light_source",true)
	cache[key] = m
	return m
