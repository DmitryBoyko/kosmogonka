extends RefCounted
## Encounters own both their obstacles and rewards. Distances are metres.
const LENGTH := 2100.0
const LANE_WIDTH := 2.6
const TUNNEL_FLOOR := 3.35
const TUNNEL_LENGTH := 44.0
const FRONT_START := 835.0
const FRONT_END := 945.0
const TRANSITION := 28.0
static var layout_seed:int=0

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
		# Reserve complete, readable feature sequences, rather than overlapping random hazards.
		if row[0] in [1072,1104,1200,1876,1908,1594,2004]: continue
		if row[0] in [1040,1844]: pattern="stairs"
		if row[0] in [1240,1562]: pattern="passage"
		if row[0] in [1168,1972]: pattern="alien"
		if planet == 2:
			if row[0] in [276,314]: continue
			if row[0] == 238: pattern="roof"; lane=2
		if planet in [1,3] and row[0]>600 and not (row[0]>=780 and row[0]<=980) and not (row[0]>1350 and row[0]<1520):
			if i%(4 if planet==1 else 3)==0 and pattern in ["jump","duck"]: pattern="duck" if pattern=="jump" else "jump"
		if planet > 0 and row[0] > 170 and pattern != "roof" and not (row[0] >= 780 and row[0] <= 980): lane = (lane+planet)%3
		var packet:Dictionary={"id":i,"s":1580.0 if row[0]==1562 else 1184.0 if row[0]==1168 else 1988.0 if row[0]==1972 else 1152.0 if row[0]==1136 else 1956.0 if row[0]==1940 else float(row[0]),"lane":lane,"pattern":pattern}
		if pattern in ["stairs","passage"]:
			var rng:=RandomNumberGenerator.new(); rng.seed=layout_seed+planet*7919+i*1613+719
			packet.lane=rng.randi_range(0,2)
			packet.floors=rng.randi_range(1,2 if planet==0 and row[0]==1040 else 3)
			packet.lower=rng.randf()<.5
			packet.bonus=rng.randi_range(0,4) # 0: no bonus; 1/2 regular; 3/4 doubled.
			packet.length=[16.,20.,24.][rng.randi_range(0,2)]
			if pattern=="passage": packet.s+=rng.randi_range(-8,8)
		result.append(packet)
	return result

