extends RefCounted
## Three fixed MultiMeshes per 30 m chunk; no individual creature nodes or CPU animation.
const Flora=preload("res://scripts/natural_flora.gd")
static var flower_mesh:ArrayMesh
static var fern_mesh:ArrayMesh
static var wing_mesh:ArrayMesh
static var materials:Dictionary={}
static func triangle(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,color:Color,normal:Vector3=Vector3.UP) -> void:
	for p in [a,b,c]:st.set_color(color);st.set_normal(normal);st.add_vertex(p)
static func prepare_meshes() -> void:
	if flower_mesh: return
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for axis in [Vector3.RIGHT,Vector3.BACK]:
		triangle(st,-axis*.018,axis*.018,Vector3(0,.62,0)+axis*.018,Color.BLACK,Vector3.FORWARD)
		triangle(st,-axis*.018,Vector3(0,.62,0)+axis*.018,Vector3(0,.62,0)-axis*.018,Color.BLACK,Vector3.FORWARD)
		triangle(st,Vector3(0,.18,0),axis*.28+Vector3.UP*.36,Vector3(0,.30,0),Color.BLACK)
	for i in 5:
		var a:=i*TAU/5.;var radial:=Vector3(sin(a),0,cos(a));var tangent:=Vector3(cos(a),0,-sin(a));var center:=Vector3(0,.62,0)
		triangle(st,center,center+radial*.22-tangent*.12,center+radial*.36+Vector3.UP*.04,Color.WHITE)
		triangle(st,center,center+radial*.36+Vector3.UP*.04,center+radial*.22+tangent*.12,Color.WHITE)
	flower_mesh=st.commit()
	st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 7:
		var basis:=Basis(Vector3.UP,i*2.399)*Basis(Vector3.RIGHT,-.45-float(i%3)*.22)
		st.append_from(Flora.blade(false),0,Transform3D(basis,Vector3.ZERO))
	fern_mesh=st.commit()
	st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in [-1.,1.]:
		triangle(st,Vector3.ZERO,Vector3(side*.20,0,-.19),Vector3(side*.33,0,.04),Color.WHITE)
		triangle(st,Vector3.ZERO,Vector3(side*.33,0,.04),Vector3(side*.13,0,.20),Color.WHITE)
	wing_mesh=st.commit()
static func material(world:int,drifter:bool) -> ShaderMaterial:
	var key:="meadow%d_%s"%[world,str(drifter)]
	if materials.has(key):return materials[key]
	var mat:=ShaderMaterial.new();mat.shader=preload("res://assets/surfaces/meadow_life.gdshader")
	mat.set_shader_parameter("flower_color",Color(["f1a5cf","e7bb80","d8bc8c","93d9df","e2aaa0","e8cc7a","bfaae5","b8dcde","d4b174","9fd4d8","c5c8ff"][world]))
	mat.set_shader_parameter("drifter",drifter);mat.set_shader_parameter("wind",0. if Flora.reduced_motion else 1.)
	materials[key]=mat;Flora.mats[key]=mat;return mat
static func populate(parent:Node3D,world:int,index:int,quality:bool) -> void:
	prepare_meshes()
	var root:=Node3D.new();parent.add_child(root);root.name="RoadsideBiology"
	var rng:=RandomNumberGenerator.new();rng.seed=world*7919+index*137+41
	for kind in 3:
		var multi:=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D;multi.use_custom_data=true
		multi.mesh=[fern_mesh,flower_mesh,wing_mesh][kind];multi.instance_count=[80,48,6][kind]
		for i in multi.instance_count:
			var side:float=-1. if i%2==0 else 1.
			var x:float=side*rng.randf_range(5.3,10.5 if kind==0 else 8.3 if kind==1 else 14.)
			var y:float=rng.randf_range(.8,2.1) if kind==2 else -.21
			var size_value:float=rng.randf_range(.36,.76) if kind==0 else rng.randf_range(.7,1.35) if kind==1 else rng.randf_range(.55,1.0)
			multi.set_instance_transform(i,Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*size_value),Vector3(x,y,rng.randf_range(-29.8,-.2))))
			multi.set_instance_custom_data(i,Color(rng.randf(),rng.randf(),0,0))
		var node:=MultiMeshInstance3D.new();root.add_child(node);node.name=["MeadowFerns","MeadowFlowers","MeadowDrifters"][kind]
		node.multimesh=multi;node.material_override=Flora.material(world) if kind==0 else material(world,kind==2)
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	set_quality(root,quality)
static func set_quality(root:Node,quality:bool) -> void:
	for node:MultiMeshInstance3D in root.find_children("Meadow*","MultiMeshInstance3D",true,false):
		var low:int={"MeadowFerns":36,"MeadowFlowers":24,"MeadowDrifters":3}[node.name]
		node.multimesh.visible_instance_count=node.multimesh.instance_count if quality else low
