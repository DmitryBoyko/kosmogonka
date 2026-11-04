extends RefCounted
## Continuous sculpted heads and fitted facial surfaces. No detached nose/cheek balls.
const G = preload("res://scripts/geometry.gd")
static var cache: Dictionary = {}
static var section_cache: Dictionary = {}
static var templates:Dictionary={}
static var baking:=false
const MOUTH_Y := -0.166

static func gaussian(x: float, y: float, cx: float, cy: float, sx: float, sy: float) -> float:
	return exp(-pow((x-cx)/sx, 2) - pow((y-cy)/sy, 2))

# Authored anatomical sections: height, half-width, face depth, occipital depth.
# The forehead, temples, cheekbones, jaw and chin are not a scaled sphere.
const GIRL_HEAD := [Vector4(-0.35,0,0,0),Vector4(-0.33,0.085,0.115,0.09),Vector4(-0.29,0.165,0.215,0.15),Vector4(-0.23,0.225,0.265,0.205),Vector4(-0.15,0.285,0.300,0.255),Vector4(-0.05,0.323,0.319,0.292),Vector4(0.07,0.326,0.317,0.312),Vector4(0.18,0.317,0.306,0.323),Vector4(0.30,0.289,0.278,0.302),Vector4(0.40,0.235,0.222,0.25),Vector4(0.47,0.126,0.116,0.14),Vector4(0.49,0,0,0)]
const BOY_HEAD := [Vector4(-0.36,0,0,0),Vector4(-0.335,0.095,0.12,0.095),Vector4(-0.29,0.184,0.222,0.16),Vector4(-0.23,0.249,0.272,0.215),Vector4(-0.15,0.305,0.303,0.265),Vector4(-0.05,0.337,0.321,0.302),Vector4(0.07,0.341,0.319,0.322),Vector4(0.18,0.331,0.310,0.329),Vector4(0.30,0.301,0.282,0.31),Vector4(0.40,0.245,0.227,0.255),Vector4(0.47,0.132,0.12,0.145),Vector4(0.49,0,0,0)]

static func eye_center(girl: bool) -> float: return 0.145 if girl else 0.151
static func eye_width(girl: bool) -> float: return 0.103 if girl else 0.096

static func section(y: float, girl: bool) -> Vector3:
	var key:=Vector2(y,1 if girl else 0)
	if section_cache.has(key): return section_cache[key]
	var value:=compute_section(y,girl)
	section_cache[key]=value
	return value

static func compute_section(y: float, girl: bool) -> Vector3:
	var rows: Array=GIRL_HEAD if girl else BOY_HEAD
	if y<=rows[0].x or y>=rows[-1].x: return Vector3.ZERO
	for i in rows.size()-1:
		if y>rows[i+1].x: continue
		var a: Vector4=rows[maxi(0,i-1)]; var b: Vector4=rows[i]
		var c: Vector4=rows[i+1]; var d: Vector4=rows[mini(rows.size()-1,i+2)]
		var p0:=Vector3(a.y,a.z,a.w); var p1:=Vector3(b.y,b.z,b.w)
		var p2:=Vector3(c.y,c.z,c.w); var p3:=Vector3(d.y,d.z,d.w)
		var span:=c.x-b.x; var t: float=(y-b.x)/span
		var m1: Vector3=(p2-p0)*span/(c.x-a.x)
		var m2: Vector3=(p3-p1)*span/(d.x-b.x)
		return ((2*t*t*t-3*t*t+1)*p1+(t*t*t-2*t*t+t)*m1+(-2*t*t*t+3*t*t)*p2+(t*t*t-t*t)*m2).max(Vector3.ZERO)
	return Vector3.ZERO

static func width(y: float, girl: bool) -> float: return section(y,girl).x

static func base_front(x: float, y: float, girl: bool) -> float:
	var row:=section(y,girl)
	var u:=absf(x)/maxf(0.0001,row.x)
	return row.y*sqrt(maxf(0,1-pow(u,4)))

static func front(x: float, y: float, girl: bool) -> float:
	var w:=maxf(0.0001,width(y,girl))
	var mask:=pow(maxf(0,1-pow(x/w,2)),1.6)
	var relief:=gaussian(x,y,0,-0.042,0.043 if girl else 0.047,0.043)*(0.055 if girl else 0.061)
	relief+=gaussian(x,y,0,0.02,0.031,0.085)*0.021
	for side in [-1.0,1.0]:
		relief+=gaussian(x,y,side*0.037,-0.077,0.025,0.022)*0.012
		var orbit:=sqrt(pow((x-side*eye_center(girl))/(0.117 if girl else 0.112),2)+pow((y-0.062)/(0.083 if girl else 0.078),2))
		relief-=exp(-orbit*orbit)*0.047
		relief+=exp(-pow((orbit-1.10)/0.24,2))*0.009
		relief+=gaussian(x,y,side*0.195,-0.085,0.085,0.085)*0.021
	relief+=gaussian(x,y,0,-0.245,0.08,0.065)*0.008
	relief-=gaussian(x,y,0,MOUTH_Y,0.12,0.012)*0.006
	return base_front(x,y,girl)+relief*mask

