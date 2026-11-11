extends Node3D

const Crew = preload("res://scripts/crew.gd")
const Avatar = preload("res://scripts/crew_avatar.gd")
const Showcase = preload("res://scripts/crew_showcase.gd")
const ShowcasePose = preload("res://scripts/crew_showcase_pose.gd")
const SPACING := 2.65
var scroll := 0.0
var target := 0
var drag := 0.0
var cards: Dictionary = {}
var poses: Dictionary = {}
var showcase := Showcase.new()
var display_time := 0.

func _ready() -> void:
	var fill := OmniLight3D.new()
	add_child(fill)
	fill.position = Vector3(0,3.6,4.)
	fill.omni_range = 9.
	fill.light_energy = 1.15
	fill.light_cull_mask = 2

func reset(index: int) -> void:
	target = index
	scroll = float(index)
	drag = 0.
	showcase.interrupt(true)

func step(direction: int) -> int:
	target += direction
	drag = 0.
	showcase.interrupt()
	return posmod(target,Crew.MODELS.size())

func suspend() -> void:
	showcase.interrupt(true)
	for pose: RefCounted in poses.values():
		pose.release()

func present(dt: float, profile: Node, only_selected: bool = false, interacting: bool = false) -> void:
	display_time += dt
	var resting := float(target) + drag
	scroll = resting if profile.reduced_motion else lerpf(scroll,resting,1. - exp(-16. * dt))
	showcase.advance(dt,target,not only_selected and not interacting and absf(scroll-target)<.045)
	var center := roundi(scroll)
	var offsets := [0] if only_selected else [-2,-1,0,1,2]
	var needed := {}
	var actors: Array[Dictionary] = []
	var pair := {}
	for offset: int in offsets:
		var slot := target if only_selected else center + offset
		var index := posmod(slot,Crew.MODELS.size())
		needed[index] = true
		if not cards.has(index):
			var actor := Avatar.new()
			add_child(actor)
			actor.build(index,true)
			if index < profile.outfits.size():
				actor.apply_outfit(profile.outfits[index])
			for mesh: GeometryInstance3D in actor.find_children("*","GeometryInstance3D",true,false):
				mesh.layers |= 2
			cards[index] = actor
			poses[index] = ShowcasePose.new(actor)
		var card: Node3D = cards[index]
		var relative := 0. if only_selected else slot - scroll
		var centrality := 1. - clampf(absf(relative),0.,1.)
		card.position = Vector3(relative * SPACING,.10,-.9 * (1. - centrality))
		card.rotation.y = clampf(-relative * .20,-.35,.35)
		card.scale = Vector3.ONE * lerpf(.90,1.15,centrality)
		card.visible = absf(relative) < 1.85
		var role := showcase.role(slot) if not only_selected and showcase.weight>.0 else -1
		var motion: Dictionary = {}
		if role>=0:
			motion = showcase.sample(role,profile.reduced_motion)
			card.position = card.position.lerp(Vector3(motion.x,.10+motion.lift,-.10),showcase.weight)
			card.rotation.y = lerpf(card.rotation.y,motion.yaw,showcase.weight)
			card.rotation.z = motion.roll*showcase.weight
			card.scale = card.scale.lerp(Vector3.ONE*(1.15 if role==0 else 1.08),showcase.weight)
			card.visible = true
			pair[role] = card
		else:
			card.rotation.z = 0.
			if showcase.weight>.0 and not only_selected:
				card.position.x += signf(relative)*showcase.weight*2.25
		card.process_mode = Node.PROCESS_MODE_INHERIT if card.visible else Node.PROCESS_MODE_DISABLED
		if card.visible:
			actors.append({"card":card,"pose":poses[index],"role":role,"motion":motion,"center":centrality})
		else:
			poses[index].set_exhaust(0.,0.)
	for entry in actors:
		if only_selected:
			entry.pose.release()
			entry.card.pose("win" if profile.completed else "idle",0.,"",dt,.22+entry.center*.52)
			continue
		var motion: Dictionary = entry.motion
		var amount := showcase.weight if entry.role>=0 else 0.
		var air := float(motion.get("air",0.))*amount
		entry.pose.update(dt,display_time,float(motion.get("towards",0.))*amount*(1.-air*.68),air,
			float(motion.get("lean",0.))*amount,float(motion.get("grin",0.))*amount,profile.reduced_motion)
		entry.pose.set_exhaust(dt,float(motion.get("jet",0.))*amount if showcase.time>=0. else 0.)
		if entry.role>=0 and pair.has(1-entry.role):
			var partner: Node3D = pair[1-entry.role]
			var towards: float = motion.towards
			entry.pose.reach(towards,partner.to_global(Vector3(-towards*.39,1.53,.15)),float(motion.reach)*amount)
	for index in cards.keys():
		if not needed.has(index):
			cards[index].hide()
			cards[index].queue_free()
			cards.erase(index)
			poses.erase(index)
