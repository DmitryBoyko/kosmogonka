extends RefCounted
const SM=preload("res://scripts/salvage_mesh.gd")
const Mat=preload("res://scripts/salvage_materials.gd")
const Jet=preload("res://scripts/jetpack_fx.gd")
const G=preload("res://scripts/geometry.gd")
const FLOOR:=3.35
const LENGTH:=44.0

static func build(variant: int=0,planet:int=0) -> Node3D:
	var root:=Node3D.new(); root.name="RocketSkyTunnel"
	# The rectangular lit corridor is the elevated jump-entry bonus route.
	var body:Node3D=preload("res://scripts/course_features.gd").build({"kind":"passage","length":LENGTH,"s":0.0,"elevated":true,"planet":planet},variant)
	root.add_child(body); body.name="Shell"; body.position.y=FLOOR
	SM.block(root,Vector3(2.12,.18,LENGTH),Vector3(0,FLOOR-.09,0),Mat.material("hull-titanium",true),.04)
	for z in [-12,12]:
		var fx:=Jet.new(); root.add_child(fx); fx.build(); fx.position=Vector3(0,FLOOR-.9,z); fx.scale=Vector3.ONE*.7
		for i in 2: fx.jets[i].position.x=(-1 if i==0 else 1)*2.17
		fx.advance(.2,true)
	var sign:=G.label(root,"↑↑  ПРЫЖОК В ПРОХОД / ★ ×2",Vector3(0,FLOOR+4.6,22.3),26)
	sign.billboard=BaseMaterial3D.BILLBOARD_ENABLED; sign.modulate=Color("ffe8a1")
	root.set_meta("tunnel_floor",FLOOR); root.set_meta("rectangular",true)
	return root

static func advance(root: Node3D, dt: float,reduced:bool=false) -> void:
	var flow_time:float=root.get_meta("flow_time",0.0)+dt; root.set_meta("flow_time",flow_time)
	preload("res://scripts/course_features.gd").animate(root.get_node("Shell"),flow_time,reduced)
	for child in root.get_children():
		if child is Jet: child.advance(dt,true)
