extends SceneTree

const Course = preload("res://scripts/course.gd")
const Turns = preload("res://scripts/turn_track.gd")
const Loops = preload("res://scripts/loop_layout.gd")
const Cargo = preload("res://scripts/cargo_containers.gd")
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(message)

func run() -> void:
	for world in 11:
		var original := ""
		for seed in [79331,93513,79331]:
			Course.layout_seed=seed
			Loops.route_seed=seed
			var events := Course.events(world)
			var plan := Turns.new()
			plan.build(world,seed,events)
			var signature := str(plan.turns)+str(events.map(func(e):return [e.s,e.lane,e.kind]))
			if original.is_empty():original=signature
			elif seed==79331:check(signature==original,"checkpoint seed reproduces the route")
			else:check(signature!=original,"new seed changes the route")
			check(plan.turns.size()>=3,"every planet has curves")
			for curve in plan.turns:
				var middle:=lerpf(curve.x,curve.y,.24)
				plan.set_distance(middle)
				check(plan.map(Vector3.ZERO).length()<.001,"the camera frame follows the tangent")
				check(plan.map(Vector3.RIGHT*2.6).distance_to(Vector3.RIGHT*2.6)<.001,"lane offsets agree with obstacle support")
				check(absf(plan.sample(middle).y)>.08,"the bend has a real heading change")
				check(plan.sample(curve.x).is_zero_approx() and plan.sample(curve.y).is_zero_approx(),"modules meet smoothly")
			for kind:String in Loops.kinds(world):
				check(plan.sample(Loops.start(kind)).is_zero_approx(),"loop entry sits on its reserved module")
			for event:Dictionary in events:
				if event.kind in ["tunnel","basement","stairs","stairs_down","skycarrier"]:
					check(plan.sample(event.s).is_zero_approx(),"precision section keeps its original collision frame")
	for variant in range(14,18):
		var cargo:=Cargo.fitted(variant,Vector3(2.08,.98,1.08))
		var bounds:=Loops.bounds(cargo,Transform3D.IDENTITY)
		check(bounds.size.is_equal_approx(Vector3(2.08,.98,1.08)) and absf(bounds.position.y)<.001,"imported cargo matches collision envelope")
		cargo.free()
	print("GENERATED ROUTES: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
