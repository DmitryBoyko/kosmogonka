extends RefCounted
## Continuous sculpted heads and fitted facial surfaces. No detached nose/cheek balls.
const G = preload("res://scripts/geometry.gd")
static var cache: Dictionary = {}
const MOUTH_Y := -0.166

static func gaussian(x: float, y: float, cx: float, cy: float, sx: float, sy: float) -> float:
	return exp(-pow((x-cx)/sx, 2) - pow((y-cy)/sy, 2))

static func latitude(y: float, girl: bool) -> float:
	var radius:=0.49 if y>=0 else 0.35 if girl else 0.36
	return maxf(0,1.0-pow(y/radius,2))

static func width(y: float, girl: bool) -> float:
	var jaw:=clampf((-y-0.10)/0.25,0,1)
	return (0.413 if girl else 0.431)*(1-jaw*(0.13 if girl else 0.08))

static func front(x: float, y: float, girl: bool) -> float:
	var lat:=maxf(0.0001,latitude(y,girl))
	var w:=width(y,girl)
	var z:=0.374*sqrt(maxf(0,lat-pow(x/w,2)))
	var mask:=pow(sqrt(maxf(0,1-pow(x/w,2)/lat)),6)
	var relief:=gaussian(x,y,0,-0.042,0.050 if girl else 0.055,0.043)*(0.059 if girl else 0.065)
	relief+=gaussian(x,y,0,0.02,0.036,0.085)*0.025
	for side in [-1.0,1.0]:
		relief+=gaussian(x,y,side*0.043,-0.077,0.028,0.022)*0.014
		var orbit:=sqrt(pow((x-side*0.177)/0.142,2)+pow((y-0.062)/0.105,2))
		# Actual recessed orbit in the head, surrounded by a continuous bony rim.
		relief-=exp(-orbit*orbit)*0.062
		relief+=exp(-pow((orbit-1.10)/0.24,2))*0.012
		relief+=gaussian(x,y,side*0.23,-0.085,0.11,0.09)*0.026
	relief+=gaussian(x,y,0,-0.245,0.10,0.065)*0.010
	relief-=gaussian(x,y,0,MOUTH_Y,0.12,0.012)*0.006
	return z+relief*mask

static func point(theta: float, phi: float, girl: bool) -> Vector3:
	var y:=cos(theta)*0.49
	if y<0: y*=0.35/0.49 if girl else 0.36/0.49
	var radial:=sqrt(latitude(y,girl))
	var x:=radial*sin(phi)*width(y,girl)
	var z:=radial*cos(phi)*0.374
	if cos(phi)>0: z=front(x,y,girl)
	return Vector3(x,y,z)

static func material(color: String, vertex_colors: bool = false) -> StandardMaterial3D:
	var key := color + str(vertex_colors)
	if cache.has(key): return cache[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color)
	mat.vertex_color_use_as_albedo = vertex_colors
	mat.vertex_color_is_srgb = vertex_colors
	mat.roughness = 0.84
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	cache[key] = mat
	return mat

