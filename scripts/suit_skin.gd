extends Resource
class_name SuitSkin
## One interchangeable visual style. No character identity or gameplay stats.
@export var id: StringName
@export var display_name: String
@export var compatible_slots: PackedStringArray = PackedStringArray()
@export var fabric_color := Color("f0eee7")
@export var shell_color := Color("ecf1f4")
@export var trim_color := Color("45dcca")
@export var joint_color := Color("324a5c")
@export var metal_color := Color("9caeb8")
@export var badge_color := Color("ffe295")
@export var fabric_texture: Texture2D
@export_range(0.0,1.0) var fabric_roughness := 0.93
@export_range(0.0,1.0) var shell_roughness := 0.36
