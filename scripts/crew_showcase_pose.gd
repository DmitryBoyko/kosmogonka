extends RefCounted

const Jet = preload("res://scripts/jetpack_fx.gd")
const Joints = preload("res://scripts/crew_joints.gd")
const FOREARM_LENGTH := .111

var actor: Node3D
var rig: Skeleton3D
var bones: Dictionary = {}
var neutral: Dictionary = {}
var jets: Node3D
var posed := false

func _init(avatar: Node3D) -> void:
	actor = avatar
	rig = actor.skeleton
	for name_value: String in ["torso","head","arm-left","arm-right","elbow-left","elbow-right","leg-left","leg-right","knee-left","knee-right"]:
		bones[name_value] = rig.find_bone(name_value)

func begin() -> void:
	actor.animation.play("crew/idle",0.)
	actor.animation.seek(0.,true)
	actor.animation.pause()
	for name_value: String in bones:
		neutral[name_value] = rig.get_bone_pose_rotation(bones[name_value])
	posed = true

func release() -> void:
	if not posed:
		return
	set_exhaust(0.,0.)
	actor.animation.play("crew/idle",0.)
	actor.animation.seek(0.,true)
	posed = false

func update(dt: float, time: float, gaze: float, airborne: float, lean: float, grin: float, reduced: bool) -> void:
	if not posed:
		begin()
	var phase: float = time + actor.character_index*.91
	var breath := 0. if reduced else sin(phase*1.31)
	var glance_time := fposmod(phase,7.8)
	var glance := 0. if reduced else smoothstep(1.4,2.15,glance_time)*(1.-smoothstep(3.3,4.15,glance_time))
	var glance_side := 1. if posmod(floori(phase/7.8)+actor.character_index,2)==0 else -1.
	set_rotation("torso",Vector3(.019*breath, .075*gaze, -.11*lean))
	set_rotation("head",Vector3(.018*breath-.024*glance-.045*airborne,
		.105*glance*glance_side+.21*gaze,.024*glance*glance_side+.08*lean))
	for side: String in Joints.SIDES:
		var sign_value := 1. if side=="left" else -1.
		set_rotation("arm-"+side,Vector3(-airborne*.25+breath*.012,0.,sign_value*.45*airborne))
		set_rotation("elbow-"+side,Vector3(0.,-sign_value*airborne*.47,0.))
		set_rotation("leg-"+side,Vector3((-0.30 if sign_value>0 else -.10)*airborne,0.,sign_value*.10*airborne))
		set_rotation("knee-"+side,Vector3((.46 if sign_value>0 else .29)*airborne,0.,0.))
	actor.update_expression(dt,.20+grin*.57)

func set_rotation(name_value: String, angles: Vector3) -> void:
	rig.set_bone_pose_rotation(bones[name_value],Quaternion.from_euler(angles)*neutral[name_value])

func reach(direction: float, target_world: Vector3, strength: float) -> void:
	if strength<=.001:
		return
	var side := "left" if direction>0. else "right"
	var shoulder: int = bones["arm-"+side]
	var elbow: int = bones["elbow-"+side]
	rig.force_update_all_bone_transforms()
	var torso := rig.get_bone_global_pose(bones["torso"])
	var start := rig.get_bone_pose_position(shoulder)
	var desired := torso.affine_inverse()*rig.to_local(target_world)-start
	if desired.length_squared()<.0001:
		return
	var direction_to_target := desired.normalized()
	var reach_length := clampf(desired.length(),.042,Joints.UPPER_ARM_LENGTH+FOREARM_LENGTH-.008)
	var bend_plane := Vector3(.0,-1.,.55)
	var bend_axis := (bend_plane-direction_to_target*bend_plane.dot(direction_to_target)).normalized()
	var along := (Joints.UPPER_ARM_LENGTH*Joints.UPPER_ARM_LENGTH-FOREARM_LENGTH*FOREARM_LENGTH+reach_length*reach_length)/(2.*reach_length)
	var upper := direction_to_target*along+bend_axis*sqrt(maxf(0.,Joints.UPPER_ARM_LENGTH*Joints.UPPER_ARM_LENGTH-along*along))
	var lower := direction_to_target*reach_length-upper
	var rest_axis := Vector3.RIGHT*direction
	var shoulder_target := Quaternion(rest_axis,upper.normalized())
	var elbow_target := Quaternion(rest_axis,shoulder_target.inverse()*lower.normalized())
	rig.set_bone_pose_rotation(shoulder,rig.get_bone_pose_rotation(shoulder).slerp(shoulder_target,strength))
	rig.set_bone_pose_rotation(elbow,rig.get_bone_pose_rotation(elbow).slerp(elbow_target,strength))

func set_exhaust(dt: float, amount: float) -> void:
	if amount>.001 and not is_instance_valid(jets):
		jets = Jet.new()
		jets.name = "ShowcaseJet"
		actor.add_child(jets)
		jets.position = Vector3(0.,.71,-.26)
		jets.scale = Vector3(.87,.73,.82)
		jets.rotation.x = .16
		jets.build()
		for material: ShaderMaterial in jets.materials:
			material.set_shader_parameter("fire_mode",true)
	if not is_instance_valid(jets):
		return
	jets.advance(dt,amount>.001)
	for i in jets.jets.size():
		jets.jets[i].scale.y *= lerpf(.72,1.76,amount)
		jets.materials[i].set_shader_parameter("power",jets.power*amount)
		jets.lights[i].light_energy *= amount
