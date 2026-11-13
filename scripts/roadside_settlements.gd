extends Node3D

const G = preload("res://scripts/geometry.gd")
const SM = preload("res://scripts/salvage_mesh.gd")
const Course = preload("res://scripts/course.gd")
const Loops = preload("res://scripts/loop_layout.gd")
const Planets = preload("res://scripts/planets.gd")
const Finishes = preload("res://scripts/salvage_materials.gd")
const SurfaceStyle = preload("res://scripts/surface_style.gd")
const PlantKit = preload("res://scripts/plant_kit.gd")
const SOURCES := [
	preload("res://assets/settlements/depot-b.glb"),
	preload("res://assets/settlements/depot-c.glb"),
	preload("res://assets/settlements/lander.glb"),
	preload("res://assets/settlements/roof-modules.glb"),
	preload("res://assets/settlements/turbine.glb"),
]
# The first pair supplies habitat silhouettes. The last pair supplies a utility.
const MIX := [
	[[0,1],[2,4]], [[1,0],[3,4]], [[0,2],[1,3]], [[1,0],[2,3]],
	[[0,2],[3,4]], [[1,0],[3,4]], [[1,2],[4,3]], [[0,1],[4,2]],
	[[1,0],[2,4]], [[2,1],[3,4]], [[0,1],[2,3]],
]
const SHELLS := ["98a9c6","b4c8b2","bb8d63","635c99","a5d7e0","d0b478","a991ad","cae0ec","85636b","a394c8","acc5d6"]
const CLADDING := [0,1,2,0,1,2,1,1,2,0,0]
const HABITAT_SCALE := 1.22
static var coatings: Dictionary = {}
var sites: Array[Dictionary] = []
var clearings: Array[AABB] = []
var world := -1
var last_seed := -1

func configure(planet: int, layout_seed: int, signs: PackedFloat32Array) -> void:
	if world == planet and last_seed == layout_seed:
		return
	for site in sites:
		site.node.queue_free()
		site.node.hide()
	sites.clear()
	clearings.clear()
	world = planet
	last_seed = layout_seed
	var rng := RandomNumberGenerator.new()
	rng.seed = layout_seed ^ (planet * 21737 + 8389)
	var positions := plan_positions(planet,rng,signs)
	var first_side := -1. if rng.randf() < .5 else 1.
	for i in positions.size():
		var s := positions[i]
		var side := first_side if i%2 == 0 else -first_side
		var x := side * rng.randf_range(12.0,15.5)
		var group := make_site(planet,x,rng)
		var footprint:=Loops.bounds(group,Transform3D.IDENTITY)
		if side>0.: x=maxf(x,6.-footprint.position.x)
		else: x=minf(x,-6.-footprint.end.x)
		group.position = Vector3(x,0,-s)
		group.hide()
		add_child(group)
		sites.append({"node":group,"s":s,"x":x})
		clearings.append((group.transform * Loops.bounds(group,Transform3D.IDENTITY)).grow(.8))

static func plan_positions(planet: int, rng: RandomNumberGenerator, signs: PackedFloat32Array) -> PackedFloat32Array:
	var total := Course.length_for(planet)
	var reserved: Array[Vector2] = [Vector2(792,1015),Vector2(1035,1510),Vector2(total*.5-54.,total*.5+54.)]
	for kind: String in Loops.kinds(planet):
		var box := Loops.clearance(kind)
		reserved.append(Vector2(-box.end.z-24.,-box.position.z+28.))
	for mark in signs:
		reserved.append(Vector2(mark-105.,mark+105.))
	var positions := PackedFloat32Array()
	var count := 3 if planet < 4 else 4
	for i in count:
		var target := (lerpf(.18,.84,float(i)/float(count-1)) + rng.randf_range(-.055,.055))*total
		var best := INF
		var score := INF
		for center in range(230,int(total)-165,15):
			var distance := absf(center-target)
			if distance >= score:
				continue
			if reserved.any(func(span:Vector2) -> bool: return center > span.x and center < span.y):
				continue
			score = distance
			best = center
		if best < INF:
			var picked := best+rng.randf_range(-4.,4.)
			positions.append(picked)
			reserved.append(Vector2(picked-275.,picked+275.))
	positions.sort()
	return positions

