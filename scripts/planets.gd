extends RefCounted
const DATA := [
	{"name": "Аврора", "subtitle": "Кристальные сады", "sky": "49418c", "horizon": "b7b7e5", "ocean": Color(0.1,0.55,0.66), "land": Color(0.55,0.3,0.78), "accent": "80f5dc", "regions": ["КРИСТАЛЬНЫЕ САДЫ", "КОСМИЧЕСКИЙ ПОСТ", "НЕОНОВЫЙ КВАРТАЛ"], "palette": {}},
	{"name": "Флора", "subtitle": "Планета живых садов", "sky": "387e92", "horizon": "c8f5d6", "ocean": Color(0.12,0.6,0.43), "land": Color(0.9,0.4,0.59), "accent": "a0ffd5", "regions": ["МЯТНАЯ РОЩА", "САДОВАЯ СТАНЦИЯ", "КОСМОДРОМ-ЦВЕТОК"], "palette": {"7061a6":"6caf9a", "35365b":"396568", "373b69":"365c67", "927ccd":"8acbb0", "9881c7":"85baac", "7d7db7":"81b29c", "bf80ee":"ffb4b0", "57dace":"b0f1bb", "cf73c6":"ff9ba8", "4bd0ba":"72e3b2", "625087":"5c8490"}},
	{"name": "Янтарь", "subtitle": "Караваны среди дюн", "sky": "9474ae", "horizon": "f9c7ac", "ocean": Color(0.83,0.44,0.26), "land": Color(1.0,0.7,0.39), "accent": "ffe2a4", "regions": ["АБРИКОСОВЫЕ ДЮНЫ", "ГРУЗОВОЙ КАРАВАН", "ПЕСЧАНЫЕ АРКИ"], "palette": {"7061a6":"d6a17d", "35365b":"5e526a", "373b69":"655172", "927ccd":"e4b49a", "9881c7":"b487a7", "7d7db7":"ac7b9f", "bf80ee":"e5b87c", "57dace":"77d6df", "e2c9eb":"80cfda", "625087":"937394", "cf73c6":"d9bb87", "4bd0ba":"84d6ce"}},
	{"name": "Неон", "subtitle": "Биолюминесцентный мир", "sky": "121d4b", "horizon": "6c659d", "ocean": Color(0.08,0.18,0.4), "land": Color(0.57,0.22,0.67), "accent": "ff9de2", "regions": ["БИРЮЗОВЫЕ ДОКИ", "СВЕТОВЫЕ ГАЛЕРЕИ", "ОРБИТАЛЬНАЯ БАШНЯ"], "palette": {"7061a6":"333b6b", "35365b":"252b4b", "373b69":"26375b", "927ccd":"715caa", "9881c7":"50477c", "7d7db7":"444872", "625087":"3c416f", "d684bb":"f584cf", "a6d9df":"67f2e0", "e2c9eb":"8086ba"}},
	{"name":"Океания","subtitle":"Коралловый океан","sky":"287a99","horizon":"b6e5e5","ocean":Color("2d88a0"),"land":Color("3b9676"),"accent":"70e8ff","regions":["КОРАЛЛОВЫЕ РИФЫ","МОРСКИЕ ДОКИ","ОКЕАНИЧЕСКИЕ ПЛАТФОРМЫ"],"palette":{},"biome":1},
	{"name":"Гелиос","subtitle":"Солнечные саванны","sky":"aa735d","horizon":"f5d5a8","ocean":Color("b96f3d"),"land":Color("b9a15c"),"accent":"ffe77e","regions":["ЗОЛОТЫЕ ЛУГА","СОЛНЕЧНАЯ СТАНЦИЯ","ТЁПЛЫЕ УЩЕЛЬЯ"],"palette":{},"biome":2},
	{"name":"Мицелий","subtitle":"Леса гигантских спор","sky":"4a4968","horizon":"b1c6ae","ocean":Color("426a67"),"land":Color("738446"),"accent":"c8ff9b","regions":["ЛЕС СПОР","КОРНЕВЫЕ ПЕРЕХОДЫ","САДЫ МИЦЕЛИЯ"],"palette":{},"biome":1},
	{"name":"Криос","subtitle":"Ледяной мир","sky":"354e80","horizon":"d1eafa","ocean":Color("427fa7"),"land":Color("b7ced1"),"accent":"b8eaff","regions":["ЛЕДЯНЫЕ ПОЛЯ","ПОЛЯРНЫЕ ДОКИ","ИНЕЕВЫЕ ДОЛИНЫ"],"palette":{},"biome":0},
	{"name":"Вулкан","subtitle":"Лавовые моря","sky":"623d48","horizon":"d69d75","ocean":Color("77453e"),"land":Color("9e5b3b"),"accent":"ff9c63","regions":["ЛАВОВЫЕ ПОТОКИ","БАЗАЛЬТОВЫЕ ОСТРОВА","ОГНЕННЫЙ КАРАВАН"],"palette":{},"biome":2},
	{"name":"Сингулярность","subtitle":"Последний космодром","sky":"171c38","horizon":"77698f","ocean":Color("2a4269"),"land":Color("694785"),"accent":"f39bff","regions":["ГРАНИЦА СИГНАЛА","ПОЛОСА ХАОСА","ПОСЛЕДНИЙ РУБЕЖ"],"palette":{},"biome":3},
	{"name":"Зеркалия","subtitle":"Зеркальная планета","sky":"192b55","horizon":"b4b4dc","ocean":Color("67b9d1"),"land":Color("9f9acb"),"accent":"8ffff1","regions":["САД ОТРАЖЕНИЙ","ПАРАДОКСАЛЬНЫЙ ЭКСПРЕСС","ЗЕРКАЛЬНЫЙ ЛАБИРИНТ"],"palette":{},"biome":3}
]

static func get_data(index: int) -> Dictionary:
	var data:Dictionary=DATA[clampi(index,0,DATA.size()-1)]
	if index>=4 and data.palette.is_empty():
		var copy:Dictionary=data.duplicate(); copy.palette=DATA[int(data.biome)].palette
		return copy
	return data

static func route_name(source: int) -> String:
	return DATA[source].name + " → " + DATA[source + 1].name

static func destination(index: int) -> String:
	return ["Аврору","Флору","Янтарь","Неон","Океанию","Гелиос","Мицелий","Криос","Вулкан","Сингулярность","Зеркалию"][clampi(index,0,DATA.size()-1)]

static func biome(index:int) -> int:
	return int(get_data(index).get("biome",index%4))

static func count() -> int:
	return DATA.size()
