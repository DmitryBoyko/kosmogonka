extends "res://scripts/stellar_particles.gd"
## Five-point star motion inspired by LittleTruck's feedback, adapted to 3D.
var spark_wait:=0.
var star_wait:=0.
var last_distance:=0.
func advance(dt:float,hero:Node3D,pose:Dictionary,distance_value:float,active:bool,reduced:bool,quality:bool) -> void:
	var scroll:=distance_value-last_distance; last_distance=distance_value
	if absf(scroll)>20. or reduced: clear();return
	spark_wait-=dt;star_wait-=dt
	if active and not pose.is_empty():
		var forward:Vector3=pose.forward;var up:Vector3=pose.up;var right:Vector3=pose.right
		if spark_wait<=0:
			spark_wait=.045 if quality else .08
			for jet:Node3D in hero.jet_fx.jets:
				emit_particle(jet.global_position,-forward*rng.randf_range(4.,7.)+up*rng.randf_range(.1,.7)+right*rng.randf_range(-.6,.6),.30,.16,Color("ffd07b"),false,2.)
		if star_wait<=0:
			star_wait=.09 if quality else .16
			emit_particle(hero.position+up*.9-forward*.4,-forward*3.+right*rng.randf_range(-.9,.9),.68,.28,Color("ffe6a7") if rng.randf()<.7 else Color("b5efff"),true,1.5)
	advance_particles(dt,scroll)
