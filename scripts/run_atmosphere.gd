extends Node3D

const G = preload("res://scripts/geometry.gd")
const MeteorMask = preload("res://assets/effects/fire_rain/meteor_mask.gdshader")
const DomeShader = preload("res://assets/effects/shield_dome/shield_basic2.tres")
const FIRST_WORLD := 5
const TRAIL = preload("res://assets/effects/fire_rain/trail1.png")
const FLARE = preload("res://assets/effects/fire_rain/flare.png")
const IMPACT = preload("res://assets/effects/fire_rain/impact1.png")
const COLORS := [Color("ff772c"), Color("62f6ff"), Color("c291ff"), Color("ff437e"), Color("96ff64")]
const ROAD_FLASH_END := 2.10
const ROAD_IMPACT := ROAD_FLASH_END * .85
const ROAD_CLEAR := 2.60

var meteors: Array[Node3D] = []
var impact_distances: Array[float] = []
var impact_cycles: Array[int] = []
var shelters: Array[Node3D] = []
var trail_material: ShaderMaterial
var core_material: ShaderMaterial
var impact_material: ShaderMaterial
var dome_material: ShaderMaterial
var dome_rim: StandardMaterial3D
var hero_field: MeshInstance3D
var hero_field_material: ShaderMaterial
var shield_flash := 0.
var shield_duration := .42
var world_index := -1
var clock := 0.
var cover := 0.
var road_meteor: Node3D
var road_warning: MeshInstance3D
var road_ring_material: StandardMaterial3D
var road_timer := -1.
var road_wait := 2.
var road_distance := 0.
var road_lane := 1
var road_serial := 0
var road_contact_used := false

func mask_material(texture: Texture2D, tail: bool = false) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = MeteorMask
	material.set_shader_parameter("effect_mask", texture)
	material.set_shader_parameter("tail", tail)
	return material

func build() -> void:
	name = "RunAtmosphere"
	trail_material = mask_material(TRAIL, true)
	core_material = mask_material(FLARE)
	impact_material = mask_material(IMPACT)
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	for i in 5:
		meteors.append(make_meteor(quad))
		impact_distances.append(0.)
		impact_cycles.append(-1)
	road_meteor = make_meteor(quad)
	road_meteor.hide()
	var warning_ring := TorusMesh.new()
	warning_ring.inner_radius = .89
	warning_ring.outer_radius = 1.04
	warning_ring.rings = 24
	warning_ring.ring_segments = 6
	road_ring_material = StandardMaterial3D.new()
	road_ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	road_ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	road_warning = G.part(self, warning_ring, Vector3.ZERO, road_ring_material)
	road_warning.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	road_warning.hide()

	var surface_noise := FastNoiseLite.new()
	surface_noise.frequency = .064
	var field := NoiseTexture2D.new()
	field.width = 128
	field.height = 128
	field.seamless = true
	field.noise = surface_noise
	var levels := Gradient.new()
	levels.colors = PackedColorArray([Color(.62, .62, .62), Color(.20, .20, .20)])
	var falloff := GradientTexture2D.new()
	falloff.width = 16
	falloff.height = 32
	falloff.gradient = levels
	falloff.fill_to = Vector2(0, 1)
	dome_material = ShaderMaterial.new()
	dome_material.shader = DomeShader
	dome_material.set_shader_parameter("Intensity", 2.2)
	dome_material.set_shader_parameter("scale", Vector2(3, 2))
	dome_material.set_shader_parameter("gradient", falloff)
	dome_material.set_shader_parameter("transparent_texture", field)
	dome_material.set_shader_parameter("fresnel_power", 4.2)
	hero_field_material = dome_material.duplicate() as ShaderMaterial
	hero_field_material.set_shader_parameter("Color", Color("36e8ff"))
	hero_field_material.set_shader_parameter("fresnel_color", Color("d0fcff"))
	hero_field_material.set_shader_parameter("direction", Vector2(.12, -.21))
	var bubble := SphereMesh.new()
	bubble.radius = 1.26
	bubble.height = 2.52
	bubble.radial_segments = 18
	bubble.rings = 10
	hero_field = G.part(self, bubble, Vector3.ZERO, hero_field_material)
	hero_field.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hero_field.hide()
	dome_rim = StandardMaterial3D.new()
	dome_rim.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var hemisphere := SphereMesh.new()
	hemisphere.radius = 6.2
	hemisphere.height = 12.4
	hemisphere.is_hemisphere = true
	hemisphere.radial_segments = 24
	hemisphere.rings = 10
	var ring := TorusMesh.new()
	ring.inner_radius = 6.02
	ring.outer_radius = 6.22
	ring.rings = 24
	ring.ring_segments = 6
	for i in 2:
		var shelter := Node3D.new()
		add_child(shelter)
		shelters.append(shelter)
		var dome := G.part(shelter, hemisphere, Vector3.ZERO, dome_material)
		dome.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var rim := G.part(shelter, ring, Vector3.UP * .08, dome_rim)
		rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hide()

