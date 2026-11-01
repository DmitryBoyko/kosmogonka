extends RefCounted
## Continuous sculpted heads and fitted facial surfaces. No detached nose/cheek balls.
const G = preload("res://scripts/geometry.gd")
static var cache: Dictionary = {}

static func gaussian(x: float, y: float, cx: float, cy: float, sx: float, sy: float) -> float:
	return exp(-pow((x-cx)/sx, 2) - pow((y-cy)/sy, 2))

static func width(y: float, girl: bool) -> float:
	var jaw := clampf((-y-0.1)/0.36, 0, 1)
	return (0.422 if girl else 0.442) * (1.0 - jaw * (0.22 if girl else 0.16))

static func front(x: float, y: float, girl: bool) -> float:
	var latitude := maxf(0.0001, 1.0-pow(y/0.49, 2))
	var w := width(y, girl)
	var z := 0.374 * sqrt(maxf(0, latitude-pow(x/w, 2)))
	var mask := pow(sqrt(maxf(0, 1.0-pow(x/w, 2)/latitude)), 8)
	var relief := gaussian(x,y,0,-0.055,0.055 if girl else 0.061,0.057) * (0.065 if girl else 0.073)
	relief += gaussian(x,y,0,0.025,0.041,0.13) * 0.02
	for side in [-1.0, 1.0]:
		relief += gaussian(x,y,side*0.052,-0.095,0.037,0.03) * 0.012
		relief -= gaussian(x,y,side*0.18,0.065,0.115,0.08) * 0.016
		relief += gaussian(x,y,side*0.23,-0.11,0.11,0.10) * 0.025
	relief += gaussian(x,y,0,-0.23,0.19,0.10) * 0.012
	return z + relief * mask

static func point(theta: float, phi: float, girl: bool) -> Vector3:
	var y := cos(theta)*0.49
	var x := sin(theta)*sin(phi)*width(y,girl)
	var z := sin(theta)*cos(phi)*0.374
	if cos(phi) > 0: z = front(x,y,girl)
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
			var color := Color("f5c5aa").lerp(Color("ed9c91"), cheek*0.35*maxf(0,cos(phi)))
			color = color.lerp(Color("dfab91"), gaussian(p.x,p.y,0,-0.1,0.07,0.027)*0.13*maxf(0,cos(phi)))
			vertices.append(p)
			var lift := (gaussian(p.x,p.y,-0.23,-0.1,0.13,0.11)+gaussian(p.x,p.y,0.23,-0.1,0.13,0.11))*maxf(0,cos(phi))
			smiling.append(p+Vector3(0,lift*0.012,lift*0.004))
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
	var shape := []
	shape.resize(Mesh.ARRAY_MAX)
	shape[Mesh.ARRAY_VERTEX] = smiling
	shape[Mesh.ARRAY_NORMAL] = normals
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[shape])
	cache[key] = mesh
	return mesh

