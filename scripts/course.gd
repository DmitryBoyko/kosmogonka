extends RefCounted
## Encounters own both their obstacles and rewards. Distances are metres.
const Basement=preload("res://scripts/basement.gd")
const LENGTH := 2100.0
const LANE_WIDTH := 2.6
const TUNNEL_FLOOR := 3.35
const TUNNEL_LENGTH := 44.0
const FRONT_START := 835.0
const FRONT_END := 945.0
const TRANSITION := 28.0
static var layout_seed:int=0
static func variant() -> int:return posmod(layout_seed,4)
static func length_for(world:int) -> float:return 5200. if world==10 else LENGTH+clampi(world,0,9)*200.

static func speed_scale(planet:int) -> float:
	return [1.,1.04,1.09,1.15,1.22,1.30,1.39,1.49,1.59,1.64,1.69][clampi(planet,0,10)]

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
	var extra_index:=0
	for at in range(2120,int(length_for(planet))-130,72-planet*3):
		rows.append([at,extra_index%3,["jump","duck","weave","alien","choice","jump","stairs","duck"][extra_index%8]])
		extra_index+=1
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
			if row[0] == 276: continue
			# A single courier after the convoy roofs replaces the old empty slot.
			if row[0] == 314: pattern="alien"; lane=1
			if row[0] == 238: pattern="roof"; lane=2
		if planet in [1,3] and row[0]>600 and not (row[0]>=780 and row[0]<=980) and not (row[0]>1350 and row[0]<1520):
			if i%(4 if planet==1 else 3)==0 and pattern in ["jump","duck"]: pattern="duck" if pattern=="jump" else "jump"
		if planet > 0 and row[0] > 170 and pattern != "roof" and not (row[0] >= 780 and row[0] <= 980): lane = (lane+planet)%3
		if row[0]>170 and not (row[0]>=780 and row[0]<=980):
			var available:=lanes_at(row[0],planet)
			if variant() in [1,3]:lane=available[available.size()-1-available.find(lane)]
			if variant() in [2,3] and pattern in ["jump","duck"]:pattern="duck" if pattern=="jump" else "jump"
			if variant()==1 and pattern=="weave" and i%3==0:pattern="choice"
			elif variant()==3 and pattern=="choice":pattern="weave"
		var packet:Dictionary={"id":i,"s":1580.0 if row[0]==1562 else 1184.0 if row[0]==1168 else 1988.0 if row[0]==1972 else 1152.0 if row[0]==1136 else 1956.0 if row[0]==1940 else float(row[0]),"lane":lane,"pattern":pattern}
		if absi(layout_seed)>3 and row[0]>330 and (row[0]<780 or row[0]>980) and pattern in ["jump","duck","weave","choice"]:
			var section:=RandomNumberGenerator.new()
			section.seed=layout_seed^(i*32569+planet*733)
			packet.s+=section.randf_range(-5.5,5.5)
			var choices:Array=lanes_at(packet.s,planet)
			packet.lane=choices[section.randi_range(0,choices.size()-1)]
			if section.randf()<.58:
				packet.pattern=["jump","duck","weave","choice","weave"][section.randi_range(0,4)]
		if pattern in ["stairs","passage"]:
			var rng:=RandomNumberGenerator.new(); rng.seed=layout_seed+planet*7919+i*1613+719
			packet.lane=rng.randi_range(0,2)
			packet.floors=rng.randi_range(1,2 if planet==0 and row[0]==1040 else 3)
			packet.lower=rng.randf()<.5
			# Preserve RNG ordering for the existing staircase layouts.
			rng.randi_range(0,4); rng.randi_range(0,2)
			packet.bonus=4
			packet.length=Basement.LENGTH
			if pattern=="passage": packet.s+=rng.randi_range(-8,8)
		result.append(packet)
	return result

static func make_event(s: float, lane: int, kind: String, encounter: int = -1, role: String = "guard", trigger: float = -1) -> Dictionary:
	return {"s":s,"origin":s,"lane":lane,"kind":kind,"encounter":encounter,"role":role,
		"speed":0.8 if kind in ["ramp","carrier"] else -5.0 if kind in ["truck","traffic"] else 0.0,
		"motion_trigger":s if trigger < 0 else trigger,"length":TUNNEL_LENGTH if kind=="tunnel" else 14.0 if kind=="cargo" else 12.0 if kind == "carrier" else 6.0 if kind in ["truck","broken","traffic"] else 1.0 if kind == "alien" else 1.4,
		"source_lane":lane,"top":top_of(kind),"cleared":false,"failed":false,"done":false,"node":null}

static func is_road_vehicle(event:Dictionary) -> bool:
	return event.kind in ["truck","traffic","broken"]