static func skin_mesh(girl: bool) -> ArrayMesh:
	var key := "skin" + str(girl)
	if cache.has(key): return cache[key]
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var smiling := PackedVector3Array()
	var opened := PackedVector3Array()
	var indices := PackedInt32Array()
	for row in 97:
		var theta := PI*row/96.0
		for col in 129:
			# Concentrate topology around the nose/eyes rather than under the hair.
			var longitude := -PI+TAU*col/128.0
			var phi := signf(longitude)*pow(absf(longitude)/PI,1.45)*PI
			var p := point(theta,phi,girl)
			var normal := Vector3.UP if row == 0 else Vector3.DOWN if row == 96 else (point(theta+0.001,phi,girl)-point(theta-0.001,phi,girl)).cross(point(theta,phi+0.001,girl)-point(theta,phi-0.001,girl)).normalized()
			var cheek := 0.0
			for side in [-1.0,1.0]: cheek += gaussian(p.x,p.y,side*0.25,-0.12,0.115,0.075)
			var color := Color("f5c5aa").lerp(Color("ef8e93"), cheek*(0.55 if girl else 0.48)*maxf(0,cos(phi)))
			color = color.lerp(Color("dfab91"), gaussian(p.x,p.y,0,-0.1,0.07,0.027)*0.13*maxf(0,cos(phi)))
			vertices.append(p)
			var lift := (gaussian(p.x,p.y,-0.23,-0.1,0.13,0.11)+gaussian(p.x,p.y,0.23,-0.1,0.13,0.11))*maxf(0,cos(phi))
			smiling.append(p+Vector3(0,lift*0.012,lift*0.004))
			var mouth_socket:=gaussian(p.x,p.y,0,MOUTH_Y-0.026,0.135,0.065)*pow(maxf(0,cos(phi)),12)
			opened.append(p-Vector3(0,0,mouth_socket*0.095))
			normals.append(normal)
			colors.append(color)
			if row < 96 and col < 128:
				var a := row*129+col
				indices.append_array(PackedInt32Array([a,a+130,a+129,a,a+1,a+130]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.blend_shape_mode = Mesh.BLEND_SHAPE_MODE_NORMALIZED
	mesh.add_blend_shape("CheekSmile")
	mesh.add_blend_shape("MouthOpen")
	var shape := []
	shape.resize(Mesh.ARRAY_MAX)
	shape[Mesh.ARRAY_VERTEX] = smiling
	shape[Mesh.ARRAY_NORMAL] = normals
	var open_shape:=[]; open_shape.resize(Mesh.ARRAY_MAX)
	open_shape[Mesh.ARRAY_VERTEX]=opened
	open_shape[Mesh.ARRAY_NORMAL]=normals
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[shape,open_shape])
	cache[key] = mesh
	return mesh

static func surface_depth(parent: Node3D, p: Vector2, girl: bool) -> float:
	# Eye/brow nodes have an anchor within the face. The head itself is the
	# coordinate origin, regardless of its position on the character's neck.
	var anchor := parent.position if parent.has_meta("eye_surface") or parent.has_meta("face_anchor") else Vector3.ZERO
	var depth := front(p.x+anchor.x,p.y+anchor.y,girl)
	if parent.has_meta("eye_surface"):
		depth += maxf(0,1.0-pow(p.x/0.137,2)-pow(p.y/0.095,2))*0.012
	return depth

static func fitted(parent: Node3D, positions: PackedVector2Array, girl: bool, color: String, thickness: float = 0.006, colors: PackedColorArray = PackedColorArray()) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in positions.size():
		var p := positions[i]
		var dx := (surface_depth(parent,p+Vector2(0.001,0),girl)-surface_depth(parent,p-Vector2(0.001,0),girl))/0.002
		var dy := (surface_depth(parent,p+Vector2(0,0.001),girl)-surface_depth(parent,p-Vector2(0,0.001),girl))/0.002
		st.set_normal(Vector3(-dx,-dy,1).normalized())
		if not colors.is_empty(): st.set_color(colors[i])
		st.add_vertex(Vector3(p.x,p.y,surface_depth(parent,p,girl)+thickness))
	return G.part(parent,st.commit(),Vector3.ZERO,material(color,not colors.is_empty()))

static func ribbon(parent: Node3D, points: PackedVector2Array, radius: float, girl: bool, color: String, offset: float = 0.009) -> MeshInstance3D:
	var triangles := PackedVector2Array()
	for i in range(points.size()-1):
		var a := points[i]
		var b := points[i+1]
		var tangent := (b-a).normalized()
		var normal := Vector2(-tangent.y,tangent.x)
		var ra := radius * (0.2+0.8*pow(sin(PI*(i+0.3)/(points.size()-0.4)),0.5))
		var rb := radius * (0.2+0.8*pow(sin(PI*(i+1.0)/(points.size()-0.4)),0.5))
		triangles.append_array(PackedVector2Array([a-normal*ra,b+normal*rb,b-normal*rb,a-normal*ra,a+normal*ra,b+normal*rb]))
	return fitted(parent,triangles,girl,color,offset)

static func eye_patch(eye: Node3D, girl: bool, side: float) -> Array[MeshInstance3D]:
	var lashes: Array[MeshInstance3D] = []
	var triangles := PackedVector2Array()
	var w := 0.128 if girl else 0.12
	var top := 0.055 if girl else 0.049
	var bottom := 0.037 if girl else 0.033
	# A tessellated scleral dome, not two flat triangles stretched across an eye.
	for col in 40:
		for row in 12:
			for uv: Vector2 in [Vector2(col,row),Vector2(col+1,row+1),Vector2(col+1,row),Vector2(col,row),Vector2(col,row+1),Vector2(col+1,row+1)]:
				var u: float=-1.0+uv.x/20.0
				var arch:=pow(maxf(0,1-u*u),0.5)
				var y:=lerpf(-bottom*arch,top*arch,uv.y/12.0)+u*side*0.006
				triangles.append(Vector2(u*w,y))
	var white_colors:=PackedColorArray()
	for p in triangles:
		var edge:=clampf(absf(p.x)/w,0,1)
		white_colors.append(Color("fffaf4").lerp(Color("e3c9b8"),pow(edge,4)*0.22))
	var sclera:=fitted(eye,triangles,girl,"ffffff",0.008,white_colors)
	sclera.material_override=sclera.material_override.duplicate()
	sclera.material_override.roughness=0.38
	var upper := PackedVector2Array()
	var lower := PackedVector2Array()
	for i in 25:
		var u := -1.0+i/12.0
		var arch := pow(maxf(0,1-u*u),0.5)
		upper.append(Vector2(u*w,top*arch+u*side*0.006))
		lower.append(Vector2(u*w,-bottom*arch+u*side*0.006))
	ribbon(eye,upper,0.009,girl,"e7b197",0.010)
	ribbon(eye,upper,0.0038 if girl else 0.0018,girl,"70503e",0.012)
	ribbon(eye,lower,0.002,girl,"e5b79f",0.012)
	# Concentric corneal iris geometry: radial fibres, limbal ring, pupil and soft depth.
	var center := Vector2(-side*0.002,0.008)
	var radius:=0.052 if girl else 0.046
	var iris:=PackedVector2Array(); var iris_colors:=PackedColorArray()
	for row in 12:
		for i in 96:
			for uv: Vector2 in [Vector2(row,i),Vector2(row+1,i+1),Vector2(row+1,i),Vector2(row,i),Vector2(row,i+1),Vector2(row+1,i+1)]:
				var r:=uv.x/12.0; var angle:=uv.y*TAU/96.0
				iris.append(center+Vector2(cos(angle),sin(angle))*radius*r)
				var fibres:=sin(angle*37+r*5)*0.5+sin(angle*71-r*8)*0.25
				var color:=Color("986235" if girl else "916036").lerp(Color("603b22" if girl else "5c381f"),clampf(r*0.45+fibres*0.16,0,1))
				color=color.lerp(Color("422a1d"),smoothstep(0.84,1.0,r)*0.85)
				color=color.lerp(Color("b88b54"),exp(-pow((r-0.48)*12,2))*0.22)
				iris_colors.append(color)
	var clipped_iris:=PackedVector2Array()
	for p in iris:
		var u:=clampf(p.x/w,-1,1)
		var arch:=pow(maxf(0,1-u*u),0.5)
		clipped_iris.append(Vector2(p.x,clampf(p.y,-bottom*arch+u*side*0.006+0.001,top*arch+u*side*0.006-0.001)))
	var iris_piece:=fitted(eye,clipped_iris,girl,"ffffff",0.014,iris_colors)
	iris_piece.material_override=iris_piece.material_override.duplicate()
	iris_piece.material_override.roughness=0.32
	iris_piece.material_override.clearcoat_enabled=true
	iris_piece.material_override.clearcoat=0.22
	var pupil:=PackedVector2Array()
	for i in 64:
		var a:=TAU*i/64.0; var b:=TAU*(i+1)/64.0
		pupil.append_array(PackedVector2Array([center,center+Vector2(cos(a),sin(a))*0.023,center+Vector2(cos(b),sin(b))*0.023]))
	fitted(eye,pupil,girl,"20150f",0.016)
	for highlight in [Vector3(-0.014,0.021,0.011),Vector3(0.015,-0.015,0.005)]:
		var points := PackedVector2Array()
		var c := center+Vector2(highlight.x,highlight.y)
		for i in 20:
			points.append_array(PackedVector2Array([c,c+Vector2(cos(TAU*i/20.0),sin(TAU*i/20.0))*highlight.z,c+Vector2(cos(TAU*(i+1)/20.0),sin(TAU*(i+1)/20.0))*highlight.z]))
		fitted(eye,points,girl,"fffdf5",0.018)
	if girl:
		for upper_lid in [true,false]:
			for i in (7 if upper_lid else 5):
				var u:=side*(0.05+i*(0.14 if upper_lid else 0.19))
				var curve:=pow(maxf(0,1-u*u),0.5)
				var base:=Vector2(u*w,(top*curve if upper_lid else -bottom*curve)+u*side*0.006)
				var length:=0.026+sin(i*0.6)*0.006 if upper_lid else 0.011+sin(i*0.7)*0.003
				var tip:=base+Vector2(side*(0.005+i*0.003),length if upper_lid else -length)
				var mid:=base.lerp(tip,0.55)+Vector2(side*0.003,0.005 if upper_lid else -0.002)
				var lash:=ribbon(eye,PackedVector2Array([base,mid,tip]),0.0025 if upper_lid else 0.0018,girl,"684434",0.017)
				lash.name=("UpperLash" if upper_lid else "LowerLash")+str(i)
				lashes.append(lash)
	return lashes

static func lip_point(girl: bool, smile: float, opening: float, upper: bool, u: float, angle: float) -> Vector3:
	var arch:=pow(maxf(0,1-u*u),0.65)
	var w: float=(0.116 if girl else 0.128)+smile*0.015
	var x:=u*w
	var seam: float=(0.012+smile*0.025)*u*u
	var bow:=exp(-pow((absf(u)-0.28)/0.19,2))
	var ry: float=(0.0105 if girl else 0.0075)*arch if upper else (0.013 if girl else 0.009)*arch
	var rz: float=(0.012 if girl else 0.009)*arch if upper else (0.015 if girl else 0.011)*arch
	var center_y:=seam+(0.006+bow*0.004)*arch+opening*0.005 if upper else seam-0.009*arch-opening*0.082*arch
	var y:=center_y+cos(angle)*ry
	var z:=front(x,MOUTH_Y+y,girl)+0.006+sin(angle)*rz
	return Vector3(x,y,z)

static func mouth_vertices(girl: bool, smile: float, opening: float, part: String) -> PackedVector3Array:
	var vertices:=PackedVector3Array()
	if part in ["upper","lower"]:
		# Closed elliptical lip volumes, with true front, back, upper and lower surfaces.
		for col in 48:
			for ring in 16:
				for uv: Vector2 in [Vector2(col,ring),Vector2(col+1,ring+1),Vector2(col+1,ring),Vector2(col,ring),Vector2(col,ring+1),Vector2(col+1,ring+1)]:
					vertices.append(lip_point(girl,smile,opening,part=="upper",-1+uv.x/24.0,uv.y*TAU/16))
	elif part=="cavity":
		var w: float=(0.116 if girl else 0.128)+smile*0.015
		for col in 40:
			for row in 8:
				for uv: Vector2 in [Vector2(col,row),Vector2(col+1,row+1),Vector2(col+1,row),Vector2(col,row),Vector2(col,row+1),Vector2(col+1,row+1)]:
					var u: float=-1+uv.x/20.0; var v:=uv.y/8.0
					var arch:=maxf(0,1-u*u); var x:=u*w
					var y: float=(0.012+smile*0.025)*u*u-v*opening*0.082*arch
					vertices.append(Vector3(x,y,front(x,MOUTH_Y+y,girl)-sin(v*PI)*arch*0.027))
	else:
		# Rounded primary teeth: the canines are shorter than the front incisors.
		var box:=BoxMesh.new(); box.size=Vector3.ONE
		box.subdivide_width=2; box.subdivide_height=2; box.subdivide_depth=2
		var raw: Array=box.surface_get_arrays(0)
		for tooth in 8:
			var u: float=(tooth-3.5)/4.0
			var x: float=(tooth-3.5)*0.021
			var height: float=0.016 if tooth in [3,4] else 0.014 if tooth in [2,5] else 0.012
			var width_value: float=0.020 if tooth in [2,3,4,5] else 0.019
			var seam: float=(0.012+smile*0.025)*u*u
			var y:=seam-height*0.5
			var z:=front(x,MOUTH_Y+y,girl)+0.003
			var size:=Vector3(width_value,height,0.012)
			var half:=size*0.5; var bevel:=Vector3.ONE*0.002
			for index in raw[Mesh.ARRAY_INDEX]:
				var p: Vector3=raw[Mesh.ARRAY_VERTEX][index]*size
				var q:=p.clamp(-half+bevel,half-bevel)
				var rounded:=q+(p-q).normalized()*0.002
				vertices.append(Vector3(x,y,z)+rounded)
	return vertices

static func mouth_arrays(girl: bool, smile: float, opening: float, part: String) -> Array:
	var st:=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	var points:=mouth_vertices(girl,smile,opening,part)
	for i in range(0,points.size(),3):
		for index in ([i,i+1,i+2] if part=="teeth" else [i,i+2,i+1]): st.add_vertex(points[index])
	st.generate_normals()
	return st.commit().surface_get_arrays(0)

static func mouth_mesh(girl: bool, part: String) -> ArrayMesh:
	var mesh:=ArrayMesh.new(); mesh.blend_shape_mode=Mesh.BLEND_SHAPE_MODE_NORMALIZED
	mesh.add_blend_shape("Smile"); mesh.add_blend_shape("Open")
	var arrays:=mouth_arrays(girl,0,0,part)
	var shapes:Array[Array]=[]
	for pose in [Vector2(1,0),Vector2(0,1)]: shapes.append(mouth_arrays(girl,pose.x,pose.y,part))
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,shapes)
	return mesh

