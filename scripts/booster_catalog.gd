extends RefCounted
const KINDS:=["jet","board"]
const LIMIT:=9
const PRICES:={"jet":24,"board":20}
const TITLES:={"jet":"Огонь ранца","board":"Энергия доски"}
const DROP_CHANCE:=.05
const MAX_DROPS:=2
const LOOP_REWARD:=72
const DROP_POINTS:=[290.,505.,765.,1020.,1290.,1660.,1795.,2010.]
static func drops(seed_value:int,planet:int) -> Array[Dictionary]:
	var rng:=RandomNumberGenerator.new(); rng.seed=seed_value+planet*3571+991
	var result:Array[Dictionary]=[]
	for point:float in DROP_POINTS:
		if rng.randf()>=DROP_CHANCE or result.size()>=MAX_DROPS: continue
		result.append({"s":point,"lane":rng.randi_range(0,2),"kind":KINDS[rng.randi_range(0,1)],"done":false,"node":null})
	return result
