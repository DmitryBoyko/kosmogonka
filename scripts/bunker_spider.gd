extends Node3D

var actor: Node3D
var age := 0.
var tabletop := 1.15
var route: Array[Dictionary] = []

func build(height: float) -> void:
	name="BunkerSpider"
	set_meta("motion",true)
	tabletop=height
	actor=load("res://scripts/plaza_trade_corner.gd").place(self,"Enemy_QuadShell",Vector3.ZERO,.90)
	for player: AnimationPlayer in actor.find_children("*","AnimationPlayer",true,false):
		for clip: String in player.get_animation_list():
			if "walk" in clip.to_lower():
				player.get_animation(clip).loop_mode=Animation.LOOP_LINEAR
				player.play(clip)
				break
	route=[
		{"at":Vector3(2.4,0,1.4),"up":Vector3.UP,"duration":1.4,"jump":.85},
		{"at":Vector3(.68,tabletop,.18),"up":Vector3.UP,"duration":2.2,"jump":0.},
		{"at":Vector3(.68,tabletop,-.37),"up":Vector3.UP,"duration":1.2,"jump":.65},
		{"at":Vector3(2.5,0,-.2),"up":Vector3.UP,"duration":2.3,"jump":0.},
		{"at":Vector3(5.69,0,-.2),"up":Vector3.UP,"duration":1.,"jump":0.},
		{"at":Vector3(5.69,.65,-.2),"up":Vector3.LEFT,"duration":2.2,"jump":0.},
		{"at":Vector3(5.69,3.35,-.2),"up":Vector3.LEFT,"duration":2.8,"jump":0.},
		{"at":Vector3(5.69,3.35,-3.4),"up":Vector3.LEFT,"duration":2.4,"jump":0.},
		{"at":Vector3(5.69,.65,-3.4),"up":Vector3.LEFT,"duration":1.,"jump":0.},
		{"at":Vector3(5.35,0,-3.4),"up":Vector3.UP,"duration":2.5,"jump":0.},
		{"at":Vector3(5.1,0,1.4),"up":Vector3.UP,"duration":2.5,"jump":0.},
	]
	advance(0.,false)

func advance(dt: float, reduced: bool) -> void:
	age+=dt
	var duration := 0.
	for point in route: duration+=float(point.duration)
	var phase := fposmod(age,duration)
	for i in route.size():
		var point: Dictionary=route[i]
		if phase>float(point.duration):
			phase-=float(point.duration)
			continue
		var next: Dictionary=route[(i+1)%route.size()]
		var t := clampf(phase/float(point.duration),0.,1.)
		var u := smoothstep(0.,1.,t)
		position=point.at.lerp(next.at,u)
		position.y+=sin(PI*t)*float(point.jump)
		var up: Vector3=point.up.slerp(next.up,u).normalized()
		var forward: Vector3=(next.at-point.at).normalized()
		forward=(forward-up*forward.dot(up)).normalized()
		if forward.length_squared()>.01:
			var right:=up.cross(forward).normalized()
			var facing:=Basis(right,up,forward).get_rotation_quaternion()
			quaternion=quaternion.slerp(facing,1.-exp(-dt*9.)) if dt>0. else facing
		actor.rotation.z=0. if reduced else sin(age*16.)*.025
		return
