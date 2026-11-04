extends SceneTree
var checks := 0
var failures := 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label_value: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label_value)

func run() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	app.test_mode = true
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app.set_physics_process(false)
	var sound = app.sound
	for person in ["boy", "girl"]:
		for event in ["jump", "laugh", "joy", "win", "hit", "surprise"]:
			var keys:Array=sound.GirlVoices.GROUPS[event] if person=="girl" else ["boy_"+event+"_0","boy_"+event+"_1","boy_"+event+"_2"]
			for key:String in keys:
				var clip:AudioStream=sound.get_clip(key)
				check(clip!=null and clip.get_length()>.08 and clip.get_length()<(6.0 if person=="girl" else 1.6),key+" imports with original take duration")
				if person=="girl": check(clip is AudioStreamOggVorbis and not clip.loop,"girl take is a non-looping OGG")
	seed(4611)
	for event:String in sound.GirlVoices.GROUPS:
		var seen:Dictionary={}; var previous:=""; var repeats:=0
		for i in 300:
			var key:String=sound.choose_voice(event,true)
			if key==previous: repeats+=1
			seen[key]=true; previous=key
		check(seen.size()==sound.GirlVoices.GROUPS[event].size(),"random selection reaches every supplied "+event+" take")
		check(repeats==0,"no immediate repeat within girl category "+event)
	check(sound.GirlVoices.CLIPS.size()==44,"all 44 user files are included")
	check(sound.GirlVoices.GROUPS.jump.has("girl_jump_12") and not sound.GirlVoices.GROUPS.laugh.has("girl_laugh_2"),"non-contiguous and two-digit take names work")
	check(sound.voice.bus == "Voices", "human voices use the independent voice bus")
	sound.enabled = true
	for girl in [false, true]:
		root.get_node("Profile").hero = 1 if girl else 0
		app.start_level()
		app.begin_run()
		sound.voice.stop()
		sound.cooldown = 0
		app.jump()
		check(sound.last_voice.begins_with("girl_jump_" if girl else "boy_jump_"), "jump selects the chosen actor")
		var previous: String = sound.last_voice
		sound.vocal("surprise", girl)
		check(sound.last_voice == previous, "warning does not interrupt a voice on cooldown")
		app.height = 0.3
		app.gesture_direction = "up"
		app.gesture_age = 0.1
		app.vertical_gesture("up")
		check(sound.last_voice.begins_with("girl_laugh_" if girl else "boy_laugh_"), "double up replaces effort with laughter")
		for i in 12:
			previous = sound.last_voice
			sound.vocal("laugh", girl, true)
			check(sound.last_voice != previous, "consecutive laughter uses different takes")
		sound.vocal("surprise", girl, true)
		check(sound.last_voice.begins_with("girl_surprise_" if girl else "boy_surprise_"), "surprise has its own recording")
		check(sound.voice.pitch_scale == 1.0, "runtime preserves prepared actor pitch")
		sound.set_paused(true)
		check(sound.voice.stream_paused, "pause freezes a human reaction")
		sound.set_paused(false)
		sound.voice.stop()
		sound.cooldown = 0
		app.distance = 780.1
		app.simulate(1.0 / 60)
		check(sound.last_voice.begins_with("girl_surprise_" if girl else "boy_surprise_"), "drone warning triggers the selected actor's surprise")
	sound.enabled = false
	app.queue_free()
	await process_frame
	await process_frame
	# Give the audio mixer time to release the rapidly replaced playback handles.
	await create_timer(0.15).timeout
	print("AUDIO: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
