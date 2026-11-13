extends Node3D
## An actual four-ship race; finish order is determined by crossing time.
signal cue(kind: String)
const G = preload("res://scripts/geometry.gd")
const Props = preload("res://scripts/props.gd")
const Planets = preload("res://scripts/planets.gd")
const PlanetVisual=preload("res://scripts/planet_visual.gd")
const Decor=preload("res://scripts/flight_scenery.gd")
const LENGTH := 1380.0
const Hazards=preload("res://scripts/flight_hazards.gd")
var hazards:Node3D
var arrival:=0.
var racing_finished:=false
var view_basis:=Basis.IDENTITY
var view_point:=Vector3.ZERO
var station_halo:MeshInstance3D
var roll_camera:=0.
const WIDTH := 4.5
var source := 0
var elapsed := 0.0
var distance := 0.0
var speed := 34.0
var lane := 1
var x := 0.0
var boost := 0.0
var bump := 0.0
var protected := 0.0
var done := false
var place := 1
var energy := 0
var order: Array[int] = []
var bots: Array[Dictionary] = []
var rings: Array[Dictionary] = []
var markers: Array[Node3D] = []
var player: Node3D
var pilot_index := -1
var destination:Node3D
var port:Node3D
var dust:MultiMeshInstance3D
var dust_stride:=0
var finish: Node3D
var rng := RandomNumberGenerator.new()

func build(route: int, race_seed: int, incremental:bool=false) -> void:
	source = route
	rng.seed = race_seed
	player = Props.ship(route)
	add_child(player)
	player.scale = Vector3.ONE * 0.48
	player.position.y = 1.4
	var profile=get_tree().root.get_node_or_null("Profile")
	if profile:
		var crew := preload("res://scripts/crew.gd")
		pilot_index = profile.hero
		player.make_pilot(crew.is_female(pilot_index),profile.suits[pilot_index],pilot_index)
	if incremental: await get_tree().process_frame
	for i in 3:
		var model := Props.ship(route+i+1)
		add_child(model)
		model.scale *= 0.48
		var label:=G.label(model,["ХВАСТУН","КАПИТАН","САМОДЕЛКИН"][i],Vector3(0,4.0,0),19)
		label.name="Callsign"; label.pixel_size=.008; label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		var warning:=G.label(model,"",Vector3(0,4.7,0),28); warning.name="LaneSignal"; warning.pixel_size=.008; warning.billboard=BaseMaterial3D.BILLBOARD_ENABLED; warning.modulate=Color("ffd59b")
		label.modulate = Color(Planets.get_data(route+1).accent)
		var pace := rng.randf_range(-0.6,0.6)
		if i==0 and rng.randf()<0.16: pace+=6.5
		bots.append({"node":model,"s":16.0+i*21.0,"lane":i,"target":i,"x":float((i-1)*WIDTH),"warning":0.0,
			"think":3.0+i*1.7,"offset":pace,"finished":false,"phase":rng.randf()*TAU,"scale":model.scale})
		if incremental: await get_tree().process_frame
	Decor.starfield(self,mini(preload("res://scripts/planets.gd").count()-1,route+1))
	for i in 18:
		var marker:=Decor.beacon(); add_child(marker); markers.append(marker)
	if incremental: await get_tree().process_frame
	for i in 11:
		var node:=Decor.charge(); add_child(node)
		rings.append({"s":100.0+i*108,"lane":(i+source)%3,"node":node,"taken":false})
	destination=PlanetVisual.create(source+1,82.,Vector3(-21,28,-185)); add_child(destination)
	if incremental: await get_tree().process_frame
	port=Decor.port(); add_child(port)
	station_halo=preload("res://scripts/energy_effects.gd").vortex(port,Vector2(14.,14.),Vector3(0,1,0),Color(Planets.get_data(source+1).accent),true)
	station_halo.rotation.x=PI*.5
	if incremental: await get_tree().process_frame
	finish=Node3D.new(); add_child(finish); finish.name="ArrivalBeacons"
	for side in [-1,1]:
		G.tube(finish,.20,2.2,Vector3(side*8.5,.2,0),"637d94")
		G.ball(finish,Vector3(.5,.35,.5),Vector3(side*8.5,1.45,0),"91ddd9",.5)
	var destination_sign:=G.label(finish,Planets.get_data(source+1).name.to_upper()+" / ПРИБЫТИЕ",Vector3(11,4,0),20)
	destination_sign.pixel_size=.01
	set_meta("overhead_gates",0)
	var multi:=MultiMesh.new(); multi.transform_format=MultiMesh.TRANSFORM_3D
	var trail:=BoxMesh.new(); trail.size=Vector3(.018,.018,.65); multi.mesh=trail; multi.instance_count=48
	dust=MultiMeshInstance3D.new(); dust.multimesh=multi; dust.material_override=G.material("7995b5",.12); dust.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; add_child(dust)
	hazards=Hazards.new(); add_child(hazards); hazards.build(self)
	sync_visuals(0)

