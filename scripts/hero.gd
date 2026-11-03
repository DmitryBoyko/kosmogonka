extends Node3D
const G = preload("res://scripts/geometry.gd")
const HairCap=preload("res://scripts/hair_cap.gd")
const Face = preload("res://scripts/face.gd")
const Suit = preload("res://scripts/suit.gd")
const JetpackFx = preload("res://scripts/jetpack_fx.gd")
var girl := false
var body: Node3D
var head: Node3D
var arms: Array[Node3D] = []
var elbows: Array[Node3D] = []
var hands: Array[Node3D] = []
var legs: Array[Node3D] = []
var knees: Array[Node3D] = []
var eyes: Array[Node3D] = []
var mouth: Node3D
var flames: Array[Node3D] = []
var board: Node3D
var pack: Node3D
var clock := 0.0
var mood := "idle"
var front_smile:=0.0
var menu_expression:float=-1.0
var menu_jet:=false
var pivot: Node3D
var trick_phase := 0.0
var roll_blend := 0.0
var stride_phase := 0.0
var braids: Array[Node3D] = []
var braid_links: Array[Node3D] = []
var quiff: Node3D
var face: Dictionary = {}
var suit_loadout: Dictionary = {}
var suit_sockets: Dictionary = {}
var jet_fx: Node3D
signal affection(kind: String, source: Vector3)
var front_gesture := ""
var front_gesture_time := 0.0
var front_gesture_blend := 0.0
var front_gesture_emitted := 0
var heart_fingers: Node3D

