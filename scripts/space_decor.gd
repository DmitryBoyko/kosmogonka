extends Control
## Code-native decorative interface lines; does not intercept touch.
var meteors:Array[Dictionary]=[]
var wait:=2.5
var rng:=RandomNumberGenerator.new()
func _ready() -> void: rng.randomize()
func _process(dt:float) -> void:
	var profile=get_tree().root.get_node_or_null("Profile")
	if profile and profile.reduced_motion:
		if not meteors.is_empty(): meteors.clear(); queue_redraw()
		return
	wait-=dt
	if wait<=0 and meteors.size()<3:
		var sign_value:float=-1 if rng.randf()<.5 else 1
		meteors.append({"p":Vector2(rng.randf_range(.12,.88)*size.x,rng.randf_range(.02,.28)*size.y),"v":Vector2(sign_value*rng.randf_range(130,230),rng.randf_range(80,140)),"age":0.,"life":rng.randf_range(.55,.95),"color":[Color("ffd0a0"),Color("c0e9ff"),Color("d7c1f5"),Color("d2e8bf")][rng.randi_range(0,3)]})
		wait=rng.randf_range(3.5,7.)
	for i in range(meteors.size()-1,-1,-1):
		meteors[i].age+=dt; meteors[i].p+=meteors[i].v*dt
		if meteors[i].age>=meteors[i].life: meteors.remove_at(i)
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
