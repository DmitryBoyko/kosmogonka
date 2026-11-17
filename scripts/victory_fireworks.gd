extends MultiMeshInstance3D

signal salvo

const CAPACITY := 600
const TIMES := [.53,1.00,1.63,2.42,3.30,4.05,4.94,5.12,5.35]
const OFFSETS := [
	Vector3(-4.,0.,0.),Vector3(5.,1.,0.),Vector3(0.,3.,-1.),
	Vector3(-8.,.5,-1.),Vector3(8.,.8,0.),Vector3(0.,2.,2.),
	Vector3(-6.,1.4,1.),Vector3(6.,2.4,1.),Vector3(0.,4.4,-1.)
]
const PALETTE := [
	Color("ff2971"),Color("38dfff"),Color("ffb826"),Color("bc54ff"),
	Color("59ed70"),Color("ff7152"),Color("f550bf"),Color("4c81ff"),Color("ffcc42")
]
const ROCKET_TIME := .48
const DURATION := 7.65
var rng := RandomNumberGenerator.new()
var sparks: Array[Dictionary] = []
var celebrating := false
var age := 0.
var next_salvo := 0
var live_count := 0
var anchor := Vector3(0,20.,-18.)
var accent := Color("80f5dc")

func _ready() -> void:
	var quad := QuadMesh.new()
	quad.size=Vector2.ONE
	multimesh=MultiMesh.new()
	multimesh.transform_format=MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data=true
	multimesh.mesh=quad
	multimesh.instance_count=CAPACITY
	multimesh.visible_instance_count=0
	var material := ShaderMaterial.new()
	material.shader=preload("res://assets/surfaces/victory_fireworks.gdshader")
	material_override=material
	cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	extra_cull_margin=20.
	hide()

func start(world: int, at: Vector3) -> void:
	stop()
	celebrating=true
	age=0.
	next_salvo=0
	anchor=at
	rng.seed=world*7919+31
	accent=Color(preload("res://scripts/planets.gd").get_data(world).accent)
	multimesh.custom_aabb=AABB(anchor-Vector3(25.,15.,20.),Vector3(50.,38.,40.))

func stop() -> void:
	celebrating=false
	sparks.clear()
	live_count=0
	multimesh.visible_instance_count=0
	hide()

func burst(index: int, quality: bool, reduced: bool) -> void:
	var color: Color = PALETTE[index]
	var centre: Vector3 = anchor+OFFSETS[index]
	var count := 32 if reduced else 76 if quality else 54
	var ring := index in [1,3,5,8]
	for i in count:
		var direction: Vector3
		if ring:
			var angle := TAU*float(i)/count
			direction=Vector3(cos(angle),sin(angle),sin(angle+.7)*.35)
		else:
			var z := 1.-2.*(float(i)+.5)/count
			var radius := sqrt(1.-z*z)
			var angle := i*2.399963
			direction=Vector3(cos(angle)*radius,sin(angle)*radius,z)
		var speed := rng.randf_range(6.4,10.8)*(1.18 if index==8 else 1.)
		var ink := color if i%5!=0 else color.lerp(accent,.35)
		sparks.append({"origin":centre,"velocity":direction*speed,"born":TIMES[index],
			"life":rng.randf_range(1.42,2.05),"width":rng.randf_range(.23,.37),"ink":ink})
	salvo.emit()

func advance(dt: float, reduced: bool, quality: bool, camera_position: Vector3) -> void:
	if not celebrating: return
	age+=dt
	if age>DURATION:
		stop()
		return
	while next_salvo<TIMES.size() and age>=TIMES[next_salvo]:
		burst(next_salvo,quality,reduced)
		next_salvo+=1
	var eye := to_local(camera_position)
	live_count=0
	for i in range(next_salvo,TIMES.size()):
		var travel: float = (age-TIMES[i]+ROCKET_TIME)/ROCKET_TIME
		if travel<=0. or travel>=1.: continue
		var centre: Vector3 = anchor+OFFSETS[i]
		var start := centre-Vector3(OFFSETS[i].x*.24,7.,0.)
		var head := start.lerp(centre,travel)
		var tail := start.lerp(centre,maxf(0.,travel-.32))
		write_streak(tail,head,.24,PALETTE[i],.92,eye)
	for i in range(sparks.size()-1,-1,-1):
		var spark := sparks[i]
		var elapsed: float = age-spark.born
		if elapsed>=spark.life:
			sparks.remove_at(i)
			continue
		var opacity := 1.-smoothstep(.61,1.,elapsed/float(spark.life))
		var trail_time := .17 if reduced else .36
		var head := trajectory(spark,elapsed)
		var tail := trajectory(spark,maxf(0.,elapsed-trail_time))
		write_streak(tail,head,spark.width, spark.ink,opacity,eye)
	multimesh.visible_instance_count=live_count
	visible=live_count>0

func trajectory(spark: Dictionary, time: float) -> Vector3:
	var spread := (1.-exp(-1.35*time))/1.35
	return spark.origin+spark.velocity*spread-Vector3.UP*(.84*time*time)

func write_streak(tail: Vector3, head: Vector3, width: float, ink: Color, opacity: float, eye: Vector3) -> void:
	if live_count>=CAPACITY: return
	var midpoint := (head+tail)*.5
	var up := (head-tail).normalized() if head.distance_squared_to(tail)>.000001 else Vector3.UP
	var normal := (eye-midpoint).normalized()
	var across := up.cross(normal).normalized()
	if across.is_zero_approx(): across=Vector3.RIGHT
	var axes := Basis(across*width,up*(head.distance_to(tail)+width),across.cross(up))
	multimesh.set_instance_transform(live_count,Transform3D(axes,midpoint))
	multimesh.set_instance_custom_data(live_count,Color(ink.r,ink.g,ink.b,opacity))
	live_count+=1
