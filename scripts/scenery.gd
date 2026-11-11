extends Node3D
const G = preload("res://scripts/geometry.gd")
const Course = preload("res://scripts/course.gd")
const Planets = preload("res://scripts/planets.gd")
const Props = preload("res://scripts/props.gd")
const SurfaceStyle=preload("res://scripts/surface_style.gd")
const LoopLayout=preload("res://scripts/loop_layout.gd")
var planet := 0
var district_clearings:Array[AABB]=[]
var chunks: Dictionary = {}
var anims: Array[Node3D] = []
var decorations := 0
var holes:Array[Dictionary]=[]
var prepared:Dictionary={}
var retired:Array[Node3D]=[]
var prepare_queue:Array[int]=[]
func _exit_tree() -> void:
	for chunk in prepared.values(): SceneDisposal.retire(chunk)
	prepared.clear()

func prepare_course() -> void:
	prepare_queue.clear()
	if not preload("res://scripts/mobile_render.gd").enabled(): return
	for index in range(-2,ceili(Course.length_for(planet)/30.)+6):
		if not chunks.has(index) and not prepared.has(index): prepare_queue.append(index)

func warm_next() -> void:
	if prepare_queue.is_empty(): return
	var index:int=prepare_queue.pop_front()
	if not chunks.has(index) and not prepared.has(index): prepared[index]=make_chunk(index,false)

func prepare_all() -> void:
	while not prepare_queue.is_empty(): warm_next()

func reserve_districts(launch:Node3D,plaza:Node3D) -> void:
	district_clearings.clear()
	var finish_offset:=Vector3.BACK*Course.length_for(planet)
	for district in [launch,plaza]:
		var offset:=Transform3D(Basis.IDENTITY,-finish_offset if district==plaza else Vector3.ZERO)
		for landmark:Node3D in district.get_children():
			district_clearings.append(LoopLayout.bounds(landmark,offset*landmark.transform).grow(.75))
	# A promenade behind the monument links both sides of the plaza.
	district_clearings.append(AABB(Vector3(-42,-1,-47)-finish_offset,Vector3(84,20,4)))

func chunk_clearings(index:int) -> Array[AABB]:
	var result:Array[AABB]=[]
	var front:float=-index*30.
	for clearing in district_clearings:
		if clearing.position.z<front and clearing.end.z>front-30.:
			result.append(AABB(clearing.position-Vector3.BACK*front,clearing.size))
	return result

func configure_openings(events:Array) -> void:
	holes.clear()
	for event:Dictionary in events:
		if event.kind!="basement": continue
		for span:Vector2 in preload("res://scripts/basement.gd").openings(event):
			holes.append({"start":span.x,"end":span.y,"x":(event.lane-1)*2.6})

func slab(root:Node3D,index:int,size:Vector3,at:Vector3,color:String,mat:Material=null,role:String="") -> void:
	var cuts:Array[Dictionary]=[]; var edges:Array[float]=[0.,30.]
	for hole in holes:
		if hole.end<=index*30 or hole.start>=index*30+30: continue
		cuts.append(hole); edges.append(clampf(hole.start-index*30,0,30)); edges.append(clampf(hole.end-index*30,0,30))
	edges.sort()
	for i in edges.size()-1:
		var begin:float=edges[i]; var end:float=edges[i+1]
		if end-begin<.001: continue
		var left:float=at.x-size.x*.5; var right:float=at.x+size.x*.5
		var xs:Array[float]=[left,right]
		var active:Array[Dictionary]=[]
		for hole in cuts:
			if index*30+(begin+end)*.5>hole.start and index*30+(begin+end)*.5<hole.end:
				active.append(hole); xs.append(clampf(hole.x-1.20,left,right)); xs.append(clampf(hole.x+1.20,left,right))
		xs.sort()
		for col in xs.size()-1:
			var x1:float=xs[col]; var x2:float=xs[col+1]
			if x2-x1<.001: continue
			var open:=false
			for hole in active:
				if absf((x1+x2)*.5-hole.x)<1.2: open=true
			if open: continue
			var mesh:=G.box(root,Vector3(x2-x1,size.y,end-begin),Vector3((x1+x2)*.5,at.y,-(begin+end)*.5),color)
			# Continuous, thin ground slabs receive object shadows but must not
			# shadow themselves: low-angle sunlight otherwise creates moving acne.
			mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if mat: mesh.material_override=mat
			if not role.is_empty(): mesh.set_meta("surface_role",role)