static func make_event(s: float, lane: int, kind: String, encounter: int = -1, role: String = "guard", trigger: float = -1) -> Dictionary:
	return {"s":s,"origin":s,"lane":lane,"kind":kind,"encounter":encounter,"role":role,
		"speed":0.8 if kind in ["ramp","carrier"] else -1.8 if kind == "truck" else 0.0,
		"motion_trigger":(s+120 if kind == "truck" else s) if trigger < 0 else trigger,"length":TUNNEL_LENGTH if kind=="tunnel" else 14.0 if kind=="cargo" else 12.0 if kind == "carrier" else 6.0 if kind in ["truck","broken","traffic"] else 1.0 if kind == "alien" else 1.4,
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
		if pattern=="stairs":
			var stair:=make_event(packet.s,lane,"stairs",packet.id,"challenge",packet.s)
			stair.top=packet.floors*1.48; stair.length=packet.floors*8.; stair.speed=.8
			stair.floors=packet.floors; stair.lower=packet.lower
			var deck:float=maxf(.74,stair.top-(1.48 if packet.floors>1 else .74)) if packet.lower else stair.top
			var gap:float=8.0 if packet.lower else 18.0
			var platform:=make_event(stair.s+stair.length*.5+gap+12,lane,"skycarrier",packet.id,"roof",packet.s)
			platform.top=deck; platform.length=24.; platform.speed=.8; platform.lower=packet.lower
			var exit:=make_event(platform.s+12+maxf(8,deck/1.48*8)*.5,lane,"stairs_down",packet.id,"exit",packet.s)
			exit.top=deck; exit.length=maxf(8,deck/1.48*8); exit.speed=.8
			result.append_array([stair,platform,exit]); continue
		if pattern=="passage":
			var passage:=make_event(packet.s,lane,"passage",packet.id,"challenge")
			passage.length=packet.length; passage.bonus=packet.bonus; passage.top=3.6
			result.append(passage); continue
		if pattern == "roof":
			result.append(make_event(packet.s,lane,"ramp",packet.id,"challenge",packet.s))
			result.append(make_event(packet.s+9,lane,"carrier",packet.id,"roof",packet.s))
			if planet == 2: result.append(make_event(packet.s+21,lane,"carrier",packet.id,"roof",packet.s))
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
	for center in [663.0,1710.0]:
		result.append(make_event(center,1,"tunnel",-1,"bonus"))
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
		elif pattern=="stairs":
			for e:Dictionary in obstacles:
				if e.encounter!=packet.id: continue
				if e.kind=="stairs":
					for offset in range(2,int(e.length),3):
						var rel:float=-e.length*.5+offset
						add_star(result,e.s+rel,lane,step_height(e,rel)+1,1,e)
				elif e.kind=="skycarrier":
					for offset in [-8.,-4.,0.,4.,8.]: add_star(result,e.s+offset,lane,e.top+1,2,e,"roof")
		elif pattern=="passage":
			if int(challenge.get("bonus",0))>0:
				for offset in range(-int(challenge.length*.5)+3,int(challenge.length*.5)-1,3):
					add_star(result,challenge.s+offset,lane,1.,2 if challenge.bonus>=3 else 1,challenge,"passage")
		else:
			for offset in [-2.0,3.0,8.0,12.0]: add_star(result,s+offset,lane,1.0,2 if offset == 12 else 1)
	for row in [[22,1],[29,1],[36,1],[150,1],[157,1],[318,1],[325,1],[610,1],[617,1],[627,0],[985,2],[992,0],[1750,1],[1757,1],[1764,2],[2060,1],[2067,1],[2074,1]]:
		add_star(result,float(row[0]),int(row[1]))
	for e: Dictionary in obstacles:
		if e.kind != "jet": continue
		for offset in range(14,119,5):
			var lane: int = [1,0,1,2,1][mini(4,int((offset-14)/23))]
			add_star(result,e.s+offset,lane,4.15)
	for e: Dictionary in obstacles:
		if e.kind != "tunnel": continue
		for offset in range(-17,19,3):
			add_star(result,e.s+offset,e.lane,TUNNEL_FLOOR+1.0,2,e,"tunnel")
			result.back().mega=true
	result.sort_custom(func(a,b): return a.s < b.s)
	return result

static func top_of(kind: String) -> float:
	return float({"barrier":1.0,"arch":2.6,"wall":2.9,"plant":2.9,"leaf":3.0,"truck":3.0,"traffic":3.0,"broken":2.5,"carrier":1.48,"gardener":1.8,"alien":1.4,"cargo":3.0}.get(kind,0))

static func walkable_top(kind: String) -> float:
	return top_of(kind) if kind in ["carrier","cargo"] else 3.6 if kind=="passage" else -1.0

static func event_deck(event:Dictionary) -> float:
	return float(event.top) if event.kind=="skycarrier" else walkable_top(event.kind)

static func step_height(event:Dictionary, rel:float) -> float:
	var count:int=maxi(1,ceili(event.top/.185))
	var phase:float=clampf((rel+event.length*.5)/event.length,0,.99999)
	var step:int=mini(count,int(phase*count)+1)
	return event.top*float(step if event.kind=="stairs" else count-step+1)/count

static func event_x(event: Dictionary, distance: float) -> float:
	if event.kind == "alien": return lerpf(-4.2,4.2,smoothstep(-30,30,distance-event.s+float(event.get("cross_offset",0))))
	var target: float = (event.lane-1)*LANE_WIDTH
	if event.kind not in ["gardener","traffic"]: return target
	return lerpf((event.source_lane-1)*LANE_WIDTH,target,smoothstep(-38,-18,distance-event.s))
