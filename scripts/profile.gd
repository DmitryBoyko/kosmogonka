extends Node
const Suit = preload("res://scripts/suit.gd")
## ConfigFile + independent audio buses adapted from ArcadaLittleTruck/audio_settings.gd.
const Planets=preload("res://scripts/planets.gd")
const Course=preload("res://scripts/course.gd")
const Crew=preload("res://scripts/crew.gd")
const PATH := "user://cosmorace.cfg"
const Gear=preload("res://scripts/gear_economy.gd")
var gear_owned:Dictionary={"suit":0,"pack":0,"board":0}
const Outfit=preload("res://scripts/outfit_catalog.gd")
var inventories:Dictionary={}
var wallets:Dictionary={}
const Boosters=preload("res://scripts/booster_catalog.gd")
var charges:Dictionary={}
var booster_training:Dictionary={}
const HEART_PRICE:=150
const HEART_LIMIT:=3
const LOSSES_PER_BOOSTER_PHASE := 3
var reserve_hearts:Dictionary={}
var retry_points:Dictionary={}
var booster_loss_cycles: Dictionary = {}
var owned_items:Array[String]:
	get:
		var key:=str(hero)
		if not inventories.has(key):
			var empty:Array[String]=[]; inventories[key]=empty
		return inventories[key]
	set(value): inventories[str(hero)]=value
var outfits:Array=[{},{}]
var persistence_enabled:=true
var hero := 0
var best := 0
var completed := false
var unlocked := 0
var selected_planet := 0
var records:Array=[0,0,0,0,0,0,0,0,0,0,0]
var star_records:Array=[0,0,0,0,0,0,0,0,0,0,0]
var cleared_planets: Array[int] = []
var suits: Array = [{},{}]
var bank:int:
	get: return int(wallets.get(str(hero),0))
	set(value): wallets[str(hero)]=maxi(0,value)
var trip_serial := 0
var hero_payments:Dictionary={}
var hero_trips:Dictionary={}
var last_trip_paid:int:
	get: return int(hero_payments.get(str(hero),0))
	set(value): hero_payments[str(hero)]=value
var pending_trip:Dictionary:
	get: return hero_trips.get(str(hero),{})
	set(value):
		if value.is_empty(): hero_trips.erase(str(hero))
		else: hero_trips[str(value.get("hero",hero))]=value
var flown_routes: Array = []
var reduced_motion := false
var vibration := true
var quality := true
var first_person := false
var volumes := {"Master": 0.8, "Music": 0.65, "Effects": 0.75, "Voices": 0.8}

