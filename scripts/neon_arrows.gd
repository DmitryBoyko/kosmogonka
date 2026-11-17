extends RefCounted

const Beacon = preload("res://assets/surfaces/shop_beacon.gdshader")
const ATLAS_PATH := "res://assets/surfaces/neon_arrows.png"
const COLORS := ["ff164c","00baff","ffe21b","83ff00","ff18f5","00c7ff","2872ff","ff10dc","ffab08","63ff2c",
	"00d9ff","d927ff","f2f7ff","8cff14","ff1cad","ff224f","ffad16","4b72ff","ff21f1","00dcff"]
const TURN_SHAPES := [0,1,2,3,4,5,9,11,12,14,15,16,17,18]
static var road_materials: Dictionary = {}
static var atlas: Texture2D

static func material(variant: int, rotation: float, plaza: bool, phase: float = 0.) -> ShaderMaterial:
	if not atlas: atlas = load(ATLAS_PATH)
	var paint := ShaderMaterial.new()
	paint.shader = Beacon
	paint.set_shader_parameter("atlas",atlas)
	paint.set_shader_parameter("tile",Vector2(variant%5,floori(variant/5.)))
	paint.set_shader_parameter("tint",Color(COLORS[variant]))
	paint.set_shader_parameter("rotation",Vector2(cos(rotation),sin(rotation)))
	paint.set_shader_parameter("plaza",plaza)
	paint.set_shader_parameter("phase",phase)
	return paint

static func road_material(variant: int, direction: int, on_road: bool, steady: bool) -> ShaderMaterial:
	var key := [variant,direction,on_road]
	if not road_materials.has(key):
		var angle := -PI*.5+direction*.58 if on_road else PI if direction<0 else 0.
		var paint := material(variant,angle,false,float(variant)*.097)
		paint.set_shader_parameter("track",true)
		road_materials[key] = paint
	road_materials[key].set_shader_parameter("steady",steady)
	return road_materials[key]

static func set_steady(enabled: bool) -> void:
	for paint: ShaderMaterial in road_materials.values():
		paint.set_shader_parameter("steady",enabled)