func build(is_girl: bool, loadout: Dictionary = {}) -> void:
	girl = is_girl
	var accent := "ff74b5" if girl else "45dcca"
	var dark := "574282" if girl else "225675"
	var hair := "ff791d" if girl else "2289ed"
	var hair_light := "ffc24e" if girl else "72ddff"
	pivot = Node3D.new()
	add_child(pivot)
	pivot.position.y = 1.1
	body = Node3D.new()
	pivot.add_child(body)
	body.position.y = -1.1
	Suit.tag(G.ball(body, Vector3(0.86, 0.96, 0.59), Vector3(0, 1.14, 0), "f3f1ff"),"torso","fabric")
	Suit.tag(G.ball(body, Vector3(0.81, 0.64, 0.61), Vector3(0, 0.92, 0), dark),"torso","joint")
	Suit.tag(G.box(body, Vector3(0.59, 0.4, 0.06), Vector3(0, 1.25, 0.29), dark),"torso","joint")
	Suit.tag(G.box(body, Vector3(0.53, 0.35, 0.08), Vector3(0, 1.25, 0.31), accent),"torso","trim")
	Suit.tag(G.star(body, 0.13, Vector3(0, 1.26, 0.37)),"torso","badge")
	Suit.tag(G.ring(body, 0.32, 0.43, Vector3(0, 1.55, 0), dark),"torso","joint")
	Suit.tag(G.ring(body, 0.33, 0.4, Vector3(0, 1.59, 0), accent, 0.2),"torso","metal")
	var neck:=G.tube(body,0.12,0.16,Vector3(0,1.64,0),"f5c5aa",0.115)
	neck.name="VisibleNeck"
	head = Node3D.new()
	body.add_child(head)
	head.position.y = 2.005
	face = Face.build(head,girl)
	HairCap.build(head,girl,hair,hair_light)
	eyes.assign(face.eyes)
	mouth = face.mouth
	if girl:
		for i in 5:
			var tuft := G.ball(head, Vector3(0.21, 0.23 + i * 0.015, 0.19), Vector3((i - 2) * 0.115, 0.33 - float(i) * 0.018, 0.30), hair_light if i == 1 else hair)
			tuft.rotation.z = -0.3
		for s in [-1.0, 1.0]:
			var braid := Node3D.new()
			head.add_child(braid)
			braid.position = Vector3(s * 0.38, 0.12, -0.18)
			braid.rotation = Vector3(0.2, s * 0.04, s * 0.22)
			braids.append(braid)
			G.ball(braid, Vector3(0.3, 0.32, 0.3), Vector3(0, -0.015, 0), hair)
			G.ring(braid, 0.11, 0.15, Vector3(0, -0.12, 0), accent)
			var previous := braid
			for link_index in 3:
				var link := Node3D.new()
				previous.add_child(link)
				link.position.y = -0.17 if link_index == 0 else -0.23
				braid_links.append(link)
				var width := 0.18 - link_index * 0.018
				for strand in 2:
					var strand_side := -1.0 if strand == 0 else 1.0
					var weave := G.ball(link, Vector3(width, 0.27, width), Vector3(strand_side * 0.035, -0.09, strand_side * 0.018), hair_light if (strand + link_index) % 2 == 0 else hair)
					weave.rotation.z = strand_side * 0.28
				if link_index == 2:
					G.ring(link, 0.065, 0.09, Vector3(0, -0.19, 0), accent)
					G.ball(link, Vector3(0.13, 0.2, 0.13), Vector3(0, -0.28, 0), hair_light)
				previous = link
	else:
		quiff = Node3D.new()
		head.add_child(quiff)
		quiff.position = Vector3(0, 0.31, 0.18)
		quiff.scale.x=0.84
		for i in 4:
			var tuft := G.ball(quiff, Vector3(0.34, 0.4 + i * 0.05, 0.29), Vector3(-0.22 + i * 0.14, 0.1 + i * 0.03, 0.08), hair_light if i == 2 else hair)
			tuft.rotation.z = -0.35
	# Open helmet frame: facial expression remains visible without a reflective visor.
	var helmet := Suit.tag(G.ring(head, 0.45, 0.50, Vector3(0, 0.02, -0.1), "f1f0ff"),"helmet","shell")
	helmet.rotation.x = PI * 0.5
	helmet.scale.x=0.79
	for s in [-1.0, 1.0]:
		var ear := Suit.tag(G.tube(head, 0.17, 0.14, Vector3(s * 0.40, -0.04, -0.1), dark),"helmet","joint")
		ear.rotation.z = PI * 0.5
		Suit.tag(G.ball(head, Vector3(0.07, 0.12, 0.15), Vector3(s * 0.48, -0.04, -0.1), accent, 0.5),"helmet","light")
	for s in [-1.0, 1.0]:
		var side := "left" if s<0 else "right"
		var arm := Node3D.new()
		body.add_child(arm)
		arm.position = Vector3(s * 0.48, 1.4, 0)
		Suit.tag(G.ball(arm, Vector3(0.32, 0.34, 0.32), Vector3.ZERO, accent),side+"_arm","trim")
		Suit.tag(G.ball(arm, Vector3(0.25, 0.37, 0.25), Vector3(0, -0.16, 0), "f2f2ff"),side+"_arm","fabric")
		var elbow := Node3D.new()
		arm.add_child(elbow)
		elbow.position.y = -0.32
		Suit.tag(G.ball(elbow, Vector3(0.25, 0.24, 0.25), Vector3.ZERO, dark),side+"_arm","joint")
		Suit.tag(G.ball(elbow, Vector3(0.25, 0.3, 0.27), Vector3(0, -0.14, 0), "f2f2ff"),side+"_arm","fabric")
		Suit.tag(G.ball(elbow, Vector3(0.26, 0.12, 0.27), Vector3(0, -0.25, 0), dark),side+"_arm","joint")
		var hand := Node3D.new()
		elbow.add_child(hand)
		hand.position.y = -0.33
		Suit.tag(G.ball(hand, Vector3(0.27, 0.2, 0.29), Vector3(0, 0, 0.025), accent),side+"_glove","joint")
		arms.append(arm)
		elbows.append(elbow)
		hands.append(hand)
		var leg := Node3D.new()
		body.add_child(leg)
		leg.position = Vector3(s * 0.23, 0.83, 0)
		Suit.tag(G.ball(leg, Vector3(0.32, 0.45, 0.34), Vector3(0, -0.19, 0), "e9eaff"),side+"_leg","fabric")
		var knee := Node3D.new()
		leg.add_child(knee)
		knee.position.y = -0.37
		Suit.tag(G.ball(knee, Vector3(0.3, 0.35, 0.32), Vector3(0, -0.14, 0), dark),side+"_leg","fabric")
		Suit.tag(G.ball(knee, Vector3(0.36, 0.24, 0.52), Vector3(0, -0.32, 0.1), "f1f3ff"),side+"_boot","shell")
		Suit.tag(G.box(knee, Vector3(0.3, 0.07, 0.43), Vector3(0, -0.43, 0.1), accent),side+"_boot","joint")
		legs.append(leg)
		knees.append(knee)
	pack = Node3D.new()
	body.add_child(pack)
	Suit.tag(G.box(pack, Vector3(0.62, 0.66, 0.33), Vector3(0, 1.2, -0.4), dark),"backpack","shell")
	for s in [-1.0, 1.0]:
		Suit.tag(G.tube(pack, 0.14, 0.6, Vector3(s * 0.37, 1.17, -0.4), accent),"backpack","trim")
		Suit.tag(G.tube(pack,0.14,0.14,Vector3(s*0.37,0.83,-0.4),dark,0.105),"backpack","metal")
		Suit.tag(G.ring(pack,0.075,0.13,Vector3(s*0.37,0.76,-0.4),dark),"backpack","joint")
	jet_fx=JetpackFx.new()
	pack.add_child(jet_fx)
	jet_fx.build()
	flames.assign(jet_fx.jets)
	board = preload("res://scripts/hover_transport.gd").build("board",0 if not girl else 2)
	add_child(board)
	board.visible = false
	Suit.details(self)
	Suit.mounts(self)
	apply_suit(loadout)
	heart_fingers=Node3D.new()
	body.add_child(heart_fingers)
	heart_fingers.position=Vector3(0,1.42,0.61)
	# Curved index fingers and meeting thumbs make an actual hand-heart silhouette.
	for side in [-1.0,1.0]:
		var points := [Vector3(side*0.16,-0.04,0),Vector3(side*0.16,0.07,0),Vector3(side*0.10,0.13,0),Vector3(side*0.035,0.10,0),Vector3(0,0.045,0)]
		for j in points.size()-1:
			Suit.tag(G.link(heart_fingers,points[j],points[j+1],0.028,accent),"left_glove" if side<0 else "right_glove","trim")
		Suit.tag(G.link(heart_fingers,Vector3(side*0.14,-0.04,0),Vector3(0,-0.13,0),0.03,accent),"left_glove" if side<0 else "right_glove","trim")
	heart_fingers.visible=false
	apply_suit(loadout)