static func point(theta: float, phi: float, girl: bool) -> Vector3:
	var y:=cos(theta)*0.49
	if y<0: y*=0.35/0.49 if girl else 0.36/0.49
	var row:=section(y,girl)
	var x:=sin(phi)*row.x
	var z:=cos(phi)*row.z
	if cos(phi)>=0: z=front(x,y,girl)
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
	var rows:int=48 if preload("res://scripts/mobile_render.gd").enabled() else 96
	var cols:int=64 if preload("res://scripts/mobile_render.gd").enabled() else 128
	for row in rows+1:
		var theta := PI*row/float(rows)
		for col in cols+1:
			# Concentrate topology around the nose/eyes rather than under the hair.
			var longitude := -PI+TAU*col/float(cols)
			var phi := signf(longitude)*pow(absf(longitude)/PI,1.45)*PI
			var p := point(theta,phi,girl)
			var normal := Vector3.UP if row == 0 else Vector3.DOWN if row == rows else (point(theta+0.001,phi,girl)-point(theta-0.001,phi,girl)).cross(point(theta,phi+0.001,girl)-point(theta,phi-0.001,girl)).normalized()
			var cheek := 0.0
			for side in [-1.0,1.0]: cheek += gaussian(p.x,p.y,side*0.195,-0.10,0.085,0.065)
			var color := Color("f5c5aa").lerp(Color("ef8e93"), cheek*(0.55 if girl else 0.48)*maxf(0,cos(phi)))
			color = color.lerp(Color("dfab91"), gaussian(p.x,p.y,0,-0.1,0.07,0.027)*0.13*maxf(0,cos(phi)))
			vertices.append(p)
			var lift := (gaussian(p.x,p.y,-0.195,-0.1,0.11,0.10)+gaussian(p.x,p.y,0.195,-0.1,0.11,0.10))*maxf(0,cos(phi))
			smiling.append(p+Vector3(0,lift*0.012,lift*0.004))
			var mouth_socket:=gaussian(p.x,p.y,0,MOUTH_Y-0.026,0.17,0.075)*pow(maxf(0,cos(phi)),12)
			opened.append(p-Vector3(0,0,mouth_socket*0.16))
			normals.append(normal)
			colors.append(color)
			if row < rows and col < cols:
				var a := row*(cols+1)+col
				indices.append_array(PackedInt32Array([a,a+cols+2,a+cols+1,a,a+1,a+cols+2]))
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
		var aperture: Vector3=parent.get_meta("aperture",Vector3(0.103,0.046,0.030))
		depth += maxf(0,1.0-pow(p.x/(aperture.x*1.1),2)-pow(p.y/((aperture.y+aperture.z)*0.95),2))*0.007
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

static func eye_lids(outward: float, top: float, bottom: float, girl: bool = false) -> Vector2:
	# Different cubic curves for the upper and lower lids; both share tear/canthus corners.
	var t:=clampf((outward+1)*0.5,0,1); var inv:=1-t
	var corners: float=lerpf(-0.004,0.014,t) if girl else lerpf(-0.001,0.006,t)
	var upper:=corners+3*inv*inv*t*top*1.43+3*inv*t*t*top*1.24
	var lower:=corners-3*inv*inv*t*bottom*1.18-3*inv*t*t*bottom*1.10
	return Vector2(lower,upper)

static func eyeliner(eye: Node3D, girl: bool, side: float, w: float, top: float) -> void:
	var triangles:=PackedVector2Array()
	var lower:=PackedVector2Array(); var upper:=PackedVector2Array()
	for i in 49:
		var t:=i/48.0; var q: float=-1+2*t
		var at:=Vector2(side*q*w,eye_lids(q,top,0,girl).y)
		var thickness: float=(0.0012+pow(t,0.7)*0.0055+sin(t*PI)*0.0015) if girl else 0.0011
		lower.append(at); upper.append(at+Vector2(0,thickness))
	if girl:
		var tip:=Vector2(side*(w+0.018),0.032)
		lower.append(tip); upper.append(tip)
	for i in lower.size()-1:
		triangles.append_array(PackedVector2Array([lower[i],upper[i+1],lower[i+1],lower[i],upper[i],upper[i+1]]))
	var line:=fitted(eye,triangles,girl,"291a22" if girl else "634837",0.014)
	line.name="UpperEyeliner"
	line.set_meta("winged",girl)
	line.material_override=line.material_override.duplicate()
	line.material_override.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED

