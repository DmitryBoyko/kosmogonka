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
var moons:Node3D
var dust:Node3D

func _ready() -> void:
	position = Vector3(500, 0, 0)
	preload("res://scripts/flight_scenery.gd").starfield(self)
	globe=PlanetVisual.create(0,17.)
	add_child(globe)
	globe_material=globe.get_node("Surface").material_override
	moons=Node3D.new(); moons.name="Moons"; add_child(moons)
	dust=Node3D.new(); dust.name="OrbitalStars"; add_child(dust)
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	for i in 125:
		var v := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.5, 1), rng.randf_range(-1, 1)).normalized() * 65
		G.ball(dust, Vector3.ONE * rng.randf_range(0.06, 0.19), v, "cff8ff" if i % 3 else "f8cbde", 0.8)
	G.batch(dust)
	ship = Props.ship()
	add_child(ship)
	configure(0)

func configure(index: int) -> void:
	planet = index
	ship.configure(index)
	preload("res://scripts/space_backdrops.gd").apply(self,index)
	var replacement:=PlanetVisual.create(index,17.)
	remove_child(globe); globe.free(); globe=replacement; add_child(globe)
	globe_material=globe.get_node("Surface").material_override
	for child in moons.get_children(): child.free()
	var profile:=preload("res://scripts/planet_identity.gd").get_profile(index)
	for i in int(profile.moons):
		var mat:=StandardMaterial3D.new(); mat.albedo_texture=PlanetVisual.MAPS[2]; mat.albedo_color=Color(profile.ridge); mat.roughness=.94
		var moon:=G.part(moons,PlanetVisual.shared_mesh,Vector3(17 if i==0 else -14,7 if i==0 else 11,-14 if i==0 else -22),mat)
		moon.scale=Vector3.ONE*(2.4 if i==0 else 1.35); moon.rotation=Vector3(.1,index*.37+i,.2)
	dust.rotation.y=index*.41

func stage(time: float, mode: String) -> Dictionary:
	globe.rotation.y = time * 0.035
	PlanetVisual.advance(globe,time)
	var angle := time * 0.13
	if mode == "intro": angle = -0.8 + time * 0.16
	elif mode == "outro": angle = time * 0.24
	if planet == 3 and mode == "outro": angle = time * 0.34
	ship.position = Vector3(sin(angle) * 13.7, 3.7 + sin(time * 0.4) * 1.3, cos(angle) * 13.7)
	ship.rotation = Vector3(0.1, angle + PI * 1.5, -0.13)
	var camera_at := Vector3(sin(angle + 0.65) * 29, 11.5, cos(angle + 0.65) * 29)
	if mode == "intro":
		var k := smoothstep(3.0, 7.0, time)
		var front_quarter := ship.position + ship.basis * Vector3(5.8,2.75,-10.)
		camera_at = camera_at.lerp(front_quarter,k)
		var cockpit := ship.position + Vector3.UP*2.18
		return {"position":position+camera_at,"target":position+(ship.position*.35).lerp(cockpit,.28+k*.58)}
	return {"position": position + camera_at, "target": position + ship.position * 0.35}
