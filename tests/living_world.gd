extends SceneTree
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures.append(message);push_error(message)
func run() -> void:
	var app=load("res://scenes/main.tscn").instantiate();app.test_mode=true;root.add_child(app)
	await process_frame;app.set_process(false);app.set_physics_process(false)
	var sound:Node=app.sound;sound.enabled=true
	for stream:AudioStream in sound.AlienSfx:check(stream.get_length()>.3 and stream.get_length()<.8,"short original alien chirp")
	sound.alien_cooldown=0.;sound.important_sfx_wait=0.;sound.voice.stop()
	check(sound.try_alien(Vector3(1,1,-5),0) and sound.alien_voice.playing,"alien uses its spatial audio source")
	check(not sound.try_alien(Vector3.ZERO,1),"two nearby aliens cannot form a chorus")
	await physics_frame;await physics_frame
	sound.set_paused(true);check(sound.alien_voice.stream_paused,"pause freezes alien voice");sound.set_paused(false)
	sound.advance(.1,false,false);check(not sound.alien_voice.playing,"menu silences ambient alien speech")
	sound.alien_cooldown=0.;sound.sfx("warning");check(not sound.try_alien(Vector3.ZERO),"hazard cue takes priority over chatter")
	sound.advance(2.,false,true);sound.alien_cooldown=0.;check(sound.try_alien(Vector3.ZERO,1),"chatter can return after a quiet gap")
	check(sound.alien_cooldown>=7. and sound.alien_cooldown<=12.,"long bounded pause between chirps")
	sound.advance(.1,false,false)
	var bio=preload("res://scripts/roadside_biology.gd")
	for world in 10:
		var chunk:=Node3D.new();root.add_child(chunk);bio.populate(chunk,world,12,true)
		var nodes:=chunk.find_children("Meadow*","MultiMeshInstance3D",true,false)
		check(nodes.size()==3,"only three draw groups per chunk world "+str(world))
		for node:MultiMeshInstance3D in nodes:
			check(node.multimesh.instance_count<=80,"fixed instance budget "+node.name)
			for i in (node.multimesh.instance_count if DisplayServer.get_name()!="headless" else 0):
				var at:Vector3=node.multimesh.get_instance_transform(i).origin
				check(absf(at.x)>5.2 and at.z> -30. and at.z<0.,"vegetation leaves all three running lanes clear")
		bio.set_quality(chunk,false)
		check(nodes[0].multimesh.visible_instance_count==36 and nodes[1].multimesh.visible_instance_count==24 and nodes[2].multimesh.visible_instance_count==3,"lower quality reduces all three groups")
		chunk.queue_free()
	preload("res://scripts/natural_flora.gd").set_motion(true)
	check(bio.material(0,true).get_shader_parameter("wind")==0.,"reduced motion freezes winged fauna and flowers")
	preload("res://scripts/natural_flora.gd").set_motion(false)
	app.reset_course();app.begin_run();app.distance=2100.;app.spawn_and_update();app.finish_level()
	var residents:Node3D=app.finish.get_node("FinishCity/RunningResidents")
	app.runner.position=residents.residents[0].global_position+Vector3(0,0,2)
	sound.voice.stop();sound.alien_cooldown=0.;sound.important_sfx_wait=0.;var before:int=sound.alien_serial;app.alien_scan_wait=0.;app._process(.01)
	check(sound.alien_serial==before+1,"nearby plaza resident occasionally speaks")
	print("LIVING WORLD: %d checks, %d failures"%[checks,failures.size()])
	app.queue_free();await process_frame;await process_frame;await create_timer(.2).timeout;quit(0 if failures.is_empty() else 1)
