extends SceneTree
const Hero = preload("res://scripts/hero.gd")
var checks := 0
var failures := 0

func _initialize() -> void: call_deferred("run")
func check(ok: bool, label_value: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label_value)

func run() -> void:
	for girl in [false, true]:
		var kid = Hero.new()
		root.add_child(kid)
		kid.build(girl)
		var opposite := 0
		var sampled := 0
		var clear_hands := true
		var min_yaw := 0.0
		var max_yaw := 0.0
		var ahead := 0
		var hair_counterphase := 0.0
		var min_braid := 10.0
		var max_braid := -10.0
		check(kid.braids.size() == (2 if girl else 0), "girl has two separate long braids")
		check(kid.braid_links.size() == (6 if girl else 0), "braids have articulated links")
		check(is_instance_valid(kid.quiff) == not girl, "boy has a separate quiff pivot")
		check(kid.face.lashes.size() == 4, "both heroes have upper and lower curved eyelash fans")
		for frame in 960:
			kid.animate(1.0 / 60, "run", 18.0)
			min_yaw = minf(min_yaw, kid.head.rotation.y)
			max_yaw = maxf(max_yaw, kid.head.rotation.y)
			if absf(kid.head.rotation.y) < 0.06: ahead += 1
			if frame < 60: continue
			if girl:
				min_braid = minf(min_braid, kid.braid_links[2].rotation.x)
				max_braid = maxf(max_braid, kid.braid_links[2].rotation.x)
			else:
				hair_counterphase += (absf(sin(kid.stride_phase)) - 0.5) * (kid.quiff.position.y - 0.31)
			for i in 2:
				var side := -1.0 if i == 0 else 1.0
				var hand_in_body: Vector3 = kid.body.to_local(kid.hands[i].global_position)
				clear_hands = clear_hands and hand_in_body.x * side > 0.48
				if absf(kid.legs[i].rotation.x) > 0.35:
					sampled += 1
					if (kid.arms[i].rotation.x + 0.12) * kid.legs[i].rotation.x < 0: opposite += 1
		check(clear_hands, "hands remain outside the torso throughout the run")
		check(float(opposite) / sampled > 0.9, "arm swing opposes the leg on the same side")
		check(min_yaw < -0.18 and max_yaw > 0.18, "head glances in both directions")
		check(min_yaw > -0.3 and max_yaw < 0.3, "glances remain small")
		check(ahead > 600, "hero looks ahead most of the time")
		if girl:
			check(max_braid - min_braid > 0.07, "braid tips swing during running")
		else:
			check(hair_counterphase < 0, "quiff spring opposes the body's upward bounce")
		kid.animate(1.0 / 60, "run", 35)
		var phase_before: float = kid.stride_phase
		kid.animate(0, "run", 5)
		check(is_equal_approx(kid.stride_phase, phase_before), "speed change does not jump the stride phase")
		var pose_before: Transform3D = kid.arms[0].transform
		kid.animate(0, "run", 5)
		check(kid.arms[0].transform.is_equal_approx(pose_before), "zero elapsed time leaves the arm pose unchanged")
		for action in ["jump", "flip", "roll", "jet", "board", "slide", "win", "idle", "run"]:
			for frame in 30: kid.animate(1.0 / 60, action, 18)
			check(kid.head.transform.is_finite() and kid.body.transform.is_finite(), "finite pose: " + action)
			for link in kid.braid_links:
				check(link.transform.is_finite() and absf(link.rotation.x) < 0.2, "braid stays bounded in " + action)
			if action == "roll":
				check(kid.pivot.rotation.x < -1.5 and absf(kid.elbows[0].rotation.x) < 0.2, "back slide retains raised, extended arms")
			if action == "run":
				check(kid.pivot.rotation.x > -0.01 and kid.body.scale.y > 0.99, "running recovers after the trick poses")
		kid.free()
	print("HERO MOTION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
