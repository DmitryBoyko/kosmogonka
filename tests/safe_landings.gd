extends SceneTree
const C=preload("res://scripts/course.gd")
var app:Node
var checks:=0
var errors:Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok:bool,label_value:String) -> void:
	checks+=1
	if not ok: errors.append(label_value); push_error(label_value)
func clean() -> void:
	app.reset_course(); app.begin_run(); app.events.clear(); app.pickups.clear(); app.distance=610.; app.lane=1; app.x=0.; app.height=0.; app.support=0.; app.vertical_speed=0.
func run() -> void:
	app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; app.set_process(false); app.set_physics_process(false)
	var p=root.get_node("Profile"); p.outfits=[{},{}]
	for hero in 2:
		p.hero=hero
		for kind in ["stairs","stairs_down","skycarrier","cargo","carrier"]:
			clean()
			var e:=C.make_event(610.,1,kind); e.top=4.44 if kind in ["stairs","stairs_down","skycarrier"] else C.top_of(kind); e.length=24. if kind in ["stairs","stairs_down","skycarrier"] else e.length; e.speed=0.; e.floors=3; e.lower=false
			app.events.append(e); app.distance=e.s+e.length*.5-.1; app.height=e.top; app.support=e.top
			app.jump()
			for frame in 180: app.simulate(1./60.)
			check(app.lives==3 and app.shield_charges==0 and app.height==0.,"jump and descent without HP cost "+kind+str(hero))
		for kind in ["truck","traffic","broken"]:
			clean(); var e:=C.make_event(610.,1,kind); app.events.append(e)
			app.distance=610.-1.2/1.35; C.advance_event(e,app.distance,15.,0,.016)
			var roof:float=C.vehicle_deck(e,app.distance-e.s)
			app.height=roof+.12; app.vertical_speed=-8.
			app.simulate(1./60.)
			check(app.lives==3 and app.height>=roof-.02,"landing on a vehicle roof is safe "+kind)
			app.jump()
			for frame in 180: app.simulate(1./60.)
			check(app.lives==3 and app.height==0.,"jumping off vehicle is safe "+kind)
		clean()
		for centre in [610.,624.,638.]: app.events.append(C.make_event(centre,1,"cargo"))
		app.distance=603.1; app.height=3.; app.support=3.; var jumped:=false
		for frame in 230:
			if app.distance>616. and not jumped: app.jump(); jumped=true
			app.simulate(1./60.)
		check(jumped and app.distance>645. and app.lives==3,"jump over three joined containers and exit safely")
		clean()
		for lane in 3: app.events.append(C.make_event(610.,lane,"cargo"))
		app.height=3.; app.support=3.; app.jump(); app.move_screen(1)
		for frame in 180: app.simulate(1./60.)
		check(app.lives==3,"sideways jump across a three-container row is safe")
	print("SAFE LANDINGS: %d checks, %d failures"%[checks,errors.size()])
	app.free(); await process_frame; quit(0 if errors.is_empty() else 1)
