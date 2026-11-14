extends Node3D

const Crew=preload("res://scripts/crew.gd")
const Avatar=preload("res://scripts/crew_avatar.gd")
const Shops=preload("res://scripts/monument_shops.gd")
const Walk=preload("res://scripts/finish_walk.gd")
var visitors:Array[Dictionary]=[]
var clock:=0.
var rng:=RandomNumberGenerator.new()
var speech: AudioStreamPlayer3D
var next_line := 9.
var previous_line := [-1,-1]
const LINE_COUNTS := [7,6]

func populate(seed_value:int,active_hero:int) -> void:
	rng.seed=seed_value
	speech = AudioStreamPlayer3D.new()
	speech.bus = "Voices"
	speech.volume_db = -4.
	speech.unit_size = 6.
	speech.max_distance = 17.
	add_child(speech)
	var choices:=range(Crew.MODELS.size())
	choices.erase(active_hero)
	var first_shop:=rng.randi_range(0,2)
	for i in rng.randi_range(3,5):
		var pick:=rng.randi_range(0,choices.size()-1)
		var index:int=choices.pop_at(pick)
		var actor:=Avatar.new()
		var shop:Vector3=Shops.POSITIONS[(first_shop+i)%3]
		var inward:=Vector3(-signf(shop.x)*7.,0,6. if is_zero_approx(shop.x) else 0.)
		var offset:=Vector3(0,0,-4.5 if i>=3 else 2.7)
		var home := shop+inward+offset
		var phase := rng.randf()*TAU
		var body := AnimatableBody3D.new()
		body.collision_layer = Walk.VISITOR_LAYER
		body.collision_mask = 0
		body.sync_to_physics = false
		body.position = home+Vector3(cos(phase)*1.55,-.225,sin(phase)*1.65)
		add_child(body)
		body.add_child(actor)
		actor.build(index,true)
		var capsule := CapsuleShape3D.new()
		capsule.radius = .36
		capsule.height = 2.55
		var collider := CollisionShape3D.new()
		collider.shape = capsule
		collider.position.y = 1.275
		body.add_child(collider)
		visitors.append({"node":actor,"body":body,"index":index,"home":home,"phase":phase,
			"pace":rng.randf_range(.38,.59),"friendly":i==0 or rng.randf()<.55,"wave_until":0.,"greet_after":rng.randf_range(2.,5.)})
	advance(0.)

func advance(dt:float, player_position: Vector3 = Vector3.INF, voice_busy: bool = false) -> void:
	clock+=dt
	for v:Dictionary in visitors:
		var actor:Node3D=v.node
		var body: AnimatableBody3D = v.body
		var toward := player_position-body.position
		toward.y = 0.
		if v.friendly and clock>=v.greet_after and toward.length_squared()<100. and toward.length_squared()>.01:
			v.wave_until = clock+2.4
			v.greet_after = clock+rng.randf_range(12.,21.)
			actor.grin(3.1)
			if clock>=next_line and not voice_busy and not speech.playing:
				say_line(body.position,Crew.is_female(v.index))
		var greeting: bool = clock<v.wave_until
		var moving: bool = not greeting and fposmod(clock+v.index*.77,13.)<9.
		var phase:float=v.phase
		var next_phase: float = phase+dt*v.pace if moving else phase
		var next_position: Vector3 = v.home+Vector3(cos(next_phase)*1.55,-.225,sin(next_phase)*1.65)
		var clearance := Vector2(player_position.x-next_position.x,player_position.z-next_position.z)
		if clearance.length_squared()>.81 or absf(player_position.y-next_position.y)>2.7:
			v.phase=next_phase
			body.position=next_position
		else:
			moving=false
		if moving: actor.rotation.y=atan2(-sin(phase),cos(phase))
		if greeting and toward.is_finite() and toward.length_squared()>.01:
			actor.rotation.y=lerp_angle(actor.rotation.y,atan2(toward.x,toward.z),1.-exp(-dt*9.))
		actor.pose("wave" if greeting else "walk" if moving else "idle",3.4 if moving else 0.,"",dt,.64 if v.friendly else .26)

func say_line(at: Vector3, girl: bool) -> void:
	var group := int(girl)
	var previous: int = previous_line[group]
	var pick := rng.randi_range(0,LINE_COUNTS[group]-1-int(previous>=0))
	if previous>=0 and pick>=previous: pick+=1
	previous_line[group]=pick
	next_line=clock+rng.randf_range(19.,29.)
	speech.position=at+Vector3.UP*1.9
	speech.stream=load("res://assets/audio/plaza/%s-%02d.ogg"%["girls" if girl else "boys",pick+1])
	speech.play()
