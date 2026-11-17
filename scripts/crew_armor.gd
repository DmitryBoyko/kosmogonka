extends RefCounted

const G = preload("res://scripts/geometry.gd")
const MeshTools = preload("res://scripts/salvage_mesh.gd")
const Materials = preload("res://scripts/salvage_materials.gd")
const SHADER = preload("res://assets/suits/armor_plate.gdshader")
const STYLES := [
	["hull-salvage","57738b","c2e8ed",.86,.05],
	["hull-ceramic","3b91a0","b6ffda",.78,.15],
	["hull-titanium","b37d4a","ffdeab",.66,.36],
	["hull-ceramic","5656a8","9beaff",.58,.25],
	["hull-titanium","3a718d","affff5",.48,.48],
	["hull-salvage","9a5a45","ffdc88",.60,.39],
	["ancient-patina","346a68","aaffd4",.47,.55],
	["hull-ceramic","a9a9c9","5065a8",.41,.29],
	["ancient-obsidian","5a3b86","ff8de7",.38,.59],
	["hull-titanium","aa935f","fff3bb",.37,.63],
	["hull-ceramic","859ed1","b8fbff",.35,.51],
	["ancient-obsidian","344971","debcff",.33,.68],
]
const OUTLINES := [
	[[-.47,-.42],[-.50,.33],[.50,.33],[.47,-.42]],
	[[-.33,-.50],[-.50,-.21],[-.50,.34],[-.28,.50],[.28,.50],[.50,.34],[.50,-.21],[.33,-.50]],
	[[-.38,-.48],[-.50,.28],[-.34,.49],[.34,.49],[.50,.28],[.38,-.48]],
	[[0,-.49],[-.43,-.21],[-.50,.37],[0,.49],[.50,.37],[.43,-.21]],
	[[-.29,-.48],[-.50,-.27],[-.45,.29],[-.20,.48],[.20,.48],[.45,.29],[.50,-.27],[.29,-.48]],
	[[-.41,-.49],[-.46,.23],[-.28,.45],[0,.32],[.28,.45],[.46,.23],[.41,-.49]],
	[[0,-.49],[-.40,-.35],[-.50,-.02],[-.35,.38],[0,.47],[.35,.38],[.50,-.02],[.40,-.35]],
	[[-.14,-.49],[-.47,-.26],[-.50,.08],[-.28,.47],[.28,.47],[.50,.08],[.47,-.26],[.14,-.49]],
	[[0,-.48],[-.49,-.15],[-.50,.25],[-.17,.46],[0,.30],[.17,.46],[.50,.25],[.49,-.15]],
	[[-.27,-.47],[-.46,-.40],[-.50,.10],[-.38,.47],[.38,.47],[.50,.10],[.46,-.40],[.27,-.47]],
	[[0,-.50],[-.46,-.28],[-.37,.12],[-.50,.42],[-.27,.46],[0,.31],[.27,.46],[.50,.42],[.37,.12],[.46,-.28]],
	[[0,-.50],[-.34,-.39],[-.50,-.05],[-.37,.39],[0,.50],[.37,.39],[.50,-.05],[.34,-.39]],
]
const ANCHORS := {
	"helmet":[[0,1],Vector3(.084,.097,.026),Vector3(0,.015,.047)],
	"torso":[[1],Vector3(.159,.106,.035),Vector3(0,-.012,.017)],
	"arms":[[0,2],Vector3(.107,.075,.035),Vector3(0,.017,.040)],
	"gloves":[[0,2],Vector3(.078,.060,.027),Vector3(0,.003,.032)],
	"legs":[[2,5],Vector3(.074,.121,.034),Vector3(0,-.019,.018)],
	"boots":[[0,2],Vector3(.093,.057,.033),Vector3(0,.001,.060)],
}
static var surfaces: Dictionary = {}
static var cloth: Dictionary = {}
static var plate_meshes: Dictionary = {}

static func coat(item: Dictionary, lining: bool = false) -> Material:
	var key := "%d/%s" % [item.tier,str(lining)]
	if surfaces.has(key): return surfaces[key]
	var look: Array = STYLES[item.tier-1]
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("texture_map",load(Materials.texture_path(look[0])))
	material.set_shader_parameter("base_tint",Color(look[1]).darkened(.42) if lining else Color(look[1]))
	material.set_shader_parameter("accent",Color(look[2]))
	material.set_shader_parameter("rough",look[3]+.08 if lining else look[3])
	material.set_shader_parameter("metal",look[4])
	material.set_shader_parameter("pattern",item.tier-1)
	surfaces[key] = material
	return material

static func fabric(item: Dictionary, original: Material) -> Material:
	var key := "%s/%d" % [item.id,original.get_instance_id()]
	if cloth.has(key): return cloth[key]
	var copy := original.duplicate() as StandardMaterial3D
	var look: Array = STYLES[item.tier-1]
	copy.albedo_color = copy.albedo_color.lerp(Color(look[1]),.47)
	copy.roughness = .72
	cloth[key]=copy
	return copy

static func plate(tier: int) -> ArrayMesh:
	if plate_meshes.has(tier): return plate_meshes[tier]
	var rim: Array = OUTLINES[tier-1]
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in rim.size():
		var a: Array = rim[i]
		var b: Array = rim[(i+1)%rim.size()]
		var a0 := Vector3(a[0],a[1],-.5)
		var b0 := Vector3(b[0],b[1],-.5)
		var a1 := Vector3(a[0]*.82,a[1]*.82,.5)
		var b1 := Vector3(b[0]*.82,b[1]*.82,.5)
		MeshTools._triangle(mesh,a0,b1,a1)
		MeshTools._triangle(mesh,a0,b0,b1)
		MeshTools._triangle(mesh,Vector3(0,0,.64),a1,b1)
	var result := mesh.commit()
	plate_meshes[tier] = result
	return result

static func decorate(group: String, item: Dictionary, panels: Array, mounted: Array[Node3D]) -> void:
	var mount_data: Array = ANCHORS[group]
	var tier: int = item.tier
	var mesh := plate(tier)
	var main := coat(item)
	var border := coat(item,true)
	var edge := Materials.glow(Color(STYLES[tier-1][2]))
	for index: int in mount_data[0]:
		var anchor: MeshInstance3D = panels[index]
		var root := Node3D.new()
		root.name = "Armor_%s_%d" % [group,tier]
		anchor.get_parent().add_child(root)
		mounted.append(root)
		root.position = anchor.position+mount_data[2]
		root.scale = mount_data[1] * Vector3(lerpf(.81,1.13,(tier-1)/11.),lerpf(.80,1.06,(tier-1)/11.),lerpf(.62,1.12,(tier-1)/11.))
		var under := G.part(root,mesh,Vector3(0,0,-.19),border)
		under.scale=Vector3(1.12,1.13,.65)
		G.part(root,mesh,Vector3.ZERO,main)
		if tier>=3:
			var stripe := MeshTools.block(root,Vector3(.52,.085,.24),Vector3(0,-.13,.61),edge,.045)
			stripe.rotation.z=.24 if tier%2==0 else -.24
		if tier>=7:
			var shoulder := G.part(root,mesh,Vector3(0,.25,.23),border)
			shoulder.scale = Vector3(.77,.37,.65)
		if tier>=10:
			for side in [-1.,1.]:
				MeshTools.block(root,Vector3(.090,.30,.24),Vector3(side*.34,.12,.56),edge,.04)
		G.merge_static(root)
		for piece: GeometryInstance3D in root.get_children():
			piece.set_layer_mask_value(10,true)
