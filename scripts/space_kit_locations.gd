extends RefCounted
## Static outposts, kept separate from the moving course and the shop entrances.
const G = preload("res://scripts/geometry.gd")
const Planets = preload("res://scripts/planets.gd")
const FINISH_CITY = preload("res://scripts/finish_city.gd")

# Model, ground position, width, heading in degrees.
const LAUNCH := [
	[["hangar_roundA", -10, -14, 7., 155.], ["craft_miner", 9.6, -17, 5.5, -22.], ["rock_crystalsLargeA", -15, -21, 4., 0.]],
	[["hangar_roundGlass", 10, -14, 8., -150.], ["corridor_window", -9, -17, 5., -23.], ["rover", 9, -22, 3., -15.]],
	[["craft_cargoA", -11, -14, 7., 32.], ["hangar_largeB", 12.6, -21, 10., -145.], ["rover", 8, -11, 2.5, -25.]],
	[["gate_complex", -9, -15, 6.5, -18.], ["craft_racer", 9.5, -18, 5., -22.], ["corridor_open", -11, -24, 5.5, -18.]],
	[["platform_high", -10, -18, 7.5, 12.], ["craft_speederD", 9.5, -15, 5., -30.], ["pipe_entrance", 12, -25, 6., 145.]],
	[["satelliteDish_large", -10, -15, 7.5, 36.], ["hangar_smallB", 10, -18, 7.5, -20.], ["machine_generatorLarge", -8, -24, 3., 22.]],
	[["corridor_window", 9, -14, 6., 20.], ["hangar_roundGlass", -11, -20, 8., 150.], ["corridor_open", 11, -23, 5., 20.]],
	[["hangar_roundB", -10, -14, 7.5, 150.], ["craft_cargoB", 11.3, -21, 7.5, -20.], ["satelliteDish_large", -13, -24, 4.5, 35.]],
	[["chimney_detailed", 10, -15, 5.5, 0.], ["craft_miner", -10.5, -17, 6., 34.], ["machine_generatorLarge", 10, -23, 3.5, 20.]],
	[["gate_complex", 10, -14, 7.5, 18.], ["hangar_largeA", -13, -22, 10., 150.], ["satelliteDish_large", 11, -24, 5.5, -15.]],
	[["pipe_ringHigh", -9, -15, 6.5, -18.], ["pipe_ringHigh", 9, -15, 6.5, 18.], ["craft_racer", 12, -24, 5., -35.], ["rock_crystalsLargeA", -12, -24, 5., 0.]]
]

const PLAZA := [
	[["hangar_roundA", -16, -36, 9., 135.], ["rock_crystalsLargeA", -13, -27, 4., 25.], ["craft_miner", 18, -34, 6., -40.]],
	[["hangar_roundGlass", -15, -38, 11., 140.], ["corridor_window", -15, -26, 5., 15.], ["corridor_open", 17, -39, 7., -15.]],
	[["hangar_largeB", 19, -40, 12., -140.], ["craft_cargoB", -17, -37, 8., 42.], ["rover", 11, -43, 3.6, -25.]],
	[["gate_complex", -14, -31, 7.5, 22.], ["corridor_open", -19, -40, 6.5, 22.], ["craft_racer", 17, -37, 6., -55.]],
	[["platform_high", 19, -36, 9., -18.], ["craft_speederD", 18, -47, 6., -38.], ["pipe_entrance", -18, -39, 7.5, 120.]],
	[["satelliteDish_large", 17, -37, 9., -25.], ["machine_generatorLarge", 12, -47, 4.5, 20.], ["hangar_smallA", -19, -41, 9., 135.]],
	[["hangar_roundGlass", 18, -40, 10., -145.], ["corridor_window", 16, -29, 6., -20.], ["corridor_window", -16, -40, 7., 20.]],
	[["hangar_roundB", 17, -36, 10., -145.], ["hangar_smallB", -18, -41, 8., 35.], ["craft_cargoB", 17, -47, 7., -40.]],
	[["chimney_detailed", -16, -37, 7., 12.], ["machine_generatorLarge", -13, -46, 4.5, 20.], ["craft_cargoA", 18, -40, 7., -35.]],
	[["hangar_largeA", -17, -40, 12., 145.], ["gate_simple", 15, -29, 6., -12.], ["gate_complex", 17, -42, 8., -12.], ["satelliteDish_large", 24, -48, 5., -25.]],
	[["pipe_ringHigh", -13, -29, 7., -24.], ["pipe_ringHigh", 13, -29, 7., 24.], ["gate_simple", -18, -41, 7.5, -24.], ["gate_simple", 18, -41, 7.5, 24.], ["craft_racer", -24, -47, 5., 32.], ["craft_racer", 24, -47, 5., -32.]]
]

const SHELL := ["b8c8e3", "c8dcc2", "e4c09a", "7c83b3", "d4e7e7", "e3d5a8", "bcc3ab", "d5e8f4", "927978", "9292be", "c0d8e9"]
const FRAME := ["566589", "567c70", "886755", "43456d", "487e91", "6f6d69", "62687b", "557087", "56454d", "4e446e", "647996"]
const TRIM := ["83e6f4", "f1a9c8", "e89352", "eb72d8", "35c6da", "f2c760", "c4d889", "8dc7ed", "f07f54", "c98eea", "a2f5ed"]
const REUSED := {
	"hangar_roundA": "hangar-rounda",
	"hangar_roundGlass": "hangar-roundglass",
	"hangar_largeA": "hangar-largea",
	"hangar_largeB": "hangar-largeb"
}
static var scenes: Dictionary = {}
static var materials: Dictionary = {}

