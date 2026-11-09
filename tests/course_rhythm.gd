extends SceneTree
const C=preload("res://scripts/course.gd")
var checks:=0
var errors:Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok:bool,label_value:String) -> void:
	checks+=1
	if not ok: errors.append(label_value)
func run() -> void:
	var costs:Array[float]=[]
	for seed_value in 80:
		for world in 10:
			C.layout_seed=seed_value
			var stamp:=Time.get_ticks_usec(); var events:=C.events(world); costs.append((Time.get_ticks_usec()-stamp)/1000.)
			var previous:=-INF
			for e:Dictionary in events:
				if e.kind!="alien": continue
				check(e.s-previous>=C.expected_speed(e.s,world)*1.4,"distinct crossing windows seed%d world%d"%[seed_value,world]); previous=e.s
				if not e.get("surprise",false): continue
				check(e.warning_distance/C.expected_speed(e.s,world)>=1.59,"warning measured in seconds")
				for other:Dictionary in events:
					if other==e: continue
					check(absf(e.s-other.s)>other.length*.5+13.9,"no extra courier inside an authored encounter")
			check(events==C.events(world),"same seed preserves authored and random plans")
	costs.sort()
	var report:={"checks":checks,"failures":errors,"plans":800,"generation_p95_ms":costs[int(costs.size()*.95)],"generation_max_ms":costs[-1]}
	var file:=FileAccess.open("res://build/course-rhythm-report.json",FileAccess.WRITE); file.store_string(JSON.stringify(report,"  ")); file.close()
	print("COURSE RHYTHM: ",JSON.stringify(report))
	quit(0 if errors.is_empty() else 1)
