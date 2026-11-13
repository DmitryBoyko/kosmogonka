extends Node3D

const Crew=preload("res://scripts/crew.gd")
const Avatar=preload("res://scripts/crew_avatar.gd")
const Shops=preload("res://scripts/monument_shops.gd")
var visitors:Array[Dictionary]=[]
var clock:=0.

func populate(seed_value:int,active_hero:int) -> void:
	var rng:=RandomNumberGenerator.new()
	rng.seed=seed_value
	var choices:=range(Crew.MODELS.size())
	choices.erase(active_hero)
	var first_shop:=rng.randi_range(0,2)
	for i in rng.randi_range(3,5):
		var pick:=rng.randi_range(0,choices.size()-1)
		var index:int=choices.pop_at(pick)
		var actor:=Avatar.new()
		add_child(actor)
		actor.build(index,true)
		var shop:Vector3=Shops.POSITIONS[(first_shop+i)%3]
		var inward:=Vector3(-signf(shop.x)*7.,0,6. if is_zero_approx(shop.x) else 0.)
		var offset:=Vector3(0,0,-4.5 if i>=3 else 2.7)
		visitors.append({"node":actor,"index":index,"home":shop+inward+offset,"phase":rng.randf()*TAU,"pace":rng.randf_range(.38,.59),"moving":false})
	advance(0.)

func advance(dt:float) -> void:
	clock+=dt
	for v:Dictionary in visitors:
		var moving:bool=fposmod(clock+v.index*.77,13.)<9.
		if moving: v.phase+=dt*v.pace
		var phase:float=v.phase
		var actor:Node3D=v.node
		actor.position=v.home+Vector3(cos(phase)*1.55,0,sin(phase)*1.65)
		if moving: actor.rotation.y=atan2(-sin(phase),cos(phase))
		actor.pose("walk" if moving else "idle",3.4 if moving else 0.,"",dt)
