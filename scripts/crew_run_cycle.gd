extends RefCounted

const Joints = preload("res://scripts/crew_joints.gd")
const CLIPS := ["idle","walk","sprint","jump","crouch","fall","sit","emote-yes","interact-right","wave"]
const LOOPED := ["idle","walk","sprint","crouch","fall","sit","wave"]
static var libraries: Dictionary = {}

static func attach(player: AnimationPlayer, skeleton: Skeleton3D, character_index: int) -> void:
	if not libraries.has(character_index):
		var library := AnimationLibrary.new()
		for clip in CLIPS:
			library.add_animation(clip,adapt(player.get_animation("idle" if clip=="wave" else clip),skeleton,clip))
		libraries[character_index] = library
	player.add_animation_library("crew",libraries[character_index])

static func adapt(source: Animation, skeleton: Skeleton3D, clip: String) -> Animation:
	var cycle := source.duplicate() as Animation
	if clip in LOOPED:
		cycle.loop_mode = Animation.LOOP_LINEAR
	var track_root := ""
	var rotations := {}
	var positions := {}
	for track in cycle.get_track_count():
		var path := String(cycle.track_get_path(track))
		var bone := path.get_slice(":",1)
		track_root = path.get_slice(":",0)
		var type := cycle.track_get_type(track)
		if type == Animation.TYPE_ROTATION_3D:
			rotations[bone] = track
			if clip == "sprint" and bone in ["torso","head"]:
				var neutral: Quaternion = cycle.track_get_key_value(track,0)
				for key in cycle.track_get_key_count(track):
					var pose: Quaternion = cycle.track_get_key_value(track,key)
					var rotation := neutral.slerp(pose,.24 if bone == "torso" else .38)
					if bone == "torso":
						rotation = Quaternion(Vector3.RIGHT,deg_to_rad(7.)) * rotation
					cycle.track_set_key_value(track,key,rotation.normalized())
				cycle.track_set_interpolation_type(track,Animation.INTERPOLATION_CUBIC)
		elif type == Animation.TYPE_POSITION_3D:
			positions[bone] = track
		if bone == "root" and type == Animation.TYPE_POSITION_3D and clip == "sprint":
			var base: Vector3 = cycle.track_get_key_value(track,0)
			clear_keys(cycle,track)
			for sample in 25:
				var phase := float(sample) / 24.
				var height := .015 * (1. - cos(TAU * 2. * phase))
				cycle.position_track_insert_key(track,phase * cycle.length,base + Vector3.UP * height)
			cycle.track_set_interpolation_type(track,Animation.INTERPOLATION_CUBIC)

	var offsets := Joints.position_offsets(clip)
	for bone: String in offsets:
		var offset: Vector3 = offsets[bone]
		if positions.has(bone):
			var track: int = positions[bone]
			for key in cycle.track_get_key_count(track):
				var position: Vector3 = cycle.track_get_key_value(track,key)
				cycle.track_set_key_value(track,key,position + offset)
		else:
			var track := cycle.add_track(Animation.TYPE_POSITION_3D)
			cycle.track_set_path(track,NodePath(track_root + ":" + bone))
			cycle.position_track_insert_key(track,0.,skeleton.get_bone_rest(skeleton.find_bone(bone)).origin + offset)

	for side in ["left","right"]:
		var direction := 1. if side == "left" else -1.
		var elbow := add_rotation(cycle,track_root,"elbow-" + side)
		var knee := add_rotation(cycle,track_root,"knee-" + side)
		var ankle := add_rotation(cycle,track_root,"ankle-" + side)
		var shoulder: int = rotations.get("arm-" + side,-1)
		var thigh: int = rotations.get("leg-" + side,-1)
		var running := clip in ["sprint","walk"]
		var sprint := clip == "sprint"
		if running or clip in ["idle","wave","sit"]:
			clear_keys(cycle,shoulder)
		if running or clip == "crouch":
			clear_keys(cycle,thigh)
		var samples := 25 if running or clip in ["idle","wave"] else 1
		var rest_elbow: float = {"idle":.21,"jump":.65,"crouch":.8,"fall":.40,"sit":.62,"emote-yes":.42,"interact-right":.30}.get(clip,.32)
		var rest_knee: float = {"idle":.0,"jump":.62,"crouch":1.74,"fall":.35,"sit":1.24}.get(clip,.05)
		for sample in samples:
			var phase := TAU * float(sample) / 24.
			var time := cycle.length * float(sample) / 24.
			var swing := sin(phase) * direction
			var bend_elbow := rest_elbow
			var bend_knee := rest_knee
			var bend_ankle := 0.
			if running:
				var legs := stride_angles(phase,direction,sprint)
				bend_knee = legs.y
				bend_ankle = legs.z
				bend_elbow = (.96 if sprint else .50) + swing * (.25 if sprint else .17)
				cycle.rotation_track_insert_key(thigh,time,Quaternion(Vector3.RIGHT,legs.x))
				var pitch := swing * (.65 if sprint else .41)
				var arm := Quaternion(Vector3.RIGHT,pitch) * Quaternion(Vector3.BACK,-direction * 1.30)
				cycle.rotation_track_insert_key(shoulder,time,arm.normalized())
			elif clip in ["idle","wave"]:
				var arm_angle := direction*.84 if clip=="wave" and side=="right" else -direction*1.32
				var arm := Quaternion(Vector3.RIGHT,sin(phase)*.035) * Quaternion(Vector3.BACK,arm_angle)
				cycle.rotation_track_insert_key(shoulder,time,arm.normalized())
			elif clip == "crouch":
				cycle.rotation_track_insert_key(thigh,time,Quaternion(Vector3.RIGHT,-1.23))
			elif clip == "sit":
				var arm := Quaternion(Vector3.RIGHT,-.50) * Quaternion(Vector3.BACK,-direction * 1.37)
				cycle.rotation_track_insert_key(shoulder,time,arm.normalized())
			var elbow_pose := Quaternion(Vector3.UP,-direction * bend_elbow)
			if clip=="wave" and side=="right":
				elbow_pose=Quaternion(Vector3.BACK,-.40+sin(phase*2.)*.39)*Quaternion(Vector3.UP,.27)
			cycle.rotation_track_insert_key(elbow,time,elbow_pose)
			cycle.rotation_track_insert_key(knee,time,Quaternion(Vector3.RIGHT,bend_knee))
			cycle.rotation_track_insert_key(ankle,time,Quaternion(Vector3.RIGHT,bend_ankle))
	if clip == "walk" and positions.has("root"):
		plant_walk(cycle,positions["root"],skeleton.get_bone_rest(skeleton.find_bone("leg-left")).origin.y+Joints.HIP_LIFT)
	return cycle

