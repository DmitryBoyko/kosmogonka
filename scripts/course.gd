extends RefCounted
## Encounters own both their obstacles and rewards. Distances are metres.
const LENGTH := 2100.0
const LANE_WIDTH := 2.6
const FRONT_START := 835.0
const FRONT_END := 945.0
const TRANSITION := 28.0

static func star_goal(planet: int) -> int:
	return 320 if planet == 2 else 300

static func lanes_at(s: float, planet: int = 0) -> Array:
	if planet > 0: return [0,1,2]
	if s < 180: return [1]
	if s < 330: return [0,1]
	return [0,1,2]

static func front_at(s: float) -> float:
	if s < FRONT_START or s > FRONT_END+TRANSITION: return 0.0
	if s < FRONT_START+TRANSITION: return smoothstep(FRONT_START,FRONT_START+TRANSITION,s)
	if s > FRONT_END: return 1.0-smoothstep(FRONT_END,FRONT_END+TRANSITION,s)
	return 1.0

static func transitioning(s: float) -> bool:
	return (s >= FRONT_START and s < FRONT_START+TRANSITION) or (s >= FRONT_END and s < FRONT_END+TRANSITION)

static func encounters(planet: int = 0) -> Array[Dictionary]:
	var rows := [
		[60,1,"jump"],[120,1,"duck"],[200,0,"weave"],[238,0,"choice"],
		[276,1,"jump"],[314,0,"weave"],
		[380,2,"weave"],[414,1,"jump"],[448,0,"weave"],[482,2,"jump"],
		[510,1,"duck"],[535,1,"roof"],
		[650,0,"jump"],[682,2,"duck"],[714,1,"weave"],[746,0,"alien"],[782,1,"jump"],
		[890,2,"jump"],[930,2,"duck"],
		[1008,0,"duck"],[1040,1,"jump"],[1072,2,"weave"],[1104,0,"alien"],
		[1136,1,"duck"],[1168,2,"jump"],[1200,0,"choice"],[1240,1,"roof"],
		[1310,2,"duck"],[1340,1,"weave"],
		[1390,0,"weave"],[1422,1,"jump"],[1454,2,"weave"],[1486,0,"jump"],
		[1530,1,"duck"],[1562,2,"jump"],[1594,0,"weave"],[1626,2,"alien"],
		[1658,0,"duck"],[1690,1,"jump"],[1722,1,"weave"],
		[1780,2,"duck"],[1812,0,"jump"],[1844,1,"weave"],[1876,0,"alien"],
		[1908,1,"choice"],[1940,2,"jump"],[1972,0,"duck"],[2004,2,"weave"],[2028,1,"jump"]]
	var result: Array[Dictionary] = []
	for i in rows.size():
		var row: Array = rows[i]
		var lane: int = row[1]
		var pattern: String = row[2]
		if planet == 2:
			if row[0] in [276,314,1168]: continue
			if row[0] == 238: pattern="roof"; lane=2
			if row[0] == 1136: pattern="roof"; lane=0
		if planet in [1,3] and row[0]>600 and not (row[0]>=780 and row[0]<=980) and not (row[0]>1350 and row[0]<1520):
			if i%(4 if planet==1 else 3)==0 and pattern in ["jump","duck"]: pattern="duck" if pattern=="jump" else "jump"
		if planet > 0 and row[0] > 170 and pattern != "roof" and not (row[0] >= 780 and row[0] <= 980): lane = (lane+planet)%3
		result.append({"id":i,"s":float(row[0]),"lane":lane,"pattern":pattern})
	return result

static func make_event(s: float, lane: int, kind: String, encounter: int = -1, role: String = "guard", trigger: float = -1) -> Dictionary:
	return {"s":s,"origin":s,"lane":lane,"kind":kind,"encounter":encounter,"role":role,
		"speed":0.8 if kind in ["ramp","carrier"] else -1.8 if kind == "truck" else 0.0,
		"motion_trigger":(s+120 if kind == "truck" else s) if trigger < 0 else trigger,"length":14.0 if kind=="cargo" else 12.0 if kind == "carrier" else 6.0 if kind in ["truck","broken","traffic"] else 1.0 if kind == "alien" else 1.4,
		"source_lane":lane,"top":top_of(kind),"cleared":false,"failed":false,"done":false,"node":null}

static func blocker(planet: int, index: int) -> String:
	var kinds := [["wall","plant","truck","broken"],["leaf","plant","gardener","leaf"],
		["truck","broken","wall","truck"],["traffic","wall","truck","traffic"]]
	return kinds[planet][index%4]

