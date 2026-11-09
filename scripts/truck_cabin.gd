extends Node3D
const G=preload("res://scripts/geometry.gd")
var head:Node3D
var led:ShaderMaterial
var beam:ShaderMaterial
var beams:Node3D
var variant:=0
var parked:=false
var headlight:SpotLight3D
static func add_to(truck:Node3D,index:int,broken:bool=false) -> void:
	var root:Node3D=load("res://scripts/truck_cabin.gd").new(); truck.add_child(root); root.name="AlienCabin"; root.variant=index; root.parked=broken; root.build()
	root.set_meta("motion","driver")
	if broken: root.scale.y=.82
	truck.set_meta("cabin",root); truck.rotation.y=PI
func build() -> void:
	var seat:=G.box(self,Vector3(.7,.65,.15),Vector3(0,1.55,-1.02),"263b51")
	seat.rotation.x=.1
	G.ball(self,Vector3(.52,.62,.42),Vector3(0,1.75,-1.43),"8fe4ae")
	head=Node3D.new(); add_child(head); head.position=Vector3(0,2.30,-1.48)
	G.ball(head,Vector3(.64,.61,.55),Vector3.ZERO,"a88bdd" if variant%2 else "8fe4ae")
	for side in [-1,1]:
		G.ball(head,Vector3(.23,.24,.14),Vector3(side*.15,.06,-.24),"fff9ed")
		G.ball(head,Vector3(.10,.12,.04),Vector3(side*.15,.06,-.32),"263b51")
		G.link(self,Vector3(side*.24,1.9,-1.42),Vector3(side*.29,1.75,-1.88),.055,"8fe4ae")
		G.ball(self,Vector3.ONE*.13,Vector3(side*.29,1.75,-1.88),"8fe4ae")
	G.ball(head,Vector3(.18,.04,.035),Vector3(0,-.13,-.27),"3b6856")
	G.ring(self,.24,.28,Vector3(0,1.75,-1.9),"425874").rotation.x=PI*.3
	var glass:=preload("res://scripts/city_windows.gd").glazing()
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
	headlight=SpotLight3D.new(); headlight.name="ModernHeadlight"; add_child(headlight)
	headlight.position=Vector3(0,1.4,-2.8); headlight.light_color=Color("d6efff")
	headlight.spot_range=26.; headlight.spot_angle=32.; headlight.spot_attenuation=.6
	headlight.shadow_enabled=false; headlight.hide()

static func approach_flash(rel:float) -> float:
	if rel>=-5. or rel< -65.: return 0.
	var strength:=0.
	for marker in [52.,42.,24.,14.]: strength=maxf(strength,1.-smoothstep(1.2,3.5,absf(-rel-marker)))
	return strength
func advance(clock:float,rel:float,aligned:bool,reduced:bool) -> void:
	head.rotation.y=sin(clock*.9+variant)*.10
	var flash:float=approach_flash(rel) if not reduced and not parked else 0.
	led.set_shader_parameter("power",(.4 if parked else .8)+flash*1.15)
	beam.set_shader_parameter("power",flash*(1. if aligned else .6)); beams.visible=flash>.01
	headlight.visible=not parked and rel< -5. and rel> -26.
	headlight.light_energy=.7+flash*(2. if aligned else 1.2)
