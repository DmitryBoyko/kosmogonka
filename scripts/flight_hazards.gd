extends Node3D

const G=preload("res://scripts/geometry.gd")
const Cargo=preload("res://scripts/cargo_containers.gd")
const FX=preload("res://scripts/energy_effects.gd")
var debris:Array[Dictionary]=[]
var bolts:Array[MeshInstance3D]=[]
var explosions:Array[Dictionary]=[]
var laser_time:=0.
var laser_age:=0.
var bot_shot:MeshInstance3D
var bot_time:=0.

func build(race:Node3D) -> void:
	var rng:=race.rng as RandomNumberGenerator
	for i in 15:
		var node:=Node3D.new()
		add_child(node)
		var kind:=i%3
		if kind==0:
			for j in 3:
				var shard:=G.tube(node,.46+j*.19,1.2+j*.6,Vector3((j-1)*.49,0,0),["59e9e9","ad68fa","ffc771"][int(i/3)%3],.45)
				shard.mesh=shard.mesh.duplicate()
				shard.mesh.radial_segments=5
				shard.mesh.top_radius=.025
				shard.rotation.z=(j-1)*.36
		elif kind==1:
			node.add_child(Cargo.fitted(i+4,Vector3(2.2,1.7,2.6)))
		else:
			var wreck:=preload("res://assets/spaceflight/craft-cargoa.glb").instantiate() as Node3D
			node.add_child(wreck)
			preload("res://scripts/space_ship.gd").center_asset(wreck)
			wreck.scale=Vector3.ONE*1.8
			for part:MeshInstance3D in wreck.find_children("*","MeshInstance3D",true,false):
				part.material_override=preload("res://scripts/salvage_materials.gd").material("hull-salvage")
			G.ball(node,Vector3.ONE*.37,Vector3(.6,.25,.22),"ff9a5f",.75)
		node.hide()
		var s:=156.+i*73.+rng.randf_range(-8.,8.)
		debris.append({"node":node,"s":s,"lane":rng.randi_range(0,2),"hp":1 if kind==0 else 2,"kind":kind,"dead":false,"spin":rng.randf_range(.44,1.04)})
	for side in [-1,1]:
		var laser:=G.box(self,Vector3(.08,.10,10.),Vector3(side*.9,0,-5.),"75efff",1.7)
		laser.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		laser.hide()
		bolts.append(laser)
	bot_shot=G.box(self,Vector3(.05,.05,5.),Vector3.ZERO,"ff9e72",.8)
	bot_shot.hide()
	bot_shot.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in 4:
		var blast:=FX.vortex(self,Vector2(4.9,4.9),Vector3.ZERO,Color("ff8955"))
		blast.hide()
		explosions.append({"node":blast,"s":0.,"lane":1,"age":1.})

func fire(race:Node3D) -> void:
	if race.done or laser_time>0.: return
	laser_time=.30
	laser_age=.14
	race.cue.emit("laser")
	var target:=closest(race.distance,race.x,64.,race.WIDTH)
	if not target.is_empty(): damage(race,target,2)

func closest(s:float,x:float,reach:float,width:float) -> Dictionary:
	for object:Dictionary in debris:
		var gap:float=object.s-s
		if not object.dead and gap>1. and gap<reach and absf((object.lane-1)*width-x)<1.4: return object
	return {}

func damage(race:Node3D,object:Dictionary,amount:int) -> void:
	object.hp-=amount
	if object.hp>0: return
	object.dead=true
	for blast:Dictionary in explosions:
		if blast.age>=.52:
			blast.s=object.s
			blast.lane=object.lane
			blast.age=0.
			break
	if absf(object.s-race.distance)<84.: race.cue.emit("explosion")

func advance(race:Node3D,dt:float) -> void:
	laser_time=maxf(0.,laser_time-dt)
	laser_age=maxf(0.,laser_age-dt)
	var player_x:float=race.x
	for i in bolts.size():
		bolts[i].visible=laser_age>0.
		bolts[i].position=Vector3(player_x+(i*2-1)*.85,1.43,-5.-(.14-laser_age)*140.)
	for object:Dictionary in debris:
		var gap:float=object.s-race.distance
		object.node.visible=not object.dead and gap>-7. and gap<145.
		if object.node.visible:
			object.node.position=race.relative_pose(object.s,(object.lane-1)*race.WIDTH)
			object.node.rotation=Vector3(race.elapsed*object.spin,race.elapsed*object.spin*.73,race.elapsed*.39)
			if absf(gap)<2.3 and absf((object.lane-1)*race.WIDTH-player_x)<1.43 and race.protected<=0.:
				race.bump=1.25
				race.protected=1.5
				race.cue.emit("bump")
				damage(race,object,2)
	bot_time=maxf(0.,bot_time-dt)
	bot_shot.visible=bot_time>.26
	for bot:Dictionary in race.bots:
		if bot_time>0. or bot.finished or absf(bot.s-race.distance)>55.: continue
		var object:=closest(bot.s,bot.x,31.,race.WIDTH)
		if object.is_empty(): continue
		bot_time=.45
		bot_shot.position=race.relative_pose(bot.s+7.,bot.x)
		damage(race,object,1)
	for blast:Dictionary in explosions:
		blast.age+=dt
		blast.node.visible=blast.age<.52
		if blast.node.visible:
			blast.node.position=race.relative_pose(blast.s,(blast.lane-1)*race.WIDTH)
			blast.node.material_override.set_shader_parameter("burst",blast.age/.52)
			blast.node.material_override.set_shader_parameter("energy_time",race.elapsed)
