extends "res://scripts/stellar_particles.gd"
## Five-point star motion inspired by LittleTruck's feedback, adapted to 3D.
var spark_wait:=0.
var star_wait:=0.
var last_distance:=0.
func advance(dt:float,hero:Node3D,pose:Dictionary,distance_value:float,jetting:bool,reduced:bool,quality:bool) -> void:
	var scroll:=distance_value-last_distance; last_distance=distance_value
	if absf(scroll)>20. or reduced: clear();return
	spark_wait-=dt;star_wait-=dt
	var looping:=not pose.is_empty()
	if looping or jetting:
		if spark_wait<=0:
			spark_wait=(.045 if looping else .095) if quality else (.08 if looping else .16)
			if jetting:
				for jet:Node3D in hero.jet_fx.jets:
					var nozzle:=jet.global_basis.orthonormalized()
					var velocity:=-nozzle.y*rng.randf_range(4.5,7.0)+nozzle.x*rng.randf_range(-.7,.7)
					emit_particle(jet.global_position,velocity,.34,.17,Color("ffd07b"),false,1.4)
			elif looping:
				emit_particle(hero.global_position-pose.forward*.4, -pose.forward*4., .24,.18,Color("80ebff"),false,.6)
		if looping and star_wait<=0:
			var forward:Vector3=pose.forward;var up:Vector3=pose.up;var right:Vector3=pose.right
			star_wait=.09 if quality else .16
			emit_particle(hero.position+up*.9-forward*.4,-forward*3.+right*rng.randf_range(-.9,.9),.68,.28,Color("ffe6a7") if rng.randf()<.7 else Color("b5efff"),true,1.5)
	if looping or jetting or live_count>0: advance_particles(dt,scroll)
