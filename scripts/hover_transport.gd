extends RefCounted
## Original industrial hovercraft, informed by the references in docs/Техника_0.4.2.txt.
## All deck geometry respects Course's existing 1.48 m support plane.
const SM=preload("res://scripts/salvage_mesh.gd")
const Mat=preload("res://scripts/salvage_materials.gd")
const G=preload("res://scripts/geometry.gd")
static var prototypes: Dictionary={}
static var coatings: Dictionary={}

static func paint(variant: int, role: String) -> ShaderMaterial:
	var key:=str(variant%3)+role
	if coatings.has(key): return coatings[key]
	var m:=Mat.material("hull-titanium").duplicate() as ShaderMaterial
	m.shader=preload("res://assets/salvage/transport_surface.gdshader")
	m.set_shader_parameter("surface_role",0 if role=="paint" else 1 if role=="deck" else 2)
	m.set_shader_parameter("tint",Color(["43ada8","eead60","859ccc"][variant%3]) if role=="paint" else Color("323f50") if role=="frame" else Color("a8b4bf"))
	m.set_shader_parameter("metalness",.32 if role=="paint" else .72)
	m.set_shader_parameter("roughness",.5 if role=="paint" else .65)
	m.set_shader_parameter("tile_scale",1.5 if role=="deck" else .9)
	coatings[key]=m
	return m

## Rings along Z: (z, half-width, bottom, top). Flat plates, sloped bows and chines.
static func hull(root: Node3D, sections: Array, material: Material) -> void:
	var rings: Array=[]
	for row: Vector4 in sections:
		var bevel:=minf(.13,(row.w-row.z)*.26)
		rings.append([Vector3(-row.y*.78,row.z,row.x),Vector3(row.y*.78,row.z,row.x),Vector3(row.y,row.z+bevel,row.x),Vector3(row.y,row.w-bevel,row.x),Vector3(row.y*.88,row.w,row.x),Vector3(-row.y*.88,row.w,row.x),Vector3(-row.y,row.w-bevel,row.x),Vector3(-row.y,row.z+bevel,row.x)])
	var tool:=SurfaceTool.new(); tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in rings.size()-1:
		for j in 8:
			var k: int=(j+1)%8
			SM._triangle(tool,rings[i][j],rings[i+1][j],rings[i+1][k]); SM._triangle(tool,rings[i][j],rings[i+1][k],rings[i][k])
	for j in range(1,7):
		SM._triangle(tool,rings[0][0],rings[0][j+1],rings[0][j]); SM._triangle(tool,rings[-1][0],rings[-1][j],rings[-1][j+1])
	SM._part(root,tool.commit(),material)

static func engine(root: Node3D, x: float, z: float, y: float, small: bool, variant: int) -> void:
	var pod:=Node3D.new(); root.add_child(pod); pod.position=Vector3(x,y,z)
	var r:=.18 if small else .25
	var frame:=paint(variant,"frame"); var alloy:=paint(variant,"deck")
	SM._cylinder(pod,r*1.27,.28,Vector3.ZERO,alloy,r*.95)
	SM._cylinder(pod,r,.10,Vector3(0,-.18,0),frame,r*1.14)
	G.ring(pod,r*.68,r*.93,Vector3(0,-.24,0),"71eced",.7)
	SM._cylinder(pod,r*.54,.025,Vector3(0,-.245,0),Mat.glow(Color("b6f8ed")))
	for i in 6:
		var a:=i*TAU/6
		SM.block(pod,Vector3(.035,.19,.07),Vector3(cos(a)*r,.02,sin(a)*r),frame,.01).rotation.y=-a

static func build(kind: String, variant: int=0) -> Node3D:
	var key:=kind+str(variant%3)
	if not prototypes.has(key):
		var source:=model(kind,variant%3)
		var parts: Array=[]
		for part: MeshInstance3D in source.get_children(): parts.append([part.mesh,part.material_override])
		prototypes[key]={"parts":parts,"deck_height":source.get_meta("deck_height"),"transport_length":source.get_meta("transport_length")}
		source.free()
	var root:=Node3D.new(); root.name="HoverTransport"
	root.set_meta("transport_model",kind); root.set_meta("finish",variant%3)
	root.set_meta("deck_height",prototypes[key].deck_height); root.set_meta("transport_length",prototypes[key].transport_length)
	for part: Array in prototypes[key].parts: SM._part(root,part[0],part[1])
	if kind in ["truck","broken"]: preload("res://scripts/truck_cabin.gd").add_to(root,variant,kind=="broken")
	return root