func sync(distance: float, dt: float, clock: float) -> void:
	SurfaceStyle.animate_edges(distance,clock,Profile.reduced_motion)
	var first := int(floor((distance - 42.0) / 30.0))
	var last := int(floor((distance + 155.0) / 30.0))
	for key in chunks.keys():
		if key < first or key > last:
			if preload("res://scripts/mobile_render.gd").enabled(): chunks[key].hide(); retired.append(chunks[key])
			else: chunks[key].queue_free()
			chunks.erase(key)
	for index in range(first, last + 1):
		if not chunks.has(index):
			if prepared.has(index):
				chunks[index]=prepared[index]; prepared.erase(index); add_child(chunks[index])
			else: chunks[index] = make_chunk(index)
		chunks[index].position.z = distance - index * 30.0
	for item in anims:
		if not is_instance_valid(item) or item.is_queued_for_deletion() or not item.is_inside_tree() or not item.is_visible_in_tree(): continue
		match item.get_meta("motion", ""):
			"radar": item.rotation.y += dt * 0.45
			"flower":
				for petal in item.get_children():
					if str(petal.name).begins_with("Petal"): petal.rotation.x = sin(clock*1.2)*0.14
			"watering": item.rotation.z = sin(clock*2.0)*0.17
			_: item.rotation.z = sin(clock * 1.6 + item.get_meta("phase", 0.0)) * 0.035
	if anims.size() > 100 and not preload("res://scripts/mobile_render.gd").enabled():
		anims = anims.filter(func(n): return is_instance_valid(n) and not n.is_queued_for_deletion())

func clear() -> void:
	for chunk in chunks.values(): SceneDisposal.retire(chunk)
	for chunk in prepared.values(): SceneDisposal.retire(chunk)
	for chunk in retired: SceneDisposal.retire(chunk)
	chunks.clear()
	prepared.clear(); retired.clear(); prepare_queue.clear()
	anims.clear()

func make_chunk(index: int,attach:bool=true) -> Node3D:
	var root := Node3D.new()
	if attach: add_child(root)
	root.name = "Aurora_%d" % index
	root.position.z = -index * 30.0
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(index * 7919 + 67)
	var mid := index * 30.0 + 15.0
	var lanes := Course.lanes_at(mid, planet)
	var road_center := -1.3 if lanes.size() == 2 else 0.0
	var width := lanes.size() * 2.6 + 0.3
	slab(root,index,Vector3(128,.65,30),Vector3(0,-.55,-15),"7061a6",SurfaceStyle.ground(planet),"ground")
	slab(root,index,Vector3(width+.8,.3,30),Vector3(road_center,-.15,-15),"373b69")
	slab(root,index,Vector3(width,.05,30),Vector3(road_center,.025,-15),"35365b",SurfaceStyle.road(planet,lanes.size()),"road")
	for side in [-1.0, 1.0]:
		# The animated light is inset into the top of the existing curb.
		var led:=G.box(root, Vector3(0.16, 0.018, 30), Vector3(road_center + side * (width * 0.5 + 0.4), 0.066, -15), "7cf3e4", 0.6)
		led.material_override=SurfaceStyle.edge(planet)
		led.set_meta("road_edge_led",true)
		G.box(root, Vector3(0.24, 0.12, 30), Vector3(road_center + side * (width * 0.5 + 0.4), 0.0, -15), "927ccd")
	for lane in lanes:
		var x: float = (lane - 1) * 2.6
		for i in 5:
			G.box(root, Vector3(0.045, 0.025, 1.4), Vector3(x - 1.28, 0.065, -3 - i * 6), "9293bc", 0.1)
			var over_hole:=false
			for hole in holes:
				if absf(x-hole.x)<1.2 and index*30+3+i*6>hole.start and index*30+3+i*6<hole.end: over_hole=true
			if not over_hole: G.box(root, Vector3(0.48, 0.015, 0.045), Vector3(x, 0.06, -3 - i * 6), "53567d")
	G.batch(root)
	var landscape:Node3D
	var clearings:=chunk_clearings(index)
	var data=preload("res://scripts/planet_cache.gd").scenery.get(planet)
	if planet not in [0,1]:
		landscape=Node3D.new();landscape.name="NativeBiome"
		preload("res://scripts/biome_landscape.gd").populate(landscape,planet,index,Profile.quality,clearings)
	elif data and index>=-2:
		landscape=data.chunks[posmod(index+2,data.chunks.size())].instantiate()
		for item:Node3D in landscape.find_children("*","Node3D",true,false):
			if item.has_meta("motion"): anims.append(item)
			if item is MultiMeshInstance3D and item.name=="WindGrass": item.multimesh.visible_instance_count=320 if Profile.quality else 180
	else: landscape=make_landscape(index)
	root.add_child(landscape)
	if planet==0:preload("res://scripts/biome_landscape.gd").populate(landscape,planet,index,Profile.quality,clearings)
	LoopLayout.clear_landscape(landscape,planet,index)
	if planet in [0,1]:preload("res://scripts/roadside_biology.gd").populate(root,planet,index,Profile.quality)
	for item:GeometryInstance3D in landscape.find_children("*","GeometryInstance3D",true,false):
		var mat:=item.material_override as ShaderMaterial
		if mat and mat.shader.resource_path.ends_with("natural_ground.gdshader"):
			item.material_override=SurfaceStyle.ground(planet,true)
		if mat and mat.shader.resource_path.ends_with("living_foliage.gdshader"):
			# Tiny animated leaf shadows alias badly on the mobile shadow map.
			# Trunks and large solid flora retain their regular shadows.
			item.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			preload("res://scripts/natural_flora.gd").mats["cached/"+str(mat.get_instance_id())]=mat
			mat.set_shader_parameter("wind",0. if Profile.reduced_motion else 1.)
	return root