static func build(head: Node3D, girl: bool) -> Dictionary:
	var skin := G.part(head,skin_mesh(girl),Vector3.ZERO,material("ffffff",true))
	for side in [-1.0,1.0]:
		G.ball(head,Vector3(0.12,0.21,0.12),Vector3(side*0.419,-0.028,-0.015),"edb69b")
		G.ball(head,Vector3(0.057,0.12,0.025),Vector3(side*0.434,-0.025,0.04),"cf947d")
	var eyes: Array[Node3D] = []
	var brows: Array[Node3D] = []
	var lashes: Array[MeshInstance3D] = []
	for side in [-1.0,1.0]:
		var eye := Node3D.new()
		head.add_child(eye)
		eye.position = Vector3(side*0.177,0.062,0)
		eye.set_meta("eye_surface",true)
		lashes.append_array(eye_patch(eye,girl,side))
		eyes.append(eye)
		var brow := Node3D.new()
		head.add_child(brow)
		brow.position = Vector3(side*0.18,0.175,0)
		brow.set_meta("face_anchor",true)
		var curve := PackedVector2Array()
		for i in 25:
			var u := i/24.0
			curve.append(Vector2(side*(-0.10+u*0.21),sin(u*PI)*0.015-u*0.008))
		ribbon(brow,curve,0.008 if girl else 0.011,girl,"ac5e2c" if girl else "255578",0.012)
		brows.append(brow)
		# Small fitted nostril crease, not a separate protruding sphere.
		var crease := PackedVector2Array()
		for i in 9:
			var a := PI*0.15+i*PI*0.7/8
			crease.append(Vector2(side*(0.035+cos(a)*0.016),-0.095-sin(a)*0.006))
		ribbon(head,crease,0.0018,girl,"ba806c",0.003)
		if girl:
			for i in 4:
				var center := Vector2(side*(0.205+i*0.027),-0.10-(i%2)*0.018)
				var points := PackedVector2Array()
				for j in 12:
					points.append_array(PackedVector2Array([center,center+Vector2(cos(TAU*j/12),sin(TAU*j/12))*0.004,center+Vector2(cos(TAU*(j+1)/12),sin(TAU*(j+1)/12))*0.004]))
				fitted(head,points,girl,"c38c6a",0.003)
	var mouth := Node3D.new()
	head.add_child(mouth)
	mouth.position.y = MOUTH_Y
	var pieces: Array[MeshInstance3D] = []
	for part in ["cavity","upper","lower","teeth"]:
		var colors := {"cavity":"885344","upper":"e66d78" if girl else "d47878","lower":"f58e96" if girl else "e99491","teeth":"fff5df"}
		var piece := G.part(mouth,mouth_mesh(girl,part),Vector3.ZERO,material(colors[part]))
		piece.name = part
		piece.visible = part not in ["teeth","cavity"]
		if part in ["upper","lower"]:
			piece.material_override=piece.material_override.duplicate()
			piece.material_override.roughness=0.52
		pieces.append(piece)
	return {"skin":skin,"eyes":eyes,"brows":brows,"lashes":lashes,"mouth":mouth,"pieces":pieces,"smile":0.0,"opening":0.0}

