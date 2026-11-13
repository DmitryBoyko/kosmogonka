extends Node
## Both heroes: all user-supplied OGG takes; see docs/audio_sources.
const BoyVoices=preload("res://assets/audio/boy_voices.gd")
const GirlVoices=preload("res://assets/audio/girl_voices.gd")
const ActionSfx={"glove_extend":preload("res://assets/audio/glove_extend.wav"),"loop_jet":preload("res://assets/audio/loop_jet.wav"),"purchase_confirm":preload("res://assets/audio/purchase_confirm.wav"),"firework_burst":preload("res://assets/audio/firework_burst.wav")}
const AlienSfx=[preload("res://assets/audio/alien_chatter_0.wav"),preload("res://assets/audio/alien_chatter_1.wav"),preload("res://assets/audio/alien_chatter_2.wav")]
var alien_voice:AudioStreamPlayer3D
var alien_cooldown:=3.
var important_sfx_wait:=0.
var alien_serial:=0
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
var loop_engine:AudioStreamPlayer
var last_sfx:=""
var sfx_serial:=0
var action_counts:Dictionary={}

func _ready() -> void:
	alien_voice=AudioStreamPlayer3D.new();alien_voice.bus="Effects";alien_voice.volume_db=-12.;alien_voice.unit_size=6.;alien_voice.max_distance=24.;add_child(alien_voice)
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
	loop_engine=AudioStreamPlayer.new(); loop_engine.bus="Effects"; loop_engine.volume_db=-11.; add_child(loop_engine)
	var jet:AudioStreamWAV=ActionSfx.loop_jet
	jet.loop_mode=AudioStreamWAV.LOOP_FORWARD; jet.loop_begin=0; jet.loop_end=roundi(jet.get_length()*jet.mix_rate)
	loop_engine.stream=jet
func get_clip(key: String) -> AudioStream:
	if key=="field_hum": return preload("res://assets/audio/field_hum.wav")
	if ActionSfx.has(key): return ActionSfx[key]
	if BoyVoices.CLIPS.has(key): return BoyVoices.CLIPS[key]
	if GirlVoices.CLIPS.has(key): return GirlVoices.CLIPS[key]
	if not streams.has(key): streams[key] = load("res://assets/audio/" + key + ".wav")
	return streams[key]

func sfx(key: String, pitch: float = 1.0) -> void:
	if key in ["warning","glove_extend","hit","win","purchase_confirm"]: important_sfx_wait=1.3
	last_sfx=key; sfx_serial+=1
	if ActionSfx.has(key): action_counts[key]=int(action_counts.get(key,0))+1
	if not enabled: return
	for p in pool:
		if not p.playing:
			p.stream = get_clip(key)
			p.pitch_scale = pitch
			p.volume_db = -14 if key=="field_hum" else -10 if key=="firework_burst" else -4
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

func advance(dt: float, music_active:bool=false,alien_world:bool=false) -> void:
	pickup_gap+=dt
	alien_cooldown=maxf(0.,alien_cooldown-dt);important_sfx_wait=maxf(0.,important_sfx_wait-dt)
	if not alien_world and alien_voice.playing: alien_voice.stop()
	cooldown = maxf(0, cooldown - dt)
	var voice_bus:=AudioServer.get_bus_index("Voices")
	var audible:=enabled and voice.playing and voice.volume_db>-60 and voice_bus>=0
	if audible:
		audible=not AudioServer.is_bus_mute(voice_bus) and AudioServer.get_bus_volume_db(voice_bus)>-60
	music.advance(dt,music_active,enabled,audible)

func try_alien(at:Vector3,variant:int=0) -> bool:
	if alien_cooldown>0. or important_sfx_wait>0. or voice.playing or alien_voice.playing: return false
	var index:=posmod(variant+alien_serial,AlienSfx.size());alien_serial+=1
	alien_cooldown=7.+posmod(alien_serial*37,50)*.1
	last_sfx="alien_chatter_"+str(index);sfx_serial+=1;action_counts[last_sfx]=int(action_counts.get(last_sfx,0))+1
	if enabled:
		alien_voice.global_position=at;alien_voice.stream=AlienSfx[index];alien_voice.pitch_scale=.93+posmod(variant,5)*.035;alien_voice.play()
	return true

func set_engine(active: bool) -> void:
	if not active: set_loop_jet(false)
	if not enabled: return
	engine.set_meta("active", active)
	if active and not engine.playing:
		engine.stream = get_clip("engine")
		engine.play()
	elif not active: engine.stop()

func set_loop_jet(active:bool,progress:float=0.) -> void:
	loop_engine.set_meta("active",active)
	engine.volume_db=-22. if active else -14.
	if not active: loop_engine.stop(); return
	loop_engine.pitch_scale=.94+.16*sin(clampf(progress,0,1)*PI)
	if enabled and not loop_engine.playing: loop_engine.play()

func set_paused(value: bool) -> void:
	for p in pool+pickup_pool: p.stream_paused = value
	voice.stream_paused = value
	engine.stream_paused = value
	loop_engine.stream_paused = value
	alien_voice.stream_paused = value
	music.set_paused(value)

func _exit_tree() -> void:
	if is_instance_valid(engine): engine.set_meta("active",false)
	for p in pool+pickup_pool+[voice,engine,loop_engine,alien_voice]:
		if is_instance_valid(p):
			p.stop()
			p.stream=null
	streams.clear()
