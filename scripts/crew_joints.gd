extends RefCounted

const G = preload("res://scripts/geometry.gd")
const Shell = preload("res://scripts/salvage_mesh.gd")
const SIDES := ["left","right"]
const HIP_LIFT := .084
const HEAD_LIFT := .031
const SHOULDER_LIFT := .034
const SHOULDER_WIDTH := .026
const THIGH_LENGTH := .132
const SHIN_LENGTH := .101
const UPPER_ARM_LENGTH := .132
const BADGE_POSITION := Vector3(0,.134,.083)
const BACKPACK_POSITION := Vector3(0,.126,-.117)
static var segments: Dictionary = {}

static func position_offsets(clip: String) -> Dictionary:
	var offsets := {
		"torso": Vector3.UP * HIP_LIFT,
		"head": Vector3.UP * HEAD_LIFT,
		"leg-left": Vector3.UP * HIP_LIFT,
		"leg-right": Vector3.UP * HIP_LIFT,
		"arm-left": Vector3(SHOULDER_WIDTH,SHOULDER_LIFT,0),
		"arm-right": Vector3(-SHOULDER_WIDTH,SHOULDER_LIFT,0)
	}
	if clip == "sit":
		offsets["root"] = Vector3.DOWN * (HIP_LIFT + HEAD_LIFT)
	return offsets

static func add_joint(skeleton: Skeleton3D, joint: String, parent: String, offset: Vector3) -> void:
	var index := skeleton.add_bone(joint)
	skeleton.set_bone_parent(index,skeleton.find_bone(parent))
	skeleton.set_bone_rest(index,Transform3D(Basis.IDENTITY,offset))
	skeleton.reset_bone_pose(index)

static func build_torso(avatar: Node3D, primary: String, trim: String, weave: String) -> void:
	var chest: Node3D = avatar.chest
	var jacket := segment(chest,[Vector3(0,.006,0),Vector3(0,.052,0),Vector3(0,.125,0),Vector3(0,.164,0),Vector3(0,.194,0)],
		[.099,.083,.109,.119,.076],G.material(primary,.17))
	jacket.scale.z = .65
	var pelvis := segment(chest,[Vector3(0,-.035,0),Vector3(0,-.013,0),Vector3(0,.015,0),Vector3(0,.047,0)],
		[.077,.098,.109,.086],G.material(weave,.08))
	pelvis.scale.z = .65
	var panel := Shell.block(chest,Vector3(.136,.073,.018),BADGE_POSITION - Vector3(0,0,.012),G.material(trim,.17),.014)
	var belt := segment(chest,[Vector3(0,.040,0),Vector3(0,.062,0)],[.087,.086],G.material(weave))
	belt.scale.z = .72
	G.box(chest,Vector3(.045,.027,.015),Vector3(0,.050,.063),trim,.14)
	var collar := G.ring(chest,.050,.071,Vector3(0,.198,0),weave)
	collar.scale.z = .80
	avatar.panels["torso"] = [jacket,panel]

static func build(avatar: Node3D, primary: String, trim: String, weave: String) -> void:
	for group in ["arms","gloves","legs","boots"]:
		avatar.panels[group] = []
	for side: String in SIDES:
		var sign_value := 1. if side == "left" else -1.
		var shoulder := "arm-" + side
		var elbow := "elbow-" + side
		var hip := "leg-" + side
		var knee := "knee-" + side
		var ankle := "ankle-" + side
		add_joint(avatar.skeleton,elbow,shoulder,Vector3(sign_value * UPPER_ARM_LENGTH,0,0))
		add_joint(avatar.skeleton,knee,hip,Vector3(0,-THIGH_LENGTH,0))
		add_joint(avatar.skeleton,ankle,knee,Vector3(0,-SHIN_LENGTH,0))

		var upper: Node3D = avatar.mount(shoulder)
		var forearm: Node3D = avatar.mount(elbow)
		var thigh: Node3D = avatar.mount(hip)
		var shin: Node3D = avatar.mount(knee)
		var foot: Node3D = avatar.mount(ankle)

		var sleeve := segment(upper,[Vector3(sign_value*.008,0,0),Vector3(sign_value*.043,0,0),Vector3(sign_value*.123,0,0)],
			[.038,.050,.031],G.material(primary,.17))
		avatar.panels["arms"].append(sleeve)
		var gauntlet := segment(forearm,[Vector3(sign_value*.021,0,0),Vector3(sign_value*.044,0,0),Vector3(sign_value*.094,0,0)],
			[.030,.036,.026],G.material(primary,.17))
		avatar.panels["arms"].append(gauntlet)
		G.ball(forearm,Vector3(.065,.065,.068),Vector3.ZERO,weave)
		plate(avatar,"gloves",forearm,Vector3(.054,.061,.069),Vector3(sign_value*.111,0,.003),trim)
		G.box(forearm,Vector3(.023,.030,.012),Vector3(sign_value*.109,0,.038),primary,.18)

		var upper_leg := segment(thigh,[Vector3(0,-.007,0),Vector3(0,-.041,0),Vector3(0,-.123,0)],
			[.046,.047,.033],G.material(weave,.08))
		upper_leg.scale.z = .92
		avatar.panels["legs"].append(upper_leg)
		G.ball(shin,Vector3(.068,.066,.071),Vector3.ZERO,weave)
		var lower_leg := segment(shin,[Vector3(0,-.013,0),Vector3(0,-.043,0),Vector3(0,-.094,0)],
			[.033,.041,.027],G.material(primary,.17))
		avatar.panels["legs"].append(lower_leg)
		plate(avatar,"legs",shin,Vector3(.049,.042,.020),Vector3(0,-.014,.037),primary)
		plate(avatar,"boots",foot,Vector3(.085,.046,.118),Vector3(0,-.004,.027),trim)
		plate(avatar,"boots",foot,Vector3(.072,.032,.068),Vector3(0,.019,.007),trim)

static func segment(at: Node3D, points: Array, radii: Array, material: Material) -> MeshInstance3D:
	var key := str(points) + "/" + str(radii)
	if segments.has(key):
		return G.part(at,segments[key],Vector3.ZERO,material)
	var piece := Shell.limb(at,points,radii,material,8)
	piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	segments[key] = piece.mesh
	return piece

static func plate(avatar: Node3D, group: String, at: Node3D, size: Vector3, position: Vector3, color: String) -> void:
	var piece := Shell.block(at,size,position,G.material(color,.17),.013)
	piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	avatar.panels[group].append(piece)
