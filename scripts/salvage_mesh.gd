extends RefCounted
static var block_meshes:Dictionary={}
## Mesh helpers adapted from spacetamagoshi; no gameplay dependencies.
static func _part(root: Node3D, mesh: Mesh, mat: Material, point: Vector3=Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh; node.material_override = mat; node.position = point
	if preload("res://scripts/mobile_render.gd").enabled(): node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(node)
	return node

static func _box(root: Node3D, size: Vector3, point: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new(); mesh.size = size
	return _part(root,mesh,mat,point)

static func _cylinder(root: Node3D, radius: float, height: float, point: Vector3, mat: Material, top: float=-1) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius if top<0 else top; mesh.bottom_radius = radius
	mesh.height = height; mesh.radial_segments = 16
	return _part(root,mesh,mat,point)

static func _beam(root: Node3D, start: Vector3, end: Vector3, width: float, mat: Material) -> void:
	var node := _cylinder(root,width,start.distance_to(end),(start+end)*.5,mat)
	node.quaternion = Quaternion(Vector3.UP,(end-start).normalized())

static func _triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal := (c-a).cross(b-a).normalized()
	for point in [a,b,c]:
		tool.set_normal(normal); tool.add_vertex(point)

static func _arc(root: Node3D, radius: float, width: float, depth: float, start: float, end: float, mat: Material) -> void:
	var tool := SurfaceTool.new(); tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := maxi(4,ceili(absf(end-start)*radius*4))
	for i in count:
		var a := lerpf(start,end,float(i)/count); var b := lerpf(start,end,float(i+1)/count)
		var rings: Array = []
		for angle in [a,b]:
			var points: Array[Vector3] = []
			for p in [Vector2(radius-width*.5,-depth*.5),Vector2(radius+width*.5,-depth*.5),Vector2(radius+width*.5,depth*.5),Vector2(radius-width*.5,depth*.5)]:
				points.append(Vector3(cos(angle)*p.x,sin(angle)*p.x,p.y))
			rings.append(points)
		for j in 4:
			var k := (j+1)%4
			_triangle(tool,rings[0][j],rings[1][j],rings[1][k]); _triangle(tool,rings[0][j],rings[1][k],rings[0][k])
		if i==0:
			_triangle(tool,rings[0][0],rings[0][2],rings[0][1]); _triangle(tool,rings[0][0],rings[0][3],rings[0][2])
		if i==count-1:
			_triangle(tool,rings[1][0],rings[1][1],rings[1][2]); _triangle(tool,rings[1][0],rings[1][2],rings[1][3])
	_part(root,tool.commit(),mat)

static func block(root: Node3D,size: Vector3,at: Vector3,mat: Material,bevel: float=.09) -> MeshInstance3D:
	var key:=str(size)+"/"+str(bevel)
	if block_meshes.has(key): return _part(root,block_meshes[key],mat,at)
	var b := minf(minf(size.x,size.z)*.22,bevel)
	var x := size.x*.5; var z := size.z*.5
	var outline := [Vector2(-x+b,-z),Vector2(x-b,-z),Vector2(x,-z+b),Vector2(x,z-b),Vector2(x-b,z),Vector2(-x+b,z),Vector2(-x,z-b),Vector2(-x,-z+b)]
	var tool := SurfaceTool.new(); tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 8:
		var j := (i+1)%8; var a: Vector2 = outline[i]; var c: Vector2 = outline[j]
		var p := Vector3(a.x,-size.y*.5,a.y); var q := Vector3(c.x,-size.y*.5,c.y)
		var u := Vector3(a.x*.97,size.y*.5,a.y*.97); var v := Vector3(c.x*.97,size.y*.5,c.y*.97)
		_triangle(tool,p,q,v); _triangle(tool,p,v,u)
		_triangle(tool,Vector3(0,size.y*.5,0),u,v)
		_triangle(tool,Vector3(0,-size.y*.5,0),q,p)
	var mesh:=tool.commit(); block_meshes[key]=mesh
	return _part(root,mesh,mat,at)

static func limb(root: Node3D,points: Array,radii: Array,mat: Material,sides: int=7) -> MeshInstance3D:
	var tool := SurfaceTool.new(); tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array = []
	for i in points.size():
		var direction: Vector3 = points[mini(i+1,points.size()-1)]-points[maxi(0,i-1)]
		var frame := Quaternion(Vector3.UP,direction.normalized())
		var ring: Array = []
		for j in sides:
			var angle := TAU*float(j)/sides
			ring.append(points[i]+frame*Vector3(cos(angle)*float(radii[i]),0,sin(angle)*float(radii[i])))
		rings.append(ring)
	for i in rings.size()-1:
		for j in sides:
			var k := (j+1)%sides
			_triangle(tool,rings[i][j],rings[i+1][k],rings[i+1][j]); _triangle(tool,rings[i][j],rings[i][k],rings[i+1][k])
	for j in range(1,sides-1):
		_triangle(tool,rings[0][0],rings[0][j+1],rings[0][j]); _triangle(tool,rings[-1][0],rings[-1][j],rings[-1][j+1])
	return _part(root,tool.commit(),mat)

static func batch(root: Node3D) -> void:
	var groups := {}
	var pieces := root.find_children("*","MeshInstance3D",true,false)
	for piece: MeshInstance3D in pieces:
		var transform := piece.transform; var parent := piece.get_parent()
		while parent!=root: transform = (parent as Node3D).transform*transform; parent = parent.get_parent()
		var mat := piece.material_override
		if not groups.has(mat):
			var tool := SurfaceTool.new(); tool.begin(Mesh.PRIMITIVE_TRIANGLES); groups[mat] = tool
		groups[mat].append_from(piece.mesh,0,transform)
	for child in root.get_children(): child.free()
	for mat: Material in groups: _part(root,groups[mat].commit(),mat)
