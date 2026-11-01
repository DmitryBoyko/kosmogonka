extends RefCounted
const DATA := [
	{"name": "Аврора", "subtitle": "Кристальные сады", "sky": "49418c", "horizon": "b7b7e5", "ocean": Color(0.1,0.55,0.66), "land": Color(0.55,0.3,0.78), "accent": "80f5dc", "regions": ["КРИСТАЛЬНЫЕ САДЫ", "КОСМИЧЕСКИЙ ПОСТ", "НЕОНОВЫЙ КВАРТАЛ"], "palette": {}},
	{"name": "Флора", "subtitle": "Планета живых садов", "sky": "387e92", "horizon": "c8f5d6", "ocean": Color(0.12,0.6,0.43), "land": Color(0.9,0.4,0.59), "accent": "a0ffd5", "regions": ["МЯТНАЯ РОЩА", "САДОВАЯ СТАНЦИЯ", "КОСМОДРОМ-ЦВЕТОК"], "palette": {"7061a6":"6caf9a", "35365b":"396568", "373b69":"365c67", "927ccd":"8acbb0", "9881c7":"85baac", "7d7db7":"81b29c", "bf80ee":"ffb4b0", "57dace":"b0f1bb", "cf73c6":"ff9ba8", "4bd0ba":"72e3b2", "625087":"5c8490"}},
	{"name": "Янтарь", "subtitle": "Караваны среди дюн", "sky": "9474ae", "horizon": "f9c7ac", "ocean": Color(0.83,0.44,0.26), "land": Color(1.0,0.7,0.39), "accent": "ffe2a4", "regions": ["АБРИКОСОВЫЕ ДЮНЫ", "ГРУЗОВОЙ КАРАВАН", "ПЕСЧАНЫЕ АРКИ"], "palette": {"7061a6":"d6a17d", "35365b":"5e526a", "373b69":"655172", "927ccd":"e4b49a", "9881c7":"b487a7", "7d7db7":"ac7b9f", "bf80ee":"e5b87c", "57dace":"77d6df", "e2c9eb":"80cfda", "625087":"937394", "cf73c6":"d9bb87", "4bd0ba":"84d6ce"}},
	{"name": "Неон", "subtitle": "Космический мегаполис", "sky": "121d4b", "horizon": "6c659d", "ocean": Color(0.08,0.18,0.4), "land": Color(0.57,0.22,0.67), "accent": "ff9de2", "regions": ["БИРЮЗОВЫЕ ДОКИ", "СВЕТОВЫЕ ГАЛЕРЕИ", "ОРБИТАЛЬНАЯ БАШНЯ"], "palette": {"7061a6":"333b6b", "35365b":"252b4b", "373b69":"26375b", "927ccd":"715caa", "9881c7":"50477c", "7d7db7":"444872", "625087":"3c416f", "d684bb":"f584cf", "a6d9df":"67f2e0", "e2c9eb":"8086ba"}}
]

static func get_data(index: int) -> Dictionary:
	return DATA[clampi(index, 0, DATA.size() - 1)]

static func route_name(source: int) -> String:
	return DATA[source].name + " → " + DATA[source + 1].name

static func destination(index: int) -> String:
	return ["Аврору","Флору","Янтарь","Неон"][clampi(index,0,3)]
