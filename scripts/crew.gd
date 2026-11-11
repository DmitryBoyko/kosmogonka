extends RefCounted

# Slots 0 and 1 inherit the saved progress of the original pair.
const MODELS := [
	"male-a", "female-a", "male-b", "female-b", "male-c", "female-c",
	"male-d", "female-d", "male-e", "female-e", "male-f", "female-f",
	"male-g", "worker", "alien", "robot", "knight", "soldier", "raider", "zombie",
]
const NAMES := [
	"Макс", "Мира", "Лео", "Ника", "Тим", "Луна", "Кай", "Астра", "Дэн", "Рея",
	"Рэй", "Селена", "Финн", "Механик", "Искра", "Робот", "Рыцарь", "Кадет",
	"Следопыт", "Зомби",
]
const ACCENTS := ["4ad8e7", "ee76b5", "ffc768", "9b83f5", "74d990", "6bb5ff"]

static func is_female(index: int) -> bool:
	return MODELS[posmod(index, MODELS.size())].begins_with("female-") or index == 14

static func scene(index: int) -> PackedScene:
	var model: String = MODELS[posmod(index, MODELS.size())]
	return load("res://assets/crew/character-" + model + ".glb") as PackedScene
