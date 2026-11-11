extends Node3D

const G = preload("res://scripts/geometry.gd")
const SM = preload("res://scripts/salvage_mesh.gd")
const Jet = preload("res://scripts/jetpack_fx.gd")
const Transport = preload("res://scripts/hover_transport.gd")
const Finish = preload("res://assets/spaceflight/ships/hull.gdshader")
const Glass = preload("res://assets/spaceflight/canopy.gdshader")
const MODELS = [
	preload("res://assets/spaceflight/ships/kestrel.glb"),
	preload("res://assets/spaceflight/ships/flamingo.glb"),
	preload("res://assets/spaceflight/ships/bee.glb"),
	preload("res://assets/spaceflight/ships/panda.glb"),
]
const SKINS = [
	preload("res://assets/salvage/hull-ceramic-v1.png"),
	preload("res://assets/salvage/hull-titanium-v1.png"),
	preload("res://assets/salvage/hull-salvage-v1.png"),
	preload("res://assets/salvage/hull-titanium-v1.png"),
]
# Native cockpit center, fitted width/height/length, paint, accent and aft nozzle positions.
const FLEET = [
	{"id":"kestrel","cockpit":-2.35,"size":Vector3(7.5,1.35,8.8),"paint":"e2edf6","accent":"31cfd0","nozzle":Vector3(.82,.60,2.39),"radius":.33},
	{"id":"flamingo","cockpit":-.90,"size":Vector3(8.8,1.45,9.0),"paint":"bbc8ff","accent":"ee5599","nozzle":Vector3(1.05,.72,2.42),"radius":.37},
	{"id":"bee","cockpit":.59,"size":Vector3(7.0,1.58,7.1),"paint":"e3ca83","accent":"ffc22d","nozzle":Vector3(.74,.84,3.35),"radius":.44},
	{"id":"panda","cockpit":-.64,"size":Vector3(8.2,1.50,9.5),"paint":"a0b4cb","accent":"ff8246","nozzle":Vector3(.86,.56,3.07),"radius":.39},
]
const SILL := 1.21
const CANOPY_RADIUS := Vector3(1.57,2.48,2.31)
const SEAT := Vector3(0.,1.12,.38)
const PILOT_SCALE := .88
static var canopy_mesh: ArrayMesh
static var footwell_mesh: ArrayMesh
static var finishes: Dictionary = {}

var pilot: Node3D
var cockpit_light: OmniLight3D
var exhaust: Node3D
var canopy_hinge: Node3D
var body: Node3D
var variant := -1

static func create(kind: int = -1) -> Node3D:
	var root := Node3D.new()
	root.set_script(load("res://scripts/space_ship.gd"))
	root.name = "CabinSpaceship"
	root.configure(kind)
	return root

static func center_asset(model: Node3D) -> void:
	var bounds := mesh_bounds(model,model.find_children("*","MeshInstance3D",true,false))
	model.position = -Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*model.scale

static func mesh_bounds(model: Node3D, pieces: Array[Node]) -> AABB:
	var bounds := AABB()
	for piece: MeshInstance3D in pieces:
		var local := Transform3D.IDENTITY
		var part: Node3D = piece
		while part != model:
			local = part.transform * local
			part = part.get_parent()
		var box := local * piece.mesh.get_aabb()
		bounds = box if piece == pieces[0] else bounds.merge(box)
	return bounds

func configure(kind: int) -> void:
	var next := posmod(maxi(0,kind),MODELS.size())
	if next == variant:
		return
	var opening := canopy_hinge.rotation.x if is_instance_valid(canopy_hinge) else 0.
	if is_instance_valid(body):
		body.free()
	variant = next
	body = Node3D.new()
	body.name = "ShipBody"
	add_child(body)
	var spec: Dictionary = FLEET[variant]
	add_hull(spec)
	add_cockpit(spec)
	add_engines(spec)
	canopy_hinge.rotation.x = opening
	set_meta("source_model",spec.id)
	set_meta("enclosed_cockpit",true)

func add_hull(spec: Dictionary) -> void:
	var hull: Node3D = MODELS[variant].instantiate()
	hull.name = "ImportedHull"
	body.add_child(hull)
	var pieces := hull.find_children("*","MeshInstance3D",true,false)
	if hull is MeshInstance3D:
		pieces.push_front(hull)
	var bounds := mesh_bounds(hull,pieces)
	var fit: Vector3 = spec.size / bounds.size
	hull.rotation.y = PI
	hull.scale = fit
	hull.position = Vector3(bounds.get_center().x*fit.x,.03-bounds.position.y*fit.y,float(spec.cockpit)*fit.z)
	for piece: MeshInstance3D in pieces:
		for surface in piece.mesh.get_surface_count():
			var original := piece.mesh.surface_get_material(surface) as BaseMaterial3D
			var atlas := original.albedo_texture if original else null
			var key := "%d/%s" % [variant,atlas.resource_path if atlas else "plain"]
			if not finishes.has(key):
				var paint := ShaderMaterial.new()
				paint.shader = Finish
				paint.set_shader_parameter("atlas",atlas)
				paint.set_shader_parameter("surface_map",SKINS[variant])
				paint.set_shader_parameter("paint",Color(spec.paint))
				paint.set_shader_parameter("accent",Color(spec.accent))
				paint.set_shader_parameter("pattern",variant)
				paint.set_shader_parameter("hull_scale",fit * piece.scale)
				finishes[key] = paint
			piece.set_surface_override_material(surface,finishes[key])

