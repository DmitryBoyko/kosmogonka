extends Node3D
const G=preload("res://scripts/geometry.gd")
var led:ShaderMaterial
var beam:ShaderMaterial
var beams:Node3D
var halo:ShaderMaterial
var halos:Node3D
var variant:=0
var parked:=false
var headlight:SpotLight3D
static func add_to(truck:Node3D,index:int,broken:bool=false) -> void:
	var root:Node3D=load("res://scripts/truck_cabin.gd").new(); truck.add_child(root); root.name="AlienCabin"; root.variant=index; root.parked=false; root.build()
	root.set_meta("motion","lights")
	if broken: root.scale.y=.82
	truck.set_meta("cabin",root); truck.rotation.y=PI
func build() -> void:
	var glass:=StandardMaterial3D.new()
	glass.albedo_color=Color("769ab5")
	glass.metallic=.87
	glass.roughness=.18
	glass.cull_mode=BaseMaterial3D.CULL_DISABLED
	var st:=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners=[Vector3(-.60,1.91,-2.69),Vector3(.60,1.91,-2.69),Vector3(.76,2.76,-2.20),Vector3(-.76,2.76,-2.20)]
	for i in [0,2,1,0,3,2]: st.set_normal(Vector3(0,.5,-.85)); st.add_vertex(corners[i])
	G.part(self,st.commit(),Vector3.ZERO,glass)
	for side in [-1,1]:
		G.link(self,Vector3(side*.60,1.91,-2.69),Vector3(side*.76,2.76,-2.20),.04,"43566d")
	G.box(self,Vector3(1.58,.10,1.55),Vector3(0,2.87,-1.45),"57788a")
	led=ShaderMaterial.new(); led.shader=preload("res://assets/surfaces/truck_led.gdshader")
	beam=ShaderMaterial.new(); beam.shader=preload("res://assets/surfaces/truck_beam.gdshader")
	beams=Node3D.new(); add_child(beams)
	beams.hide()
	halo=ShaderMaterial.new(); halo.shader=preload("res://assets/surfaces/truck_halo.gdshader")
	halos=Node3D.new(); add_child(halos)
	halos.hide()
	var glow_quad:=QuadMesh.new()
	glow_quad.size=Vector2(.85,.60)
	for side in [-1,1]:
		for segment in 4:
			G.box(self,Vector3(.095,.045,.035),Vector3(side*(.37+segment*.105),1.40,-2.735)).material_override=led
		G.box(self,Vector3(.045,.20,.04),Vector3(side*.745,1.33,-2.73)).material_override=led
		var cone:=SurfaceTool.new(); cone.begin(Mesh.PRIMITIVE_TRIANGLES)
		var a:=Vector3(side*.55,1.40,-2.76)
		for edge in 4:
			var angles=[Vector2(-1,-.5),Vector2(1,-.5),Vector2(1,.5),Vector2(-1,.5)]
			cone.set_uv(Vector2(.5,0)); cone.add_vertex(a)
			for offset in [edge,(edge+1)%4]: cone.set_uv(Vector2(float(offset%2),1)); cone.add_vertex(a+Vector3(angles[offset].x*1.2,angles[offset].y,-8.))
		cone.generate_normals(); G.part(beams,cone.commit(),Vector3.ZERO,beam)
		var flare:=G.part(halos,glow_quad,Vector3(side*.56,1.40,-2.79),halo)
		flare.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	headlight=SpotLight3D.new(); headlight.name="ModernHeadlight"; add_child(headlight)
	headlight.position=Vector3(0,1.4,-2.8); headlight.light_color=Color("d6efff")
	headlight.spot_range=55.; headlight.spot_angle=28.; headlight.spot_attenuation=.6
	headlight.shadow_enabled=false; headlight.hide()

static func approach_flash(rel:float) -> float:
	return smoothstep(5.,9.,-rel)*(1.-smoothstep(92.,112.,-rel))
static func double_flash(rel:float) -> float:
	var phase:=fposmod((94.+rel)/19.5,1.)
	var first:=smoothstep(.015,.06,phase)*(1.-smoothstep(.25,.31,phase))
	var second:=smoothstep(.47,.52,phase)*(1.-smoothstep(.72,.78,phase))
	return maxf(first,second)
func advance(_clock:float,rel:float,aligned:bool,reduced:bool) -> void:
	var flash:float=approach_flash(rel)*double_flash(rel) if not reduced and not parked else 0.
	led.set_shader_parameter("power",(.52 if parked or reduced else .16)+flash*3.6)
	halo.set_shader_parameter("power",flash); halos.visible=flash>.02
	beam.set_shader_parameter("power",flash*(3.1 if aligned else 2.1)); beams.visible=flash>.02
	headlight.visible=not parked and rel< -5. and rel> -52. and (reduced or flash>.02)
	headlight.light_energy=.52+flash*(5.8 if aligned else 3.4)