func make_site(planet: int, site_x: float, rng: RandomNumberGenerator) -> Node3D:
	var group := Node3D.new()
	group.name = "RemoteSettlement"
	var side := signf(site_x)
	var profile: Array = MIX[planet]
	var order := rng.randi_range(0,1)
	var floor_y := -.39
	if planet in [4,8]: floor_y = -.04
	var yaw := -side*.62
	place(group,profile[0][order],Vector3(side*.6,floor_y,5.4),rng.randf_range(5.6,7.5)*HABITAT_SCALE,yaw+rng.randf_range(-.30,.30),planet)
	place(group,profile[0][1-order],Vector3(side*4.1,floor_y,-5.5),rng.randf_range(4.7,6.3)*HABITAT_SCALE,yaw+1.4,planet)
	if rng.randf() < .78:
		var auxiliary: int = profile[1][rng.randi_range(0,1)]
		place(group,auxiliary,Vector3(side*8.7,floor_y,1.9),2.2 if auxiliary==4 else rng.randf_range(2.7,4.)*1.12,yaw,planet)
	var buildings: Array[Rect2] = []
	for holder: Node3D in group.get_children():
		var box := Loops.bounds(holder,holder.transform)
		buildings.append(Rect2(Vector2(box.position.x,box.position.z),Vector2(box.size.x,box.size.z)))
	G.merge_static(group)
	if planet in [4,8]: rocky_ground(group,planet,side,rng)
	PlantKit.populate_settlement(group,planet,site_x,rng,get_node("/root/Profile").quality,buildings)
	return group

static func rocky_ground(group: Node3D, planet: int, side: float, rng: RandomNumberGenerator) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center := Vector3(side*2.8,.22,-.7)
	var inner := PackedVector3Array()
	var outer := PackedVector3Array()
	for i in 13:
		var angle := TAU*float(i)/13.
		var radius := Vector2(12.5,16.9) if planet==4 else Vector2(11.,16.)
		var outline := Vector3(cos(angle)*radius.x,0,sin(angle)*radius.y)
		var edge := rng.randf_range(.86,1.14)
		var shelf := center+outline*.80+Vector3.DOWN*rng.randf_range(.01,.10)
		var shore := center+outline*edge+Vector3.DOWN*rng.randf_range(.60,.76)
		shelf.x = side*maxf(side*shelf.x,-8.7)
		shore.x = side*maxf(side*shore.x,-9.1)
		inner.append(shelf)
		outer.append(shore)
	for i in inner.size():
		var next := (i+1)%inner.size()
		SM._triangle(tool,center,inner[i],inner[next])
		SM._triangle(tool,inner[i],outer[i],outer[next])
		SM._triangle(tool,inner[i],outer[next],inner[next])
	var ground := G.part(group,tool.commit(),Vector3.ZERO,SurfaceStyle.ground(planet,true))
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

static func place(group: Node3D, key: int, at: Vector3, width: float, yaw: float, planet: int) -> void:
	var model: Node3D = SOURCES[key].instantiate()
	if key == 3:
		for piece: Node3D in model.get_children():
			if not String(piece.name).contains("roofmodule_solarpanels"): piece.free()
	var bounds := Loops.bounds(model,Transform3D.IDENTITY)
	var factor := width/maxf(.01,bounds.size.x)
	if key==4:
		factor = minf(factor,7.5/maxf(.01,bounds.size.y))
	var holder := Node3D.new()
	group.add_child(holder)
	holder.position = at
	holder.rotation.y = yaw
	holder.add_child(model)
	model.scale = Vector3.ONE*factor
	model.position = -Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*factor
	for piece: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		var source := piece.mesh.surface_get_material(0) as StandardMaterial3D
		if source and source.albedo_texture:
			piece.material_override = coating(planet,source.albedo_texture)
		piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

static func coating(planet: int, atlas: Texture2D) -> ShaderMaterial:
	if coatings.has(planet):
		return coatings[planet]
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://assets/settlements/coating.gdshader")
	mat.set_shader_parameter("atlas",atlas)
	mat.set_shader_parameter("cladding",load(Finishes.texture_path(Finishes.HULLS[CLADDING[planet]])))
	mat.set_shader_parameter("shell",Color(SHELLS[planet]))
	mat.set_shader_parameter("trim",Color(Planets.get_data(planet).accent))
	mat.set_shader_parameter("world",planet)
	coatings[planet] = mat
	return mat

func advance(running: bool, distance_value: float, track:RefCounted=null) -> void:
	for site in sites:
		var z: float = distance_value - site.s
		var local:=Vector3(site.x,0,z)
		site.node.position=(track.map_ground(local,true) if world==4 else track.map(local)) if track else local
		site.node.rotation.y=track.heading(site.s) if track else 0.
		site.node.visible = running and z > -228. and z < 34.