static func lash_fan(eye: Node3D, girl: bool, side: float, w: float, top: float, bottom: float, upper: bool) -> MeshInstance3D:
	var count: int=(24 if upper else 12) if girl else (12 if upper else 6)
	var tool:=SurfaceTool.new(); tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for strand in count:
		var f:=strand/float(count-1)
		var q:=lerpf(-0.78,0.98,f)
		var lids:=eye_lids(q,top,bottom,girl)
		var root:=Vector2(side*q*w,lids.y if upper else lids.x)
		var length_value: float=lerpf(0.018,0.038,f) if girl and upper else lerpf(0.008,0.017,f) if girl else lerpf(0.009,0.019,f) if upper else lerpf(0.005,0.009,f)
		length_value*=0.86 if strand%3==1 else 1.0
		var tip:=root+Vector2(side*lerpf(-0.004,0.022,f)*(1 if girl else 0.65),length_value*(1 if upper else -1))
		var c1:=root+Vector2(side*0.001,length_value*(0.5 if upper else -0.35))
		var c2:=tip-Vector2(side*0.012,length_value*(0.08 if upper else -0.12))
		var points:Array[Vector2]=[]
		for i in 9:
			var t:=i/8.0; var inv:=1-t
			points.append(root*inv*inv*inv+3*c1*inv*inv*t+3*c2*inv*t*t+tip*t*t*t)
		for i in 8:
			var direction:Vector2=(points[i+1]-points[i]).normalized()
			var normal:=Vector2(-direction.y,direction.x)
			for corner:Vector2 in [Vector2(i,-1),Vector2(i+1,1),Vector2(i+1,-1),Vector2(i,-1),Vector2(i,1),Vector2(i+1,1)]:
				var t:=corner.x/8.0
				var radius:float=(0.0026 if upper else 0.0015) if girl else (0.0014 if upper else 0.0008)
				var p:Vector2=points[int(corner.x)]+normal*corner.y*radius*pow(1-t,1.25)
				var curl:float=sin(t*PI*0.75)*(0.012 if girl else 0.006)
				tool.set_normal(Vector3.FORWARD)
				tool.add_vertex(Vector3(p.x,p.y,surface_depth(eye,p,girl)+0.016+curl))
	var mat:=material("302027" if girl and upper else "49312c" if girl else "49372e").duplicate() as StandardMaterial3D
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	var mesh:=G.part(eye,tool.commit(),Vector3.ZERO,mat)
	mesh.name="UpperLashFan" if upper else "LowerLashFan"
	mesh.set_meta("strand_count",count)
	mesh.set_meta("curled_lashes",true)
	mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh

