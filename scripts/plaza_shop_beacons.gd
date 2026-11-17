extends Node3D
const G=preload("res://scripts/geometry.gd")
const Shops=preload("res://scripts/monument_shops.gd")
var markers: Array[Node3D]=[]
var elapsed:=0.

func build(finish: Node3D) -> void:
	name="ShopBeacons"
	var points:=PackedVector2Array([Vector2(-.43,1.25),Vector2(.43,1.25),Vector2(.43,-.25),Vector2(1.15,-.25),Vector2(0,-1.55),Vector2(-1.15,-.25),Vector2(-.43,-.25)])
	var mesh:=SurfaceTool.new();mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	var indices:=Geometry2D.triangulate_polygon(points)
	for i in range(0,indices.size(),3):
		for j in [0,2,1]:
			var p:=points[indices[i+j]];mesh.add_vertex(Vector3(p.x,p.y,.18))
		for j in [0,1,2]:
			var p:=points[indices[i+j]];mesh.add_vertex(Vector3(p.x,p.y,-.18))
	for i in points.size():
		var a:=points[i];var b:=points[(i+1)%points.size()]
		for p in [Vector3(a.x,a.y,.18),Vector3(b.x,b.y,.18),Vector3(b.x,b.y,-.18),Vector3(a.x,a.y,.18),Vector3(b.x,b.y,-.18),Vector3(a.x,a.y,-.18)]:mesh.add_vertex(p)
	mesh.generate_normals()
	var shape:=mesh.commit()
	for i in 3:
		var marker:=Node3D.new();add_child(marker);markers.append(marker)
		marker.name=preload("res://scripts/gear_economy.gd").CATEGORIES[i]
		var booth: Node3D=finish.get_node("MonumentShops/"+marker.name)
		var bounds:=preload("res://scripts/loop_layout.gd").bounds(booth,Transform3D.IDENTITY)
		marker.position=Shops.POSITIONS[i]+Vector3.UP*maxf(9.,bounds.end.y+2.2)
		marker.set_meta("height",marker.position.y)
		var tint: String=["54ffe2","ff67cf","ffd261"][i]
		G.part(marker,shape,Vector3.ZERO,preload("res://scripts/arcade_materials.gd").coating(Color("233768"),Color(tint),0))
		for z in [-.20,.20]:
			for edge in points.size():
				var a:=points[edge];var b:=points[(edge+1)%points.size()]
				G.link(marker,Vector3(a.x,a.y,z),Vector3(b.x,b.y,z),.065,tint).material_override=G.material(tint,1.4)
		G.merge_static(marker)
		for part: GeometryInstance3D in marker.find_children("*","GeometryInstance3D",true,false):part.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func advance(dt: float,camera: Camera3D,reduced: bool) -> void:
	elapsed+=dt
	for i in markers.size():
		var marker:=markers[i]
		var phase:=fposmod(elapsed/2.2+i*.12,1.)
		var offset:=1.1*(1.-smoothstep(0.,.24,phase))+.32*sin(clampf((phase-.24)/.28,0.,1.)*PI)+1.1*smoothstep(.63,1.,phase)
		marker.position.y=float(marker.get_meta("height"))+(0. if reduced else offset)
		var target:=camera.global_position;target.y=marker.global_position.y
		if marker.global_position.distance_squared_to(target)>.01:marker.look_at(target,Vector3.UP,true)
