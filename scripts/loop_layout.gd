extends RefCounted
## Optional branches build from reusable vertical, side and spiral modules.
static var route_seed := 0
static func kinds(world:int) -> Array:
	if world==10:return ["jet","board","double","spiral","double_board","triple_board","triple"]
	if world>=8:return ["jet","board","double","side_combo","spiral"]
	if world>=5:return ["jet","board","double","side_combo"]
	if world>=2:return ["jet","board","double"]
	return ["jet","training_side"] if world==0 else ["jet","board"]
static func start(kind:String) -> float:
	var base:float={"jet":400.,"board":1400.,"double":2000.,"spiral":2850.,"double_board":3400.,"triple_board":3900.,"triple":4400.,"side_combo":2490.,"training_side":1560.}.get(kind,2850.)
	if absi(route_seed)<=3:
		return base
	var step:=posmod(hash(Vector2i(route_seed,int(base))),9)-4
	return base+float(step)*(5. if kind=="jet" else 7.)
static func turns(kind:String) -> int:return 3 if kind.begins_with("triple") else 2 if kind.begins_with("double") or kind=="side_combo" else 1
static func board(kind:String) -> bool:return kind in ["board","side_combo","training_side"] or kind.ends_with("_board")
static func clearance(kind:String) -> AABB:
	return AABB(Vector3(-29.,-.3,-start(kind)-80.),Vector3(66.,55.,100.))
static func bounds(node:Node3D,transform_value:Transform3D) -> AABB:
	var result:=AABB(); var found:=false
	if node is MeshInstance3D and node.mesh: result=transform_value*node.mesh.get_aabb(); found=true
	if node is MultiMeshInstance3D and node.multimesh: result=transform_value*node.get_aabb(); found=true
	for child in node.get_children():
		if not child is Node3D: continue
		var box:=bounds(child,transform_value*child.transform)
		if not box.has_volume(): continue
		result=result.merge(box) if found else box; found=true
	return result
static func clear_landscape(root:Node3D,world:int,index:int) -> void:
	for child:Node3D in root.get_children():
		if child.name in ["WindGrass","PlanetEcosystem"]: continue
		var box:=bounds(child,Transform3D(Basis.IDENTITY,Vector3(0,0,-index*30.))*child.transform)
		if box.size.y<.5: continue
		for kind:String in kinds(world):
			if clearance(kind).intersects(box): root.remove_child(child); child.free(); break
