extends Node3D

const G = preload("res://scripts/geometry.gd")
const ModelPath := "res://assets/finish_city/bunker/deep_space_guard.glb"
var model: Node3D
var scanner: MeshInstance3D
var scanner_material: StandardMaterial3D
var age := 0.
var rig: RefCounted
var joint_sparks: Node3D

func build() -> void:
	name="BunkerGuard"
	set_meta("motion",true)
	model=load(ModelPath).instantiate()
	add_child(model)
	preload("res://scripts/robot_armor.gd").apply(model)
	var track := preload("res://scripts/loop_layout.gd")
	var bounds := track.bounds(model,Transform3D.IDENTITY)
	var fit := 3.05 / maxf(.01,bounds.size.y)
	model.scale=Vector3.ONE*fit
	# Imported guard faces -Z; the patrol and scanner use +Z as forward.
	model.rotation.y=PI
	model.position=-(Basis(Vector3.UP,PI)*Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z))*fit
	rig=preload("res://scripts/robot_rig.gd").new()
	rig.build(model,fit)
	joint_sparks=preload("res://scripts/robot_sparks.gd").new();add_child(joint_sparks);joint_sparks.build(3.05,1.2)
	var cone := CylinderMesh.new()
	cone.top_radius = .04
	cone.bottom_radius = 1.1
	cone.height = 1.
	cone.radial_segments = 18
	cone.cap_top=false
	cone.cap_bottom=false
	scanner_material = StandardMaterial3D.new()
	scanner_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	scanner_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	scanner_material.cull_mode=BaseMaterial3D.CULL_DISABLED
	scanner_material.albedo_color=Color(.15,1.,.68,.18)
	scanner=G.part(self,cone,Vector3.ZERO,scanner_material)
	scanner.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	scanner.hide()
	position=Vector3(5.65,0.,5.28)

func advance(dt: float, reduced: bool) -> void:
	age+=dt
	var phase := fposmod(age,14.)
	var returning := phase>=7.
	var leg := fposmod(phase,7.)
	var walking := leg>.65 and leg<4.65
	var direction := 1. if returning else -1.
	var progress := smoothstep(.65,4.65,leg)
	var previous_x:=position.x
	position.x=lerpf(3.4,5.65,progress if returning else 1.-progress)
	rotation.y=lerp_angle(rotation.y,direction*PI*.5 if leg<4.65 else 0.,1.-exp(-dt*6.))
	rig.advance(dt,absf(position.x-previous_x)/maxf(dt,.001),reduced)
	joint_sparks.advance(dt,absf(position.x-previous_x)>.0001,reduced)
	scanner.visible=not walking and leg>5.1 and leg<6.85
	if scanner.visible:
		var eye:=Vector3(0,2.45,.60)
		var target:=Vector3(lerpf(-3.2,1.1,smoothstep(5.1,6.85,leg)),.24,4.7)
		var ray:=target-eye
		scanner.position=eye+ray*.5
		scanner.quaternion=Quaternion(Vector3.DOWN,ray.normalized())
		scanner.scale=Vector3(1.,ray.length(),1.)
