extends Node3D

const G=preload("res://scripts/geometry.gd")
var arrows:Array[Node3D]=[]
var edge:StandardMaterial3D
var phase:=0.

func _ready() -> void:
	edge=G.material("43f6ff",1.).duplicate()
	var body: StandardMaterial3D = G.material("317bd9",.18).duplicate()
	# These controls frame the carousel and must stay above actors and scenery.
	for material: StandardMaterial3D in [body,edge]:
		material.no_depth_test = true
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	body.render_priority = 2
	edge.render_priority = 3
	var points:=PackedVector2Array([Vector2(-.25,.32),Vector2(.08,.32),Vector2(.43,0),Vector2(.08,-.32),Vector2(-.25,-.32),Vector2(.09,0)])
	var model:=SurfaceTool.new()
	model.begin(Mesh.PRIMITIVE_TRIANGLES)
	var indices:=Geometry2D.triangulate_polygon(points)
	for i in range(0,indices.size(),3):
		for j in [0,2,1]:
			var p:=points[indices[i+j]]
			model.add_vertex(Vector3(p.x,p.y,.1))
		for j in [0,1,2]:
			var p:=points[indices[i+j]]
			model.add_vertex(Vector3(p.x,p.y,-.1))
	for i in points.size():
		var a:=points[i]
		var b:=points[(i+1)%points.size()]
		for p:Vector3 in [Vector3(a.x,a.y,.1),Vector3(b.x,b.y,.1),Vector3(b.x,b.y,-.1),
				Vector3(a.x,a.y,.1),Vector3(b.x,b.y,-.1),Vector3(a.x,a.y,-.1)]:
			model.add_vertex(p)
	model.generate_normals()
	var extrusion:=model.commit()
	for side in [-1,1]:
		var arrow:=Node3D.new()
		add_child(arrow)
		arrow.rotation.z=PI if side<0 else 0.
		arrows.append(arrow)
		G.part(arrow,extrusion,Vector3.ZERO,body).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for i in points.size():
			var a:=points[i]
			var b:=points[(i+1)%points.size()]
			var outline:=G.link(arrow,Vector3(a.x,a.y,.11),Vector3(b.x,b.y,.11),.036,"43f6ff")
			outline.material_override=edge
			outline.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func present(camera:Camera3D,dt:float,reduced:bool) -> void:
	phase+=dt
	var pulse:=0. if reduced else .5+.5*sin(phase*4.)
	edge.emission_energy_multiplier=.85+pulse*.95
	var viewport:=camera.get_viewport().get_visible_rect().size
	for i in arrows.size():
		var side:=i*2-1
		var screen:=viewport*Vector2(.085 if i==0 else .915,.48)
		arrows[i].global_position=camera.project_position(screen,7.1)+camera.global_basis.x*side*pulse*.09
		arrows[i].global_basis=camera.global_basis*Basis(Vector3.BACK,PI if i==0 else 0.)*Basis(Vector3.UP,side*.25)
