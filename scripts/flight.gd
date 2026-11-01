extends Node3D
## An actual four-ship race; finish order is determined by crossing time.
signal cue(kind: String)
const G = preload("res://scripts/geometry.gd")
const Props = preload("res://scripts/props.gd")
const Planets = preload("res://scripts/planets.gd")
const LENGTH := 880.0
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
var destination: MeshInstance3D
var finish: Node3D
var rng := RandomNumberGenerator.new()

func build(route: int, race_seed: int) -> void:
	source = route
	rng.seed = race_seed
	player = Props.ship()
	add_child(player)
	player.scale = Vector3.ONE * 0.48
	player.position.y = 1.4
	for i in 3:
		var model := Props.ship(i)
		add_child(model)
		model.scale *= 0.48
		var label := G.label(model,["ХВАСТУН","КАПИТАН","САМОДЕЛКИН"][i],Vector3(0,3.1,0),24)
		label.modulate = Color(Planets.get_data(route+1).accent)
		var pace := rng.randf_range(-0.6,0.6)
		if i==0 and rng.randf()<0.16: pace+=6.5
		bots.append({"node":model,"s":16.0+i*21.0,"lane":i,"target":i,"x":float((i-1)*WIDTH),"warning":0.0,
			"think":3.0+i*1.7,"offset":pace,"finished":false,"phase":rng.randf()*TAU,"scale":model.scale})
	for i in 32:
		var marker := Node3D.new()
		add_child(marker)
		for j in 4:
			var at := Vector3((j-1.5)*WIDTH,0,0)
			G.tube(marker,0.07,0.5,at-Vector3.UP*0.25,"7767b3")
			G.ball(marker,Vector3(0.36,0.18,0.75),at,"ff99de" if j%2==0 else "85f8e5",1.2)
			G.box(marker,Vector3(0.075,0.035,5.8),at+Vector3(0,-0.1,-2.8),"a29bdb",0.3)
		if i%6==0:
			for side in [-1.0,1.0]: G.box(marker,Vector3(0.1,6,0.14),Vector3(side*7.4,2.5,0),"bb92ec",0.5)
			G.box(marker,Vector3(14.8,0.1,0.14),Vector3(0,5.5,0),"bb92ec",0.5)
		G.batch(marker)
		markers.append(marker)
	for i in 7:
		var node := G.ring(self,0.75,0.86,Vector3.ZERO,"ffe4a0",0.7)
		node.rotation.x = PI*0.5
		rings.append({"s":100.0+i*105,"lane":(i+source)%3,"node":node,"taken":false})
	destination = G.ball(self,Vector3.ONE*43,Vector3(-28,20,-165),"83a5cf")
	destination.material_override=preload("res://scripts/surface_style.gd").globe(source+1)
	var stars_rng := RandomNumberGenerator.new()
	stars_rng.seed = race_seed + 71
	for i in 80:
		G.ball(self,Vector3.ONE*stars_rng.randf_range(0.05,0.18),Vector3(stars_rng.randf_range(-80,80),stars_rng.randf_range(8,60),stars_rng.randf_range(-130,30)),"d5d9ff",0.7)
	finish = Node3D.new()
	add_child(finish)
	for side in [-1.0,1.0]: G.box(finish,Vector3(0.35,8,0.45),Vector3(side*7,3,0),"88f8dc",0.5)
	G.box(finish,Vector3(14.5,0.45,0.5),Vector3(0,7,0),"9aa8e8")
	G.label(finish,"КОСМОДРОМ  /  "+Planets.get_data(source+1).name.to_upper(),Vector3(0,6.8,0.4),28)
	sync_visuals(0)

func steer(direction: int) -> void:
	if not done: lane = clampi(lane+direction,0,2)

func advance(dt: float) -> void:
	if done: return
	elapsed += dt
	boost = maxf(0,boost-dt)
	bump = maxf(0,bump-dt)
	protected = maxf(0,protected-dt)
	speed = move_toward(speed,(45.0 if boost>0 else 34.0)*(0.72 if bump>0 else 1.0),dt*18)
	var previous := distance
	distance = minf(LENGTH,distance+speed*dt)
	x = move_toward(x,(lane-1)*WIDTH,dt*16)
	var crossings: Array[Dictionary] = []
	if previous < LENGTH and distance >= LENGTH:
		crossings.append({"id":3,"time":(LENGTH-previous)/maxf(0.001,speed)})
	for i in bots.size():
		var bot: Dictionary = bots[i]
		if bot.finished: continue
		var old: float = bot.s
		var velocity: float = 31.0 + float(source)*0.2 + bot.offset
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
	place=1
	for bot in bots:
		if bot.s>distance: place+=1
	if distance>=LENGTH:
		done=true
		place=order.find(3)+1
	sync_visuals(dt)

func sync_visuals(_dt: float) -> void:
	player.position = Vector3(x,1.4+sin(elapsed*4)*0.07,0)
	player.rotation.z = ((lane-1)*WIDTH-x)*-0.07+sin(elapsed*24)*bump*0.12
	for i in bots.size():
		var bot: Dictionary = bots[i]
		bot.node.position = Vector3(bot.x,1.3+sin(elapsed*3+bot.phase)*0.18,distance-bot.s)
		bot.node.rotation.z = sin(elapsed*2+bot.phase)*0.06
		if bot.warning>0: bot.node.rotation.z += sin(elapsed*18)*0.14
		bot.node.scale = bot.scale*(1.05 if bot.warning>0 and fmod(elapsed,0.2)<0.1 else 1.0)
	for i in markers.size():
		markers[i].position.z = fposmod(distance,7.0)-i*7+21
	for ring in rings:
		ring.node.visible = not ring.taken and ring.s>distance-4
		ring.node.position = Vector3((ring.lane-1)*WIDTH,1.5,distance-ring.s)
	finish.position.z = distance-LENGTH
	destination.position.z = -165 + distance*0.045
	destination.rotation.y=elapsed*0.03

func camera_pose() -> Dictionary:
	return {"position":Vector3(0,5.5,13.0),"target":Vector3(x*0.12,1,-17)}
