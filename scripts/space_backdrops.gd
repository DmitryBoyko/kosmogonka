extends RefCounted
const NAMES=["aurora","flora","amber","neon","oceania","helios","mycelium","cryos","volcano","singularity"]
static var textures:Dictionary={}
static func path(world:int) -> String:return "res://assets/space_backdrops/space_%d_%s.png"%[world,NAMES[world]]
static func texture(world:int) -> Texture2D:
	world=clampi(world,0,9)
	if not textures.has(world):textures[world]=load(path(world))
	return textures[world]
static func apply(root:Node3D,world:int) -> void:
	var backdrop:MeshInstance3D=root.get_node_or_null("DeepStarfield")
	if backdrop:
		backdrop.material_override.shader=preload("res://assets/spaceflight/mirror_starfield.gdshader") if world==10 else preload("res://assets/spaceflight/starfield.gdshader")
		if world!=10:backdrop.material_override.set_shader_parameter("stars_map",texture(world))
		backdrop.set_meta("backdrop_world",world)
		backdrop.rotation=Vector3(.60,.45+world*.23,.18)