static func events(planet: int = 0) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var previous_lane := 1
	for packet in encounters(planet):
		var available := lanes_at(packet.s,planet)
		var pattern: String = packet.pattern
		var lane: int = packet.lane
		var approach := absi(lane-previous_lane)
		previous_lane=lane
		if pattern == "roof":
			result.append(make_event(packet.s,lane,"ramp",packet.id,"challenge",packet.s))
			result.append(make_event(packet.s+9,lane,"carrier",packet.id,"roof",packet.s))
			if planet == 2: result.append(make_event(packet.s+25,lane,"carrier",packet.id,"roof",packet.s))
			continue
		if pattern == "alien":
			var crossing := make_event(packet.s,(lane+1)%3,"alien",packet.id,"crossing")
			crossing.cross_offset = (crossing.lane-1)*12.0
			result.append(crossing)
			continue
		if pattern in ["jump","duck","choice"]:
			result.append(make_event(packet.s,lane,"barrier" if pattern == "jump" else "arch",packet.id,"challenge"))
		var guards: Array = available.duplicate()
		guards.erase(lane)
		if pattern == "choice" and not guards.is_empty(): guards.pop_back()
		for guard_lane: int in guards:
			var e := make_event(packet.s,guard_lane,blocker(planet,packet.id+guard_lane),packet.id)
			if pattern=="weave" and packet.s>330 and approach<=1:
				e = make_event(packet.s,guard_lane,"cargo",packet.id)
			for other: int in guards:
				if other != guard_lane: e.source_lane = other
			result.append(e)
	for row in [[345,1,"jet"],[600,1,"board"],[1355,1,"jet"],[1740,1,"board"]]:
		result.append(make_event(float(row[0]),int(row[1]),String(row[2]),-1,"booster"))
	result.sort_custom(func(a,b): return a.s < b.s)
	return result

static func add_star(result: Array[Dictionary], s: float, lane: int, y: float = 1.0, value: int = 1, anchor: Dictionary = {}, requirement: String = "") -> void:
	var star := {"s":s,"lane":lane,"y":y,"value":value,"done":false,"node":null,"requirement":requirement}
	if not anchor.is_empty():
		star.anchor = anchor
		star.offset = s-anchor.s
	result.append(star)

static func stars(planet: int = 0, course_events: Array = []) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var obstacles := events(planet) if course_events.is_empty() else course_events
	for packet in encounters(planet):
		var challenge: Dictionary = {}
		for e: Dictionary in obstacles:
			if e.encounter == packet.id and e.role == "challenge": challenge = e; break
		var s: float = packet.s
		var lane: int = packet.lane
		var pattern: String = packet.pattern
		for offset in [-14.0,-10.0,-6.0]: add_star(result,s+offset,lane,1.0,1,challenge)
		if pattern in ["duck","choice"]:
			for offset in [-2.0,2.0,6.0]: add_star(result,s+offset,lane,0.68,1,challenge,"duck" if offset<3 else "cleared")
			add_star(result,s+9,lane,1.0,1,challenge,"cleared")
			add_star(result,s+12,lane,1.0,3,challenge,"cleared")
			if pattern == "choice":
				var bypass: int = lanes_at(s,planet).back()
				if bypass == lane: bypass = lanes_at(s,planet).front()
				for offset in [-2.0,8.0]: add_star(result,s+offset,bypass)
		elif pattern == "jump":
			var span := 2.0 if front_at(s) > 0.5 else 4.0
			add_star(result,s-span,lane,2.1,1,challenge)
			add_star(result,s,lane,2.65,1,challenge,"cleared")
			add_star(result,s+span,lane,2.1,1,challenge,"cleared")
			add_star(result,s+10,lane,1.0,2,challenge,"cleared")
		elif pattern == "roof":
			for e: Dictionary in obstacles:
				if e.encounter != packet.id or e.kind != "carrier": continue
				for offset in [-4.0,-1.0,2.0,4.0]: add_star(result,e.s+offset,lane,2.48,2 if offset == 4 else 1,e,"roof")
		else:
			for offset in [-2.0,3.0,8.0,12.0]: add_star(result,s+offset,lane,1.0,2 if offset == 12 else 1)
	for row in [[22,1],[29,1],[36,1],[150,1],[157,1],[318,1],[325,1],[610,1],[617,1],[627,0],[985,2],[992,0],[1750,1],[1757,1],[1764,2],[2060,1],[2067,1],[2074,1]]:
		add_star(result,float(row[0]),int(row[1]))
	for e: Dictionary in obstacles:
		if e.kind != "jet": continue
		for offset in range(14,119,5):
			var lane: int = [1,0,1,2,1][mini(4,int((offset-14)/23))]
			add_star(result,e.s+offset,lane,4.15)
	result.sort_custom(func(a,b): return a.s < b.s)
	return result

static func top_of(kind: String) -> float:
	return float({"barrier":1.0,"arch":2.6,"wall":2.9,"plant":2.9,"leaf":3.0,"truck":3.0,"traffic":3.0,"broken":2.5,"carrier":1.48,"gardener":1.8,"alien":1.4,"cargo":3.0}.get(kind,0))

static func event_x(event: Dictionary, distance: float) -> float:
	if event.kind == "alien": return lerpf(-4.2,4.2,smoothstep(-30,30,distance-event.s+float(event.get("cross_offset",0))))
	var target: float = (event.lane-1)*LANE_WIDTH
	if event.kind not in ["gardener","traffic"]: return target
	return lerpf((event.source_lane-1)*LANE_WIDTH,target,smoothstep(-38,-18,distance-event.s))
