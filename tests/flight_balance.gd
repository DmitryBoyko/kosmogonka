extends SceneTree
const Flight=preload("res://scripts/flight.gd")
var wins:=0
var active_wins:=0
var errors:=0
var times: Array=[]

func _initialize() -> void: call_deferred("run")

func run() -> void:
	for seed_value in 80:
		var race:=Flight.new()
		root.add_child(race)
		race.build((seed_value%40)%9,(seed_value%40)*7919+17)
		for frame in 1000:
			if seed_value>=40:
				for charge in race.rings:
					if not charge.taken and charge.s>race.distance:
						race.steer(signi(int(charge.lane)-race.lane)); break
			race.advance(1.0/30)
			if race.done: break
		if race.place==1:
			if seed_value<40: wins+=1
			else: active_wins+=1
		if not race.done or race.elapsed<19 or race.elapsed>30:
			errors+=1
			push_error("Flight duration/finish seed %d %.1f" % [seed_value,race.elapsed])
		times.append(race.elapsed)
		race.free()
		await process_frame
	if wins<5 or wins>28 or active_wins<32 or active_wins<=wins:
		errors+=1
		push_error("Idle wins %d/40, active charging wins %d/40" % [wins,active_wins])
	print("FLIGHT BALANCE: 80 races, idle wins %d/40, active wins %d/40, %.1f–%.1fs, %d failures" % [wins,active_wins,times.min(),times.max(),errors])
	var file:=FileAccess.open("res://build/flight-balance.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"races":80,"idle_wins":wins,"active_wins":active_wins,"min_seconds":times.min(),"max_seconds":times.max(),"failures":errors},"  "))
	file.close()
	await create_timer(0.15).timeout
	quit(0 if errors==0 else 1)