static func surface_depth(parent: Node3D, p: Vector2, girl: bool) -> float:
	# Eye/brow nodes have an anchor within the face. The head itself is the
	# coordinate origin, regardless of its position on the character's neck.
	var anchor := parent.position if parent.has_meta("eye_surface") or parent.has_meta("face_anchor") else Vector3.ZERO
	var depth := front(p.x+anchor.x,p.y+anchor.y,girl)
	if parent.has_meta("eye_surface"):
		depth += maxf(0,1.0-pow(p.x/0.123,2)-pow(p.y/0.073,2))*0.012
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
	var w := 0.123 if girl else 0.12
	var top := 0.064 if girl else 0.059
	var bottom := 0.046
	for i in 40:
		var u := -1.0+i/20.0
		var v := -1.0+(i+1)/20.0
		var a := pow(maxf(0,1-u*u),0.65)
		var b := pow(maxf(0,1-v*v),0.65)
		triangles.append_array(PackedVector2Array([Vector2(u*w,top*a+u*side*0.006),Vector2(v*w,top*b+v*side*0.006),Vector2(v*w,-bottom*b+v*side*0.006),Vector2(u*w,top*a+u*side*0.006),Vector2(v*w,-bottom*b+v*side*0.006),Vector2(u*w,-bottom*a+u*side*0.006)]))
	fitted(eye,triangles,girl,"fff6e9",0.008)
	var upper := PackedVector2Array()
	var lower := PackedVector2Array()
	for i in 25:
		var u := -1.0+i/12.0
		var arch := pow(maxf(0,1-u*u),0.65)
		upper.append(Vector2(u*w,top*arch+u*side*0.006))
		lower.append(Vector2(u*w,-bottom*arch+u*side*0.006))
	ribbon(eye,upper,0.009,girl,"e7b197",0.010)
	ribbon(eye,upper,0.0035 if girl else 0.0025,girl,"764c3c",0.012)
	ribbon(eye,lower,0.003,girl,"d59379",0.012)
	# Round iris with a dark limbal ring and a small round pupil, not a vertical slot.
	var iris := PackedVector2Array()
	var pupil := PackedVector2Array()
	var center := Vector2(-side*0.003,0.002)
	for i in 64:
		var a := TAU*i/64.0
		var b := TAU*(i+1)/64.0
		iris.append_array(PackedVector2Array([center,center+Vector2(cos(a),sin(a))*0.043,center+Vector2(cos(b),sin(b))*0.043]))
		pupil.append_array(PackedVector2Array([center,center+Vector2(cos(a),sin(a))*0.021,center+Vector2(cos(b),sin(b))*0.021]))
	fitted(eye,iris,girl,"235c57" if girl else "254e71",0.013)
	var inner := PackedVector2Array()
	for i in 64:
		var a := TAU*i/64.0
		var b := TAU*(i+1)/64.0
		inner.append_array(PackedVector2Array([center,center+Vector2(cos(a),sin(a))*0.037,center+Vector2(cos(b),sin(b))*0.037]))
	var iris_colors := PackedColorArray()
	for p in inner:
		var radius := p.distance_to(center)/0.037
		var angle := atan2(p.y-center.y,p.x-center.x)
		var fibers := (sin(angle*29)*sin(angle*11)+1.0)*0.5
		var pigment := Color("66aa83" if girl else "6aa6ce").lerp(Color("397861" if girl else "356d9d"),radius*0.5+fibers*0.23)
		iris_colors.append(pigment)
	fitted(eye,inner,girl,"ffffff",0.014,iris_colors)
	fitted(eye,pupil,girl,"172d3c",0.015)
	for highlight in [Vector3(-0.014,0.021,0.011),Vector3(0.015,-0.015,0.005)]:
		var points := PackedVector2Array()
		var c := center+Vector2(highlight.x,highlight.y)
		for i in 20:
			points.append_array(PackedVector2Array([c,c+Vector2(cos(TAU*i/20.0),sin(TAU*i/20.0))*highlight.z,c+Vector2(cos(TAU*(i+1)/20.0),sin(TAU*(i+1)/20.0))*highlight.z]))
		fitted(eye,points,girl,"fffdf5",0.018)
	if girl:
		for i in 3:
			var u := side*(0.62+i*0.12)
			var base := Vector2(u*w,top*pow(1-u*u,0.65)+u*side*0.006)
			var tip := base+Vector2(side*(0.015+i*0.006),0.032-i*0.004)
			var lash := ribbon(eye,PackedVector2Array([base,base.lerp(tip,0.55)+Vector2(0,0.003),tip]),0.004,girl,"603c2f",0.014)
			lash.name = "Lash" + str(i)
			lashes.append(lash)
	return lashes

