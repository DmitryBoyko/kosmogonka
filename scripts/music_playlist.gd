extends Node
## Two streaming decoders, shuffled bags, equal-power overlap and an independent bus.
const CATALOG=preload("res://assets/music/catalog.gd")
const CROSSFADE:=6.0
var players:Array[AudioStreamPlayer]=[]
var bag:Array[int]=[]
var last_index:=-1
var current:=0
var incoming:=-1
var cross_age:=0.0
var cross_length:=CROSSFADE
var envelope:=0.0
var requested:=false
var paused:=false
var rng:=RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	for i in 2:
		var p:=AudioStreamPlayer.new(); p.bus="Music"; add_child(p); players.append(p)
		p.finished.connect(finished.bind(i))

func next_index() -> int:
	if bag.is_empty():
		for i in CATALOG.STREAMS.size(): bag.append(i)
		for i in range(bag.size()-1,0,-1):
			var j:=rng.randi_range(0,i); var saved:=bag[i]; bag[i]=bag[j]; bag[j]=saved
		if bag.size()>1 and bag.back()==last_index:
			var saved:=bag[0]; bag[0]=bag[-1]; bag[-1]=saved
	last_index=bag.pop_back(); return last_index

func play_on(index:int) -> void:
	var p:=players[index]; p.stream=CATALOG.STREAMS[next_index()]
	p.volume_db=-80; p.play()

func finished(index:int) -> void:
	if index!=current: return
	if incoming>=0:
		current=incoming; incoming=-1; cross_age=0
	elif requested: play_on(current)

func advance(dt:float,active:bool,enabled:bool=true) -> void:
	if paused: return
	requested=active and enabled
	envelope=move_toward(envelope,1.0 if requested else 0.0,dt/(1.5 if requested else 2.0))
	if not requested and envelope<=0:
		for p in players: p.stop()
		incoming=-1; cross_age=0; return
	if requested and not players[current].playing and incoming<0: play_on(current)
	if incoming<0 and players[current].playing:
		var p:=players[current]
		var remaining:float=p.stream.get_length()-p.get_playback_position()
		if remaining<=CROSSFADE and requested:
			incoming=1-current; cross_age=0; cross_length=clampf(remaining,.1,CROSSFADE)
			play_on(incoming)
	var old_gain:=1.0; var new_gain:=0.0
	if incoming>=0:
		cross_age+=dt
		var t:float=clampf(cross_age/cross_length,0,1)
		old_gain=cos(t*PI*.5); new_gain=sin(t*PI*.5)
	players[current].volume_db=linear_to_db(maxf(.0001,old_gain*envelope*.55))
	if incoming>=0:
		players[incoming].volume_db=linear_to_db(maxf(.0001,new_gain*envelope*.55))
		if cross_age>=cross_length:
			players[current].stop(); current=incoming; incoming=-1; cross_age=0

func set_paused(value:bool) -> void:
	paused=value
	for p in players: p.stream_paused=value

func _exit_tree() -> void:
	for p in players: p.stop(); p.stream=null