func add_cockpit(spec: Dictionary) -> void:
	var frame := Node3D.new()
	frame.name = "CockpitStructure"
	body.add_child(frame)
	var graphite := Transport.paint(variant,"frame")
	var alloy := Transport.paint(variant,"deck")
	var accent: String = spec.accent
	SM._part(frame,get_footwell_mesh(),graphite)
	for side in [-1.,1.]:
		var panel := SM.block(frame,Vector3(.115,.33,1.75),Vector3(side*1.29,1.03,-.38),alloy,.045)
		panel.rotation.y = side*.18
		SM._beam(frame,Vector3(side*1.36,1.09,.58),Vector3(side*1.14,1.09,-1.12),.025,G.material(accent,.42))
		G.box(frame,Vector3(.12,.05,.29),Vector3(side*1.36,1.16,.66),accent,.45)
	SM.block(frame,Vector3(1.18,.20,1.13),Vector3(0,.99,.51),graphite,.08)
	var back := SM.block(frame,Vector3(1.09,.94,.22),Vector3(0,1.47,1.01),graphite,.11)
	back.rotation.x = -.17
	SM.block(frame,Vector3(.88,.26,.28),Vector3(0,2.02,1.11),alloy,.09)
	var dash := SM.block(frame,Vector3(1.76,.23,.55),Vector3(0,1.23,-1.48),graphite,.07)
	dash.rotation.x = -.20
	for i in 3:
		var display := G.box(frame,Vector3(.38,.025,.29),Vector3((i-1)*.49,1.36,-1.48),accent,.30)
		display.rotation.x = -.20
	SM.batch(frame)

	canopy_hinge = Node3D.new()
	canopy_hinge.name = "CanopyHinge"
	canopy_hinge.position = Vector3(0,SILL,CANOPY_RADIUS.z)
	body.add_child(canopy_hinge)
	var glass := ShaderMaterial.new()
	glass.shader = Glass
	glass.render_priority = 4
	glass.set_shader_parameter("tint",Color("a4eaf7").lerp(Color(accent),.24))
	var shell := G.part(canopy_hinge,get_canopy_mesh(),-canopy_hinge.position,glass)
	shell.name = "Canopy"
	shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var rim := Node3D.new()
	rim.position = -canopy_hinge.position
	canopy_hinge.add_child(rim)
	for col in 32:
		var from := canopy_point(0.,col*TAU/32.)
		var to := canopy_point(0.,(col+1)*TAU/32.)
		G.link(rim,from,to,.034,spec.paint)
	# Rear ribs leave the windshield unobstructed.
	for side in [-1.,1.]:
		for row in 8:
			var angle: float = PI*.5+side*.58
			G.link(rim,canopy_point(row*PI/20.,angle),canopy_point((row+1)*PI/20.,angle),.032,spec.paint)
	SM.batch(rim)

static func canopy_point(lat: float, angle: float) -> Vector3:
	return Vector3(cos(angle)*cos(lat),sin(lat),sin(angle)*cos(lat))*CANOPY_RADIUS + Vector3.UP*SILL

static func get_footwell_mesh() -> ArrayMesh:
	if footwell_mesh:
		return footwell_mesh
	# Closed underside and inside walls, with a continuous rim following the glass.
	var sections := [
		Vector3(.74,.12,.70),Vector3(.95,.35,.97),Vector3(1.,SILL,1.),
		Vector3(.91,SILL,.93),Vector3(.68,.34,.68),
	]
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for col in 32:
		var a := canopy_point(0.,col*TAU/32.) - Vector3.UP*SILL
		var b := canopy_point(0.,(col+1)*TAU/32.) - Vector3.UP*SILL
		for row in sections.size()-1:
			var lower: Vector3 = sections[row]
			var upper: Vector3 = sections[row+1]
			var p := a*lower + Vector3.UP*lower.y
			var q := b*lower + Vector3.UP*lower.y
			var r := b*upper + Vector3.UP*upper.y
			var s := a*upper + Vector3.UP*upper.y
			SM._triangle(tool,p,q,r)
			SM._triangle(tool,p,r,s)
		var bottom: Vector3 = sections.front()
		var floor: Vector3 = sections.back()
		SM._triangle(tool,a*bottom+Vector3.UP*bottom.y,Vector3.UP*bottom.y,b*bottom+Vector3.UP*bottom.y)
		SM._triangle(tool,a*floor+Vector3.UP*floor.y,b*floor+Vector3.UP*floor.y,Vector3.UP*floor.y)
	footwell_mesh = tool.commit()
	return footwell_mesh