static func reserve_stair_traffic(course_events:Array[Dictionary]) -> void:
	var closures := [[],[],[]]
	for stair in course_events:
		var half_length:float=stair.length*.5
		var lane_closures:Array=closures[stair.lane]
		match stair.kind:
			"stairs","stairs_down":
				lane_closures.append({"event":stair,"offsets":Vector2(-half_length,half_length)})
			"upper_stairs":
				# Road traffic can pass below a staircase that is entirely overhead.
				var low:float=minf(stair.from_height,stair.to_height)
				var high:float=maxf(stair.from_height,stair.to_height)
				const ROAD_CLEARANCE := 3.45
				if low<ROAD_CLEARANCE:
					var fraction:=clampf((ROAD_CLEARANCE-low)/maxf(.01,high-low),0.,1.)
					var span:float=stair.length*fraction
					var offsets:=Vector2(-half_length,-half_length+span) if stair.from_height<stair.to_height else Vector2(half_length-span,half_length)
					lane_closures.append({"event":stair,"offsets":offsets})
			"basement":
				for opening:Vector2 in Basement.openings(stair):
					lane_closures.append({"event":stair,"offsets":opening-Vector2.ONE*float(stair.s)})
	for vehicle in course_events:
		if not is_road_vehicle(vehicle):
			continue
		var source:int=vehicle.source_lane if vehicle.kind=="traffic" else vehicle.lane
		var reservations:Array=[]
		for lane_index in range(mini(source,vehicle.lane),maxi(source,vehicle.lane)+1):
			reservations.append_array(closures[lane_index])
		vehicle["stair_reservations"]=reservations

static func traffic_on_road(event:Dictionary) -> bool:
	if not event.has("stair_reservations"):
		return true
	var margin:float=event.length*.5+1.25
	var start:=minf(event.s,event.origin)-margin
	var end:=maxf(event.s,event.origin)+margin
	for reservation:Dictionary in event.stair_reservations:
		var stair:Dictionary=reservation.event
		var offsets:Vector2=reservation.offsets
		if start<stair.s+offsets.y and end>stair.s+offsets.x:
			return false
	return true

static func advance_event(event:Dictionary,distance_value:float,runner_speed:float,planet:int,dt:float) -> void:
	if is_road_vehicle(event):
		# Keep the encounter in its assigned stretch while giving players
		# more time to read traffic around bends.
		var ratio:=.64+clampi(planet,0,9)*.008
		if not event.has("motion_distance") or dt<=0. or absf(distance_value-float(event.motion_distance))>5.:
			event.s=event.origin+(event.origin-distance_value)*ratio
		else: event.s-=runner_speed*ratio*dt
		event.motion_distance=distance_value
		event.speed=-runner_speed*ratio
	elif distance_value>=float(event.get("motion_trigger",event.s))-155.:
		event.s+=event.speed*dt

static func blocker(planet: int, index: int) -> String:
	var kinds := [["wall","plant","truck","broken"],["leaf","plant","gardener","leaf"],
		["truck","broken","wall","truck"],["traffic","wall","truck","traffic"]]
	return kinds[preload("res://scripts/planets.gd").biome(planet)][index%4]

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
			var passage:=make_event(packet.s,lane,"basement",packet.id,"challenge")
			passage.length=packet.length; passage.bonus=packet.bonus; passage.round=packet.s<1400
			result.append(passage)
			for offset in [-6.0,9.0]:
				var glove:=make_event(passage.s+offset,lane,"glove",packet.id,"underground_hazard")
				glove.anchor=passage; glove.length=2.0; result.append(glove)
			continue
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
	# Booster supply is finite inventory from shops / seeded rare drops.
	for center in [663.0,1710.0]:
		result.append(make_event(center,1,"tunnel",-1,"bonus"))
	# Couriers occupy gaps between authored encounters; no spawning inside features.
	var rng:=RandomNumberGenerator.new(); rng.seed=layout_seed+planet*9283+461
	var candidates:Array[float]=[]
	var blocked:Array[Vector2]=[]
	for event:Dictionary in result:
		var clearance:float=event.length*.5+maxf(14.,expected_speed(event.s,planet)*.5)
		if event.kind=="alien": clearance=maxf(clearance,expected_speed(event.s,planet)*1.6)
		if event.kind in ["stairs","stairs_down","skycarrier","basement","tunnel"]: clearance+=28
		var span:=Vector2(event.s-clearance,event.s+clearance)
		if event.kind in ["ramp","carrier","stairs","stairs_down","skycarrier"]:
			span.x=minf(span.x,event.s-event.length*.5-25); span.y=maxf(span.y,event.s+event.length*.5+100)
		blocked.append(span)
	blocked.sort_custom(func(a,b): return a.x<b.x)
	var merged:Array[Vector2]=[]
	for span:Vector2 in blocked:
		if not merged.is_empty() and span.x<merged[-1].y: merged[-1].y=maxf(merged[-1].y,span.y)
		else: merged.append(span)
	for distance_value in range(210,2020,4):
		var safe:=not transitioning(distance_value) and not (distance_value>FRONT_START-35 and distance_value<FRONT_END+TRANSITION+35)
		for span:Vector2 in merged:
			if distance_value>span.x and distance_value<span.y: safe=false; break
		if safe: candidates.append(float(distance_value))
	var extra_count:=2+planet
	while extra_count>0 and not candidates.is_empty():
		# Fill the emptiest available interval first, not a random cluster.
		var s:float=candidates[0]
		var best_gap:=-1.
		for candidate:float in candidates:
			var nearest:=INF
			for e:Dictionary in result:
				if e.kind in ["jet","board"]: continue
				nearest=minf(nearest,absf(e.s-candidate)/expected_speed(candidate,planet))
			if nearest>best_gap: best_gap=nearest; s=candidate
		var alien:=make_event(s,1,"alien",-2,"surprise")
		alien.cross_offset=0.; alien.cross_span=expected_speed(s,planet)*lerpf(1.35,.75,planet/9.)
		alien.cross_direction=-1. if rng.randf()<.5 else 1.
		alien.warning_distance=expected_speed(s,planet)*lerpf(2.5,1.6,planet/9.)
		alien.surprise=true; result.append(alien)
		candidates=candidates.filter(func(value):return absf(value-s)>expected_speed(s,planet)*lerpf(2.4,1.6,planet/9.))
		extra_count-=1
	# One crossing is one encounter. No five-metre duplicate couriers.
	result.sort_custom(func(a,b): return a.s < b.s)
	return result

