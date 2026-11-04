extends RefCounted
const SM=preload("res://scripts/salvage_mesh.gd")
const G=preload("res://scripts/geometry.gd")
static var mesh:ArrayMesh
static var gold:ShaderMaterial
static func prepare() -> void:
	if mesh: return
	gold=ShaderMaterial.new(); gold.shader=preload("res://assets/surfaces/arcade_gold.gdshader")
	var st:=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 10:
		var a:=PI*.5+i*TAU/10; var b:=PI*.5+(i+1)*TAU/10
		var p:=Vector2(cos(a),sin(a))*(1.0 if i%2==0 else .47)
		var q:=Vector2(cos(b),sin(b))*(1.0 if (i+1)%2==0 else .47)
		for side in [-1.,1.]:
			var outer_p:=Vector3(p.x,p.y,side*.18); var outer_q:=Vector3(q.x,q.y,side*.18)
			var inner_p:=Vector3(p.x*.88,p.y*.88,side*.28); var inner_q:=Vector3(q.x*.88,q.y*.88,side*.28)
			if side>0:
				SM._triangle(st,Vector3(0,0,.28),inner_q,inner_p)
				SM._triangle(st,inner_p,inner_q,outer_q); SM._triangle(st,inner_p,outer_q,outer_p)
			else:
				SM._triangle(st,Vector3(0,0,-.28),inner_p,inner_q)
				SM._triangle(st,inner_q,inner_p,outer_p); SM._triangle(st,inner_q,outer_p,outer_q)
		# Godot front faces are clockwise: the old side strip faced inward and vanished.
		SM._triangle(st,Vector3(p.x,p.y,-.18),Vector3(q.x,q.y,.18),Vector3(q.x,q.y,-.18))
		SM._triangle(st,Vector3(p.x,p.y,-.18),Vector3(p.x,p.y,.18),Vector3(q.x,q.y,.18))
	mesh=st.commit()

static func build(parent:Node3D, amount:int, mega:bool=false) -> Node3D:
	prepare()
	var root:=Node3D.new(); parent.add_child(root); root.name="GoldenPickup"
	var spin:=Node3D.new(); root.add_child(spin); spin.name="Spin"
	var radius:=.82 if mega else .65 if amount>1 else .40
	G.part(spin,mesh,Vector3.ZERO,gold).scale=Vector3.ONE*radius
	root.set_meta("radius",radius); root.set_meta("amount",amount)
	if amount>1:
		var label:=G.label(root,"×%d"%amount,Vector3(0,radius+.12,0),20)
		label.pixel_size=.005
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; label.modulate=Color("fff1bc")
	return root

static func animate(root:Node3D, clock:float, offset:float, reduced:bool) -> void:
	root.get_node("Spin").rotation=Vector3(.12,clock*1.8+offset,.08)
	root.get_node("Spin").position.y=0 if reduced else sin(clock*2.8+offset)*.075
