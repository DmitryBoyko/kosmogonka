extends Node3D
## Crossed additive plume volumes. Simulation time freezes with the hero on pause.
const EXHAUST=preload("res://assets/suits/jet_exhaust.gdshader")
const PLUME=preload("res://assets/suits/textures/jet_plume_v1.png")
const G=preload("res://scripts/geometry.gd")
var jets: Array[Node3D]=[]
var lights: Array[OmniLight3D]=[]
var materials: Array[ShaderMaterial]=[]
var flow_time:=0.0
var power:=0.0

func build() -> void:
	var quad:=QuadMesh.new()
	quad.size=Vector2(0.74,1.35)
	for i in 2:
		var side: float=-1.0 if i==0 else 1.0
		var jet:=Node3D.new()
		add_child(jet)
		jet.position=Vector3(side*0.37,0.755,-0.4)
		jet.visible=false
		jets.append(jet)
		var mat:=ShaderMaterial.new()
		mat.shader=EXHAUST
		mat.set_shader_parameter("plume_texture",PLUME)
		mat.set_shader_parameter("phase_offset",i*0.713)
		materials.append(mat)
		for plane in 3:
			var plume:=MeshInstance3D.new()
			jet.add_child(plume)
			plume.mesh=quad
			plume.material_override=mat
			plume.position.y=-0.675
			plume.rotation.y=plane*PI/3.0
			plume.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var light:=OmniLight3D.new()
		jet.add_child(light)
		light.position=Vector3(0,-0.12,0)
		light.light_color=Color("8edbff")
		light.omni_range=1.65
		light.light_energy=0.0
		light.shadow_enabled=false
		lights.append(light)

func advance(dt: float, active: bool, intensity:float=1.) -> void:
	if active:
		flow_time+=dt
		power=move_toward(power,clampf(intensity,1.,1.9),dt*9.0)
	else: power=0.0
	for i in jets.size():
		jets[i].visible=active
		var flutter:=0.97+sin(flow_time*37+i)*0.018+sin(flow_time*61+i*2)*0.012
		jets[i].scale=Vector3(1.+(intensity-1.)*.22,flutter*(1.+(intensity-1.)*.9),1.+(intensity-1.)*.22)
		materials[i].set_shader_parameter("flow_time",flow_time)
		materials[i].set_shader_parameter("power",power)
		lights[i].light_energy=power*(0.6+sin(flow_time*31+i)*0.07)