static func animate(face: Dictionary, dt: float, action: String, clock: float, blink: float) -> void:
	var happy := action in ["win","flip"]
	var target_smile := 1.0 if happy else 0.55 if action == "jump" else 0.25
	# Closed relaxed smile by default. Brief openings only during laughter/celebration.
	var opening := 0.0
	if happy:
		var beat := fposmod(clock,1.7)
		opening = smoothstep(0.1,0.25,beat)*(1.0-smoothstep(0.6,0.85,beat))*0.52
	var blend := 1.0-exp(-12*dt)
	face.smile = lerpf(face.smile,target_smile,blend)
	face.opening = lerpf(face.opening,opening,blend)
	face.skin.set_blend_shape_value(0,face.smile)
	face.skin.set_blend_shape_value(1,face.opening)
	for piece: MeshInstance3D in face.pieces:
		piece.set_blend_shape_value(0,face.smile)
		piece.set_blend_shape_value(1,face.opening)
		if piece.name == "teeth": piece.visible = face.opening > 0.12
		if piece.name == "cavity": piece.visible = face.opening > 0.025
	for eye: Node3D in face.eyes:
		eye.scale.y = blink*(1.0-face.smile*0.1)
		eye.position.y = 0.062+face.smile*0.003
	for i in face.brows.size():
		# Low calm brows; a small sympathetic motion on a smile, never a fixed arch.
		face.brows[i].position.y = 0.175+face.smile*0.003
