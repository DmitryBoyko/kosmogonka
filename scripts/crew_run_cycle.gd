extends RefCounted

static var cycles: Dictionary = {}

static func attach(player: AnimationPlayer, character_index: int) -> void:
	if not cycles.has(character_index):
		cycles[character_index] = smooth_sprint(player.get_animation("sprint"))
	var library := AnimationLibrary.new()
	library.add_animation("sprint", cycles[character_index])
	player.add_animation_library("crew", library)

static func smooth_sprint(source: Animation) -> Animation:
	var cycle := source.duplicate() as Animation
	cycle.loop_mode = Animation.LOOP_LINEAR
	for track in cycle.get_track_count():
		var bone := String(cycle.track_get_path(track)).get_slice(":", 1)
		var type := cycle.track_get_type(track)
		if bone == "root" and type == Animation.TYPE_POSITION_3D:
			var base: Vector3 = cycle.track_get_key_value(track, 0)
			for key in range(cycle.track_get_key_count(track) - 1, -1, -1):
				cycle.track_remove_key(track, key)
			# Two shallow rises per stride. Match the value and slope at the seam.
			for sample in 31:
				var phase := float(sample) / 30.
				var height := .015 * (1. - cos(TAU * 2. * phase))
				cycle.position_track_insert_key(track, phase * cycle.length, base + Vector3.UP * height)
			cycle.track_set_interpolation_type(track, Animation.INTERPOLATION_CUBIC)
		elif type == Animation.TYPE_ROTATION_3D and cycle.track_get_key_count(track) > 1:
			var neutral: Quaternion = cycle.track_get_key_value(track, 0)
			var weight := .75
			if bone == "torso":
				weight = .24
			elif bone == "head":
				weight = .38
			for key in cycle.track_get_key_count(track):
				var pose: Quaternion = cycle.track_get_key_value(track, key)
				var rotation := neutral.slerp(pose, weight)
				if bone == "torso":
					rotation = Quaternion(Vector3.RIGHT, deg_to_rad(7.)) * rotation
				cycle.track_set_key_value(track, key, rotation.normalized())
			cycle.track_set_interpolation_type(track, Animation.INTERPOLATION_CUBIC)
	return cycle