func apply_suit(loadout: Dictionary) -> void:
	suit_loadout=Suit.apply(self,loadout,girl)

func suit_parts(slot: String) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D]=[]
	for part: Node in find_children("*","MeshInstance3D",true,false):
		if part.get_meta("suit_slot","")==slot: result.append(part)
	return result

func animate(dt: float, action: String, velocity: float = 0.0, lean: float = 0.0) -> void:
	clock += dt
	mood = action
	var running := action == "run"
	# Integrate cadence: acceleration must not jump to a different stride pose.
	stride_phase = fposmod(stride_phase + dt * (11.0 + clampf(velocity, 0, 35) * 0.16), TAU)
	var phase := stride_phase
	var breath := sin(clock * 2.4)
	body.position = Vector3(sin(phase) * 0.025 if running else 0.0,
		-1.1 + (absf(sin(phase)) * 0.065 if running else breath * 0.018), 0)
	roll_blend = move_toward(roll_blend, 1.0 if action == "roll" else 0.0, dt * 10)
	pivot.position.y = lerpf(1.1,0.43,roll_blend)
	pivot.rotation.x = -PI * 0.5 * roll_blend
	if action == "flip": pivot.rotation.x = -TAU * smoothstep(0,1,trick_phase)
	body.rotation = Vector3(0.085 + cos(phase * 2) * 0.012 if running else 0.0,
		sin(phase) * 0.065 if running else breath * 0.012,
		(sin(phase) * 0.028 if running else sin(clock * 1.3) * 0.012) - lean * 0.12)
	body.scale = Vector3(1.0 + breath * 0.004, 1.0 + breath * 0.006, 1.0 + breath * 0.006)
	for i in 2:
		var wave := sin(phase + i * PI)
		var side := -1.0 if i == 0 else 1.0
		# Local -Y limbs: the left shoulder needs negative Z to open outward.
		var shoulder := Vector3(-0.12 - wave * 0.72 if running else -0.12 + sin(clock * 2 + i) * 0.045,
			side * 0.04, side * (0.25 + cos(phase * 2) * 0.025 if running else 0.18))
		var bend := -0.9 - wave * 0.18 if running else -0.24
		legs[i].rotation = Vector3(wave * 0.72 if running else 0.0, 0, side * 0.025)
		knees[i].rotation.x = maxf(0, -wave) * 1.05 if running else 0.06
		if action in ["jump", "flip"]:
			shoulder.x = -1.25
			shoulder.z = side * 0.3
			bend = -0.45
			legs[i].rotation.x = 0.35 if i == 0 else -0.4
			knees[i].rotation.x = 0.8
		elif action == "slide":
			shoulder.x = 0.45
			bend = -0.6
		elif action == "roll":
			shoulder = Vector3(-1.65, 0, side * 0.18)
			bend = -0.12
			legs[i].rotation.x = -0.1
			knees[i].rotation.x = 0.15
		elif action == "jet":
			shoulder = Vector3(-0.3, 0, side * 0.5)
			bend = -0.55
			legs[i].rotation.x = -0.3
		elif action == "board":
			shoulder = Vector3(-0.15 + sin(clock * 3 + i) * 0.08, 0, side * 0.8)
			bend = -0.55
		elif action == "win":
			shoulder = Vector3(-0.15, 0, side * (2.4 + sin(clock * 7 + i) * 0.12))
			bend = -0.3
			legs[i].rotation.x = sin(clock * 5 + i * PI) * 0.18
			knees[i].rotation.x = 0.15 + maxf(0,sin(clock * 5 + i * PI))*0.25
		var blend := 1.0 - exp(-20.0 * dt)
		arms[i].quaternion = arms[i].quaternion.slerp(Quaternion.from_euler(shoulder), blend)
		elbows[i].rotation.x = lerp_angle(elbows[i].rotation.x, bend, blend)
		hands[i].rotation = Vector3(sin(phase + i * PI - 0.3) * 0.07 if running else 0.0, 0, side * 0.06)
	if action == "slide":
		body.scale.y = 0.48
		body.rotation.x = -0.4
	elif action == "board":
		body.rotation.z = sin(clock * 3) * 0.08
	elif action == "win":
		body.position.y += absf(sin(clock * 5)) * 0.18
	board.visible = action == "board" or bool(get_meta("riding",false))
	jet_fx.advance(dt,action=="jet" or menu_jet)
	# A brief glance, then several seconds looking ahead; alternate directions.
	var glance_time := clock + (1.1 if girl else 0.0)
	var cycle := int(floor(glance_time / 7.3))
	var local_time := fposmod(glance_time, 7.3)
	var glance := smoothstep(2.0, 2.45, local_time) * (1.0 - smoothstep(3.0, 3.65, local_time))
	var looking_around := action in ["run", "idle", "board", "win"]
	var yaw := glance * (0.24 if cycle % 2 == 0 else -0.24) if looking_around else 0.0
	var head_target := Vector3(breath * 0.018 - (cos(phase * 2) * 0.012 if running else 0.0),
		yaw - body.rotation.y * 0.4, sin(clock * 1.8) * 0.025 + yaw * 0.12)
	head.quaternion = head.quaternion.slerp(Quaternion.from_euler(head_target), 1.0 - exp(-9.0 * dt))
	var blink_time := fposmod(clock + (0.7 if girl else 0.0), 4.1)
	var blink := 1.0 - 0.9 * smoothstep(3.88, 3.97, blink_time) * (1.0 - smoothstep(3.97, 4.1, blink_time))
	var expression:float=front_smile if action in ["run","board"] else 0.0
	if menu_expression>=0: expression=menu_expression
	Face.animate(face,dt,action,clock,blink,expression)
	animate_front_gesture(dt,action)
	animate_hair(dt, action, phase)