static func build(planet: int, plaza: bool) -> Node3D:
	var district := Node3D.new()
	district.name = "MonumentSpaceKit" if plaza else "LaunchSpaceKit"
	district.set_meta("stream_partition", true)
	for item: Array in (PLAZA if plaza else LAUNCH)[planet]:
		var at := Vector3(item[1], -.20, item[2] - (0. if plaza else 6.))
		var unit := Node3D.new()
		unit.name = item[0]
		unit.position = at
		unit.rotation_degrees.y = item[4]
		district.add_child(unit)
		var width: float = item[3]
		if String(item[0]).begins_with("craft_"):
			var pad := model(unit, "platform_large", Vector3.ZERO, width * 1.34, planet)
			var surface_y := pad.end.y
			model(unit, item[0], Vector3(0, surface_y, 0), width, planet)
			pad_lights(unit, pad, planet)
		else:
			var has_deck := planet in [4, 8] and not String(item[0]).begins_with("platform_")
			var bounds := model(unit, item[0], Vector3.UP * .22 if has_deck else Vector3.ZERO, width, planet)
			if has_deck:
				var deck := AABB(Vector3(-bounds.size.x * .5 - .3, 0, -bounds.size.z * .5 - .3), Vector3(bounds.size.x + .6, .22, bounds.size.z + .6))
				G.box(unit, deck.size, deck.get_center(), FRAME[planet])
				pad_lights(unit, deck, planet)
		# Merge per landmark so the camera can still cull either side of the district.
		G.merge_static(unit)
		for piece: MeshInstance3D in unit.find_children("*", "MeshInstance3D", true, false):
			if plaza and piece.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				piece.set_meta("architecture_solid", true)
	if plaza and planet in [4, 8]:
		connect_decks(district, planet)
	return district

static func model(root: Node3D, key: String, at: Vector3, width: float, planet: int) -> AABB:
	if not scenes.has(key):
		var path: String = "res://assets/finish_city/" + REUSED[key] if REUSED.has(key) else "res://assets/space_kit/" + key
		scenes[key] = load(path + ".glb")
	var instance: Node3D = scenes[key].instantiate()
	var bounds := AABB()
	var first := true
	for piece: MeshInstance3D in instance.find_children("*", "MeshInstance3D", true, false):
		var box := FINISH_CITY.local_transform(piece, instance) * piece.mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
		for surface in piece.mesh.get_surface_count():
			var source := piece.mesh.surface_get_material(surface) as StandardMaterial3D
			if source != null:
				piece.set_surface_override_material(surface, finish_material(source, planet, key.begins_with("rock_")))
	var factor := width / bounds.size.x
	var fit := Vector3(factor, minf(factor, 12. / bounds.size.y) if key == "chimney_detailed" else factor, factor)
	var pivot := Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
	instance.scale = fit
	instance.position = at - pivot * fit
	root.add_child(instance)
	return AABB(at + (bounds.position - pivot) * fit, bounds.size * fit)

static func pad_lights(unit: Node3D, pad: AABB, planet: int) -> void:
	var color: String = Planets.get_data(planet).accent
	for side in [-1., 1.]:
		for row in [-1., 0., 1.]:
			var light := G.box(unit, Vector3(.15, .026, .52), Vector3(side * pad.size.x * .41, pad.end.y + .015, row * pad.size.z * .30), color, .55)
			light.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

static func connect_decks(district: Node3D, planet: int) -> void:
	var walkway := Node3D.new()
	walkway.name = "ServiceWalkways"
	district.add_child(walkway)
	var tint: String = Planets.get_data(planet).accent
	for side in [-1., 1.]:
		var z := -39. if planet == 4 else -37.
		var span := G.box(walkway, Vector3(10.4, .24, 2.8), Vector3(side * 9.8, -.055, z), FRAME[planet])
		for edge in [-1., 1.]:
			var guide := G.box(walkway, Vector3(10.2, .025, .07), Vector3(side * 9.8, .08, z + edge * 1.25), tint, .28)
			guide.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		span.set_meta("architecture_solid", true)
	G.merge_static(walkway)

static func finish_material(source: StandardMaterial3D, planet: int, mineral: bool) -> StandardMaterial3D:
	var role := source.resource_name.to_lower()
	var key := "%d/%s/%s" % [planet, role, mineral]
	if materials.has(key):
		return materials[key]
	var material := source.duplicate() as StandardMaterial3D
	match role:
		"metal": material.albedo_color = Color(SHELL[planet])
		"metaldark": material.albedo_color = Color(FRAME[planet])
		"metalred": material.albedo_color = Color(TRIM[planet])
		"dark": material.albedo_color = Color(FRAME[planet]).darkened(.52)
		"_defaultmat": material.albedo_color = Color(SHELL[planet]).lightened(.17)
	if mineral:
		material.albedo_color = source.albedo_color.lerp(Color(TRIM[planet]), .32)
	material.roughness = .36 if planet == 10 or mineral else .65
	material.metallic = .35 if planet == 10 else .15
	materials[key] = material
	return material
