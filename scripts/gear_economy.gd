extends RefCounted
const CATEGORIES=["suit","pack","board"]
const TITLES={"suit":"Скафандры","pack":"Ранцы","board":"Платформы"}
const PRICES={"suit":[450,800,1300,1950,2750],"pack":[550,950,1500,2200,3050],"board":[500,875,1400,2050,2900]}
const NAMES={"suit":["Контур разведчика","Панцирь пилота","Спектральный страж","Керамический бастион","Скафандр Сингулярности"],"pack":["Ионный резерв","Векторный ранец","Аварийный ореол","Дальний импульс","Ранец горизонта"],"board":["Струна скольжения","Двойной киль","Магнитный серфер","Тройной стабилизатор","Платформа последнего рубежа"]}
static func normalized(raw:Dictionary) -> Dictionary:
	var result:Dictionary={}
	for category in CATEGORIES: result[category]=clampi(int(raw.get(category,0)),0,5)
	return result
static func price(category:String,tier:int) -> int:
	return int(PRICES[category][tier-1]) if PRICES.has(category) and tier>=1 and tier<=5 else -1
static func required_world(tier:int) -> int: return maxi(0,(tier-1)*2)
static func recommended(planet:int) -> int: return mini(5,int((planet+1)/2))
static func stats(raw:Dictionary) -> Dictionary:
	var levels:=normalized(raw); var suit:int=levels.suit; var pack:int=levels.pack; var board:int=levels.board
	return {"magnet":suit*.10,"tempo":1.-suit*.03,"shields":int((suit+1)/2),"jet_seconds":8.+pack*.8,"lane_speed":13.+pack*.5,"rescues":2 if pack==5 else 1 if pack>=3 else 0,"board_seconds":10.+board,"board_armor":1+int(board/2),"board_magnet":board*.08}
static func feature(category:String,tier:int) -> String:
	var levels:=normalized({}); levels[category]=tier; var s:=stats(levels)
	match category:
		"suit": return "Щит: %d · сбор +%.1f м · реакция +%d%%"%[s.shields,s.magnet,tier*3]
		"pack": return "Полёт %.1f с · манёвр %.1f · спасения %d"%[s.jet_seconds,s.lane_speed,s.rescues]
		_: return "Работа %.0f с · прочность %d · магнит +%.1f м"%[s.board_seconds,s.board_armor,s.board_magnet]
static func total_cost() -> int:
	var total:=0
	for category in CATEGORIES:
		for cost:int in PRICES[category]: total+=cost
	return total
