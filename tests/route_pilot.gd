extends RefCounted
## Reward-route QA driver. Uses only normal lane, jump and slide input.
const Course = preload("res://scripts/course.gd")

static func drive(app: Node) -> void:
	if Course.transitioning(app.distance): return
	if app.events.is_empty(): return
	if not app.events[0].get("pilot_prepared",false):
		var prepared: Array = []
		for packet in Course.encounters(app.planet):
			var item := {"s":packet.s,"lane":packet.lane,"center":{},"roof":{}}
			for e: Dictionary in app.events:
				if int(e.get("encounter",-1)) != packet.id: continue
				if e.get("role","") == "challenge": item.center=e
				if e.kind == "carrier": item.roof=e
			prepared.append(item)
		app.set_meta("qa_route_packets",prepared)
		app.events[0].pilot_prepared=true
	var desired := 1
	var next_center := INF
	for packet: Dictionary in app.get_meta("qa_route_packets"):
		var center: float = packet.center.s if not packet.center.is_empty() else packet.s
		var end := center+13.0
		if not packet.roof.is_empty(): end=maxf(end,packet.roof.s+7)
		if app.distance > end: continue
		desired = packet.lane
		next_center = center
		break
	for e: Dictionary in app.events:
		if e.done or e.kind not in ["jet","board"]: continue
		var gap: float = e.s-app.distance
		if gap > -1 and gap < 30 and e.s < next_center: desired = e.lane; break
	if app.booster == "jet":
		for p: Dictionary in app.pickups:
			if p.done or p.y < 3: continue
			if p.s > app.distance-0.5 and p.s < app.distance+28:
				desired = p.lane
				break
	if not Course.lanes_at(app.distance,app.planet).has(desired): desired = app.lane
	if app.lane != desired:
		var direction := 1 if desired > app.lane else -1
		app.move_screen(-direction if Course.front_at(app.distance)>0.5 else direction)
	for e: Dictionary in app.events:
		if e.done or e.lane != app.lane: continue
		var time_to: float = (e.s-app.distance)/maxf(1,app.speed-e.speed)
		if time_to > 0 and time_to < 0.5:
			if e.kind == "barrier": app.jump()
			elif e.kind == "arch": app.slide()