func make_meteor(quad: QuadMesh) -> Node3D:
	var meteor := Node3D.new()
	add_child(meteor)
	for material in [trail_material, core_material, impact_material]:
		var sprite := G.part(meteor, quad, Vector3.ZERO, material)
		sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return meteor

func style(world: int, reduced: bool) -> void:
	if world_index != world:
		world_index = world
		var tint: Color = COLORS[posmod(world - FIRST_WORLD, COLORS.size())]
		trail_material.set_shader_parameter("tint", tint)
		core_material.set_shader_parameter("tint", tint.lerp(Color.WHITE, .46))
		impact_material.set_shader_parameter("tint", tint)
		var shield := tint.lerp(Color("36e8ff"), .72)
		dome_material.set_shader_parameter("Color", shield)
		dome_material.set_shader_parameter("fresnel_color", shield.lerp(Color.WHITE, .38))
		dome_rim.albedo_color = shield
	var drift := Vector2.ZERO if reduced else Vector2(-.023, .044)
	if dome_material.get_shader_parameter("direction") != drift:
		dome_material.set_shader_parameter("direction", drift)

func pose_meteor(meteor: Node3D, start: Vector3, land: Vector3, progress: float, reduced: bool, camera: Camera3D, size_factor: float) -> void:
	var head := start.lerp(land, minf(progress / .85, 1.))
	var tail_up := land.direction_to(start)
	var right := tail_up.cross(head.direction_to(camera.global_position)).normalized()
	var tail := meteor.get_child(0) as Node3D
	var core := meteor.get_child(1) as Node3D
	var impact := meteor.get_child(2) as Node3D
	var length_value := (8. if reduced else 16.) * size_factor
	tail.visible = progress < .85
	core.visible = tail.visible
	tail.position = head + tail_up * length_value * .42
	tail.basis = Basis(right, tail_up, right.cross(tail_up)).scaled_local(Vector3(3.8 * size_factor, length_value, 1.))
	core.position = head
	core.basis = camera.global_basis.scaled(Vector3.ONE * (1.9 if reduced else 2.8) * size_factor)
	impact.visible = not tail.visible
	impact.position = land + Vector3.UP * .55
	impact.basis = camera.global_basis.scaled(Vector3.ONE * lerpf(1.5, 6., smoothstep(.85, 1., progress)) * size_factor)

func advance_road_strike(dt: float, world: int, distance: float, speed: float, remaining: float, reduced: bool, track: RefCounted, camera: Camera3D) -> void:
	if road_timer < 0.:
		road_wait = maxf(0., road_wait - dt)
		if cover < .45 or road_wait > 0. or remaining < 270.: return
		# Land a short distance ahead of the runner at impact, even at race speed.
		road_distance = distance + speed * ROAD_IMPACT + 10.
		road_lane = posmod(world + road_serial * 2, 3)
		road_serial += 1
		road_timer = 0.
		road_contact_used = false
	road_timer += dt
	if road_timer >= ROAD_CLEAR:
		road_timer = -1.
		road_wait = 3.6 + float(posmod(world + road_serial, 4)) * .65
		road_meteor.hide()
		road_warning.hide()
		return
	var lateral := (road_lane - 1) * 2.6
	var offset := distance - road_distance
	var land: Vector3 = track.map(Vector3(lateral, .055, offset))
	var start: Vector3 = track.map(Vector3(lateral + (-15. if road_lane == 0 else 15.), 37., offset - 20.))
	var strike_phase := minf(1., road_timer / ROAD_FLASH_END)
	road_warning.visible = true
	road_warning.position = land
	var expansion := lerpf(1., 2.7, smoothstep(ROAD_IMPACT, ROAD_CLEAR, road_timer))
	road_warning.scale = Vector3.ONE * expansion
	var pulse := .8 if reduced else .68 + .28 * sin(road_timer * 11.)
	var fade := 1. - smoothstep(ROAD_IMPACT, ROAD_CLEAR, road_timer)
	road_ring_material.albedo_color = Color(1., .49, .16, pulse * fade)
	road_meteor.visible = road_timer > .38 and road_timer < ROAD_FLASH_END
	if road_meteor.visible:
		pose_meteor(road_meteor, start, land, strike_phase, reduced, camera, 1.18)

