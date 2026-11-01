extends SceneTree
const Flight=preload("res://scripts/flight.gd")
var wins:=0
var errors:=0
var times: Array=[]

func _initialize() -> void: call_deferred("run")

func run() -> void:
	for seed_value in 40:
		var race:=Flight.new()
		root.add_child(race)
		race.build(seed_value%3,seed_value*7919+17)
		for frame in 1000:
			race.advance(1.0/30)
			if race.done: break
		if race.place==1: wins+=1
		if not race.done or race.elapsed<20 or race.elapsed>30:
			errors+=1
			push_error("Flight duration/finish seed %d %.1f" % [seed_value,race.elapsed])
		times.append(race.elapsed)
		race.free()
		await process_frame
	if wins<20 or wins>38:
		errors+=1
		push_error("Idle middle-lane baseline wins %d/40" % wins)
	print("FLIGHT BALANCE: 40 races, %d player wins, %d bot wins, %.1f–%.1fs, %d failures" % [wins,40-wins,times.min(),times.max(),errors])
	var file:=FileAccess.open("res://build/flight-balance.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"races":40,"player_wins":wins,"bot_wins":40-wins,"min_seconds":times.min(),"max_seconds":times.max(),"failures":errors},"  "))
	file.close()
	await create_timer(0.15).timeout
	quit(0 if errors==0 else 1)