static func eye_patch(eye: Node3D, girl: bool, side: float) -> Array[MeshInstance3D]:
	var lashes: Array[MeshInstance3D] = []
	var triangles := PackedVector2Array()
	var w := eye_width(girl)
	var top := 0.046 if girl else 0.041
	var bottom := 0.030 if girl else 0.028
	eye.set_meta("aperture",Vector3(w,top,bottom))
	# A tessellated scleral dome, not two flat triangles stretched across an eye.
	var cols:int=20 if preload("res://scripts/mobile_render.gd").enabled() else 40
	var rows:int=6 if preload("res://scripts/mobile_render.gd").enabled() else 12
	for col in cols:
		for row in rows:
			for uv: Vector2 in [Vector2(col,row),Vector2(col+1,row+1),Vector2(col+1,row),Vector2(col,row),Vector2(col,row+1),Vector2(col+1,row+1)]:
				var u: float=-1.0+uv.x*2./cols
				var lids:=eye_lids(u*side,top,bottom,girl)
				var y:=lerpf(lids.x,lids.y,uv.y/rows)
				triangles.append(Vector2(u*w,y))
	var white_colors:=PackedColorArray()
	for p in triangles:
		var edge:=clampf(absf(p.x)/w,0,1)
		white_colors.append(Color("fffaf4").lerp(Color("e3c9b8"),pow(edge,4)*0.22))
	var sclera:=fitted(eye,triangles,girl,"ffffff",0.008,white_colors)
	sclera.name="Sclera"
	sclera.material_override=sclera.material_override.duplicate()
	sclera.material_override.roughness=0.38
	var upper := PackedVector2Array()
	var lower := PackedVector2Array()
	for i in 25:
		var u := -1.0+i/12.0
		var lids:=eye_lids(u*side,top,bottom,girl)
		upper.append(Vector2(u*w,lids.y))
		lower.append(Vector2(u*w,lids.x))
	ribbon(eye,upper,0.005,girl,"e7b197",0.010)
	eyeliner(eye,girl,side,w,top)
	ribbon(eye,lower,0.0015,girl,"e5b79f",0.012)
	# Concentric corneal iris geometry: radial fibres, limbal ring, pupil and soft depth.
	var center := Vector2(-side*0.001,0.011 if girl else 0.006)
	var radius:=0.043 if girl else 0.039
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
		var lids:=eye_lids(u*side,top,bottom,girl)
		clipped_iris.append(Vector2(p.x,clampf(p.y,lids.x+0.001,lids.y-0.001)))
	var iris_piece:=fitted(eye,clipped_iris,girl,"ffffff",0.014,iris_colors)
	iris_piece.material_override=iris_piece.material_override.duplicate()
	iris_piece.material_override.roughness=0.32
	iris_piece.material_override.clearcoat_enabled=true
	iris_piece.material_override.clearcoat=0.22
	var pupil:=PackedVector2Array()
	for i in 64:
		var a:=TAU*i/64.0; var b:=TAU*(i+1)/64.0
		pupil.append_array(PackedVector2Array([center,center+Vector2(cos(a),sin(a))*(0.019 if girl else 0.018),center+Vector2(cos(b),sin(b))*(0.019 if girl else 0.018)]))
	fitted(eye,pupil,girl,"20150f",0.016)
	for highlight in [Vector3(-0.011,0.016,0.008),Vector3(0.012,-0.011,0.004)]:
		var points := PackedVector2Array()
		var c := center+Vector2(highlight.x,highlight.y)
		for i in 20:
			points.append_array(PackedVector2Array([c,c+Vector2(cos(TAU*i/20.0),sin(TAU*i/20.0))*highlight.z,c+Vector2(cos(TAU*(i+1)/20.0),sin(TAU*(i+1)/20.0))*highlight.z]))
		fitted(eye,points,girl,"fffdf5",0.018)
	for upper_lid in [true,false]: lashes.append(lash_fan(eye,girl,side,w,top,bottom,upper_lid))
	return lashes

static func lip_point(girl: bool, smile: float, opening: float, upper: bool, u: float, angle: float) -> Vector3:
	var arch:=pow(maxf(0,1-u*u),0.65)
	var w: float=(0.116 if girl else 0.128)+smile*0.032
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
	var mobile:=preload("res://scripts/mobile_render.gd").enabled()
	if part in ["upper","lower"]:
		# Closed elliptical lip volumes, with true front, back, upper and lower surfaces.
		var cols:int=24 if mobile else 48; var rings:int=8 if mobile else 16
		for col in cols:
			for ring in rings:
				for uv: Vector2 in [Vector2(col,ring),Vector2(col+1,ring+1),Vector2(col+1,ring),Vector2(col,ring),Vector2(col,ring+1),Vector2(col+1,ring+1)]:
					vertices.append(lip_point(girl,smile,opening,part=="upper",-1+uv.x*2./cols,uv.y*TAU/rings))
	elif part=="cavity":
		var w: float=(0.116 if girl else 0.128)+smile*0.032
		var cols:int=20 if mobile else 40; var rows:int=4 if mobile else 8
		for col in cols:
			for row in rows:
				for uv: Vector2 in [Vector2(col,row),Vector2(col+1,row+1),Vector2(col+1,row),Vector2(col,row),Vector2(col,row+1),Vector2(col+1,row+1)]:
					var u: float=-1+uv.x*2./cols; var v:=uv.y/rows
					var arch:=maxf(0,1-u*u); var x:=u*w
					var y: float=(0.012+smile*0.025)*u*u-v*opening*0.082*arch
					vertices.append(Vector3(x,y,front(x,MOUTH_Y+y,girl)+0.002-sin(v*PI)*arch*0.012))
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
	var key:="mouth/%s/%s" % [str(girl),part]
	if cache.has(key): return cache[key]
	var mesh:=ArrayMesh.new(); mesh.blend_shape_mode=Mesh.BLEND_SHAPE_MODE_NORMALIZED
	mesh.add_blend_shape("Smile"); mesh.add_blend_shape("Open")
	var arrays:=mouth_arrays(girl,0,0,part)
	var shapes:Array[Array]=[]
	for pose in [Vector2(1,0),Vector2(0,1)]: shapes.append(mouth_arrays(girl,pose.x,pose.y,part))
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,shapes)
	cache[key]=mesh
	return mesh

