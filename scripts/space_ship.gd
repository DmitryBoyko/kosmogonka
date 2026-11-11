extends Node3D
const G=preload("res://scripts/geometry.gd")
const SM=preload("res://scripts/salvage_mesh.gd")
const Jet=preload("res://scripts/jetpack_fx.gd")
const KEYS=["craft-racer","craft-speedera","craft-speederb","craft-speederd"]
static var scenes:Dictionary={}
static var coatings:Dictionary={}
var pilot:Node3D
var exhaust:Node3D
var throttle:=1.0
var canopy_hinge:Node3D

static func create(kind:int=-1) -> Node3D:
	var root:=Node3D.new(); root.set_script(load("res://scripts/space_ship.gd")); root.build(kind); return root

static func coating(name_value:String,variant:int) -> Material:
	var key:=name_value+str(variant)
	if coatings.has(key): return coatings[key]
	var m:=ShaderMaterial.new(); m.shader=preload("res://assets/salvage/space_surface.gdshader")
	var hull_maps=[preload("res://assets/salvage/hull-titanium-v1.png"),preload("res://assets/salvage/hull-ceramic-v1.png"),preload("res://assets/salvage/hull-salvage-v1.png")]
	m.set_shader_parameter("surface_map",hull_maps[variant%3])
	var color:=Color("ced7dc")
	if name_value=="metalRed": color=Color(["50bfc5","e3ad66","b4b8da","c98291"][variant])
	elif name_value.to_lower().contains("dark"): color=Color("718ba1")
	m.set_shader_parameter("tint",color); m.set_shader_parameter("metalness",.45); m.set_shader_parameter("roughness",.48)
	m.set_shader_parameter("tile_scale",1.25); coatings[key]=m; return m

static func center_asset(model:Node3D) -> void:
	var bounds:=AABB(); var first:=true
	for piece:MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		var transform:=piece.transform; var parent:=piece.get_parent()
		while parent!=model: transform=(parent as Node3D).transform*transform; parent=parent.get_parent()
		var box:AABB=transform*piece.mesh.get_aabb(); bounds=box if first else bounds.merge(box); first=false
	model.position=-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*model.scale

func build(kind:int) -> void:
	name="CabinSpaceship"
	var variant:=posmod(kind+1,4); var key:String=KEYS[variant]
	if not scenes.has(key): scenes[key]=load("res://assets/spaceflight/"+key+".glb")
	var hull:Node3D=scenes[key].instantiate(); add_child(hull); hull.name="ImportedHull"; hull.scale=Vector3(3.8,1.4,4.)
	center_asset(hull)
	for piece:MeshInstance3D in hull.find_children("*","MeshInstance3D",true,false):
		for surface in piece.mesh.get_surface_count():
			var original:=piece.mesh.surface_get_material(surface)
			piece.set_surface_override_material(surface,coating(original.resource_name if original else "metal",variant))
	# Seat and controls are inside a closed transparent canopy, not on the roof.
	G.box(self,Vector3(1.05,.18,1.05),Vector3(0,.70,.22),"263c51")
	G.box(self,Vector3(1.05,1.0,.20),Vector3(0,1.15,.82),"314a63").rotation.x=.10
	G.box(self,Vector3(1.15,.23,.45),Vector3(0,1.06,-.85),"263c51").rotation.x=-.25
	G.box(self,Vector3(.85,.025,.24),Vector3(0,1.19,-.85),"76d9db",.25)
	for side in [-1,1]: G.link(self,Vector3(side*.32,.83,-.42),Vector3(side*.32,1.0,-.42),.035,"8ca6b7")
	var st:=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in 9:
		var a:=row*PI*.5/9.; var b:float=(row+1)*PI*.5/9.
		for col in 32:
			var c:=col*TAU/32.; var d:float=(col+1)*TAU/32.
			var p:=canopy_point(a,c); var q:=canopy_point(a,d); var r:=canopy_point(b,d); var s:=canopy_point(b,c)
			SM._triangle(st,p,q,r); SM._triangle(st,p,r,s)
	var glass:=ShaderMaterial.new(); glass.shader=preload("res://assets/spaceflight/canopy.gdshader")
	canopy_hinge=Node3D.new(); add_child(canopy_hinge); canopy_hinge.name="CanopyHinge"; canopy_hinge.position=Vector3(0,.82,1.72)
	var canopy:=G.part(canopy_hinge,st.commit(),-canopy_hinge.position,glass); canopy.name="Canopy"; canopy.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var rim:=Node3D.new(); canopy_hinge.add_child(rim); rim.position=-canopy_hinge.position
	for col in 32: G.link(rim,canopy_point(0,col*TAU/32),canopy_point(0,(col+1)*TAU/32),.045,"8ca6b7")
	for side in [-1,1]:
		for i in 9: G.link(rim,canopy_point(i*PI*.5/9,side*PI*.5),canopy_point((i+1)*PI*.5/9,side*PI*.5),.024,"7593a9")
	SM.batch(rim)
	exhaust=Jet.new(); add_child(exhaust); exhaust.build(); exhaust.name="Engines"
	exhaust.set_meta("motion","engines"); exhaust.rotation.x=-PI*.5; exhaust.scale=Vector3(.9,1.5,.9); exhaust.position=Vector3(0,.8,5.18)
	for mat:ShaderMaterial in exhaust.materials: mat.set_shader_parameter("fire_mode",true)
	for i in 2: exhaust.jets[i].position.x=(-1 if i==0 else 1)*1.35
	var frame:=Node3D.new(); add_child(frame); frame.name="CockpitStructure"
	for child in get_children():
		if child is MeshInstance3D and child!=canopy: child.reparent(frame,false)
	SM.batch(frame)
	set_meta("source_model",key); set_meta("enclosed_cockpit",true)

func set_canopy(opening:float) -> void:
	canopy_hinge.rotation.x=clampf(opening,0.,1.)*1.15

func canopy_point(lat:float,angle:float) -> Vector3:
	return Vector3(cos(angle)*cos(lat)*1.13,.82+sin(lat)*1.83,sin(angle)*cos(lat)*1.85-.13)

func seat_pilot(hero:Node3D) -> void:
	if hero.get_parent()!=self:
		if hero.get_parent(): hero.reparent(self,false)
		else: add_child(hero)
	pilot=hero; pilot.name="SeatedPilot"; pilot.position=Vector3(0,.24,.20); pilot.scale=Vector3.ONE; pilot.rotation.y=PI
	pilot.animate(.15,"pilot"); set_meta("pilot_seated",true)

func make_pilot(girl:bool,loadout:Dictionary={},character_index:int=-1) -> Node3D:
	var hero:Node3D=load("res://scripts/hero.gd").new()
	add_child(hero)
	hero.build(girl,loadout,character_index)
	seat_pilot(hero)
	return hero

func advance(dt:float,boosting:bool=false) -> void:
	if is_instance_valid(pilot) and pilot.visible: pilot.animate(dt,"pilot")
	if is_instance_valid(pilot):
		for i in 2: pilot.gesture_ik(i,Vector3((-1 if i==0 else 1)*.32,1.24,.62),Vector3.LEFT if i==0 else Vector3.RIGHT,1.)
	if is_instance_valid(exhaust): exhaust.advance(dt,true); exhaust.scale.y=2.1 if boosting else 1.5