func make_landscape(index:int) -> Node3D:
	var root:=Node3D.new(); root.name="NaturalLandscape"
	var rng:=RandomNumberGenerator.new(); rng.seed=absi(index*7919+67)
	var mid:float=index*30.+15.
	preload("res://scripts/natural_landmarks.gd").populate(root,planet,index)
	var theme := (index / 3) % 3
	if Planets.biome(planet) == 1: theme = 0 if theme != 1 else 1
	if Planets.biome(planet) == 3: theme = 2 if index % 4 != 0 else 1
	for side in [-1.0, 1.0]:
		var x: float = side * rng.randf_range(9.0, 13.0)
		var z := rng.randf_range(-24, -6)
		if (index + int(side)) % 4 != 0:
			plant(root, Vector3(x, -.2, z), rng, index)
		for i in 3:
			crystal(root, Vector3(side * rng.randf_range(5.6, 8), -0.2, -i * 10 - 3), rng.randf_range(0.5, 1.3), "bf80ee" if i % 2 else "57dace")
		if absf(mid-Course.length_for(planet))>100:
			var hill := G.ball(root, Vector3(rng.randf_range(14, 24), rng.randf_range(10, 22), 20), Vector3(side * rng.randf_range(28, 43), -1, -15), "9881c7" if index % 2 else "7d7db7")
			hill.material_override=SurfaceStyle.ground(planet,true)
			hill.rotation.z = side * 0.2
		if index % 3 == 0:
			plant(root, Vector3(side * 19, 0, -20), rng, index + 4)
	if Planets.biome(planet) == 1 and index % 3 == 1:
		var bloom:=Node3D.new(); root.add_child(bloom); bloom.position=Vector3(-13,0,-15)
		for i in 9: preload("res://scripts/city_garden.gd").flower(bloom,Vector3((i%3-1)*.65,0,(int(i/3)-1)*.65),i)
		bloom.set_meta("motion","plant")
		anims.append(bloom)
		var alien := Props.alien()
		root.add_child(alien)
		alien.position = Vector3(-9.5,0,-15)
		var can := Node3D.new()
		alien.add_child(can)
		can.position = Vector3(-0.7,0.65,0)
		G.tube(can,0.22,0.45,Vector3.ZERO,"92d7ee")
		G.link(can,Vector3.ZERO,Vector3(-0.7,0.1,0),0.07,"92d7ee")
		for i in 4: G.ball(can,Vector3.ONE*0.055,Vector3(-0.7-i*0.06,0.1-i*0.13,0),"a1f4ef",0.2)
		can.set_meta("motion","watering")
		anims.append(can)
	preload("res://scripts/natural_flora.gd").grass(root,planet,index)
	G.recolor(root,Planets.get_data(planet).palette)
	preload("res://scripts/loop_layout.gd").clear_landscape(root,planet,index)
	G.batch(root)
	return root

