extends Node3D
## Crossed additive plume volumes. Simulation time freezes with the hero on pause.
const EXHAUST=preload("res://assets/suits/jet_exhaust.gdshader")
const PLUME=preload("res://assets/suits/textures/jet_plume_v1.png")
const TRAIL_NOISE=preload("res://assets/effects/energy/noise_soft.png")
var jets: Array[Node3D]=[]
var lights: Array[OmniLight3D]=[]
var materials: Array[ShaderMaterial]=[]
var flow_time:=0.0
var power:=0.0

func build() -> void:
	var quad:=QuadMesh.new()
	quad.size=Vector2(.79,1.72)
	for i in 2:
		var side: float=-1.0 if i==0 else 1.0
		var jet:=Node3D.new()
		add_child(jet)
		jet.position=Vector3(side*0.37,0.755,-0.4)
		jet.rotation.x=.23
		jet.visible=false
		jets.append(jet)
		var mat:=ShaderMaterial.new()
		mat.shader=EXHAUST
		mat.set_shader_parameter("plume_texture",PLUME)
		mat.set_shader_parameter("trail_noise",TRAIL_NOISE)
		mat.set_shader_parameter("rocket_trail",true)
		mat.set_shader_parameter("phase_offset",i*0.713)
		materials.append(mat)
		for plane in 2:
			var plume:=MeshInstance3D.new()
			jet.add_child(plume)
			plume.mesh=quad
			plume.material_override=mat
			plume.position.y=-quad.size.y*.5
			plume.rotation.y=plane*PI*.5
			plume.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var light:=OmniLight3D.new()
		jet.add_child(light)
		light.position=Vector3(0,-0.12,0)
		light.light_color=Color("ffc16b")
		light.omni_range=1.45
		light.light_energy=0.0
		light.shadow_enabled=false
		lights.append(light)

func advance(dt: float, active: bool, intensity:float=1.) -> void:
	if not active and power<=0.: return
	flow_time+=dt
	power=move_toward(power,clampf(intensity,1.,1.9) if active else 0.,dt*(12. if active else 8.5))
	for i in jets.size():
		jets[i].visible=power>0.
		var flutter:=1.+sin(flow_time*31.+i)*.09+sin(flow_time*57.+i*2.)*.045
		var width:=.80+minf(1.9,power)*.21
		jets[i].scale=Vector3(width,flutter*(.30+power*.70),width)
		materials[i].set_shader_parameter("flow_time",flow_time)
		materials[i].set_shader_parameter("power",power)
		lights[i].light_energy=power*(.40+sin(flow_time*31+i)*.09)
