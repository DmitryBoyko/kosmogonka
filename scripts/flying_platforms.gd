extends RefCounted

const G = preload("res://scripts/geometry.gd")
const SM = preload("res://scripts/salvage_mesh.gd")
const H = preload("res://scripts/hover_support.gd")
const Transport = preload("res://scripts/hover_transport.gd")
const Finishes = preload("res://scripts/salvage_materials.gd")
const SOURCE := [preload("res://assets/flying_platforms/platform-square.glb"),preload("res://assets/flying_platforms/platform-long.glb")]
# Source hull, coating, neon, side equipment, width and hull depth.
const STYLES := [
	[0,"376987","6ff0ff",0,1.02,1.00],
	[1,"4e4995","e5a7ff",1,.94,.82],
	[0,"9b6344","ffbd60",2,1.12,1.08],
	[1,"482866","ff79d9",3,.98,.80],
	[0,"2d7778","74ffcc",4,1.05,.92],
	[1,"687a93","e8e683",0,.95,.76],
	[0,"635082","adf98e",1,1.07,.88],
	[1,"447f9d","b9edff",2,1.09,.92],
	[0,"733c49","ff8568",3,1.12,1.06],
	[1,"557f88","83fff0",4,1.03,.84],
]
static var paints: Dictionary = {}
static var displays: Dictionary = {}
static var reduced := false

static func set_motion(value: bool) -> void:
	reduced = value
	for screen: ShaderMaterial in displays.values():
		screen.set_shader_parameter("motion",0. if reduced else 1.)

static func build_chain(root: Node3D, length_value: float, deck_y: float, seed: int, depth: float = 1.) -> void:
	var count := maxi(1,ceili(length_value / 11.))
	var span := length_value / count
	var gap := .78 if count > 1 else 0.
	var styles := PackedInt32Array()
	for i in count:
		var variant := posmod(seed + i * 3,STYLES.size())
		var z := (float(count - 1) * .5 - i) * span
		var module := Node3D.new()
		module.name = "FlightDeck_%02d" % i
		root.add_child(module)
		var cap := gap * .5 if i == 0 or i == count - 1 else 0.
		var extension := cap * (.5 if i == 0 else -.5)
		module.position = Vector3(0,deck_y,z + extension)
		module.scale.y = depth
		build_module(module,span - gap + cap,variant)
		styles.append(variant)
		if i < count - 1:
			var center := Vector3(0,deck_y-.06,z-span*.5)
			SM.block(root,Vector3(2.17,.12,gap+.03),center,Transport.paint(0,"deck"),.04)
			for side in [-1.,1.]:
				G.box(root,Vector3(.07,.02,gap+.04),center+Vector3(side*1.04,.06,0),"9fe8f4",.32).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.set_meta("flight_deck_styles",styles)
	root.set_meta("flight_deck_count",count)
	root.set_meta("flight_deck_height",deck_y)

static func build_module(module: Node3D, length_value: float, variant: int) -> void:
	var style: Array = STYLES[variant]
	var tint: String = style[2]
	var instance: Node3D = SOURCE[style[0]].instantiate()
	module.add_child(instance)
	instance.scale = Vector3(style[4],style[5],length_value / 4.0)
	var pieces := instance.find_children("*","MeshInstance3D",true,false)
	if instance is MeshInstance3D:
		pieces.append(instance)
	for piece: MeshInstance3D in pieces:
		piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for surface in piece.mesh.get_surface_count():
			var source: Material = piece.mesh.surface_get_material(surface)
			var role: String = source.resource_name if source else ""
			piece.set_surface_override_material(surface,coating(variant,role))

	var keel: float = -.66 * style[5]
	var width: float = .98 * style[4]
	Transport.hull(module,[
		Vector4(-length_value*.48,width*.66,keel*.49,-.14),
		Vector4(-length_value*.34,width,keel,-.13),
		Vector4(length_value*.29,width,keel,-.13),
		Vector4(length_value*.47,width*.71,keel*.53,-.14),
	],coating(variant,"LightGrey"))
	# This low-profile grating is the contact plane for all hull silhouettes.
	SM.block(module,Vector3(2.24,.115,length_value),Vector3(0,-.0575,0),Transport.paint(0,"deck"),.065)
	for side in [-1.,1.]:
		var strip := G.box(module,Vector3(.048,.018,length_value-.30),Vector3(side*1.095,-.024,0),tint,.63)
		strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		fairing(module,side,length_value,variant)
		screen(module,Vector3(side*1.18,-.34,length_value*.27),side*PI*.5,variant)
	screen(module,Vector3(0,-.29,length_value*.5+.01),0.,variant)
	H.mount(module,2.18,length_value,0.,0.)
	module.set_meta("flight_deck_style",variant)

