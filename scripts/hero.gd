extends Node3D
const G = preload("res://scripts/geometry.gd")
var girl := false
var body: Node3D
var head: Node3D
var arms: Array[Node3D] = []
var legs: Array[Node3D] = []
var knees: Array[Node3D] = []
var eyes: Array[Node3D] = []
var mouth: Node3D
var flames: Array[Node3D] = []
var board: Node3D
var pack: Node3D
var clock := 0.0
var mood := "idle"
var pivot: Node3D
var trick_phase := 0.0
var roll_blend := 0.0

func build(is_girl: bool) -> void:
	girl = is_girl
	var accent := "ff74b5" if girl else "45dcca"
	var dark := "574282" if girl else "225675"
	var hair := "663654" if girl else "8a512f"
	pivot = Node3D.new()
	add_child(pivot)
	pivot.position.y = 1.1
	body = Node3D.new()
	pivot.add_child(body)
	body.position.y = -1.1
	G.ball(body, Vector3(0.86, 0.96, 0.59), Vector3(0, 1.14, 0), "f3f1ff")
	G.ball(body, Vector3(0.81, 0.64, 0.61), Vector3(0, 0.92, 0), dark)
	G.box(body, Vector3(0.53, 0.35, 0.08), Vector3(0, 1.25, 0.31), accent)
	G.star(body, 0.13, Vector3(0, 1.26, 0.37))
	G.ring(body, 0.32, 0.43, Vector3(0, 1.55, 0), dark)
	G.ring(body, 0.33, 0.4, Vector3(0, 1.59, 0), accent, 0.2)
	head = Node3D.new()
	body.add_child(head)
	head.position.y = 1.95
	# Sculpted cheeks, ears, nose and recessed smile. Face points along +Z.
	G.ball(head, Vector3(0.89, 0.94, 0.77), Vector3.ZERO, "f6c5a3")
	G.ball(head, Vector3(0.72, 0.51, 0.6), Vector3(0, -0.21, 0.11), "f6c5a3")
	for sign_value in [-1.0, 1.0]:
		G.ball(head, Vector3(0.18, 0.25, 0.17), Vector3(sign_value * 0.44, -0.035, 0), "edb18f")
		G.ball(head, Vector3(0.17, 0.095, 0.025), Vector3(sign_value * 0.25, -0.16, 0.375), "ed978f")
		var eye := Node3D.new()
		head.add_child(eye)
		eye.position = Vector3(sign_value * 0.18, 0.04, 0.351)
		G.ball(eye, Vector3(0.195, 0.235, 0.085), Vector3.ZERO, "fffaf6")
		G.ball(eye, Vector3(0.108, 0.145, 0.045), Vector3(-sign_value * 0.01, 0, 0.046), "447f93")
		G.ball(eye, Vector3(0.061, 0.11, 0.025), Vector3(-sign_value * 0.01, 0, 0.069), "192841")
		G.ball(eye, Vector3(0.035, 0.042, 0.012), Vector3(-0.025, 0.038, 0.086), "ffffff", 0.3)
		eyes.append(eye)
		var brow := G.ball(head, Vector3(0.22, 0.047, 0.048), Vector3(sign_value * 0.19, 0.21, 0.343), hair)
		brow.rotation.z = -sign_value * 0.15
	G.ball(head, Vector3(0.13, 0.145, 0.14), Vector3(0, -0.08, 0.409), "efb48d")
	mouth = Node3D.new()
	head.add_child(mouth)
	mouth.position = Vector3(0, -0.255, 0.371)
	G.ball(mouth, Vector3(0.29, 0.15, 0.065), Vector3.ZERO, "903e58")
	G.ball(mouth, Vector3(0.23, 0.057, 0.018), Vector3(0, 0.04, 0.033), "fff9ed")
	G.ball(mouth, Vector3(0.13, 0.042, 0.02), Vector3(0, -0.04, 0.035), "ef7a92")
	G.ball(head, Vector3(0.91, 0.62, 0.76), Vector3(0, 0.25, -0.06), hair)
	for i in 5:
		var tuft := G.ball(head, Vector3(0.27, 0.24 + i * 0.018, 0.19), Vector3((i - 2) * 0.15, 0.31 - float(i) * 0.018, 0.30), hair)
		tuft.rotation.z = -0.25
	if girl:
		for s in [-1.0, 1.0]:
			G.ball(head, Vector3(0.31, 0.49, 0.34), Vector3(s * 0.49, 0.08, -0.13), hair)
			G.ball(head, Vector3(0.24, 0.11, 0.23), Vector3(s * 0.46, 0.2, -0.1), accent)
	# Open helmet frame: facial expression remains visible without a reflective visor.
	var helmet := G.ring(head, 0.45, 0.50, Vector3(0, 0.02, -0.1), "f1f0ff")
	helmet.rotation.x = PI * 0.5
	for s in [-1.0, 1.0]:
		var ear := G.tube(head, 0.17, 0.14, Vector3(s * 0.49, -0.04, -0.1), dark)
		ear.rotation.z = PI * 0.5
		G.ball(head, Vector3(0.07, 0.12, 0.15), Vector3(s * 0.57, -0.04, -0.1), accent, 0.5)
	for s in [-1.0, 1.0]:
		var arm := Node3D.new()
		body.add_child(arm)
		arm.position = Vector3(s * 0.46, 1.4, 0)
		G.ball(arm, Vector3(0.32, 0.34, 0.32), Vector3.ZERO, accent)
		G.ball(arm, Vector3(0.25, 0.47, 0.25), Vector3(0, -0.23, 0), "f2f2ff")
		G.ball(arm, Vector3(0.26, 0.35, 0.29), Vector3(0, -0.48, 0.06), dark)
		G.ball(arm, Vector3(0.27, 0.2, 0.29), Vector3(0, -0.65, 0.08), accent)
		arms.append(arm)
		var leg := Node3D.new()
		body.add_child(leg)
		leg.position = Vector3(s * 0.23, 0.83, 0)
		G.ball(leg, Vector3(0.32, 0.45, 0.34), Vector3(0, -0.19, 0), "e9eaff")
		var knee := Node3D.new()
		leg.add_child(knee)
		knee.position.y = -0.37
		G.ball(knee, Vector3(0.3, 0.35, 0.32), Vector3(0, -0.14, 0), dark)
		G.ball(knee, Vector3(0.36, 0.24, 0.52), Vector3(0, -0.32, 0.1), "f1f3ff")
		G.box(knee, Vector3(0.3, 0.07, 0.43), Vector3(0, -0.43, 0.1), accent)
		legs.append(leg)
		knees.append(knee)
	pack = Node3D.new()
	body.add_child(pack)
	G.box(pack, Vector3(0.62, 0.66, 0.33), Vector3(0, 1.2, -0.4), dark)
	for s in [-1.0, 1.0]:
		G.tube(pack, 0.14, 0.6, Vector3(s * 0.37, 1.17, -0.4), accent)
		var flame := G.ball(pack, Vector3(0.18, 0.65, 0.18), Vector3(s * 0.37, 0.65, -0.4), "67f7ff", 1.5)
		flames.append(flame)
	board = Node3D.new()
	add_child(board)
	G.ball(board, Vector3(1.55, 0.24, 2.15), Vector3(0, 0, 0), dark)
	G.ball(board, Vector3(1.4, 0.12, 1.9), Vector3(0, 0.12, 0), accent, 0.3)
	for s in [-1.0, 1.0]:
		G.ball(board, Vector3(0.24, 0.12, 1.2), Vector3(s * 0.65, -0.09, 0), "72f9ee", 1)
	board.visible = false