func steer(direction: int) -> void:
	if done or racing_finished: return
	lane = clampi(lane+direction,0,2)
	x = (lane-1)*WIDTH
	player.position.x = x

func advance(dt: float) -> void:
	if done: return
	elapsed += dt
	if racing_finished:
		arrival+=dt
		speed=move_toward(speed,7.,dt*13.)
		sync_visuals(dt)
		done=arrival>=3.8
		return
	boost = maxf(0,boost-dt)
	bump = maxf(0,bump-dt)
	protected = maxf(0,protected-dt)
	speed = move_toward(speed,(45.0 if boost>0 else 34.0)*(0.60 if bump>0 else 1.0),dt*18)
	var previous := distance
	distance = minf(LENGTH,distance+speed*dt)
	var crossings: Array[Dictionary] = []
	if previous < LENGTH and distance >= LENGTH:
		crossings.append({"id":3,"time":(LENGTH-previous)/maxf(0.001,speed)})
	for i in bots.size():
		var bot: Dictionary = bots[i]
		if bot.finished: continue
		var old: float = bot.s
		var velocity: float = 32.4 + float(source)*0.12 + bot.offset
		if i==0: velocity += 4.3*sin(elapsed*0.53+bot.phase)
		elif i==1: velocity += 8.0 if fmod(elapsed+bot.phase,8.0)<1.4 else -0.8
		else: velocity += 3.8*sin(elapsed*0.9+bot.phase)
		bot.s += velocity*dt
		if old < LENGTH and bot.s >= LENGTH:
			bot.finished = true
			bot.s = LENGTH
			crossings.append({"id":i,"time":(LENGTH-old)/velocity})
		bot.think -= dt
		if bot.think<=0 and bot.warning<=0:
			bot.target = clampi(bot.lane+(-1 if rng.randf()<0.5 else 1),0,2)
			# Within the player's corridor, at most two distinct lanes are occupied.
			var occupied: Array = []
			for other in bots:
				if other!=bot and absf(other.s-distance)<14 and not occupied.has(other.target): occupied.append(other.target)
			if occupied.size()>=2 and not occupied.has(bot.target): bot.target=occupied[0]
			bot.warning = 0.95
			bot.think = rng.randf_range(4,6)
			cue.emit("honk"+str(i))
		if bot.warning>0: bot.warning=maxf(0,bot.warning-dt)
		else:
			bot.lane = bot.target
			bot.x = move_toward(bot.x,(bot.lane-1)*WIDTH,dt*5)
		if protected<=0 and absf(bot.s-distance)<2.5 and absf(bot.x-x)<1.4:
			bump=0.7
			protected=1.5
			cue.emit("bump")
	crossings.sort_custom(func(a,b): return a.time<b.time)
	for crossing in crossings:
		if not order.has(crossing.id): order.append(crossing.id)
	for ring in rings:
		if not ring.taken and absf(distance-ring.s)<1.6 and absf(x-(ring.lane-1)*WIDTH)<1.2:
			ring.taken=true
			boost=1.9
			energy+=1
			cue.emit("boost")
	view_basis=route_basis(distance)
	view_point=route_point(distance)
	hazards.advance(self,dt)
	place=1
	for bot in bots:
		if bot.s>distance: place+=1
	if distance>=LENGTH:
		racing_finished=true
		place=order.find(3)+1
		cue.emit("arrival")
	sync_visuals(dt)

