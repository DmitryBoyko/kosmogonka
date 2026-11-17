extends RefCounted

const Worlds = preload("res://scripts/expedition_worlds.gd")

# Distances are course metres. Each row is [distance, lane, action, bonus].
# The middle checkpoint and the front camera change have clear approaches.
const WIND_GATES := [
	[220., 0, "avoid", false], [374., 1, "jump", false],
	[604., 1, "avoid", false], [717., 2, "jump", false],
	[1080., 0, "avoid", false], [1390., 1, "jump", false],
	[1500., 2, "avoid", false], [1740., 1, "avoid", false],
	[1880., 1, "jump", false], [1960., 2, "avoid", false], [1960., 1, "avoid", false],
	[2260., 1, "jump", false],
]
const PULSE_GATES := [
	[230., 1, "duck", false], [399., 0, "avoid", false], [474., 1, "duck", false],
	[590., 0, "duck", true], [659., 2, "duck", true], [659., 0, "avoid", false],
	[746., 1, "jump", false], [1090., 2, "avoid", false], [1170., 1, "duck", false],
	[1510., 1, "duck", false], [1610., 2, "jump", false],
	[1720., 2, "duck", true], [1801., 2, "jump", true],
	[1930., 1, "avoid", false], [2000., 0, "duck", false],
	[2180., 1, "duck", true], [2255., 1, "avoid", false],
	[2255., 2, "jump", true], [2320., 2, "duck", true],
	[2460., 0, "avoid", false], [2530., 1, "jump", false],
]

static func length_for(planet: int) -> float:
	return 5350. + minf(1800.,float(planet-Worlds.VETRA)*145.)

static func pressure(planet: int) -> float:
	return 1.-exp(-float(maxi(0,planet-Worlds.VETRA))/13.)

static func layout(planet: int, seed_value: int) -> Dictionary:
	var wind := Worlds.uses_wind(planet)
	var gates := WIND_GATES if wind else PULSE_GATES
	var mirrored := planet > Worlds.LUMA and posmod(seed_value + planet, 2) == 1
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ (planet * 7727)
	var pieces: Array[Dictionary] = []
	var section_shift: Array[float] = [0., 0., 0.]
	if planet > Worlds.LUMA:
		for i in section_shift.size():
			section_shift[i] = float(rng.randi_range(-16, 16))
	for row: Array in gates:
		var lane: int = 2 - row[1] if mirrored else row[1]
		var s: float = row[0]
		s += section_shift[0 if s < 800. else 1 if s < 1700. else 2]
		pieces.append({"s": s, "lane": lane, "kind": "exp_gate", "action": row[2],
			"bonus": row[3], "wind": wind, "length": 2.4, "lead": 69. if wind else 75.})
	if wind:
		add_bridge(pieces, 476. + section_shift[0], 0 if mirrored else 2, false)
		add_bridge(pieces, 1814. + section_shift[2], 2 if mirrored else 0, true)
	add_connectors(pieces, planet, wind, rng)
	pieces.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.s < b.s)
	var stars: Array[Dictionary] = []
	var length := length_for(planet)
	var phase := rng.randi_range(0, 3)
	for s in range(30, int(length) - 42, 12):
		var lane: int = [1, 0, 1, 2][posmod(floori(s / 90.) + phase, 4)]
		if s >= 800 and s <= 1000: lane = 1
		for try_lane in [lane, posmod(lane + 1, 3), posmod(lane + 2, 3)]:
			if clear_for_star(pieces, s, try_lane):
				stars.append({"s": float(s), "lane": try_lane, "y": 1., "value": 2})
				break
	return {"pieces": pieces, "stars": stars}

static func add_connectors(pieces: Array[Dictionary], planet: int, wind: bool, rng: RandomNumberGenerator) -> void:
	var authored := pieces.duplicate()
	var length := length_for(planet)
	var challenge := pressure(planet)
	var spacing := roundi(lerpf(27.,17.,challenge))
	var safe_lane := 1
	var wave := 0
	for mark in range(65, int(length)-78, spacing):
		var s := float(mark)+rng.randf_range(-2.,2.)
		if (s >= 755. and s <= 1010.) or absf(s-length*.5)<36.:
			continue
		if authored.any(func(piece: Dictionary): return absf(s-piece.s)<piece.length*.5+19.):
			continue
		var next_lane: int = safe_lane+(-1 if rng.randf()<.5 else 1)
		safe_lane = 1 if next_lane<0 or next_lane>2 else next_lane
		var double := wave%5!=0 or rng.randf()<challenge
		for lane in 3:
			if lane==safe_lane: continue
			var pattern := posmod(wave+lane*2+Worlds.family_index(planet),6)
			var action: String = ["jump","avoid","duck","jump","duck","avoid"][pattern]
			var kind := "biome_ridge" if pattern==3 else "exp_ufo" if pattern in [1,5] and wave%3==1 else "exp_gate"
			var bonus := kind=="exp_gate" and action!="avoid" and wave%6==3 and lane==posmod(safe_lane+1,3)
			pieces.append({"s":s,"lane":lane,"kind":kind,"action":action,"shape":pattern,
				"bonus":bonus,"wind":wind,"length":1.8 if kind=="biome_ridge" else 2.4,"lead":lerpf(72.,63.,challenge)})
			if not double: break
		wave+=1

