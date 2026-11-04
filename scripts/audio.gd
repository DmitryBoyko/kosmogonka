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

func _ready() -> void:
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

func advance(dt: float, music_active:bool=false) -> void:
	cooldown = maxf(0, cooldown - dt)
	music.advance(dt,music_active,enabled)

func set_engine(active: bool) -> void:
	if not enabled: return
	engine.set_meta("active", active)
	if active and not engine.playing:
		engine.stream = get_clip("engine")
		engine.play()
	elif not active: engine.stop()

func set_paused(value: bool) -> void:
	for p in pool: p.stream_paused = value
	voice.stream_paused = value
	engine.stream_paused = value
	music.set_paused(value)

func _exit_tree() -> void:
	if is_instance_valid(engine): engine.set_meta("active",false)
	for p in pool+[voice,engine]:
		if is_instance_valid(p):
			p.stop()
			p.stream=null
	streams.clear()