static func expected_speed(s:float,planet:int) -> float:
	return lerpf(13.,18.5,clampf(s/length_for(planet),0,1))*speed_scale(planet)

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
		var approach_s:float=s-challenge.length*.5 if pattern=="passage" and not challenge.is_empty() else s
		for offset in [-14.0,-10.0,-6.0]: add_star(result,approach_s+offset,lane,1.0,1,challenge)
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
			if challenge.is_empty(): continue
			for offset in range(-18,20,2):
				add_star(result,challenge.s+offset,lane,Basement.FLOOR+(.65 if abs(offset+6)<3 or abs(offset-9)<3 else 1.0),2,challenge,"basement")

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
	# Deliberate recovery stretches still have a readable trail to follow.
	# Do not fill them with another danger or lay rewards into a blocked lane.
	for s in range(240,2021,7):
		if front_at(s)>.05: continue
		var near_star:=false
		for pickup:Dictionary in result:
			if absf(pickup.s-s)<15.: near_star=true; break
		if near_star: continue
		var safe_lane:=-1
		for candidate_lane in lanes_at(s,planet):
			var safe:=true
			for obstacle:Dictionary in obstacles:
				var gap:float=absf(obstacle.s-s)
				if obstacle.kind=="alien" and gap<obstacle.get("cross_span",30.): safe=false; break
				if obstacle.lane==candidate_lane and gap<obstacle.length*.5+12.: safe=false; break
			if safe: safe_lane=candidate_lane; break
		if safe_lane>=0: add_star(result,float(s),safe_lane)
	result.sort_custom(func(a,b): return a.s < b.s)
	return result

static func top_of(kind: String) -> float:
	return float({"barrier":1.0,"arch":2.6,"wall":2.9,"plant":2.9,"leaf":3.0,"truck":3.0,"traffic":3.0,"broken":2.5,"carrier":1.48,"gardener":1.8,"alien":1.4,"cargo":3.0}.get(kind,0))

static func walkable_top(kind: String) -> float:
	return top_of(kind) if kind in ["carrier","cargo"] else 3.6 if kind=="passage" else -1.0

static func event_deck(event:Dictionary) -> float:
	return float(event.top) if event.kind=="skycarrier" else walkable_top(event.kind)

static func vehicle_deck(event:Dictionary,rel:float) -> float:
	if event.kind in ["truck","traffic","broken"] and absf(rel)<=event.length*.5:
		var deck:float=1.86 if rel< -2.25 else 2.94 if rel<=-.56 else 1.1
		return deck*(.82 if event.kind=="broken" else 1.)
	return -1.

static func step_height(event:Dictionary, rel:float) -> float:
	var count:int=maxi(1,ceili(event.top/.185))
	var phase:float=clampf((rel+event.length*.5)/event.length,0,.99999)
	var step:int=mini(count,int(phase*count)+1)
	return event.top*float(step if event.kind=="stairs" else count-step+1)/count

static func event_x(event: Dictionary, distance: float) -> float:
	if event.kind == "alien":
		var span:float=event.get("cross_span",30.)
		return lerpf(-4.2,4.2,smoothstep(-span,span,distance-event.s+float(event.get("cross_offset",0))))*float(event.get("cross_direction",1.))
	var target: float = (event.lane-1)*LANE_WIDTH
	if event.kind not in ["gardener","traffic"]: return target
	return lerpf((event.source_lane-1)*LANE_WIDTH,target,smoothstep(-38,-18,distance-event.s))