static func add_bridge(pieces: Array[Dictionary], start: float, lane: int, gap: bool) -> void:
	pieces.append({"s": start, "lane": lane, "kind": "exp_lift", "length": 2., "lead": 69.})
	# First deck starts at the top of the assisted jump. The final deck
	# slopes down to the public road, without a drop at the merge.
	add_span(pieces, lane, start + 14., start + (49. if gap else 65.), 2.75, 2.75)
	if gap:
		pieces.back().jump_edge = true
		add_span(pieces, lane, start + 55., start + 96., 2.75, 2.75)
		pieces.back().landing_edge = true
	add_span(pieces, lane, start + (96. if gap else 65.), start + (121. if gap else 90.), 2.75, 0.)

static func add_span(pieces: Array[Dictionary], lane: int, start: float, end: float, from_y: float, to_y: float) -> void:
	pieces.append({"s": (start + end) * .5, "lane": lane, "kind": "exp_deck",
		"length": end - start, "from_y": from_y, "to_y": to_y})

static func clear_for_star(pieces: Array[Dictionary], s: float, lane: int) -> bool:
	for piece in pieces:
		if lane == piece.lane and absf(s - piece.s) < piece.length * .5 + 12.:
			return false
	return true

static func deck_height(piece: Dictionary, rel: float) -> float:
	return lerpf(piece.from_y, piece.to_y, clampf(rel / piece.length + .5, 0., 1.))

static func lift_reach(gap: float) -> bool:
	return gap >= -4. and gap <= 5.

static func action_text(action: String) -> String:
	match action:
		"duck": return "ПОДКАТ"
		"jump": return "ПРЫЖОК"
		_: return "СМЕНИ ПОЛОСУ"

static func region(distance: float) -> int:
	if distance < 775.: return 0
	return 1 if distance < 1700. else 2

static func hint(events: Array[Dictionary], distance: float, lane: int, height: float) -> String:
	var nearest := INF
	var message := ""
	var bonus_ahead := INF
	var bonus_message := ""
	for event in events:
		var ahead: float = event.s - distance
		if event.kind == "exp_deck" and event.lane == lane and height > 1.9:
			var edge: float = ahead + event.length * .5
			if ahead - event.length * .5 < 0. and edge >= 0. and edge < 23. and event.get("jump_edge", false):
				return "РАЗРЫВ МОСТА · у янтарной кромки"
		elif event.kind == "exp_lift" and ahead >= -4. and ahead < event.lead and ahead < nearest:
			nearest = ahead
			var side := "СПРАВА" if event.lane == 2 else "СЛЕВА"
			message = "МОСТ %s · НА МЕТКЕ\nПрямо — нижняя дорога"%side
		elif event.has("action") and event.lane == lane and ahead >= -.9 and ahead < event.lead and ahead < nearest:
			nearest = ahead
			message = action_text(event.action)
			if event.kind=="exp_ufo": message="НЛО · СМЕНИ ПОЛОСУ"
			if event.bonus: message += " · БОНУСНЫЕ ЗВЁЗДЫ"
		elif event.kind == "exp_gate" and event.get("bonus", false) and ahead > 14. and ahead < event.lead and ahead < bonus_ahead:
			bonus_ahead = ahead
			var side := "СЛЕВА" if event.lane == 0 else "СПРАВА" if event.lane == 2 else "ПО ЦЕНТРУ"
			bonus_message = "БОНУС %s · %s" % [side, action_text(event.action)]
	if message.is_empty() and height > 1.9:
		for event in events:
			if event.kind == "exp_deck" and event.lane == lane and absf(distance - event.s) < event.length * .5:
				return "ВЕТРОВОЙ МОСТ · держи полосу"
	return message if not message.is_empty() else bonus_message
