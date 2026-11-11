extends Node3D
## Pulsing beacon with the GraviCube silhouette and REEBOO plasma and arcs.

const G = preload("res://scripts/geometry.gd")
const FX = preload("res://scripts/energy_effects.gd")
const Planets = preload("res://scripts/planets.gd")
var heart: MeshInstance3D
var halo: MeshInstance3D
var orbit: MeshInstance3D
var rays: MultiMeshInstance3D

func build(world: int) -> void:
	var color := Color(Planets.get_data(world).accent)
	var secondary := Color("58daff") if world in [2,5,8] else Color("dc8bff")
	heart = G.ball(self,Vector3.ONE*2.45,Vector3.ZERO)
	heart.material_override = FX.material(FX.PLASMA,color)
	halo = G.ring(self,1.62,1.72,Vector3.ZERO,color.lightened(.18).to_html(false),.73)
	orbit = FX.vortex(self,Vector2(7.1,5.9),Vector3.ZERO,secondary,true)
	rays = FX.filaments(self,color.lerp(secondary,.30))
	for mesh: GeometryInstance3D in [heart,halo,orbit,rays]:
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func advance(clock: float, reduced: bool) -> void:
	var t := 0. if reduced else clock
	heart.scale = Vector3.ONE*(2.45 + sin(t*3.)*.19)
	heart.material_override.set_shader_parameter("energy_time",t)
	halo.rotation = Vector3(PI*.5+sin(t*.55)*.37,t*.33,0.)
	orbit.rotation = Vector3(.18+sin(t*.54)*.16,t*.37, t*.13)
	orbit.material_override.set_shader_parameter("energy_time",t)
	rays.rotation = Vector3(sin(t*.44)*.37,t*.29,t*.22)
	rays.material_override.set_shader_parameter("energy_time",t)