func _ready() -> void:
	for bus in ["Music", "Effects", "Voices"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		hero = clampi(int(cfg.get_value("game", "hero", 0)), 0, Crew.MODELS.size()-1)
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
		var saved_clears: Variant = cfg.get_value("campaign","cleared_planets",null)
		if saved_clears is Array:
			for world in saved_clears:
				if world is int and world>=0 and world<Planets.count() and not cleared_planets.has(world):
					cleared_planets.append(world)
		else:
			for world in Planets.count():
				if records[world]-25*star_records[world]>=int(Course.length_for(world))+1000:
					cleared_planets.append(world)
			if completed and not cleared_planets.has(0): cleared_planets.append(0)
		var saved_suits = cfg.get_value("appearance","suits",[{},{}])
		if saved_suits is Array:
			for i in mini(saved_suits.size(),Crew.MODELS.size()):
				while suits.size()<=i: suits.append({})
				if saved_suits[i] is Dictionary: suits[i]=Suit.normalize(saved_suits[i],Crew.is_female(i))
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
		first_person = bool(cfg.get_value("view", "first_person", false))
		for bus in volumes:
			volumes[bus] = clampf(float(cfg.get_value("audio", bus, volumes[bus])), 0, 1)
	var raw_items=cfg.get_value("equipment","items",[])
	if raw_items is Array:
		for id in raw_items:
			if Outfit.all().has(str(id)) and not owned_items.has(str(id)): owned_items.append(str(id))
	if int(cfg.get_value("equipment","catalog_version",0))<2:
		var migrated:=Outfit.legacy(gear_owned); outfits=[migrated.duplicate(),migrated.duplicate()]
		for id:String in migrated.values():
			if not owned_items.has(id): owned_items.append(id)
	else:
		var saved_outfits=cfg.get_value("equipment","outfits",[{},{}])
		if saved_outfits is Array:
			for i in mini(saved_outfits.size(),Crew.MODELS.size()):
				while outfits.size()<=i: outfits.append({})
				if saved_outfits[i] is Dictionary: outfits[i]=Outfit.normalized(saved_outfits[i],owned_items) if not owned_items.is_empty() else {}
	if int(cfg.get_value("heroes","version",0))>=1:
		wallets.clear(); inventories.clear()
		var saved_wallets=cfg.get_value("heroes","wallets",{})
		var saved_inventories=cfg.get_value("heroes","inventories",{})
		if saved_wallets is Dictionary:
			for key in saved_wallets: wallets[str(key)]=maxi(0,int(saved_wallets[key]))
		if saved_inventories is Dictionary:
			for key in saved_inventories:
				var valid:Array[String]=[]
				if saved_inventories[key] is Array:
					for id in saved_inventories[key]:
						if Outfit.all().has(str(id)) and not valid.has(str(id)): valid.append(str(id))
				inventories[str(key)]=valid
		var raw_outfits=cfg.get_value("equipment","outfits",[{},{}])
		if raw_outfits is Array:
			outfits=[]
			for i in raw_outfits.size():
				var inventory:Array=inventories.get(str(i),[])
				outfits.append(Outfit.normalized(raw_outfits[i],inventory) if raw_outfits[i] is Dictionary and not inventory.is_empty() else {})
	else:
		# Preserve previously shared purchases on migration, then keep independent copies.
		var inherited:Array[String]=owned_items.duplicate()
		for i in 2: inventories[str(i)]=inherited.duplicate()
	while outfits.size()<Crew.MODELS.size(): outfits.append({})
	while suits.size()<Crew.MODELS.size(): suits.append({})
	var saved_trips=cfg.get_value("heroes","trips",hero_trips)
	if saved_trips is Dictionary: hero_trips=saved_trips
	var saved_payments=cfg.get_value("heroes","payments",hero_payments)
	if saved_payments is Dictionary: hero_payments=saved_payments
	apply_audio()
	load_charge_state(cfg)

func load_charge_state(cfg:ConfigFile) -> void:
	charges.clear(); booster_training.clear()
	reserve_hearts.clear()
	var retries=cfg.get_value("heroes","retry_points",{})
	retry_points=retries if retries is Dictionary else {}
	var cycles = cfg.get_value("heroes","booster_loss_cycles",{})
	booster_loss_cycles = cycles if cycles is Dictionary else {}
	var hearts=cfg.get_value("heroes","reserve_hearts",{})
	if hearts is Dictionary:
		for key in hearts:reserve_hearts[str(key)]=clampi(int(hearts[key]),0,HEART_LIMIT)
	var saved_charges=cfg.get_value("heroes","charges",{})
	if saved_charges is Dictionary:
		for key in saved_charges:
			if saved_charges[key] is Dictionary:
				charges[str(key)]={}
				for kind:String in Boosters.KINDS: charges[str(key)][kind]=clampi(int(saved_charges[key].get(kind,0)),0,Boosters.LIMIT)
	var saved_training=cfg.get_value("heroes","booster_training",{})
	if saved_training is Dictionary: booster_training=saved_training

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
	cfg.set_value("campaign","cleared_planets",cleared_planets)
	cfg.set_value("appearance","suits",suits)
	cfg.set_value("campaign","bank",bank)
	cfg.set_value("equipment","owned",gear_owned)
	cfg.set_value("equipment","catalog_version",2)
	cfg.set_value("equipment","items",owned_items)
	cfg.set_value("equipment","outfits",outfits)
	cfg.set_value("heroes","version",1)
	cfg.set_value("heroes","wallets",wallets)
	cfg.set_value("heroes","charges",charges)
	cfg.set_value("heroes","reserve_hearts",reserve_hearts)
	cfg.set_value("heroes","retry_points",retry_points)
	cfg.set_value("heroes","booster_loss_cycles",booster_loss_cycles)
	cfg.set_value("heroes","booster_training",booster_training)
	cfg.set_value("heroes","inventories",inventories)
	cfg.set_value("heroes","trips",hero_trips)
	cfg.set_value("heroes","payments",hero_payments)
	cfg.set_value("campaign","trip_serial",trip_serial)
	cfg.set_value("campaign","last_trip_paid",last_trip_paid)
	cfg.set_value("campaign","pending_trip",pending_trip)
	cfg.set_value("campaign","flown_routes",flown_routes)
	cfg.set_value("view", "reduced_motion", reduced_motion)
	cfg.set_value("view", "vibration", vibration)
	cfg.set_value("view", "quality", quality)
	cfg.set_value("view", "first_person", first_person)
	for bus in volumes:
		cfg.set_value("audio", bus, volumes[bus])
	return cfg.save(path)

func current_outfit() -> Dictionary:
	while outfits.size()<=hero: outfits.append({})
	return outfits[hero]

func charge_count(kind:String) -> int:
	return int(charges.get(str(hero),{}).get(kind,0))

func record_booster_loss(run_hero: int, world: int) -> void:
	var key := "%d:%d" % [run_hero,world]
	booster_loss_cycles[key] = (int(booster_loss_cycles.get(key,0))+1)%(LOSSES_PER_BOOSTER_PHASE*2)

func booster_stars_enabled(run_hero: int, world: int) -> bool:
	return int(booster_loss_cycles.get("%d:%d" % [run_hero,world],0))>=LOSSES_PER_BOOSTER_PHASE

func heart_count() -> int:return int(reserve_hearts.get(str(hero),0))

func consume_heart() -> bool:
	if heart_count()<=0:return false
	var before:Dictionary=reserve_hearts.duplicate()
	reserve_hearts[str(hero)]=heart_count()-1
	if save()!=OK:reserve_hearts=before;return false
	return true

func buy_heart(world:int) -> Dictionary:
	if world<0 or world>unlocked:return {"ok":false,"message":"Магазин недоступен"}
	if heart_count()>=HEART_LIMIT:return {"ok":false,"message":"Запас полон: 3 сердца"}
	if bank<HEART_PRICE:return {"ok":false,"message":"Не хватает %d ★"%[HEART_PRICE-bank]}
	var before:Dictionary=reserve_hearts.duplicate();var old_bank:=bank
	reserve_hearts[str(hero)]=heart_count()+1;bank-=HEART_PRICE
	if save()!=OK:
		reserve_hearts=before;bank=old_bank;return {"ok":false,"message":"Покупка не сохранена"}
	return {"ok":true,"message":"Запасное сердце куплено · %d / 3"%heart_count()}

func debug_unlock() -> bool:
	var before_bank:=bank;var before_unlocked:=unlocked
	bank+=1000000;unlocked=Planets.count()-1
	if save()!=OK: bank=before_bank;unlocked=before_unlocked;return false
	return true

func change_charge(kind:String,delta:int) -> bool:
	if not Boosters.KINDS.has(kind): return false
	var count:=charge_count(kind)
	if count+delta<0 or count+delta>Boosters.LIMIT: return false
	var before:Dictionary=charges.duplicate(true)
	if not charges.has(str(hero)): charges[str(hero)]={}
	charges[str(hero)][kind]=count+delta
	if save()!=OK: charges=before; return false
	return true

func buy_charge(kind:String,world:int) -> Dictionary:
	if not Boosters.KINDS.has(kind) or world<0 or world>unlocked: return {"ok":false,"message":"Магазин недоступен"}
	if charge_count(kind)>=Boosters.LIMIT: return {"ok":false,"message":"Запас полон: 9 зарядов"}
	var cost:int=Boosters.PRICES[kind]
	if bank<cost: return {"ok":false,"message":"Не хватает %d ★"%[cost-bank]}
	var before:=bank; bank-=cost
	if not change_charge(kind,1): bank=before; return {"ok":false,"message":"Покупка не сохранена"}
	return {"ok":true,"message":"Заряд добавлен в запас · %d / 9"%charge_count(kind)}

func grant_booster_training() -> bool:
	if booster_training.has(str(hero)): return false
	var before:Dictionary=charges.duplicate(true)
	booster_training[str(hero)]=true
	charges[str(hero)]={"jet":maxi(1,charge_count("jet")),"board":maxi(1,charge_count("board"))}
	if save()!=OK: charges=before; booster_training.erase(str(hero)); return false
	return true
func credit(amount:int,owner_hero:int) -> void:
	var key:=str(owner_hero); wallets[key]=maxi(0,int(wallets.get(key,0))+amount)
func buy_item(id:String,world:int) -> Dictionary:
	var item:=Outfit.get_item(id)
	if item.is_empty(): return {"ok":false,"message":"Товар не найден"}
	if owned_items.has(id): return {"ok":false,"message":"Уже куплено"}
	if item.world!=world or world>unlocked: return {"ok":false,"message":"Продаётся на планете "+Planets.get_data(item.world).name}
	if bank<item.price: return {"ok":false,"message":"Не хватает %d ★"%[item.price-bank]}
	var old_bank:=bank; bank-=int(item.price); owned_items.append(id)
	if save()!=OK:
		bank=old_bank; owned_items.erase(id); return {"ok":false,"message":"Покупка не сохранена"}
	return {"ok":true,"message":"Куплено! Можно надеть или оставить в гардеробе"}

func wear_item(id:String) -> bool:
	var item:=Outfit.get_item(id)
	if item.is_empty() or not owned_items.has(id): return false
	current_outfit()
	var before:Dictionary=outfits[hero].duplicate(); outfits[hero][item.group]=id
	if save()!=OK: outfits[hero]=before; return false
	return true

func remove_item(group:String) -> bool:
	if not Outfit.GROUPS.has(group): return false
	current_outfit()
	var before:Dictionary=outfits[hero].duplicate(); outfits[hero].erase(group)
	if save()!=OK: outfits[hero]=before; return false
	return true

func buy_gear(category:String,tier:int) -> Dictionary:
	if not Gear.CATEGORIES.has(category) or tier!=int(gear_owned[category])+1 or tier>5: return {"ok":false,"message":"Этот контейнер уже открыт или недоступен"}
	if unlocked<Gear.required_world(tier): return {"ok":false,"message":"Сначала открой планету %d"%[Gear.required_world(tier)+1]}
	var cost:=Gear.price(category,tier)
	if bank<cost: return {"ok":false,"message":"Нужно ещё %d ★"%[cost-bank]}
	var old_bank:=bank; var old_suits:Array=suits.duplicate(true); bank-=cost; gear_owned[category]=tier
	if category=="suit":
		var slots:Dictionary={}
		for slot in Suit.SLOTS: slots[slot]="equipment_t%d"%tier
		suits[hero]=Suit.normalize({"version":1,"slots":slots},Crew.is_female(hero))
	if save()!=OK:
		bank=old_bank; gear_owned[category]=tier-1; suits=old_suits
		return {"ok":false,"message":"Не удалось сохранить покупку"}
	return {"ok":true,"message":"Открыто: "+Gear.NAMES[category][tier-1],"category":category,"tier":tier}
