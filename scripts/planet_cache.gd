extends RefCounted
static var finishes:Dictionary={}
static var scenery:Dictionary={}
static var requested:Dictionary={}
static func paths(world:int) -> Array[String]:
	return ["res://assets/planet_cache/finish_%d.scn"%world,"res://assets/planet_cache/landscape_%d.res"%world]
static func request(world:int) -> void:
	if DisplayServer.get_name()=="headless":
		var list:=paths(world)
		if not finishes.has(world) and ResourceLoader.exists(list[0]): finishes[world]=load(list[0])
		if not scenery.has(world) and ResourceLoader.exists(list[1]): scenery[world]=load(list[1])
		return
	for path:String in paths(world):
		if requested.has(path) or not ResourceLoader.exists(path): continue
		requested[path]=true
		ResourceLoader.load_threaded_request(path)
static func ready(world:int) -> bool:
	var list:=paths(world)
	for i in 2:
		if (finishes if i==0 else scenery).has(world): continue
		var path:String=list[i]
		if not ResourceLoader.exists(path): continue
		if ResourceLoader.load_threaded_get_status(path)!=ResourceLoader.THREAD_LOAD_LOADED: return false
	return true
static func collect(world:int) -> void:
	var list:=paths(world)
	if not finishes.has(world) and ResourceLoader.exists(list[0]): finishes[world]=ResourceLoader.load_threaded_get(list[0])
	if not scenery.has(world) and ResourceLoader.exists(list[1]): scenery[world]=ResourceLoader.load_threaded_get(list[1])
static func poll() -> void:
	for path:String in requested:
		var world:int=path.get_file().get_basename().get_slice("_",1).to_int()
		var destination:Dictionary=finishes if path.contains("/finish_") else scenery
		if destination.has(world): continue
		if ResourceLoader.load_threaded_get_status(path)==ResourceLoader.THREAD_LOAD_LOADED: destination[world]=ResourceLoader.load_threaded_get(path)
static func finish_pending() -> void:
	for path:String in requested:
		var world:int=path.get_file().get_basename().get_slice("_",1).to_int()
		var destination:Dictionary=finishes if path.contains("/finish_") else scenery
		if not destination.has(world): destination[world]=ResourceLoader.load_threaded_get(path)