func begin_front_gesture(kind: String) -> void:
	front_gesture=kind
	front_gesture_time=0
	front_gesture_emitted=0

func cancel_front_gesture() -> void:
	front_gesture=""
	front_gesture_time=0
	front_gesture_emitted=0
	heart_fingers.visible=false

func gesture_ik(index: int, target: Vector3, pole: Vector3, blend: float) -> void:
	var origin:=arms[index].position
	var delta:=target-origin
	var distance_to:=clampf(delta.length(),0.05,0.649)
	var forward:=delta.normalized()
	var across: Vector3=(pole-forward*pole.dot(forward)).normalized()
	var along: float=(0.32*0.32-0.33*0.33+distance_to*distance_to)/(2*distance_to)
	var elbow_at:=origin+forward*along+across*sqrt(maxf(0,0.32*0.32-along*along))
	var shoulder_q:=Quaternion(Vector3.DOWN,(elbow_at-origin).normalized())
	var elbow_q:=Quaternion(Vector3.DOWN,shoulder_q.inverse()*(target-elbow_at).normalized())
	arms[index].quaternion=arms[index].quaternion.slerp(shoulder_q,blend)
	elbows[index].quaternion=elbows[index].quaternion.slerp(elbow_q,blend)

func animate_front_gesture(dt: float, action: String) -> void:
	heart_fingers.visible=false
	if action!="run": cancel_front_gesture(); front_gesture_blend=0; return
	if front_gesture.is_empty(): return
	front_gesture_time+=dt
	var t:=front_gesture_time
	var duration:=1.35 if front_gesture=="wave" else 1.6 if front_gesture=="tap" else 1.4
	var blend:=smoothstep(0,0.2,t)*(1-smoothstep(duration-0.20,duration,t))
	front_gesture_blend=blend
	if front_gesture=="wave":
		gesture_ik(1,Vector3(0.75+sin(t*17)*0.035,2.0,0.18),Vector3.RIGHT,blend)
		hands[1].rotation.z=sin(t*17)*0.35*blend
	elif front_gesture=="tap":
		var contact:=exp(-pow((t-0.5)*20,2))+exp(-pow((t-1.0)*20,2))
		gesture_ik(0,Vector3(-0.13,1.32,0.51-contact*0.035),Vector3.LEFT,blend)
		for mark in [0.5,1.0]:
			if t>=mark and front_gesture_emitted<int(mark*2):
				front_gesture_emitted=int(mark*2)
				affection.emit("tap",hands[0].global_position)
	else:
		var send:=smoothstep(0.85,1.15,t)*0.08
		for i in 2: gesture_ik(i,Vector3(-0.16 if i==0 else 0.16,1.38,0.49+send),Vector3.LEFT if i==0 else Vector3.RIGHT,blend)
		heart_fingers.position.z=0.61+send
		heart_fingers.visible=blend>0.7
		if t>=0.95 and front_gesture_emitted==0:
			front_gesture_emitted=1
			affection.emit("heart",heart_fingers.global_position)
	face.smile=lerpf(face.smile,maxf(0.85,front_smile),blend)
	face.skin.set_blend_shape_value(0,face.smile)
	for piece: MeshInstance3D in face.pieces: piece.set_blend_shape_value(0,face.smile)
	head.rotation.y=lerp_angle(head.rotation.y,0,blend)
	if t>=duration: cancel_front_gesture()