static func batch(root: Node3D) -> void:
	# Preserve per-piece transforms and normals explicitly when joining mixed meshes.
	var groups: Dictionary={}
	for piece: MeshInstance3D in root.find_children("*","MeshInstance3D",true,false):
		var transform:=piece.transform
		var ancestor:=piece.get_parent()
		while ancestor!=root:
			transform=(ancestor as Node3D).transform*transform; ancestor=ancestor.get_parent()
		var mat:=piece.material_override
		if not groups.has(mat):
			var tool:=SurfaceTool.new(); tool.begin(Mesh.PRIMITIVE_TRIANGLES); groups[mat]=tool
		var tool: SurfaceTool=groups[mat]
		var arrays:=piece.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
		var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
		for i in (indices.size() if not indices.is_empty() else verts.size()):
			var j: int=indices[i] if not indices.is_empty() else i
			tool.set_normal((transform.basis.inverse().transposed()*normals[j]).normalized())
			tool.add_vertex(transform*verts[j])
	for child in root.get_children(): child.free()
	for mat: Material in groups: SM._part(root,groups[mat].commit(),mat)

static func model(kind: String, variant: int) -> Node3D:
	var root:=Node3D.new(); root.name="HoverTransport"
	root.set_meta("transport_model",kind); root.set_meta("finish",variant)
	var mini:=kind=="board"; var carrier:=kind=="carrier"
	var length:=2.1 if mini else 12.0 if carrier else 5.8
	var w:=.72 if mini else 1.08
	var top:=0.0 if mini else 1.48 if carrier else 1.10
	var bottom:=top-(.24 if mini else .65)
	var paint_mat:=paint(variant,"paint"); var frame:=paint(variant,"frame"); var alloy:=paint(variant,"deck")
	hull(root,[Vector4(-length*.5,w*.68,bottom+.13,top-.06),Vector4(-length*.5+.32,w,bottom,top-.06),Vector4(length*.5-.25,w,bottom,top-.06),Vector4(length*.5,w*.8,bottom+.1,top-.06)],paint_mat)
	# Recessed central non-slip walkway; no raised rail across the running path.
	SM.block(root,Vector3(w*1.78,.032,length-.7),Vector3(0,top-.016,0),alloy,.10)
	var n:=2 if mini else 10 if carrier else 4
	for i in n:
		var z:=lerpf(-length*.5+.46,length*.5-.46,float(i)/maxi(1,n-1))
		for side in [-1,1]:
			SM.block(root,Vector3(w*.16,.013,.07),Vector3(side*w*.6,top-.006,z),frame,.015)
			# Flush paired lane indicators, readable without flooding the entire craft with glow.
			SM.block(root,Vector3(.035,.012,.17),Vector3(side*w*.83,top-.008,z),Mat.glow(Color("8fe6dc")),.005)
	for side in [-1,1]:
		# Separate armoured sponsons with recessed seams and service hatches.
		var count:=2 if mini else 5 if carrier else 3
		for i in count:
			var span: float=(length-.7)/count*.87
			var z:=lerpf(-length*.5+span*.5+.15,length*.5-span*.5-.15,float(i)/maxi(1,count-1))
			hull(root,[Vector4(z-span*.5,w*.11,bottom+.09,top-.09),Vector4(z-span*.35,w*.18,bottom+.025,top-.05),Vector4(z+span*.5,w*.15,bottom+.06,top-.09)],frame)
			var part: Node3D=root.get_child(root.get_child_count()-1); part.position.x=side*w*.84
			SM.block(root,Vector3(.035,.17,span*.72),Vector3(side*w*.99,bottom+.3,z),paint_mat,.015)
			if not mini:
				for j in 4: SM.block(root,Vector3(.018,.095,.032),Vector3(side*w*1.01,bottom+.30,z+(j-1.5)*.095),alloy,.004)
			for end in [-1,1]:
				SM._cylinder(root,.025,.018,Vector3(side*w*.91,top-.055,z+end*span*.32),alloy)
		for z in [-length*.31,length*.31]: engine(root,side*w*.76,z,bottom-.015,mini,variant)
		for end in [-1,1]:
			# Directional head/tail lamps sit in dark protective recesses.
			SM.block(root,Vector3(.30 if not mini else .17,.11,.07),Vector3(side*w*.61,top-.15,end*(length*.5-.035)),frame,.025)
			SM.block(root,Vector3(.22 if not mini else .11,.045,.075),Vector3(side*w*.61,top-.14,end*(length*.5-.025)),Mat.glow(Color("e5faff") if end<0 else Color("ff916e")),.012)
		# Corner hazard marks on the deck, localised rather than a noisy full-surface pattern.
		for i in 4:
			var stripe:=SM.block(root,Vector3(.09,.01,.21),Vector3(side*w*.7,top-.004,length*.5-.43-i*.15),Mat.glow(Color("dfbb69")),.01)
			stripe.rotation.y=.55
	if not mini and not carrier:
		# Slanted wedge cabin with separate inset glazing and protective brow.
		hull(root,[Vector4(-2.72,.62,1.02,1.78),Vector4(-2.15,.94,1.02,1.86),Vector4(-.85,.90,1.02,1.86),Vector4(-.56,.78,1.02,2.5)],paint_mat)
		# The cabin's windshield is transparent; its frame is supplied by TruckCabin.
		for side in [-1,1]:
			SM.block(root,Vector3(.025,.48,.76),Vector3(side*.948,2.19,-1.54),frame,.10)
			SM.block(root,Vector3(.035,.035,.33),Vector3(side*.925,1.78,-1.32),alloy,.012)
			SM._beam(root,Vector3(side*.96,1.3,-2),Vector3(side*.96,1.3,-.9),.034,alloy)
		SM._beam(root,Vector3(0,2.02,-2.67),Vector3(0,2.86,-2.14),.026,alloy)
		# Rear power module and ribbed heat exchanger, not another rounded blob.
		hull(root,[Vector4(-.25,.8,1.1,2.08),Vector4(.05,.9,1.1,2.48),Vector4(2.4,.87,1.1,2.48),Vector4(2.78,.66,1.1,2.0)],paint_mat)
		SM.block(root,Vector3(1.38,.035,1.65),Vector3(0,2.485,1.25),frame,.12)
		for i in 9: SM.block(root,Vector3(1.25,.045,.042),Vector3(0,2.51,.55+i*.16),alloy,.01)
		for side in [-1,1]:
			for z in [.3,1.4,2.35]: SM.block(root,Vector3(.045,.9,.08),Vector3(side*.88,1.7,z),frame,.02)
			SM._beam(root,Vector3(side*.7,2.5,-1.6),Vector3(side*.7,2.89,-1.6),.04,alloy)
			G.ball(root,Vector3(.12,.07,.14),Vector3(side*.7,2.94,-1.6),"ffd188",.6)
		if kind=="broken":
			SM.block(root,Vector3(.7,.06,.9),Vector3(.25,2.51,1.3),frame,.08).rotation.z=.22
			for i in 4: G.ball(root,Vector3(.25,.7+i*.1,.28),Vector3(sin(i)*.55,2.6,1+cos(i)*.4),"ffad67",.7)
	if kind=="broken":
		# Damaged, lower chassis agrees with the existing 2.5 m obstacle envelope.
		for part: Node3D in root.get_children(): part.position.y*=.82; part.scale.y*=.82
	batch(root)
	root.set_meta("deck_height",top); root.set_meta("transport_length",length)
	return root

static func ramp() -> Node3D:
	var root:=Node3D.new()
	var st:=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for tri in [[Vector3(-1.1,0,3),Vector3(-1.1,1.48,-3),Vector3(1.1,1.48,-3)],[Vector3(-1.1,0,3),Vector3(1.1,1.48,-3),Vector3(1.1,0,3)]]:
		for p: Vector3 in tri: st.add_vertex(p)
	st.generate_normals(); SM._part(root,st.commit(),paint(0,"deck"))
	for side in [-1,1]:
		SM._beam(root,Vector3(side*1.05,.01,2.98),Vector3(side*1.05,1.48,-3),.045,paint(0,"frame"))
		for i in 8:
			var z:=2.6-i*.72; var y: float=(3-z)/6*1.48
			SM.block(root,Vector3(.09,.015,.23),Vector3(side*.91,y+.003,z),Mat.glow(Color("a7ebe2")),.015).rotation.x=atan(1.48/6)
	batch(root); return root

