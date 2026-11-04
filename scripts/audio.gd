extends Node
## Both heroes: all user-supplied OGG takes; see docs/audio_sources.
const BoyVoices=preload("res://assets/audio/boy_voices.gd")
const GirlVoices=preload("res://assets/audio/girl_voices.gd")
var pool: Array[AudioStreamPlayer] = []
var voice: AudioStreamPlayer
var music: Node
var engine: AudioStreamPlayer
var cooldown := 0.0
var last_voice := ""
var last_voice_by_category:Dictionary={}
var streams: Dictionary = {}
var enabled := DisplayServer.get_name() != "headless"
var pickup_pool:Array[AudioStreamPlayer]=[]
var pickup_cursor:=0
var pickup_chain:=0
var pickup_gap:=10.0
var last_pickup_key:=""

func _ready() -> void:
	for i in 4:
		var player:=AudioStreamPlayer.new(); player.bus="Effects"; add_child(player); pickup_pool.append(player)
	for i in 10:
		var p := AudioStreamPlayer.new()
		p.bus = "Effects"
		add_child(p)
		pool.append(p)
	voice = AudioStreamPlayer.new()
	voice.bus = "Voices"
	add_child(voice)
	music=preload("res://scripts/music_playlist.gd").new()
	add_child(music)
	engine = AudioStreamPlayer.new()
	engine.bus = "Effects"
	engine.volume_db = -14
	add_child(engine)
	engine.finished.connect(func():
		if bool(engine.get_meta("active", false)): engine.play())
func get_clip(key: String) -> AudioStream:
	if BoyVoices.CLIPS.has(key): return BoyVoices.CLIPS[key]
	if GirlVoices.CLIPS.has(key): return GirlVoices.CLIPS[key]
	if not streams.has(key): streams[key] = load("res://assets/audio/" + key + ".wav")
	return streams[key]

func sfx(key: String, pitch: float = 1.0) -> void:
	if not enabled: return
	for p in pool:
		if not p.playing:
			p.stream = get_clip(key)
			p.pitch_scale = pitch
			p.volume_db = -4
			p.play()
			return

func vocal(event: String, girl: bool, force: bool = false) -> void:
	if not enabled: return
	if not force and (cooldown > 0 or voice.playing): return
	var key:=choose_voice(event,girl)
	if key.is_empty(): return
	voice.pitch_scale = 1.0
	voice.volume_db = -2
	voice.stream = get_clip(key)
	voice.play()
	cooldown = 2.3

func choose_voice(event:String,girl:bool) -> String:
	var category: String=("girl" if girl else "boy")+"_"+event
	var candidates:Array=GirlVoices.GROUPS.get(event,[]) if girl else BoyVoices.GROUPS.get(event,[])
	if candidates.is_empty(): return ""
	var previous:String=last_voice_by_category.get(category,"")
	var choices:Array=candidates.filter(func(value): return value!=previous and value!=last_voice)
	var key:String=(choices if not choices.is_empty() else candidates).pick_random()
	last_voice = key
	last_voice_by_category[category]=key
	return key

func star_pickup(amount:int,mega:bool=false) -> void:
	pickup_chain=0 if pickup_gap>.65 else mini(pickup_chain+1,7)
	pickup_gap=0
	last_pickup_key="pickup_mega" if mega else "pickup_double" if amount>1 else "pickup_gold"
	if not enabled: return
	var player:=pickup_pool[pickup_cursor]; pickup_cursor=(pickup_cursor+1)%pickup_pool.size()
	player.stop(); player.stream=get_clip(last_pickup_key)
	player.pitch_scale=pow(2.,float([0,2,4,7,9,12,14,16][pickup_chain])/24.)
	player.volume_db=-8 if amount>1 else -10
	player.play()

func reset_pickups() -> void:
	pickup_gap=10; pickup_chain=0
	for player in pickup_pool: player.stop()

func advance(dt: float, music_active:bool=false) -> void:
	pickup_gap+=dt
	cooldown = maxf(0, cooldown - dt)
	var voice_bus:=AudioServer.get_bus_index("Voices")
	var audible:=enabled and voice.playing and voice.volume_db>-60 and voice_bus>=0
	if audible:
		audible=not AudioServer.is_bus_mute(voice_bus) and AudioServer.get_bus_volume_db(voice_bus)>-60
	music.advance(dt,music_active,enabled,audible)

func set_engine(active: bool) -> void:
	if not enabled: return
	engine.set_meta("active", active)
	if active and not engine.playing:
		engine.stream = get_clip("engine")
		engine.play()
	elif not active: engine.stop()

func set_paused(value: bool) -> void:
	for p in pool+pickup_pool: p.stream_paused = value
	voice.stream_paused = value
	engine.stream_paused = value
	music.set_paused(value)

func _exit_tree() -> void:
	if is_instance_valid(engine): engine.set_meta("active",false)
	for p in pool+pickup_pool+[voice,engine]:
		if is_instance_valid(p):
			p.stop()
			p.stream=null
	streams.clear()