func animate_hair(dt: float, action: String, phase: float) -> void:
	var active := action == "run" or action == "win"
	var hair_blend := 1.0 - exp(-12.0 * dt)
	for i in braids.size():
		var side := -1.0 if i == 0 else 1.0
		var bounce := cos(phase * 2 - 0.35 - i * 0.3) * 0.15 if active else sin(clock * 2.4 + i) * 0.025
		var swing := sin(phase - 0.4 - i * 0.2) * 0.1 if active else sin(clock * 1.7 + i) * 0.02
		var target := Vector3(0.2 + bounce, side * 0.04, side * 0.22 + swing)
		if action in ["jump", "flip", "jet"]: target.x = 0.38
		braids[i].quaternion = braids[i].quaternion.slerp(Quaternion.from_euler(target), hair_blend)
	for i in braid_links.size():
		var depth := i % 3
		var side := -1.0 if i < 3 else 1.0
		# Each link follows later than the previous one, so the tip trails the root.
		var target := Vector3(sin(phase * 2 - depth * 0.5 - 0.6) * 0.1 if active else sin(clock * 2 - depth * 0.5) * 0.025,
			0, side * 0.025 + (sin(phase - depth * 0.45 - 0.7) * 0.09 if active else 0.0))
		braid_links[i].quaternion = braid_links[i].quaternion.slerp(Quaternion.from_euler(target), hair_blend)
	if is_instance_valid(quiff):
		# Hair rises as the body settles and compresses as the body rises.
		var counter_bob := -(absf(sin(phase)) - 0.5) if active else sin(clock * 2.4) * 0.1
		quiff.position.y = lerpf(quiff.position.y, 0.31 + counter_bob * 0.035, hair_blend)
		quiff.scale.y = lerpf(quiff.scale.y, 1.0 + counter_bob * 0.09, hair_blend)
		var target := Vector3(-0.04 + (cos(phase * 2 - 0.25) * 0.14 if active else sin(clock * 2.4) * 0.025), 0,
			-0.06 + (sin(phase - 0.4) * 0.045 if active else 0.0))
		quiff.quaternion = quiff.quaternion.slerp(Quaternion.from_euler(target), hair_blend)
