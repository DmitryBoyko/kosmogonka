extends RefCounted

const VETRA := 11
const LUMA := 12
const FAMILIES := [
	[7, "wind", "Парящие острова", "ВЕТРОВЫЕ АРКИ", "ПОДВЕСНЫЕ ДОКИ", "БАШНЯ-ФЛЮГЕР", "72efcf",
		[["Борей","Борей"],["Аэрон","Аэрон"],["Вента","Венту"],["Зефир","Зефир"],["Аэрис","Аэрис"]]],
	[6, "pulse", "Светящиеся споровые леса", "САД СИГНАЛОВ", "СПОРОВЫЕ ГАЛЕРЕИ", "ГРИБНОЙ КОСМОДРОМ", "deabff",
		[["Люмар","Люмар"],["Микора","Микору"],["Искра","Искру"],["Спория","Спорию"],["Люцента","Люценту"]]],
	[4, "wind", "Коралловые отмели", "РИФЫ", "ВЫСОКИЕ НАСТИЛЫ", "ЛАГУННЫЙ МАЯК", "76e7ff",
		[["Таласса","Талассу"],["Лагуна","Лагуну"],["Нерис","Нерис"],["Коралия","Коралию"],["Марея","Марею"]]],
	[8, "pulse", "Грозовые ущелья", "БАЗАЛЬТОВЫЕ АРКИ", "ГРОЗОВЫЕ ДОКИ", "ГРОМООТВОД", "ffd082",
		[["Шторма","Шторму"],["Вольтар","Вольтар"],["Электра","Электру"],["Громар","Громар"],["Вулканис","Вулканис"]]],
	[3, "wind", "Промышленные доки", "ГРУЗОВЫЕ ПОДЪЁМНИКИ", "ВЕРХНИЙ ТЕРМИНАЛ", "КОЛЬЦЕВОЙ ВОКЗАЛ", "80e5ff",
		[["Феррон","Феррон"],["Магнетар","Магнетар"],["Кобальт","Кобальт"],["Килон","Килон"],["Ферра","Ферру"]]],
	[9, "pulse", "Сумеречные террасы", "НОЧНЫЕ ТЕРРАСЫ", "НЕОНОВЫЙ РЫНОК", "ТАМОЖЕННАЯ БАШНЯ", "ffa7e8",
		[["Веспера","Весперу"],["Нокта","Нокту"],["Лантерна","Лантерну"],["Астралис","Астралис"],["Гесперия","Гесперию"]]],
]

static func is_expedition(planet: int) -> bool:
	return planet >= VETRA

static func family_index(planet: int) -> int:
	var offset := planet - VETRA
	var slot := posmod(offset, 6)
	var first := 0 if slot < 3 else 3
	# Keeping each family in its half prevents repeats across cycle boundaries.
	return first + posmod(slot - first + floori(offset / 6.0), 3)

static func style_index(planet: int) -> int:
	return FAMILIES[family_index(planet)][0]

static func uses_wind(planet: int) -> bool:
	return FAMILIES[family_index(planet)][1] == "wind"

static func describe(planet: int) -> Dictionary:
	var family: Array = FAMILIES[family_index(planet)]
	var names: Array = family[7]
	var name_pair: Array = names[posmod(floori((planet - VETRA) / 6.0), names.size())]
	if planet == VETRA:
		name_pair = ["Ветра", "Ветру"]
	elif planet == LUMA:
		name_pair = ["Люма", "Люму"]
	return {
		"name": name_pair[0], "destination": name_pair[1], "style": family[0],
		"route": family[1], "subtitle": family[2], "accent": family[6],
		"regions": [family[3], family[4], family[5]],
	}