func crystal(root: Node3D, at: Vector3, size: float, color: String) -> void:
	var p := Node3D.new()
	root.add_child(p)
	p.position = at
	p.rotation.z = sin(at.z) * 0.2
	G.tube(p, size * 0.38, size * 1.9, Vector3(0, size * 0.9, 0), color, 0)
	G.tube(p, size * 0.27, size, Vector3(size * 0.4, size * 0.4, 0.2), color, 0)
	G.ring(p, size * 0.28, size * 0.33, Vector3(0, size * 0.3, 0), "e7b6ff", 0.25)

func plant(root:Node3D,at:Vector3,rng:RandomNumberGenerator,phase:int) -> void:
	var crown:=preload("res://scripts/natural_flora.gd").tree(root,at,planet,phase*7919+rng.randi_range(0,100))
	anims.append(crown)
	var boxes:Array=root.get_meta("solid_nature_boxes",[]); boxes.append(AABB(at-Vector3(.22,0,.22),Vector3(.44,3.3,.44))); root.set_meta("solid_nature_boxes",boxes)

func station(root: Node3D, at: Vector3, side: float) -> void:
	var p := Node3D.new()
	root.add_child(p)
	p.position = at
	p.rotation.y = -side * PI * 0.5
	G.box(p, Vector3(4.8, 0.4, 4.0), Vector3(0, 0.2, 0), "4b4c7e")
	G.ball(p, Vector3(4.9, 3.1, 3.8), Vector3(0, 1.8, 0), "e2c9eb")
	G.box(p, Vector3(4.3, 0.2, 3.4), Vector3(0, 1.25, 0), "ff9bb7")
	G.box(p, Vector3(1.8, 1.15, 0.09), Vector3(0, 1.9, 1.85), "37577d")
	G.box(p, Vector3(1.5, 0.1, 0.11), Vector3(0, 2.3, 1.91), "6ff8de", 0.8)
	G.tube(p, 0.065, 2.2, Vector3(1.4, 3.4, 0), "f6d5ef")
	var radar := Node3D.new()
	p.add_child(radar)
	radar.position = Vector3(1.4, 4.5, 0)
	var dish := G.ball(radar, Vector3(1.3, 0.25, 1.3), Vector3.ZERO, "64f1d9")
	dish.rotation.z = 0.6
	radar.set_meta("motion", "radar")
	anims.append(radar)
	G.batch(radar)
	for i in 3:
		G.box(p, Vector3(0.9, 0.75, 0.9), Vector3(3.0, 0.4, i * 1.1 - 1.1), "9296c2")

func tower(root: Node3D, at: Vector3, rng: RandomNumberGenerator, side: float) -> void:
	var p := Node3D.new()
	root.add_child(p)
	p.position = at
	var h := rng.randf_range(5.5, 10)
	G.box(p, Vector3(4.5, h, 4.4), Vector3(0, h * 0.5, 0), "625087").material_override=preload("res://scripts/finish_city.gd").coating("Dark",planet)
	G.box(p, Vector3(4.9, 0.4, 4.8), Vector3(0, h, 0), "d684bb")
	for row in range(2, int(h),2):
		G.box(p, Vector3(4.55, 0.07, 4.45), Vector3(0, row+.7, 0), "a6d9df", 0.10)
	var bays:=Node3D.new(); p.add_child(bays); bays.position=Vector3(-side*3.23,0,0); bays.rotation.y=-side*PI*.5; bays.scale=Vector3.ONE*.5
	for floor in range(2,int(h),2):
		for col in 3: preload("res://scripts/city_windows.gd").window(bays,Vector3((col-1)*2.5,floor*2,0),rng.randf()>.3,planet)
	var sign_node := G.box(p, Vector3(0.12, 1.8, 2.6), Vector3(-side * 2.4, h * 0.62, 0), "56cabd", 0.2)
	G.box(p, Vector3(0.13, 0.18, 1.6), sign_node.position + Vector3(-side * 0.03, 0.3, 0), "d9ffef", 0.3)