static func mouth_vertices(girl: bool, smile: float, opening: float, part: String) -> PackedVector3Array:
	var vertices := PackedVector3Array()
	var w := (0.139 if girl else 0.146)+smile*0.017
	for i in 32:
		for corner: Vector2 in [Vector2(i,0),Vector2(i+1,1),Vector2(i+1,0),Vector2(i,0),Vector2(i,1),Vector2(i+1,1)]:
			var u := -1.0+corner.x/16.0
			var arch := maxf(0,1-u*u)
			var curve := (0.018+smile*0.028)*u*u
			var upper := curve+0.002*arch
			var lower := curve-opening*0.085*arch
			var y := 0.0
			var offset := 0.009
			if part == "cavity": y = lerpf(upper,lower,corner.y)
			elif part == "upper":
				y = upper+(corner.y*2-1)*0.0045*pow(arch,0.4)
				offset = 0.012
			elif part == "lower":
				y = lower+(corner.y*2-1)*0.006*pow(arch,0.5)
				offset = 0.012
			elif part == "teeth":
				y = upper-0.004-corner.y*minf(opening*0.065,0.024)*arch
				offset = 0.011
			var x := u*w*(0.84 if part == "teeth" else 1.0)
			vertices.append(Vector3(x,y,front(x,y-0.214,girl)+offset))
	return vertices

static func mouth_mesh(girl: bool, part: String) -> ArrayMesh:
	var base := mouth_vertices(girl,0,0,part)
	var mesh := ArrayMesh.new()
	mesh.blend_shape_mode = Mesh.BLEND_SHAPE_MODE_NORMALIZED
	mesh.add_blend_shape("Smile")
	mesh.add_blend_shape("Open")
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = base
	var normals := PackedVector3Array()
	for p in base: normals.append(Vector3(0,0,1))
	arrays[Mesh.ARRAY_NORMAL] = normals
	var shapes: Array[Array] = []
	for pose in [Vector2(1,0),Vector2(0,1)]:
		var shape := []
		shape.resize(Mesh.ARRAY_MAX)
		shape[Mesh.ARRAY_VERTEX] = mouth_vertices(girl,pose.x,pose.y,part)
		shape[Mesh.ARRAY_NORMAL] = normals
		shapes.append(shape)
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
	mouth.position.y = -0.214
	var pieces: Array[MeshInstance3D] = []
	for part in ["cavity","upper","lower","teeth"]:
		var colors := {"cavity":"885344","upper":"bd826d","lower":"d89581","teeth":"fff5df"}
		var piece := G.part(mouth,mouth_mesh(girl,part),Vector3.ZERO,material(colors[part]))
		piece.name = part
		piece.visible = part != "teeth"
		pieces.append(piece)
	return {"skin":skin,"eyes":eyes,"brows":brows,"lashes":lashes,"mouth":mouth,"pieces":pieces,"smile":0.0,"opening":0.0}

static func animate(face: Dictionary, dt: float, action: String, clock: float, blink: float) -> void:
	var happy := action in ["win","flip"]
	var target_smile := 1.0 if happy else 0.55 if action == "jump" else 0.25
	# Closed relaxed smile by default. Brief openings only during laughter/celebration.
	var opening := 0.0
	if happy:
		var beat := fposmod(clock,1.7)
		opening = smoothstep(0.1,0.25,beat)*(1.0-smoothstep(0.6,0.85,beat))*0.65
	var blend := 1.0-exp(-12*dt)
	face.smile = lerpf(face.smile,target_smile,blend)
	face.opening = lerpf(face.opening,opening,blend)
	face.skin.set_blend_shape_value(0,face.smile)
	for piece: MeshInstance3D in face.pieces:
		piece.set_blend_shape_value(0,face.smile)
		piece.set_blend_shape_value(1,face.opening)
		if piece.name == "teeth": piece.visible = face.opening > 0.12
	for eye: Node3D in face.eyes:
		eye.scale.y = blink*(1.0-face.smile*0.1)
		eye.position.y = 0.062+face.smile*0.003
	for i in face.brows.size():
		# Low calm brows; a small sympathetic motion on a smile, never a fixed arch.
		face.brows[i].position.y = 0.175+face.smile*0.003
