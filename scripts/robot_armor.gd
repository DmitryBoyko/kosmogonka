extends RefCounted

static var paints: Dictionary={}
const SHADER=preload("res://assets/surfaces/robot_armor.gdshader")
const PANEL=preload("res://assets/salvage/hull-titanium-v1.png")
const WEAR=preload("res://assets/salvage/hull-salvage-v1.png")
# Original source material slots retain the supplied model's armor segmentation.
const COLORS={"mat16":"8b9560","mat13":"c3a14e","mat17":"39443b","mat21":"a1aa8b",
	"mat23":"242b28","mat20":"665542","mat11":"ffb844","mat12":"ffd579",
	"mat14":"ba6841","mat8":"bc754d","mat5":"869664"}

static func apply(model: Node3D) -> void:
	for piece: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		for slot in piece.mesh.get_surface_count():
			var original:=piece.mesh.surface_get_material(slot)
			var key: String=original.resource_name if original else "mat16"
			if not paints.has(key):
				var material:=ShaderMaterial.new()
				material.shader=SHADER
				material.set_shader_parameter("armor_map",PANEL)
				material.set_shader_parameter("wear_map",WEAR)
				material.set_shader_parameter("paint_color",Color(COLORS.get(key,"8b9560")))
				material.set_shader_parameter("metalness",.48 if key in ["mat17","mat21"] else .26)
				material.set_shader_parameter("hazard",key=="mat13")
				material.set_shader_parameter("glow",.75 if key in ["mat11","mat12"] else 0.)
				paints[key]=material
			piece.set_surface_override_material(slot,paints[key])
