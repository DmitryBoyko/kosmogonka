extends Node3D

const Crew = preload("res://scripts/crew.gd")
const Avatar = preload("res://scripts/crew_avatar.gd")
const SPACING := 2.65
var scroll := 0.0
var target := 0
var drag := 0.0
var cards: Dictionary = {}

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

func step(direction: int) -> int:
	target += direction
	drag = 0.
	return posmod(target,Crew.MODELS.size())

func present(dt: float, profile: Node, only_selected: bool = false) -> void:
	var resting := float(target) + drag
	scroll = resting if profile.reduced_motion else lerpf(scroll,resting,1. - exp(-16. * dt))
	var center := roundi(scroll)
	var offsets := [0] if only_selected else [-2,-1,0,1,2]
	var needed := {}
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
		var card: Node3D = cards[index]
		var relative := 0. if only_selected else slot - scroll
		var centrality := 1. - clampf(absf(relative),0.,1.)
		card.position = Vector3(relative * SPACING,.10,-.9 * (1. - centrality))
		card.rotation.y = clampf(-relative * .20,-.35,.35)
		card.scale = Vector3.ONE * lerpf(.90,1.15,centrality)
		card.visible = absf(relative) < 1.85
		card.process_mode = Node.PROCESS_MODE_INHERIT if card.visible else Node.PROCESS_MODE_DISABLED
		card.pose("win" if only_selected and profile.completed else "idle")
	for index in cards.keys():
		if not needed.has(index):
			cards[index].hide()
			cards[index].queue_free()
			cards.erase(index)