func road_hit(distance: float, lateral: float, height: float) -> bool:
	if road_contact_used or road_timer < ROAD_IMPACT or road_timer >= ROAD_CLEAR:
		return false
	if absf(distance - road_distance) > 1.30 or absf(lateral - (road_lane - 1) * 2.6) > 1.04:
		return false
	if height > 1.55 or height < -.36:
		return false
	road_contact_used = true
	return true

func flash_hero_shield(from_badge: bool = false) -> void:
	shield_duration = .78 if from_badge else .42
	shield_flash = shield_duration
	hero_field_material.set_shader_parameter("Color",Color("95eaff") if from_badge else Color("35d8ff"))
	hero_field_material.set_shader_parameter("fresnel_color",Color("f1e5ff") if from_badge else Color("a3ffff"))

func advance(dt: float, world: int, distance: float, speed: float, remaining: float, active: bool, reduced: bool, high_quality: bool, track: RefCounted, camera: Camera3D, hero_at: Vector3) -> float:
	visible = active and world >= FIRST_WORLD
	if not visible:
		cover = 0.
		road_timer = -1.
		road_wait = 2.
		road_meteor.hide()
		road_warning.hide()
		hero_field.hide()
		shield_flash = 0.
		return cover
	if world_index != world:
		clock = 0.
		impact_cycles.fill(-1)
		road_serial = 0
	clock += dt
	style(world, reduced)
	var spacing := 540. + float(posmod(world, 5)) * 57.
	var lead := 360. + float(posmod(world * 47, 170))
	var segment := floori((distance - lead) / spacing)
	var phase := fposmod(distance - lead, spacing)
	var target := smoothstep(0., 40., phase) * (1. - smoothstep(140., 215., phase))
	if distance < lead or remaining < 195.: target = 0.
	cover = move_toward(cover, target, dt * .8)
	shield_flash = maxf(0., shield_flash - dt)
	hero_field.visible = shield_flash > 0.
	if hero_field.visible:
		hero_field.position = hero_at + Vector3.UP * 1.25
		hero_field.scale = Vector3.ONE * lerpf(1.32, 1., shield_flash / shield_duration)
		hero_field_material.set_shader_parameter("Intensity", 1. + 2.2 * shield_flash / shield_duration)
	var brightness := cover * (.48 if reduced else .85)
	trail_material.set_shader_parameter("opacity", brightness)
	core_material.set_shader_parameter("opacity", brightness)
	impact_material.set_shader_parameter("opacity", brightness * .52)
	var count := 2 if reduced else 5 if high_quality else 3
	for i in meteors.size():
		var meteor := meteors[i]
		meteor.visible = cover > .05 and i < count
		if not meteor.visible: continue
		var side := -1. if posmod(segment + i + world, 2) == 0 else 1.
		var travel := clock * (.45 + .035 * i) + .23 * i
		var cycle := floori(travel)
		if cycle != impact_cycles[i]:
			impact_cycles[i] = cycle
			impact_distances[i] = distance + 98. + 16. * i
		var offset := distance - impact_distances[i]
		var start: Vector3 = track.map(Vector3(side * (26. + 5. * i), 38. + 4. * i, offset - 28.))
		var land: Vector3 = track.map_ground(Vector3(side * (15. + 4. * i), .06, offset))
		pose_meteor(meteor, start, land, fposmod(travel, 1.), reduced, camera, 1.05 + .1 * i)
	advance_road_strike(dt, world, distance, speed, remaining, reduced, track, camera)
	for i in shelters.size():
		var shelter := shelters[i]
		var section := segment + i
		var at := lead + section * spacing + 102.
		var offset := at - distance
		shelter.visible = section >= 0 and offset > -35. and offset < minf(146., remaining - 190.)
		if shelter.visible:
			var side := -1. if posmod(section + world, 2) == 0 else 1.
			shelter.position = track.map_ground(Vector3(side * 17.5, .05, -offset))
	return cover
