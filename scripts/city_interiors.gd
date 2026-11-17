extends Node3D

const G = preload("res://scripts/geometry.gd")
const Crew = preload("res://scripts/crew.gd")
const Avatar = preload("res://scripts/crew_avatar.gd")
const Props = preload("res://scripts/props.gd")
const Planets = preload("res://scripts/planets.gd")
const FURNITURE := [
	preload("res://assets/finish_city/interiors/counter.glb"),
	preload("res://assets/finish_city/interiors/kiosk.glb"),
	preload("res://assets/finish_city/interiors/terminal.glb"),
]
var clock := 0.

static func front_window(arrays: Array) -> AABB:
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var plane := INF
	var pane := AABB()
	for i in range(0,indices.size(),3):
		var a := vertices[indices[i]]
		var b := vertices[indices[i+1]]
		var c := vertices[indices[i+2]]
		if not is_equal_approx(a.z,b.z) or not is_equal_approx(a.z,c.z) or a.z>plane:
			continue
		if a.z<plane:
			plane=a.z
			pane=AABB(a,Vector3.ZERO)
		pane=pane.expand(a).expand(b).expand(c)
	return pane

func add_room(window: Dictionary, planet: int) -> void:
	var index := get_child_count()
	var room := Node3D.new()
	room.name="Showroom%d"%index
	room.position=window.front
	room.rotation.y=window.yaw
	add_child(room)
	var width: float = window.width
	var height: float = window.height
	var depth: float = minf(width*.47,2.8*window.depth_scale)
	room.set_meta("workplace",[width,height,depth,index,planet])
	var accent: String = Planets.get_data(planet).accent
	G.box(room,Vector3(width,.12,depth),Vector3(0,.04,depth*.5),"344258")
	G.box(room,Vector3(width,height,.09),Vector3(0,height*.5,depth),"786d84",.20)
	G.box(room,Vector3(width*.78,.08,.16),Vector3(0,height*.87,depth-.12),accent,.55)
	for side in [-1.,1.]:
		G.box(room,Vector3(.08,height*.57,.12),Vector3(side*width*.39,height*.52,depth-.12),accent,.30)
	place_furniture(room,FURNITURE[index%3],Vector3(-width*.24,.10,depth*.52),Vector3(width*.25,height*.46,depth*.30))
	place_furniture(room,FURNITURE[0],Vector3(width*.24,.10,depth*.77),Vector3(width*.29,height*.39,depth*.27))
	preload("res://scripts/arcade_materials.gd").apply(room,planet)
	G.merge_static(room)
	var lamp:=OmniLight3D.new()
	lamp.name="InteriorLight"
	lamp.position=Vector3(0,height*.72,depth*.48)
	lamp.light_color=Color("ffce8e") if index%2==0 else Color("96eaff")
	lamp.light_energy=1.8
	lamp.omni_range=maxf(width,height)*1.2
	lamp.shadow_enabled=false
	lamp.hide()
	room.add_child(lamp)
	for piece: MeshInstance3D in room.find_children("*","MeshInstance3D",true,false):
		piece.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		piece.visibility_range_end=65.

static func place_furniture(room: Node3D, scene: PackedScene, at: Vector3, size: Vector3) -> void:
	var piece := scene.instantiate() as Node3D
	var mesh := piece.find_children("*","MeshInstance3D",true,false)[0] as MeshInstance3D
	var bounds := mesh.get_aabb()
	piece.scale=size/bounds.size
	piece.position=at-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*piece.scale
	room.add_child(piece)

func populate_staff(room: Node3D, height: float, index: int, planet: int) -> Node3D:
	var staff := Node3D.new()
	staff.name="Staff"
	room.add_child(staff)
	var count := 1 if (index+planet)%3==0 else 2
	for i in count:
		var alien := (i+index+planet)%2==0
		var actor: Node3D
		if alien:
			actor=Props.running_alien()
			actor.get_node("Warning").free()
			actor.get_node("Crossing").free()
			actor.get_node("AlienBody").rotation.y=0.
			actor.scale=Vector3.ONE*height*.39
		else:
			actor=Avatar.new()
			actor.scale=Vector3.ONE*height*.26
		actor.name="Alien%d"%i if alien else "Hero%d"%i
		staff.add_child(actor)
		if not alien: actor.build((index*7+planet*3)%Crew.ALIEN_GUY)
		for piece: GeometryInstance3D in actor.find_children("*","GeometryInstance3D",true,false):
			piece.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return staff

func advance(dt: float, camera_position: Vector3) -> void:
	clock+=dt
	var can_populate := true
	for room: Node3D in get_children():
		var lamp:=room.get_node_or_null("InteriorLight") as OmniLight3D
		if lamp: lamp.visible=room.global_position.distance_squared_to(camera_position)<17.*17.
		var near := room.global_position.distance_squared_to(camera_position)<34.*34.
		var staff := room.get_node_or_null("Staff") as Node3D
		if not near:
			if staff:
				staff.hide()
				staff.process_mode=Node.PROCESS_MODE_DISABLED
			continue
		var layout: Array = room.get_meta("workplace")
		var width: float = layout[0]
		var depth: float = layout[2]
		if not staff:
			if not can_populate: continue
			staff=populate_staff(room,layout[1],layout[3],layout[4])
			can_populate=false
		staff.show()
		staff.process_mode=Node.PROCESS_MODE_INHERIT
		for actor: Node3D in staff.get_children():
			var phase := clock*.55+float(layout[3])*1.67+actor.get_index()*PI
			var side := 1. if actor.get_index()==0 else -1.
			var route := sin(phase)
			var working := absf(route)>.72
			actor.position=Vector3(width*(side*.14+route*.07),.10,depth*(.51 if side>0. else .76))
			var heading := -side*.80 if working else .5*signf(cos(phase))+PI
			actor.rotation.y=lerp_angle(actor.rotation.y,heading,1.-exp(-9.*dt))
			if actor.name.begins_with("Alien"):
				Props.animate_alien(actor,clock*1.15+side,.40 if working else 0.)
			else:
				actor.pose("work" if working else "walk",1.6,"",dt,.46)
