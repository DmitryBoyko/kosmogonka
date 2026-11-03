extends SceneTree
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok:bool,label_value:String) -> void:
	checks+=1
	if not ok: failures.append(label_value); push_error(label_value)
func run() -> void:
	var app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; app.set_process(false); app.set_physics_process(false)
	var music=app.sound.music
	check(music.CATALOG.STREAMS.size()==10,"all ten supplied songs are export-referenced")
	for stream in music.CATALOG.STREAMS:
		check(stream is AudioStreamOggVorbis and stream.get_length()>60 and not stream.loop,"normalized OGG has a real duration and does not loop")
	for cycle in 3:
		var seen:Dictionary={}; var previous:int=music.last_index
		for i in 10:
			var current:int=music.next_index()
			check(previous!=current,"no immediate song repetition, including shuffle boundary")
			seen[current]=true; previous=current
		check(seen.size()==10,"all songs occur once in a shuffled bag")
	app.sound.enabled=true; app.show_menu(); app._process(.2)
	check(music.envelope==0 and music.players.all(func(p):return not p.playing),"main menu does not start race music")
	app.start_level(); app.begin_run(); app._process(1.5)
	check(music.players[music.current].playing and music.envelope==1,"run fades music in")
	var outgoing:int=music.current; var old_index:int=music.last_index
	var p:AudioStreamPlayer=music.players[outgoing]
	p.seek(p.stream.get_length()-5)
	await create_timer(.08).timeout
	music.advance(.01,true)
	check(music.incoming>=0 and music.players[0].playing and music.players[1].playing,"new song overlaps the end of the old song")
	check(music.last_index!=old_index,"overlapping song is different")
	music.advance(music.cross_length*.5,true)
	check(absf(music.players[0].volume_db-music.players[1].volume_db)<1.5,"equal-power fade balances both voices at midpoint")
	var age:float=music.cross_age
	music.set_paused(true); music.advance(3,true)
	check(music.cross_age==age and music.players.all(func(player):return player.stream_paused),"pause freezes both streams and fade phase")
	music.set_paused(false); music.advance(6,true)
	check(music.current!=outgoing and music.incoming<0 and not music.players[outgoing].playing,"fade completes and releases old decoder")
	check(music.players.all(func(player):return player.bus=="Music"),"existing music volume slider controls both streams")
	app.start_flight(0); app._process(.2)
	check(music.requested and music.players[music.current].playing,"interplanetary race uses the same shuffled playlist")
	app.show_menu(); app._process(2.2)
	check(music.envelope==0 and music.players.all(func(player):return not player.playing),"leaving the race fades music out and stops decoding")
	var out:=FileAccess.open("res://build/music-report.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"checks":checks,"failures":failures},"  ")); out.close()
	print("MUSIC: %d checks, %d failures"%[checks,failures.size()])
	app.free(); await create_timer(.2).timeout; quit(0 if failures.is_empty() else 1)
