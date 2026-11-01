extends RefCounted
## Hand-authored safe encounters. Distances are metres, not elapsed frames.
const LENGTH := 2100.0
const LANE_WIDTH := 2.6
const FRONT_START := 835.0
const FRONT_END := 945.0
const TRANSITION := 28.0

static func lanes_at(s: float, planet: int = 0) -> Array:
	if planet > 0: return [0, 1, 2]
	if s < 170: return [1]
	if s < 330: return [0, 1]
	return [0, 1, 2]

static func front_at(s: float) -> float:
	if s < FRONT_START or s > FRONT_END + TRANSITION: return 0.0
	if s < FRONT_START + TRANSITION: return smoothstep(FRONT_START, FRONT_START + TRANSITION, s)
	if s > FRONT_END: return 1.0 - smoothstep(FRONT_END, FRONT_END + TRANSITION, s)
	return 1.0

static func transitioning(s: float) -> bool:
	return (s >= FRONT_START and s < FRONT_START + TRANSITION) or (s >= FRONT_END and s < FRONT_END + TRANSITION)

static func events(planet: int = 0) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	# At least one reachable route is left in every multi-lane encounter.
	var rows := [
		[60, 1, "barrier"], [120, 1, "arch"],
		[225, 1, "wall"], [285, 0, "barrier"],
		[410, 0, "wall"], [410, 2, "plant"], [470, 1, "barrier"],
		[535, 1, "ramp"], [544, 1, "carrier"],
		[675, 1, "barrier"], [735, 0, "wall"], [735, 2, "plant"],
		[890, 0, "barrier"], [890, 1, "wall"], [930, 2, "barrier"],
		[1110, 1, "wall"], [1110, 0, "plant"],
		[1175, 2, "arch"], [1240, 1, "ramp"], [1249, 1, "carrier"],
		[1440, 1, "wall"], [1440, 2, "plant"], [1510, 0, "barrier"],
		[1600, 0, "truck"], [1665, 2, "broken"], [1665, 1, "barrier"],
		[1820, 1, "barrier"], [1885, 0, "wall"], [1885, 2, "arch"],
		[1970, 1, "plant"]
	]
	if planet == 1:
		rows = [[70,1,"barrier"],[140,1,"arch"],[225,1,"leaf"],[300,0,"gardener"],
			[420,0,"leaf"],[420,1,"barrier"],[490,2,"arch"],[535,1,"ramp"],[544,1,"carrier"],
			[690,1,"leaf"],[760,0,"barrier"],[890,0,"barrier"],[890,1,"wall"],[930,2,"barrier"],
			[1100,1,"gardener"],[1170,0,"leaf"],[1240,1,"ramp"],[1249,1,"carrier"],
			[1440,0,"leaf"],[1520,2,"arch"],[1610,1,"gardener"],[1680,0,"leaf"],
			[1810,1,"barrier"],[1880,0,"leaf"],[1880,2,"arch"],[1970,1,"leaf"]]
	elif planet == 2:
		rows = [[70,1,"barrier"],[140,2,"arch"],[230,1,"ramp"],[239,1,"carrier"],[255,1,"carrier"],
			[420,0,"truck"],[490,2,"broken"],[535,1,"ramp"],[544,1,"carrier"],[560,1,"carrier"],
			[690,1,"wall"],[760,0,"barrier"],[890,0,"barrier"],[890,1,"wall"],[930,2,"barrier"],
			[1100,2,"ramp"],[1109,2,"carrier"],[1125,2,"carrier"],[1240,1,"ramp"],[1249,1,"carrier"],[1265,1,"carrier"],
			[1440,0,"truck"],[1520,1,"wall"],[1620,1,"ramp"],[1629,1,"carrier"],[1645,1,"carrier"],
			[1810,1,"barrier"],[1880,0,"wall"],[1880,2,"arch"],[1970,1,"broken"]]
	elif planet == 3:
		rows = [[70,1,"barrier"],[125,1,"arch"],[220,1,"traffic"],[280,0,"barrier"],
			[420,1,"traffic"],[480,2,"arch"],[535,1,"ramp"],[544,1,"carrier"],
			[690,0,"traffic"],[750,2,"barrier"],[890,0,"barrier"],[890,1,"wall"],[930,2,"barrier"],
			[1100,1,"traffic"],[1150,0,"barrier"],[1200,2,"arch"],[1250,1,"barrier"],
			[1440,0,"traffic"],[1500,1,"arch"],[1580,2,"traffic"],[1650,0,"barrier"],
			[1810,1,"traffic"],[1870,2,"arch"],[1940,1,"barrier"]]
	for row in rows:
		var kind: String = row[2]
		result.append({"s": float(row[0]), "lane": int(row[1]), "kind": kind,
			"speed": -2.5 if kind == "truck" else (0.8 if kind in ["carrier", "ramp"] else 0.0),
			"length": 12.0 if kind == "carrier" else (6.0 if kind in ["truck", "broken", "traffic"] else 1.4),
			"source_lane": (int(row[1]) + 1) % 3, "top": top_of(kind),
			"done": false, "node": null})
	for row in [[345, 1, "jet"], [600, 1, "board"], [1355, 1, "jet"], [1740, 1, "board"]]:
		result.append({"s": float(row[0]), "lane": int(row[1]), "kind": String(row[2]), "speed": 0.0, "length": 1.0, "done": false, "node": null})
	return result

static func stars(planet: int = 0) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for s in range(22, 2070, 7):
		var lane := 1
		if s >= 185 and s < 260: lane = 0
		elif s >= 330: lane = [1, 2, 0, 1, 2, 1][int(s / 84) % 6]
		if s >= 860 and s < 910: lane = 2
		if s >= 910 and s < 975: lane = 1
		var height := 1.0
		if (s > 353 and s < 480) or (s > 1363 and s < 1490):
			height = 4.15
			lane = 1
		var safe := true
		for event in events(planet):
			if event.lane == lane and absf(event.s - s) < event.length * 0.5 + 6:
				if event.kind in ["wall", "plant", "truck", "broken", "carrier", "leaf", "gardener", "traffic"] and height < 3.0:
					safe = false
				elif event.kind == "barrier": height = 2.2
				elif event.kind == "arch": safe = false
		if safe:
			result.append({"s": float(s), "lane": lane, "y": height, "done": false, "node": null})
	# Roof rewards use carrier-relative positions in the game, not static stars.
	return result

static func top_of(kind: String) -> float:
	return float({"barrier":1.0,"arch":2.6,"wall":2.9,"plant":2.9,"leaf":3.0,"truck":3.0,"traffic":3.0,"broken":2.5,"carrier":1.48,"gardener":1.8}.get(kind, 0))

static func event_x(event: Dictionary, distance: float) -> float:
	var target: float = (event.lane - 1) * LANE_WIDTH
	if event.kind not in ["gardener", "traffic"]: return target
	var k := smoothstep(-38, -18, distance - event.s)
	return lerpf((event.source_lane - 1) * LANE_WIDTH, target, k)
