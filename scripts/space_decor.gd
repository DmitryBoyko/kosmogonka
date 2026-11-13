extends Control
const COLORS := [Color("ffd45e"),Color("ff657f"),Color("66d4ff")]
var meteors:Array[Dictionary]=[]
var wait:=2.5
var rng:=RandomNumberGenerator.new()
var slow_meteors: Array[Dictionary] = []
var slow_wait := .2
var next_color := 0
var show_slow := false
func _ready() -> void: rng.randomize()

func set_slow_meteors(enabled: bool) -> void:
	if enabled == show_slow: return
	show_slow = enabled
	slow_meteors.clear()
	slow_wait = .2
	queue_redraw()

func _process(dt:float) -> void:
	var profile=get_tree().root.get_node_or_null("Profile")
	if profile and profile.reduced_motion:
		if not meteors.is_empty() or not slow_meteors.is_empty():
			meteors.clear()
			slow_meteors.clear()
			queue_redraw()
		return
	wait-=dt
	if wait<=0 and meteors.size()<3:
		var sign_value:float=-1 if rng.randf()<.5 else 1
		meteors.append({"p":Vector2(rng.randf_range(.12,.88)*size.x,rng.randf_range(.02,.28)*size.y),"v":Vector2(sign_value*rng.randf_range(130,230),rng.randf_range(80,140)),"age":0.,"life":rng.randf_range(.55,.95),"color":Color("f4f8ff")})
		wait=rng.randf_range(3.5,7.)
	if show_slow:
		slow_wait -= dt
		if slow_wait<=0. and slow_meteors.size()<3:
			var from_left := next_color%2==0
			var start := Vector2(.08 if from_left else .92,rng.randf_range(.22,.40))*size
			var velocity := Vector2(50. if from_left else -50.,rng.randf_range(15.,27.))
			slow_meteors.append({"p":start,"v":velocity,"age":0.,"life":rng.randf_range(3.4,4.4),"color":COLORS[next_color%COLORS.size()]})
			next_color += 1
			slow_wait = rng.randf_range(1.5,2.4)
	for group in [meteors,slow_meteors]:
		for i in range(group.size()-1,-1,-1):
			group[i].age+=dt
			group[i].p+=group[i].v*dt
			if group[i].age>=group[i].life: group.remove_at(i)
	queue_redraw()

func _draw() -> void:
	var daytime:bool=get_parent().get_meta("daylight",true)
	for meteor:Dictionary in meteors:
		var fade:float=sin(PI*meteor.age/meteor.life)*(.38 if daytime else .72)
		var tip:Vector2=meteor.p; var direction:Vector2=meteor.v.normalized()
		for segment in 6:
			var a:Vector2=tip-direction*segment*10.; var b:Vector2=tip-direction*(segment+1)*10.
			var color:Color=meteor.color; color.a=fade*(1.-segment/6.)
			draw_line(a,b,Color(color,.10*color.a),5.,true)
			draw_line(a,b,color,1.4,true)
		draw_circle(tip,1.4,Color(1.,.96,.88,fade))
	for meteor in slow_meteors:
		var fade := sin(PI*float(meteor.age)/float(meteor.life))*.85
		var tip: Vector2 = meteor.p
		var step: Vector2 = meteor.v.normalized()*8.
		for segment in 6:
			var color := Color(meteor.color,fade*(1.-float(segment)/6.))
			draw_line(tip-step*segment,tip-step*(segment+1),Color(color,color.a*.25),7.,true)
			draw_line(tip-step*segment,tip-step*(segment+1),color,2.,true)
		draw_circle(tip,5.,Color(meteor.color,fade*.20),true,-1.,true)
		draw_circle(tip,2.2,Color(meteor.color,fade),true,-1.,true)