func sync_visuals(_dt: float) -> void:
	player.position = Vector3(x,1.4+sin(elapsed*4)*0.07,0)
	var basis:=route_basis(distance)
	view_basis=basis
	view_point=route_point(distance)
	roll_camera=lerpf(roll_camera,clampf(basis.x.y,-.3,.3)*.14,clampf(_dt*5.,0.,1.))
	player.rotation.z = sin(elapsed*24)*bump*.22+sin(distance*.015)*.23
	player.position.x+=sin(elapsed*29.)*bump*.11
	if racing_finished:
		var u:=smoothstep(0.,3.8,arrival)
		var angle:=lerpf(-1.9,2.5,u)
		var flyby:=Vector3(15.+cos(angle)*11.,1.9+sin(u*PI)*3.-u*7.,-21.+sin(angle)*11.)
		player.position=player.position.lerp(flyby,smoothstep(0.,.85,arrival))
		var arrival_heading:=Vector3.FORWARD.lerp(Vector3(-sin(angle),-.16,cos(angle)),smoothstep(0.,.9,arrival))
		player.look_at(player.position+arrival_heading)
		player.rotate_object_local(Vector3.BACK,.28)
		hazards.hide()
	else:
		player.rotation.x=clampf(-basis.z.y,-.34,.34)*.45
	player.advance(_dt,boost>0)
	for i in bots.size():
		var bot: Dictionary = bots[i]
		bot.node.visible=not racing_finished and absf(bot.s-distance)<160.
		if not bot.node.visible: continue
		bot.node.position=relative_pose(bot.s,bot.x,1.4+sin(elapsed*2+bot.phase)*.08)
		bot.node.rotation.z=((bot.target-1)*WIDTH-bot.x)*-.07+sin(elapsed*2+bot.phase)*.025
		bot.node.advance(_dt)
		var warning:Label3D=bot.node.get_node("LaneSignal")
		warning.text="←" if bot.target<bot.lane else "→"
		warning.visible=bot.warning>0 and bot.target!=bot.lane
		bot.node.get_node("Callsign").modulate.a=1.-smoothstep(50.,105.,absf(bot.s-distance))
	for i in markers.size():
		var rel:float=fposmod(distance,18.)-i*18+18
		markers[i].position=relative_pose(distance-rel,0.,0.)
	for ring in rings:
		ring.node.visible = not racing_finished and not ring.taken and ring.s>distance-4 and ring.s<distance+160.
		if not ring.node.visible: continue
		ring.node.position=relative_pose(ring.s,(ring.lane-1)*WIDTH,1.8)
		ring.node.rotation.y=elapsed*.7
	finish.position=relative_pose(LENGTH,0.,0.)
	finish.visible=not racing_finished and distance>LENGTH-160.
	destination.position.z=-185+distance*.065
	destination.rotation.y=elapsed*.012
	PlanetVisual.advance(destination,elapsed)
	port.position=Vector3(15,1,-21) if racing_finished else relative_pose(LENGTH+23.,15.,1.)
	port.rotation.y=.3
	port.visible=racing_finished or distance>LENGTH-170.
	if port.visible:
		station_halo.rotation.y=elapsed*.27
		station_halo.material_override.set_shader_parameter("energy_time",elapsed)
	get_node("DeepStarfield").basis=view_basis.inverse()*Basis.from_euler(Vector3(.30,.45,.32))
	dust_stride+=1
	if dust_stride%2==0: return
	for i in 48:
		var side:float=-1. if i%2==0 else 1.
		var pos:=Vector3(side*(9.+fposmod(i*7.1,32.)),fposmod(i*3.7,25.)-5.,fposmod(distance*1.25+i*17.3,190.)-175.)
		dust.multimesh.set_instance_transform(i,Transform3D(Basis().scaled(Vector3(1,1,1.8 if boost>0 else 1.)),pos))

func fire() -> void:
	if not racing_finished: hazards.fire(self)

func camera_pose() -> Dictionary:
	if racing_finished:
		var t:=smoothstep(0.,1.,arrival)
		var side:=sin(arrival*.8)
		return {"position":Vector3(x*.18,5.5,13.).lerp(Vector3(30.+side*8.,13.,5.-arrival*4.),t),"target":Vector3(15.,0.,-21.).lerp(player.position,.45),"fov":57.}
	return {"position":Vector3(x*.18,5.5,13.),"target":relative_pose(distance+24.,x*.25,1.8),"roll":roll_camera,"fov":57.+(3. if boost>0 else 0.)}

func route_point(s:float) -> Vector3:
	var x_value:=sin(s*.012+source*.27)*12.+sin(s*.024)*3.
	var y:=sin(s*.012)*4.
	var z:=-s
	for start in [345.,870.]:
		if s<=start: continue
		if s>=start+112.:
			z+=112.
			continue
		var u:float=(s-start)/112.
		var a:=u*TAU
		y+=17.*(1.-cos(a))
		z+=s-start-17.*sin(a)
	return Vector3(x_value,y,z)

func route_basis(s:float) -> Basis:
	var forward:=(route_point(s+.1)-route_point(s-.1)).normalized()
	var up:=Vector3.UP
	for start in [345.,870.]:
		if s>=start and s<=start+112.:
			var a:float=(s-start)*TAU/112.
			up=Vector3(0,cos(a),sin(a))
	if absf(forward.dot(up))>.99: up=Vector3.RIGHT
	return Basis.looking_at(forward,up)

func relative_pose(s:float,lateral:float,altitude:float=1.4) -> Vector3:
	var basis:=route_basis(s)
	var offset:=route_point(s)+basis.x*lateral+basis.y*altitude-view_point
	return view_basis.inverse()*offset
