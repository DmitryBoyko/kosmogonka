extends RefCounted
## Conservative swept camera volume against the actual corridor shell slabs.
## Visual course meshes have no physics bodies: use the same dimensions here.
const MARGIN := .32
static func shells(events:Array,distance:float) -> Array[AABB]:
	var result:Array[AABB]=[]
	for e:Dictionary in events:
		if e.kind not in ["tunnel","passage"]: continue
		var rel:float=distance-e.s
		if absf(rel)>e.length*.5+35.: continue
		var cx:float=(e.lane-1)*2.6
		var floor_y:float=3.35 if e.kind=="tunnel" else 0.
		for side in [-1,1]:
			result.append(AABB(Vector3(cx+side*1.14-.09,floor_y,rel-e.length*.5),Vector3(.18,3.25,e.length)))
		result.append(AABB(Vector3(cx-1.225,floor_y+3.25,rel-e.length*.5),Vector3(2.45,.35,e.length)))
		if e.kind=="tunnel": result.append(AABB(Vector3(cx-1.06,floor_y-.18,rel-e.length*.5),Vector3(2.12,.18,e.length)))
	return result

static func clear_view(eye:Vector3,at:Vector3,boxes:Array[AABB]) -> bool:
	for box:AABB in boxes:
		if box.grow(MARGIN).intersects_segment(eye,at)!=null: return false
	return true

static func resolve(at:Vector3,hero:Vector3,boxes:Array[AABB]) -> Vector3:
	var eye:=hero+Vector3(0,1.65,0)
	if clear_view(eye,at,boxes): return at
	# Stay on the player's side, never the neighbouring lane's centreline.
	var aligned:=Vector3(hero.x,at.y,at.z)
	if clear_view(eye,aligned,boxes): return aligned
	# Passing below a suspended corridor needs a low camera, not its inside pose.
	var low:=Vector3(hero.x,hero.y+2.65,at.z)
	if clear_view(eye,low,boxes): return low
	# Shorten in one frame if necessary; smoothing through a wall is unsafe.
	var safe:=eye
	for i in range(1,25):
		var candidate:=eye.lerp(low,i/24.)
		if not clear_view(eye,candidate,boxes): break
		safe=candidate
	return safe if safe.distance_to(eye)>.2 else eye+Vector3(0,0,.2*signf(at.z))
