extends "res://scripts/stellar_particles.gd"
## Four staggered salvos, radial shells and gold stars; CubicWords-style timing.
signal salvo
const SALVOS:=[.18,1.0,1.9,2.8]
var celebrating:=false
var age:=0.
var next_salvo:=0
var accent:=Color("80f5dc")
func _init() -> void: capacity=192
func start(world:int) -> void:
	clear();celebrating=true;age=0.;next_salvo=0;rng.seed=world*7919+31
	accent=Color(preload("res://scripts/planets.gd").get_data(world).accent)
func stop() -> void: celebrating=false;clear()
func advance(dt:float,reduced:bool,quality:bool) -> void:
	if not celebrating: return
	age+=dt
	while next_salvo<SALVOS.size() and age>=SALVOS[next_salvo]:
		var centre:=Vector3([-7.,7.,-4.,4.][next_salvo],[14.,16.,19.,17.][next_salvo],[-6.,-8.,-10.,-7.][next_salvo])
		var count:=18 if reduced else 42 if quality else 28
		for i in count:
			var angle:=i*TAU/count
			var v:=Vector3(cos(angle),sin(angle),rng.randf_range(-.35,.35))*rng.randf_range(3.5,6.)*(.4 if reduced else 1.)
			var star:=i%5==0
			emit_particle(centre,v,1.9,.7 if star else .42,[Color("ffe4a2"),accent,Color("ffa5de")][(i+next_salvo)%3],star,1.1)
		next_salvo+=1;salvo.emit()
	advance_particles(dt)
	if age>5.: stop()
