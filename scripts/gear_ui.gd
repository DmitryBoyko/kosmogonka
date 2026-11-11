extends RefCounted
const Economy=preload("res://scripts/gear_economy.gd")
const Suit=preload("res://scripts/suit.gd")
const SLOT_NAMES={"torso":"Корпус","left_arm":"Левая рука","right_arm":"Правая рука","left_glove":"Левая перчатка","right_glove":"Правая перчатка","left_leg":"Левая нога","right_leg":"Правая нога","left_boot":"Левый ботинок","right_boot":"Правый ботинок","helmet":"Шлем","backpack":"Ранец"}
static func shop(ui:Node,category:String,profile:Node,message:String="") -> void:
	ui.clear_screen("shop")
	ui.text(ui.screen,Economy.TITLES[category],34,48,55).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	ui.text(ui.screen,"БАЛАНС  %d ★"%profile.bank,23,108,38,30,480,Color("ffe3a0")).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var level:int=profile.gear_owned[category]
	var owned_text:String="Базовая экипировка" if level==0 else Economy.NAMES[category][level-1]+"\n"+Economy.feature(category,level)
	var description:Label=ui.text(ui.screen,owned_text,17,157,75,36,468); description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; description.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	ui.panel(ui.screen,602,254)
	var default_status:String="Коллекция этого магазина собрана" if level==5 else "Новая экипировка — сюрприз"
	var status:Label=ui.text(ui.screen,message if not message.is_empty() else default_status,21,620,57,50,440,Color("bce5ef")); status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	if level<5:
		var tier:=level+1; var price:=Economy.price(category,tier)
		ui.text(ui.screen,"КОНТЕЙНЕР ?  /  КЛАСС %d"%tier,18,687,32,50,440)
		var buy:Button=ui.button(ui.screen,"Открыть за %d ★"%price,"buy_"+category+"_"+str(tier),742,true,48,444,66)
		buy.disabled=profile.bank<price or profile.unlocked<Economy.required_world(tier)
		if profile.unlocked<Economy.required_world(tier): ui.text(ui.screen,"Нужна планета %d"%[Economy.required_world(tier)+1],14,815,28,50,440)
		elif profile.bank<price: ui.text(ui.screen,"Осталось накопить %d ★"%[price-profile.bank],14,815,28,50,440)
	else: ui.text(ui.screen,"ЛУЧШИЙ КЛАСС УЖЕ СОБРАН",22,722,60,50,440,Color("ffe3a0"))
	ui.button(ui.screen,"Конструктор","builder",882,false,38,260,50)
	ui.button(ui.screen,"Закрыть","close_gear",882,false,318,184,50)

static func list_area(ui:Node) -> Control:
	ui.panel(ui.screen,550,320)
	var scroll:=ScrollContainer.new(); ui.screen.add_child(scroll); scroll.position=Vector2(38,566); scroll.size=Vector2(464,280)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; scroll.follow_focus=true
	var list:=Control.new(); list.custom_minimum_size=Vector2(444,1); scroll.add_child(list); return list

static func builder(ui:Node,profile:Node) -> void:
	ui.clear_screen("builder")
	ui.text(ui.screen,"Конструктор скафандра",30,52,55).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	ui.text(ui.screen,"Скафандр %d · ранец %d · платформа %d"%[profile.gear_owned.suit,profile.gear_owned.pack,profile.gear_owned.board],18,112,50).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	ui.text(ui.screen,"Выбери деталь. Доступны открытые материалы.",16,176,45).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var list:=list_area(ui); list.custom_minimum_size.y=Suit.SLOTS.size()*62
	var loadout:Dictionary=Suit.normalize(profile.suits[profile.hero],preload("res://scripts/crew.gd").is_female(profile.hero))
	for i in Suit.SLOTS.size():
		var slot:String=Suit.SLOTS[i]; var skin:Resource=Suit.catalog()[loadout.slots[slot]]
		var button:Button=ui.button(list,SLOT_NAMES[slot]+" · "+skin.display_name,"slot_"+slot,i*62,false,0,444,54)
		button.add_theme_font_size_override("font_size",18)
	ui.button(ui.screen,"Готово","close_gear",892,true,48,444,50)

static func allowed_skins(profile:Node) -> Array[String]:
	var result:Array[String]=["explorer_mint","explorer_rose"]
	for tier in range(1,int(profile.gear_owned.suit)+1): result.append("equipment_t%d"%tier)
	var saved:Dictionary=Suit.normalize(profile.suits[profile.hero],preload("res://scripts/crew.gd").is_female(profile.hero))
	if saved.slots.values().has("solar_rescue"): result.append("solar_rescue")
	return result

static func skins(ui:Node,profile:Node,slot:String) -> void:
	ui.clear_screen("skin_picker")
	ui.text(ui.screen,SLOT_NAMES[slot],33,52,55).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	ui.text(ui.screen,"Материалы открываются в магазине скафандров",16,114,65).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var list:=list_area(ui); var ids:=allowed_skins(profile); list.custom_minimum_size.y=ids.size()*66
	var current:Dictionary=Suit.normalize(profile.suits[profile.hero],preload("res://scripts/crew.gd").is_female(profile.hero))
	for i in ids.size(): ui.button(list,Suit.catalog()[ids[i]].display_name,"skin_"+ids[i],i*66,current.slots[slot]==ids[i],0,444,56)
	ui.button(ui.screen,"К деталям","builder",892,true,48,444,50)
