extends Node3D
## Adaptation of GraviCube/scripts/CoreBeacon.cs: pulsing heart, halo and ray tips.
const G=preload("res://scripts/geometry.gd")
var heart:MeshInstance3D
var halo:MeshInstance3D
var rays:Node3D
var phase:=0.
func build(world:int) -> void:
	var color:=Color(preload("res://scripts/planets.gd").get_data(world).accent)
	var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.albedo_color=color.lightened(.25);mat.emission_enabled=true;mat.emission=color;mat.emission_energy_multiplier=1.4
	heart=G.ball(self,Vector3.ONE*2.1,Vector3.ZERO);heart.material_override=mat
	halo=G.ring(self,1.65,1.82,Vector3.ZERO);halo.material_override=mat;halo.rotation.x=PI*.5
	rays=Node3D.new();add_child(rays)
	for i in 6:
		var a:=i*TAU/6.;var tip:=Vector3(sin(a)*2.75,cos(a)*2.75,sin(a*2.)*.45)
		G.link(rays,tip.normalized()*1.1,tip,.035,"86e9fa").material_override=G.material("86e9fa",.6)
		G.ball(rays,Vector3.ONE*.28,tip,"c4f9ed",.6)
	G.merge_static(rays)
	for mesh:GeometryInstance3D in find_children("*","GeometryInstance3D",true,false):mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func advance(clock:float,reduced:bool) -> void:
	var t:float=0. if reduced else clock
	heart.scale=Vector3.ONE*(1.+sin(t*3.)*.14)
	halo.rotation=Vector3(PI*.5+sin(t*.55)*.22,t*.22,0)
	rays.rotation=Vector3(0,0,t*.13)
