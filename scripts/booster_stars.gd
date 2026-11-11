extends RefCounted

const Course = preload("res://scripts/course.gd")
const Boosters = preload("res://scripts/booster_catalog.gd")
const G = preload("res://scripts/geometry.gd")
const BEAM = preload("res://assets/effects/booster_star/loot_beam.gdshader")
const MARKER = preload("res://assets/effects/booster_star/jump_marker.gdshader")
const COUNT := 3
const HEIGHT := 2.95
const HIT_DEPTH := 2.25
const MIN_JUMP := .82

static func place(planet: int, restart: float, seed_value: int, events: Array, routes: Array, gates: Array, regular_drops: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + planet * 179 + 41
	var first_kind := rng.randi_range(0,1)
	var start := restart + 68.
	var section := (Course.length_for(planet)-95.-start)/COUNT
	for i in COUNT:
		var low := start + i*section
		var target := low + section*rng.randf_range(.38,.62)
		var lanes := [rng.randi_range(0,2)]
		lanes.append((lanes[0]+1)%3)
		lanes.append((lanes[0]+2)%3)
		var point := find_clear_point(planet,low,low+section,target,lanes,events,routes,gates,regular_drops)
		if point.x < 0.:
			continue
		result.append({"s":point.x,"lane":int(point.y),"kind":Boosters.KINDS[(first_kind+i)%2],"done":false,"node":null})
	return result

static func find_clear_point(planet: int, low: float, high: float, target: float, lanes: Array, events: Array, routes: Array, gates: Array, regular_drops: Array) -> Vector2:
	for i in ceili((high-low)/4.)+1:
		var s := target + ceili(i*.5)*4.*(-1. if i%2 else 1.)
		if s<low+14. or s>high-14. or Course.front_at(s-20.)>0. or Course.front_at(s+20.)>0.:
			continue
		if routes.any(func(route): return s>route.start-75. and s<route.start+110.):
			continue
		if gates.any(func(gate): return absf(s-gate.s)<34.):
			continue
		if regular_drops.any(func(drop): return absf(s-drop.s)<10.):
			continue
		var open_lanes := Course.lanes_at(s,planet)
		for lane: int in lanes:
			if open_lanes.has(lane) and lane_clear(s,lane,events):
				return Vector2(s,lane)
	return Vector2(-1.,-1.)

static func lane_clear(s: float, lane: int, events: Array) -> bool:
	for event: Dictionary in events:
		var margin: float = event.length*.5+17.
		if event.kind=="alien":
			margin = float(event.get("cross_span",30.))+12.
			if absf(s-event.s)<margin:
				return false
		elif lane>=mini(event.lane,event.source_lane) and lane<=maxi(event.lane,event.source_lane):
			if absf(s-event.s)<margin:
				return false
	return true

static func visual(kind: String, jump_lead: float) -> Node3D:
	var root := Node3D.new()
	root.name = "BoosterStar"
	var tint := Color("ff649c") if kind=="jet" else Color("54ffed")
	var star := G.star(root,.70,Vector3.UP*HEIGHT)
	star.material_override = G.material(tint.to_html(false),.57)
	var icon := Sprite3D.new()
	icon.texture = preload("res://assets/ui/boost-fire.svg") if kind=="jet" else preload("res://assets/ui/boost-energy.svg")
	icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	icon.pixel_size = .016
	icon.position.y = HEIGHT+.87
	icon.shaded = false
	root.add_child(icon)

	var beam := CylinderMesh.new()
	beam.top_radius = .40
	beam.bottom_radius = .83
	beam.height = HEIGHT+.55
	beam.radial_segments = 12
	beam.rings = 0
	beam.cap_top = false
	beam.cap_bottom = false
	var light := ShaderMaterial.new()
	light.shader = BEAM
	light.set_shader_parameter("color",tint)
	light.set_shader_parameter("alpha",.29)
	light.set_shader_parameter("edge_soft",2.1)
	light.set_shader_parameter("top_fade",.7)
	G.part(root,beam,Vector3.UP*(beam.height*.5+.02),light)

	var plate := QuadMesh.new()
	plate.size = Vector2(2.55,2.55)
	var hologram := ShaderMaterial.new()
	hologram.shader = MARKER
	hologram.set_shader_parameter("color",tint)
	var cue := G.part(root,plate,Vector3(0,.034,jump_lead),hologram)
	cue.rotation.x = -PI*.5
	var halo_quad := QuadMesh.new()
	halo_quad.size = Vector2.ONE*2.26
	var halo := hologram.duplicate() as ShaderMaterial
	halo.set_shader_parameter("airborne",true)
	var aura := G.part(root,halo_quad,Vector3.UP*HEIGHT,halo)
	for part: GeometryInstance3D in root.get_children():
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.set_meta("star",star)
	root.set_meta("beam",light)
	root.set_meta("marker",hologram)
	root.set_meta("aura",aura)
	return root

static func animate(node: Node3D, time: float, reduced_motion: bool) -> void:
	var phase := 0. if reduced_motion else time
	var star: Node3D = node.get_meta("star")
	star.rotation.y = .16 + sin(phase*2.5)*.64
	star.position.y = HEIGHT + sin(phase*3.)*.10
	var aura: MeshInstance3D = node.get_meta("aura")
	aura.position.y = star.position.y
	aura.material_override.set_shader_parameter("animation_time",-phase*1.35)
	node.get_meta("beam").set_shader_parameter("animation_time",phase)
	node.get_meta("marker").set_shader_parameter("animation_time",phase)
