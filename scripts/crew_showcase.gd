extends RefCounted

signal laugh(girl: bool)

const MenuCrew = preload("res://scripts/menu_crew.gd")
const Crew = preload("res://scripts/crew.gd")
const FIRST_CONTACT := .76
const COUNTER_CONTACT := 3.60
const FLIGHT_TIME := 2.42
const DURATION := 6.85
const STAGE_WIDTH := 1.11

var time := -1.
var pose_time := 0.
var wait := 3.2
var anchor := 0
var neighbor := 1
var first := 0
var contacts := 0
var weight := 0.
var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()

func interrupt(instant: bool = false) -> void:
	time = -1.
	wait = 3.2
	if instant:
		weight = 0.

func start(slot: int, direction: int, initiator: int) -> void:
	anchor = slot
	neighbor = direction
	first = initiator
	time = 0.
	pose_time = 0.
	contacts = 0
	weight = 0.

func advance(dt: float, target: int, ready: bool) -> void:
	if not ready:
		interrupt()
		weight = move_toward(weight,0.,dt*7.)
		return
	if time<0.:
		weight = move_toward(weight,0.,dt*7.)
		wait -= dt
		if wait<=0.:
			start(target,1 if rng.randf()<.5 else -1,rng.randi_range(0,1))
		return
	time += dt
	pose_time = time
	weight = smoothstep(0.,.55,time)*(1.-smoothstep(DURATION-.65,DURATION,time))
	if time>=FIRST_CONTACT and contacts==0:
		contacts = 1
		laugh.emit(Crew.is_female(posmod(anchor+neighbor*(1-first),Crew.MODELS.size())))
	if time>=COUNTER_CONTACT and contacts==1:
		contacts = 2
		laugh.emit(Crew.is_female(posmod(anchor+neighbor*first,Crew.MODELS.size())))
	if time>=DURATION:
		time = -1.
		weight = 0.
		wait = rng.randf_range(7.,11.)

func role(slot: int) -> int:
	if slot==anchor: return 0
	if slot==anchor+neighbor: return 1
	return -1

func sample(index: int, reduced: bool) -> Dictionary:
	var towards := float(neighbor*(1 if index==0 else -1))
	var contact := FIRST_CONTACT if index==first else COUNTER_CONTACT
	var hit := COUNTER_CONTACT if index==first else FIRST_CONTACT
	var prepare := smoothstep(contact-.37,contact,pose_time)*(1.-smoothstep(contact+.07,contact+.50,pose_time))
	var return_time := clampf((pose_time-hit)/FLIGHT_TIME,0.,1.)
	var recoil := MenuCrew.flow_ease(return_time/.34)*(1.-MenuCrew.flow_ease((return_time-.34)/.66))
	var rise := sin(MenuCrew.flow_ease(return_time)*PI)
	var strength := .42 if reduced else 1.
	var jet := smoothstep(.11,.24,return_time)*(1.-smoothstep(.77,.98,return_time))
	var grin := smoothstep(hit-.15,hit+.18,pose_time)*(1.-smoothstep(hit+1.4,hit+2.1,pose_time))
	return {
		"x":-towards*(STAGE_WIDTH+strength*.45*recoil-.19*prepare),
		"lift":.42*rise*strength,
		"yaw":towards*(.18+.17*prepare+.40*rise),
		"roll":towards*.15*strength*(prepare-recoil),
		"air":rise*strength,
		"lean":towards*(prepare-.55*recoil),
		"reach":prepare,
		"towards":towards,
		"jet":jet,
		"grin":maxf(grin,prepare*.7),
	}
