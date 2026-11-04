extends Node3D
const Props=preload("res://scripts/props.gd")
const G=preload("res://scripts/geometry.gd")
var residents:Array[Node3D]=[]
var clock:=0.0
func populate(planet:int) -> void:
	name="RunningResidents"
	set_meta("motion","residents")
	for i in 12:
		var alien:=Props.running_alien(); add_child(alien)
		alien.get_node("Warning").hide(); alien.get_node("Crossing").hide()
		alien.name="Resident%02d"%i
		var tall:=false
		alien.scale=Vector3.ONE*(.78+(i%3)*.10)
		alien.get_node("AlienBody").rotation.y=0
		G.recolor(alien,{"8fe4ae":["bda0f4","f5b28b","7cd9cc","9ddd93"][(i+planet)%4],"6eb291":"7585ae"})
		alien.set_meta("tall",tall); residents.append(alien)
	advance(0)

func advance(dt:float) -> void:
	clock+=dt
	for i in residents.size():
		var alien:=residents[i]
		var side:float=-1 if i%2==0 else 1
		var a:=clock*(.20+(i%3)*.025)+i*TAU/6
		var radius:=Vector2(3.0,23.0) if i<8 else Vector2(5,3)
		var center:=Vector3(side*31,0,-26) if i<8 else Vector3(side*15,0,7)
		alien.position=center+Vector3(cos(a)*radius.x,-.14,sin(a)*radius.y)
		alien.rotation.y=atan2(-sin(a)*radius.x,cos(a)*radius.y)
		Props.animate_alien(alien,clock*(.8 if alien.get_meta("tall") else 1.3)+i*.7)
