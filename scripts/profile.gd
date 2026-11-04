extends Node
const Suit = preload("res://scripts/suit.gd")
## ConfigFile + independent audio buses adapted from ArcadaLittleTruck/audio_settings.gd.
const Planets=preload("res://scripts/planets.gd")
const PATH := "user://cosmorace.cfg"
const Gear=preload("res://scripts/gear_economy.gd")
var gear_owned:Dictionary={"suit":0,"pack":0,"board":0}
var persistence_enabled:=true
var hero := 0
var best := 0
var completed := false
var unlocked := 0
var selected_planet := 0
var records:Array=[0,0,0,0,0,0,0,0,0,0]
var star_records:Array=[0,0,0,0,0,0,0,0,0,0]
var suits: Array = [{},{}]
var bank := 0
var trip_serial := 0
var last_trip_paid := 0
var pending_trip: Dictionary = {}
var flown_routes: Array = []
var reduced_motion := false
var vibration := true
var quality := true
var volumes := {"Master": 0.8, "Music": 0.65, "Effects": 0.75, "Voices": 0.8}

func _ready() -> void:
	for bus in ["Music", "Effects", "Voices"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		hero = clampi(int(cfg.get_value("game", "hero", 0)), 0, 1)
		best = maxi(0, int(cfg.get_value("game", "best", 0)))
		completed = bool(cfg.get_value("game", "completed", false))
		unlocked = clampi(int(cfg.get_value("campaign","unlocked",1 if completed else 0)),0,Planets.count()-1)
		selected_planet = clampi(int(cfg.get_value("campaign","selected",0)),0,unlocked)
		records = cfg.get_value("campaign","records",[best,0,0,0])
		records.resize(Planets.count())
		for i in records.size(): records[i]=int(records[i]) if records[i]!=null else 0
		star_records = cfg.get_value("campaign","star_records",[0,0,0,0])
		star_records.resize(Planets.count())
		for i in star_records.size(): star_records[i]=int(star_records[i]) if star_records[i]!=null else 0
		var saved_suits = cfg.get_value("appearance","suits",[{},{}])
		if saved_suits is Array and saved_suits.size()==2:
			for i in 2:
				if saved_suits[i] is Dictionary: suits[i]=Suit.normalize(saved_suits[i],i==1)
		bank = maxi(0,int(cfg.get_value("campaign","bank",0)))
		var saved_gear=cfg.get_value("equipment","owned",{})
		gear_owned=Gear.normalized(saved_gear if saved_gear is Dictionary else {})
		trip_serial = int(cfg.get_value("campaign","trip_serial",0))
		last_trip_paid = int(cfg.get_value("campaign","last_trip_paid",0))
		pending_trip = cfg.get_value("campaign","pending_trip",{})
		flown_routes = cfg.get_value("campaign","flown_routes",[])
		reduced_motion = bool(cfg.get_value("view", "reduced_motion", false))
		vibration = bool(cfg.get_value("view", "vibration", true))
		quality = bool(cfg.get_value("view", "quality", true))
		for bus in volumes:
			volumes[bus] = clampf(float(cfg.get_value("audio", bus, volumes[bus])), 0, 1)
	apply_audio()

func apply_audio() -> void:
	for bus in volumes:
		var index := AudioServer.get_bus_index(bus)
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(0.0001, volumes[bus])))
		AudioServer.set_bus_mute(index, volumes[bus] < 0.001)

func save(path: String = PATH) -> int:
	if not persistence_enabled and path==PATH: return OK
	var cfg := ConfigFile.new()
	cfg.set_value("game", "hero", hero)
	cfg.set_value("game", "best", best)
	cfg.set_value("game", "completed", completed)
	cfg.set_value("campaign","unlocked",unlocked)
	cfg.set_value("campaign","selected",selected_planet)
	cfg.set_value("campaign","records",records)
	cfg.set_value("campaign","star_records",star_records)
	cfg.set_value("appearance","suits",suits)
	cfg.set_value("campaign","bank",bank)
	cfg.set_value("equipment","owned",gear_owned)
	cfg.set_value("campaign","trip_serial",trip_serial)
	cfg.set_value("campaign","last_trip_paid",last_trip_paid)
	cfg.set_value("campaign","pending_trip",pending_trip)
	cfg.set_value("campaign","flown_routes",flown_routes)
	cfg.set_value("view", "reduced_motion", reduced_motion)
	cfg.set_value("view", "vibration", vibration)
	cfg.set_value("view", "quality", quality)
	for bus in volumes:
		cfg.set_value("audio", bus, volumes[bus])
	return cfg.save(path)

func buy_gear(category:String,tier:int) -> Dictionary:
	if not Gear.CATEGORIES.has(category) or tier!=int(gear_owned[category])+1 or tier>5: return {"ok":false,"message":"Этот контейнер уже открыт или недоступен"}
	if unlocked<Gear.required_world(tier): return {"ok":false,"message":"Сначала открой планету %d"%[Gear.required_world(tier)+1]}
	var cost:=Gear.price(category,tier)
	if bank<cost: return {"ok":false,"message":"Нужно ещё %d ★"%[cost-bank]}
	var old_bank:=bank; var old_suits:Array=suits.duplicate(true); bank-=cost; gear_owned[category]=tier
	if category=="suit":
		var slots:Dictionary={}
		for slot in Suit.SLOTS: slots[slot]="equipment_t%d"%tier
		suits[hero]=Suit.normalize({"version":1,"slots":slots},hero==1)
	if save()!=OK:
		bank=old_bank; gear_owned[category]=tier-1; suits=old_suits
		return {"ok":false,"message":"Не удалось сохранить покупку"}
	return {"ok":true,"message":"Открыто: "+Gear.NAMES[category][tier-1],"category":category,"tier":tier}
