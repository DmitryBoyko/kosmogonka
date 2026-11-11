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
const PAINT := [
	["168ad8","ffad42"], ["f33794","74f9ef"], ["4b59ef","f4ed69"], ["a646ef","ffa4cc"],
	["ed6a2c","64e6fc"], ["22bda8","ff73b1"], ["40ad58","ffce5c"], ["5265f4","fda8ff"],
	["e74656","80eaf5"], ["dc2ac6","b1ff80"], ["17a9b8","ff8575"], ["9162f7","ffdb72"],
	["e99529","6855ed"], ["2d7ee6","fdcc4e"], ["873aed","bcfa60"], ["347ef6","78edca"],
	["4b70d9","ffbd63"], ["55b34a","ff9656"], ["c83a75","ffdd73"], ["33b87c","ef93f8"],
]

static func is_female(index: int) -> bool:
	return MODELS[posmod(index, MODELS.size())].begins_with("female-") or index == 14

static func scene(index: int) -> PackedScene:
	var model: String = MODELS[posmod(index, MODELS.size())]
	return load("res://assets/crew/character-" + model + ".glb") as PackedScene
