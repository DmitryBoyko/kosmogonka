extends RefCounted
const NAMES = [
	"race-future", "sedan-sports", "suv-luxury", "sedan", "taxi", "police", "delivery", "van", "truck-flat",
	"ambulance", "delivery-flat", "firetruck", "garbage-truck", "hatchback-sports",
	"kart-oobi", "kart-oodi", "kart-ooli", "kart-oopi", "kart-oozi",
	"race", "suv", "tractor-police", "tractor-shovel", "tractor", "truck",
]
const LENGTHS = [4.61,4.08,3.95,3.54,3.81,4.30,4.51,3.81,3.81,4.13,4.51,4.58,4.48,4.56,3.05,3.05,3.05,3.05,3.05,4.10,3.74,3.10,3.09,3.15,4.09]
const HEIGHTS = [1.77,2.08,2.13,2.13,2.40,2.13,2.61,2.20,2.13,2.61,2.19,2.61,2.40,2.08,1.76,1.76,1.76,1.76,1.76,1.49,2.12,2.61,2.21,2.61,2.12]
const PACE = [.60,.48,.36,.40,.55,.65,.28,.34,.25,.55,.31,.43,.26,.52,.58,.58,.58,.58,.58,.64,.39,.37,.27,.31,.30]

static func shuffled_order(seed_value: int, world: int) -> Array[int]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ ((world + 1) * 31627)
	var order: Array[int] = []
	for index in NAMES.size():
		order.append(index)
	for index in range(order.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var style := order[index]
		order[index] = order[other]
		order[other] = style
	return order
static func variant(encounter: int,lane: int,world: int) -> int:
	return posmod(absi(encounter)*7+lane*3+world,NAMES.size())