static func own_face(node:Node,scene_root:Node) -> void:
	for child in node.get_children(): child.owner=scene_root; own_face(child,scene_root)

static func build(head:Node3D,girl:bool) -> Dictionary:
	var key:=str(girl)+str(preload("res://scripts/mobile_render.gd").enabled())
	var path:String="res://assets/hero_cache/face_"+("girl" if girl else "boy")+".scn"
	if not baking and not templates.has(key) and preload("res://scripts/mobile_render.gd").enabled() and ResourceLoader.exists(path): templates[key]=load(path)
	if not baking and templates.has(key):
		var rig:Node3D=templates[key].instantiate(); head.add_child(rig)
		var result:Dictionary={"smile":0.,"opening":0.}; var bindings:Dictionary=rig.get_meta("face_bindings")
		for name_value:String in bindings:
			if bindings[name_value] is Array:
				var nodes:Array=[]
				for node_path:NodePath in bindings[name_value]: nodes.append(rig.get_node(node_path))
				result[name_value]=nodes
			else: result[name_value]=rig.get_node(bindings[name_value])
		return result
	var rig:=Node3D.new(); rig.name="FaceRig"; head.add_child(rig)
	var result:=build_uncached(rig,girl); var bindings:Dictionary={}
	for name_value:String in ["skin","eyes","brows","lashes","mouth","pieces"]:
		if result[name_value] is Array:
			var paths:Array=[]
			for node:Node in result[name_value]: paths.append(rig.get_path_to(node))
			bindings[name_value]=paths
		else: bindings[name_value]=rig.get_path_to(result[name_value])
	rig.set_meta("face_bindings",bindings); own_face(rig,rig)
	var scene:=PackedScene.new(); scene.pack(rig); templates[key]=scene
	return result

static func build_uncached(head: Node3D, girl: bool) -> Dictionary:
	var skin := G.part(head,skin_mesh(girl),Vector3.ZERO,material("ffffff",true))
	for side in [-1.0,1.0]:
		G.ball(head,Vector3(0.12,0.21,0.12),Vector3(side*(0.331 if girl else 0.349),-0.028,-0.015),"edb69b")
		G.ball(head,Vector3(0.057,0.12,0.025),Vector3(side*(0.346 if girl else 0.364),-0.025,0.04),"cf947d")
	var eyes: Array[Node3D] = []
	var brows: Array[Node3D] = []
	var lashes: Array[MeshInstance3D] = []
	for side in [-1.0,1.0]:
		var eye := Node3D.new()
		head.add_child(eye)
		eye.position = Vector3(side*eye_center(girl),0.062,0)
		eye.set_meta("eye_surface",true)
		lashes.append_array(eye_patch(eye,girl,side))
		eyes.append(eye)
		var brow := Node3D.new()
		head.add_child(brow)
		brow.position = Vector3(side*eye_center(girl),0.175,0)
		brow.set_meta("face_anchor",true)
		var curve := PackedVector2Array()
		for i in 25:
			var u := i/24.0
			curve.append(Vector2(side*(-0.085+u*0.18),sin(u*PI)*0.015-u*0.008))
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
				var center := Vector2(side*(0.170+i*0.022),-0.10-(i%2)*0.018)
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
		if part=="cavity":
			# Occluded mouth interior stays dark; animated concave normals must not glitter.
			piece.material_override=piece.material_override.duplicate()
			piece.material_override.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
			piece.material_override.albedo_color=Color("512d38")
		piece.visible = part not in ["teeth","cavity"]
		if part in ["upper","lower"]:
			piece.material_override=piece.material_override.duplicate()
			piece.material_override.roughness=0.52
		pieces.append(piece)
	return {"skin":skin,"eyes":eyes,"brows":brows,"lashes":lashes,"mouth":mouth,"pieces":pieces,"smile":0.0,"opening":0.0}

static func animate(face: Dictionary, dt: float, action: String, clock: float, blink: float, front_smile: float=0.0) -> void:
	var happy := action in ["win","flip"]
	var target_smile := 1.0 if happy else 0.55 if action == "jump" else 0.25
	target_smile=lerpf(target_smile,1.0,front_smile)
	# Front-facing running has a sustained toothy grin; other poses keep their expressions.
	var opening := 0.0
	if happy:
		var beat := fposmod(clock,1.7)
		opening = smoothstep(0.1,0.25,beat)*(1.0-smoothstep(0.6,0.85,beat))*0.52
	opening=lerpf(opening,.68,front_smile)
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
