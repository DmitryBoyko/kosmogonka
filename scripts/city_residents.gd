extends Node3D
const Props=preload("res://scripts/props.gd")
const G=preload("res://scripts/geometry.gd")
const Walk=preload("res://scripts/finish_walk.gd")
var residents:Array[Node3D]=[]
var patrols: Array[Dictionary] = []
var clock:=0.0
func _ready() -> void:
	if residents.is_empty():
		for child:Node3D in get_children():
			if child.name.begins_with("Resident"): residents.append(child)
	for resident in residents:
		register_patrol(resident)

func register_patrol(resident: Node3D) -> void:
	var follower := Walk.patrol_collider(resident,.59,1.95,true)
	follower.top_level = true
	follower.global_position = resident.global_position
	patrols.append({"body":follower,"phase":0.,"direction":1.,"placed":false,"center_shift":0.})
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
		if is_inside_tree(): register_patrol(alien)
	advance(0)

func route_point(center: Vector3, radius: Vector2, angle: float) -> Vector3:
	return center+Vector3(cos(angle)*radius.x,-.14,sin(angle)*radius.y)

func advance(dt:float, solid: bool = false) -> void:
	clock+=dt
	for i in residents.size():
		var alien:=residents[i]
		var side:float=-1 if i%2==0 else 1
		var a:=clock*(.20+(i%3)*.025)+i*TAU/6
		var radius:=Vector2(3.0,23.0) if i<8 else Vector2(5,3)
		var center:=Vector3(side*31,0,-26) if i<8 else Vector3(side*15,0,7)
		var direction := 1.
		if solid:
			var patrol: Dictionary = patrols[i]
			var body: AnimatableBody3D = patrol.body
			if not patrol.placed:
				for shift in [0., -side*5., side*5., -side*10.]:
					for j in 48:
						var candidate := a+j*TAU/48.
						var point := route_point(center+Vector3(shift,0,0),radius,candidate)
						if not Walk.patrol_clear(body,to_global(point)): continue
						patrol.phase = candidate
						patrol.center_shift = shift
						alien.position = point
						body.global_position = alien.global_position
						patrol.placed = true
						break
					if patrol.placed: break
				alien.visible = patrol.placed
				body.collision_layer = Walk.VISITOR_LAYER | 4 if patrol.placed else 0
				if not patrol.placed: continue
			direction = patrol.direction
			center.x += patrol.center_shift
			a = patrol.phase+dt*(.20+(i%3)*.025)*direction
			if not Walk.can_patrol(body,alien,route_point(center,radius,a)):
				patrol.direction = -direction
				continue
			patrol.phase = a
		alien.position=route_point(center,radius,a)
		if i<patrols.size():
			var follower: AnimatableBody3D = patrols[i].body
			follower.global_position=alien.global_position
		alien.rotation.y=atan2(-sin(a)*radius.x*direction,cos(a)*radius.y*direction)
		Props.animate_alien(alien,clock*(.8 if alien.get_meta("tall") else 1.3)+i*.7)