static func get_canopy_mesh() -> ArrayMesh:
	if canopy_mesh:
		return canopy_mesh
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in 10:
		var a := row*PI/20.
		var b := (row+1)*PI/20.
		for col in 32:
			var c := col*TAU/32.
			var d := (col+1)*TAU/32.
			for point in [canopy_point(a,c),canopy_point(a,d),canopy_point(b,d),canopy_point(a,c),canopy_point(b,d),canopy_point(b,c)]:
				tool.set_normal(((point-Vector3.UP*SILL)/(CANOPY_RADIUS*CANOPY_RADIUS)).normalized())
				tool.add_vertex(point)
	canopy_mesh = tool.commit()
	return canopy_mesh

func add_engines(spec: Dictionary) -> void:
	var mounts := Node3D.new()
	mounts.name = "EngineNozzles"
	body.add_child(mounts)
	var nozzle: Vector3 = spec.nozzle
	var radius: float = spec.radius
	var frame := Transport.paint(variant,"frame")
	var alloy := Transport.paint(variant,"deck")
	var accent: String = spec.accent
	for side in [-1.,1.]:
		var center := Vector3(nozzle.x*side,nozzle.y,nozzle.z)
		SM._cylinder(mounts,radius,.65,center-Vector3.BACK*.25,frame,radius*1.20).rotation.x = PI*.5
		SM._cylinder(mounts,radius*1.14,.14,center,alloy).rotation.x = PI*.5
		G.ring(mounts,radius*.72,radius*.94,center+Vector3.BACK*.075,accent,.68).rotation.x = PI*.5
	SM.batch(mounts)
	exhaust = Jet.new()
	exhaust.name = "Engines"
	exhaust.set_meta("motion","engines")
	body.add_child(exhaust)
	exhaust.build()
	exhaust.rotation.x = -PI*.5
	exhaust.position = Vector3(0.,nozzle.y,nozzle.z+.08)
	for i in 2:
		exhaust.jets[i].position = Vector3(nozzle.x*(-1 if i == 0 else 1),0.,0.)
		exhaust.materials[i].set_shader_parameter("fire_mode",true)
		exhaust.lights[i].light_color = Color(accent)

func set_canopy(opening: float) -> void:
	canopy_hinge.rotation.x = clampf(opening,0.,1.)*1.15

func seat_pilot(hero: Node3D) -> void:
	if hero.get_parent() != self:
		if hero.get_parent():
			hero.reparent(self,false)
		else:
			add_child(hero)
	pilot = hero
	pilot.name = "SeatedPilot"
	pilot.position = Vector3.ZERO
	pilot.scale = Vector3.ONE*PILOT_SCALE
	pilot.rotation = Vector3(0.,PI,0.)
	pilot.animate(.15,"pilot")
	var hip := Vector3(0.,.8,0.)
	if is_instance_valid(pilot.crew_avatar):
		var crew: Node3D = pilot.crew_avatar
		crew.animation.play("crew/sit",0.)
		crew.animation.seek(0.,true)
		var skeleton: Skeleton3D = crew.skeleton
		skeleton.force_update_all_bone_transforms()
		var pelvis := skeleton.get_bone_global_pose(skeleton.find_bone("torso")).origin
		hip = pilot.to_local(skeleton.to_global(pelvis))
	pilot.position = SEAT-pilot.transform.basis*hip
	if not is_instance_valid(cockpit_light):
		cockpit_light = OmniLight3D.new()
		cockpit_light.name = "InstrumentFill"
		cockpit_light.position = Vector3(0.,2.12,-1.48)
		cockpit_light.omni_range = 2.9
		cockpit_light.light_color = Color("d5eeff")
		cockpit_light.light_energy = .78
		add_child(cockpit_light)
	set_meta("pilot_seated",true)

func make_pilot(girl: bool, loadout: Dictionary = {}, character_index: int = -1) -> Node3D:
	var hero: Node3D = load("res://scripts/hero.gd").new()
	add_child(hero)
	hero.build(girl,loadout,character_index)
	seat_pilot(hero)
	return hero

func advance(dt: float, boosting: bool = false) -> void:
	var seated := is_instance_valid(pilot) and pilot.visible
	if is_instance_valid(cockpit_light):
		cockpit_light.visible = seated
	if seated:
		pilot.animate(dt,"pilot")
	exhaust.advance(dt,true,1.6 if boosting else 1.)
	exhaust.scale.y = 2.1 if boosting else 1.5