static func fairing(module: Node3D, side: float, length_value: float, variant: int) -> void:
	var style: Array = STYLES[variant]
	var tint: String = style[2]
	var finish := coating(variant,"LightGrey")
	var frame := coating(variant,"Black")
	var at := Vector3(side*1.05,-.30,-length_value*.13)
	match int(style[3]):
		0:
			for z in [-.31,.09]:
				var pod := G.tube(module,.21,.58,Vector3(side*1.03,-.34,length_value*z),tint)
				pod.rotation.x=PI*.5
				pod.material_override=finish
			G.box(module,Vector3(.13,.045,length_value*.48),at+Vector3(side*.19,-.01,0),tint,.55)
		1:
			var vane := SM.block(module,Vector3(.26,.18,length_value*.63),at,finish,.11)
			vane.rotation.z = side*.56
			G.box(module,Vector3(.065,.025,length_value*.55),at+Vector3(side*.155,-.075,0),tint,.55)
		2:
			for z in [-.34,.0,.34]:
				var armored := SM.block(module,Vector3(.35,.33,.58),Vector3(side*1.03,-.32,length_value*z),finish,.11)
				armored.rotation.z = side*.23
				G.box(module,Vector3(.035,.04,.28),armored.position+Vector3(side*.18,0,0),tint,.5)
		3:
			for z in [-.27,.22]:
				var panel := SM.block(module,Vector3(.44,.12,length_value*.24),Vector3(side*1.08,-.28,length_value*z),finish,.09)
				panel.rotation.y = side*.25
				G.box(module,Vector3(.085,.045,length_value*.14),panel.position+Vector3(side*.23,-.02,0),tint,.56).rotation.y=panel.rotation.y
		4:
			SM.block(module,Vector3(.24,.27,length_value*.7),at,frame,.09)
			for z in [-.30,-.18,-.06,.06,.18]:
				var louver := SM.block(module,Vector3(.12,.16,.35),Vector3(side*1.17,-.30,length_value*z),finish,.065)
				louver.rotation.x=.48
				G.box(module,Vector3(.023,.045,.18),louver.position+Vector3(side*.07,-.028,0),tint,.5)

static func screen(root: Node3D, at: Vector3, yaw: float, variant: int) -> void:
	var mount := Node3D.new()
	root.add_child(mount)
	mount.position=at
	mount.rotation.y=yaw
	SM.block(mount,Vector3(.92,.40,.15),Vector3.ZERO,coating(variant,"Black"),.052)
	var quad := QuadMesh.new()
	quad.size=Vector2(.82,.30)
	var display := G.part(mount,quad,Vector3(0,0,.079),display_material(variant))
	display.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

static func display_material(variant: int) -> ShaderMaterial:
	if not displays.has(variant):
		var material := ShaderMaterial.new()
		material.shader=preload("res://assets/flying_platforms/status_screen.gdshader")
		material.set_shader_parameter("accent",Color(STYLES[variant][2]))
		material.set_shader_parameter("mode",variant % 5)
		material.set_shader_parameter("motion",0. if reduced else 1.)
		displays[variant]=material
	return displays[variant]

static func coating(variant: int, role: String) -> ShaderMaterial:
	var key := str(variant) + "/" + role
	if paints.has(key):
		return paints[key]
	var painted := role in ["LightGrey","Orange"]
	var material := Finishes.material(Finishes.HULLS[variant % 3],not painted).duplicate() as ShaderMaterial
	material.shader=preload("res://assets/salvage/transport_surface.gdshader")
	material.set_shader_parameter("tint",Color(STYLES[variant][1]) if painted else Color("3d5268") if role=="Grey" else Color("243448"))
	material.set_shader_parameter("surface_role",0)
	material.set_shader_parameter("tile_scale",1.75)
	paints[key]=material
	return material