static func stride_angles(phase: float, side: float, sprint: bool) -> Vector3:
	var swing := sin(phase)*side
	var recovery := maxf(0.,sin(phase+.95)*side)
	var hip := swing*(-.68 if sprint else -.44)
	var knee := .08+recovery*(.93 if sprint else .58)
	return Vector3(hip,knee,-(hip+knee)*.72)

static func plant_walk(cycle: Animation, track: int, hip_y: float) -> void:
	var samples := PackedVector3Array()
	for i in 25:
		var phase := TAU*float(i)/24.
		var point := cycle.position_track_interpolate(track,cycle.length*float(i)/24.)
		point.y = -minf(sole_height(hip_y,stride_angles(phase,1.,false)),sole_height(hip_y,stride_angles(phase,-1.,false)))
		samples.append(point)
	clear_keys(cycle,track)
	for i in samples.size():
		cycle.position_track_insert_key(track,cycle.length*float(i)/24.,samples[i])
	cycle.track_set_interpolation_type(track,Animation.INTERPOLATION_CUBIC)

static func sole_height(hip_y: float, angles: Vector3) -> float:
	var shin := angles.x+angles.y
	var ankle := shin+angles.z
	var ankle_y := hip_y-cos(angles.x)*Joints.THIGH_LENGTH-cos(shin)*Joints.SHIN_LENGTH
	return ankle_y-.027*cos(ankle)+minf(.032*sin(ankle),-.086*sin(ankle))

static func clear_keys(cycle: Animation, track: int) -> void:
	for key in range(cycle.track_get_key_count(track)-1,-1,-1):
		cycle.track_remove_key(track,key)

static func add_rotation(cycle: Animation, path: String, bone: String) -> int:
	var track := cycle.add_track(Animation.TYPE_ROTATION_3D)
	cycle.track_set_path(track,NodePath(path + ":" + bone))
	return track