func animate(dt: float, action: String, velocity: float = 0.0, lean: float = 0.0) -> void:
	clock += dt
	mood = action
	var running := action == "run"
	var phase := clock * (12.0 + velocity * 0.16)
	body.position.y = -1.1 + (absf(sin(phase)) * 0.055 if running else sin(clock * 2.4) * 0.025)
	roll_blend = move_toward(roll_blend, 1.0 if action == "roll" else 0.0, dt * 10)
	pivot.position.y = lerpf(1.1,0.43,roll_blend)
	pivot.rotation.x = -PI * 0.5 * roll_blend
	if action == "flip": pivot.rotation.x = -TAU * smoothstep(0,1,trick_phase)
	body.rotation = Vector3(-0.08 if running else 0.0, 0, -lean * 0.12)
	body.scale = Vector3.ONE
	for i in 2:
		var wave := sin(phase + i * PI)
		arms[i].rotation = Vector3(-wave * 0.7 if running else sin(clock * 2 + i) * 0.08, 0, (1 if i == 0 else -1) * 0.1)
		legs[i].rotation.x = wave * 0.65 if running else 0.0
		knees[i].rotation.x = maxf(0, -wave) * 0.8 if running else 0.06
	if action in ["jump", "flip"]:
		for i in 2:
			arms[i].rotation.x = -1.25
			legs[i].rotation.x = 0.35 if i == 0 else -0.4
			knees[i].rotation.x = 0.8
	elif action == "slide":
		body.scale.y = 0.48
		body.rotation.x = -0.4
	elif action == "roll":
		for i in 2:
			arms[i].rotation.x = -1.65
			arms[i].rotation.z = (1 if i == 0 else -1) * 0.18
			legs[i].rotation.x = -0.1
			knees[i].rotation.x = 0.15
	elif action == "jet":
		for i in 2:
			arms[i].rotation.z = (1 if i == 0 else -1) * 0.5
			legs[i].rotation.x = -0.3
	elif action == "board":
		body.rotation.z = sin(clock * 3) * 0.08
		for i in 2:
			arms[i].rotation.z = (1 if i == 0 else -1) * 0.8
	elif action == "win":
		body.position.y += absf(sin(clock * 5)) * 0.18
		for i in 2:
			arms[i].rotation.z = (1 if i == 0 else -1) * 2.4
	board.visible = action == "board" or bool(get_meta("riding",false))
	for flame in flames:
		flame.visible = action == "jet"
		flame.scale.y = 0.8 + sin(clock * 37) * 0.22
	head.rotation = Vector3(0, sin(clock * 1.4) * 0.04, sin(clock * 1.8) * 0.035)
	var blink := 0.12 if fmod(clock, 4.1) > 3.97 else 1.0
	for eye in eyes: eye.scale.y = blink
	mouth.scale.y = 1.35 if action in ["jet", "win", "flip", "roll"] else 1.0
