extends Node3D
const G = preload("res://scripts/geometry.gd")
const Props = preload("res://scripts/props.gd")
const Planets = preload("res://scripts/planets.gd")
const PlanetVisual=preload("res://scripts/planet_visual.gd")
const SurfaceStyle=preload("res://scripts/surface_style.gd")
var ship: Node3D
var globe: Node3D
var planet := 0
var globe_material: ShaderMaterial
var ring_mesh: MeshInstance3D

func _ready() -> void:
	position = Vector3(500, 0, 0)
	preload("res://scripts/flight_scenery.gd").starfield(self)
	globe=PlanetVisual.create(0,17.)
	add_child(globe)
	globe_material=globe.get_node("Surface").material_override
	var rings := G.ring(globe, 10.4, 11.9, Vector3.ZERO, "bdad95", 0.0)
	rings.rotation_degrees = Vector3(21, 0, -19)
	rings.scale.y = 0.025
	ring_mesh = rings
	var moon := G.ball(self, Vector3.ONE * 2.4, Vector3(17, 7, -14), "efbad0")
	moon.rotation.z = 0.2
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	for i in 125:
		var v := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.5, 1), rng.randf_range(-1, 1)).normalized() * 65
		G.ball(self, Vector3.ONE * rng.randf_range(0.06, 0.19), v, "cff8ff" if i % 3 else "f8cbde", 0.8)
	ship = Props.ship()
	add_child(ship)

func configure(index: int) -> void:
	planet = index
	var data := Planets.get_data(index)
	var replacement:=PlanetVisual.create(index,17.)
	globe.get_node("Surface").material_override=replacement.get_node("Surface").material_override
	globe.get_node("Clouds").material_override=replacement.get_node("Clouds").material_override
	globe.get_node("Atmosphere").material_override=replacement.get_node("Atmosphere").material_override
	replacement.free()
	globe_material=globe.get_node("Surface").material_override
	ring_mesh.visible=index in [2,6,9]

func stage(time: float, mode: String) -> Dictionary:
	globe.rotation.y = time * 0.035
	PlanetVisual.advance(globe,time)
	var angle := time * 0.13
	if mode == "intro": angle = -0.8 + time * 0.16
	elif mode == "outro": angle = time * 0.24
	if planet == 3 and mode == "outro": angle = time * 0.34
	ship.position = Vector3(sin(angle) * 13.7, 3.7 + sin(time * 0.4) * 1.3, cos(angle) * 13.7)
	ship.rotation = Vector3(0.1, angle + PI * 0.5, -0.13)
	var camera_at := Vector3(sin(angle + 0.65) * 29, 11.5, cos(angle + 0.65) * 29)
	if mode == "intro":
		var k := smoothstep(3.0, 7.0, time)
		camera_at = camera_at.lerp(ship.position + Vector3(6, 4, 9), k)
	return {"position": position + camera_at, "target": position + ship.position * 0.35}
