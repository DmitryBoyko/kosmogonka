extends RefCounted
## Planet-specific, instanced ecosystems; no generic green forest on water/lava/ice.
static var meshes:Dictionary={}
static var materials:Dictionary={}
const G=preload("res://scripts/geometry.gd")
static func part(st:SurfaceTool,mesh:Mesh,at:Vector3,size:Vector3,color:Color,rotation:Vector3=Vector3.ZERO) -> void:
	var arrays:=mesh.surface_get_arrays(0);var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL];var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
	var basis:=Basis.from_euler(rotation).scaled(size)
	for i in (indices.size() if not indices.is_empty() else vertices.size()):
		var index:int=indices[i] if not indices.is_empty() else i
		st.set_color(color);st.set_normal((basis.inverse().transposed()*normals[index]).normalized());st.add_vertex(basis*vertices[index]+at)
static func mesh(kind:String) -> ArrayMesh:
	if meshes.has(kind):return meshes[kind]
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cylinder:=CylinderMesh.new();cylinder.top_radius=.5;cylinder.bottom_radius=.5;cylinder.height=1.;cylinder.radial_segments=8
	var ball:=SphereMesh.new();ball.radius=.5;ball.height=1.;ball.radial_segments=10;ball.rings=5
	if kind=="mirror":
		var panel:=BoxMesh.new();panel.size=Vector3.ONE
		part(st,panel,Vector3(0,.6,0),Vector3(.45,1.2,.10),Color("a9cfe9"),Vector3(0,.4,.15))
		part(st,panel,Vector3(.30,.36,.16),Vector3(.35,.72,.08),Color("dfa8da"),Vector3(0,-.5,-.20))
	elif kind in ["crystal","ice","silicon"]:
		cylinder.top_radius=.035;cylinder.radial_segments=6
		part(st,cylinder,Vector3(0,.5,0),Vector3(.6,1.,.6),Color("b0e7ec"))
		part(st,cylinder,Vector3(.24,.25,.12),Vector3(.32,.5,.32),Color("83bcc8"),Vector3(0,0,-.23))
	elif kind=="fungus":
		part(st,cylinder,Vector3(0,.45,0),Vector3(.18,.9,.18),Color(.7,.73,.63,0))
		part(st,ball,Vector3(0,.96,0),Vector3(1.3,.48,1.3),Color(.62,.36,.74,1))
	elif kind=="coral":
		for i in 5:
			var a:=i*TAU/5.;var height:=.7+float(i%3)*.24
			part(st,cylinder,Vector3(sin(a)*.24,height*.5,cos(a)*.24),Vector3(.13,height,.13),Color("a788a7"),Vector3(sin(a)*.35,0,cos(a)*.35))
			part(st,ball,Vector3(sin(a)*.4,height,cos(a)*.4),Vector3(.35,.25,.35),Color("7bcbbd"))
	elif kind=="cactus":
		part(st,cylinder,Vector3(0,.65,0),Vector3(.32,1.3,.32),Color("9ca66b"))
		part(st,ball,Vector3(0,1.3,0),Vector3(.32,.32,.32),Color("c8b878"))
		for side in [-1.,1.]:
			part(st,cylinder,Vector3(side*.26,.65,0),Vector3(.19,.6,.19),Color("949d67"),Vector3(0,0,side*.8))
	else:
		part(st,ball,Vector3(0,.35,0),Vector3(1.,.8,.9),Color(.18,.16,.18,.3) if kind=="basalt" else Color(.49,.42,.64,.1))
	var result:=st.commit();meshes[kind]=result;return result
static func material(world:int) -> ShaderMaterial:
	if materials.has(world):return materials[world]
	var mat:=ShaderMaterial.new();mat.shader=preload("res://assets/surfaces/biome_life.gdshader");mat.set_shader_parameter("world",world);mat.set_shader_parameter("motion",0. if preload("res://scripts/natural_flora.gd").reduced_motion else 1.)
	materials[world]=mat;preload("res://scripts/natural_flora.gd").mats["biome-life-"+str(world)]=mat
	return mat
static func populate(parent:Node3D,world:int,index:int,quality:bool) -> Node3D:
	var root:=Node3D.new();parent.add_child(root);root.name="PlanetEcosystem"
	root.set_meta("biome_world",world)
	var rng:=RandomNumberGenerator.new();rng.seed=world*7919+index*137+53
	var kind:String={0:"crystal",2:"crystal",3:"silicon",4:"coral",5:"cactus",6:"fungus",7:"ice",8:"basalt",9:"mineral",10:"mirror"}.get(world,"fungus")
	var count:int=180 if world==0 else 110 if world in [3,6,7] else 70 if world==4 else 55 if world in [2,5,8,9] else 40
	var multi:=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D;multi.use_colors=true;multi.use_custom_data=true;multi.mesh=mesh(kind);multi.instance_count=count
	var large_transforms:Array[Transform3D]=[];var large_colors:Array[Color]=[];var solids:Array=[]
	for i in count:
		var side:float=-1. if i%2==0 else 1.;var x:float=side*rng.randf_range(5.4,31.);var z:float=rng.randf_range(-29.8,-.2)
		var large:bool=i<8;var height:float=rng.randf_range(3.,8.) if large else rng.randf_range(.45,2.0)
		if world in [2,5]:height*=.65
		if large:x=side*rng.randf_range(13.,29.)
		var finish_z:float=z-index*30.+preload("res://scripts/course.gd").length_for(world)
		for home:Vector2 in [Vector2(-21,10),Vector2(21,10),Vector2(0,-51)]:
			if absf(x-home.x)<3.5 and absf(finish_z-home.y)<4.:x=side*34.
		var y:float=-.65 if world==4 else rng.randf_range(1.,3.) if world==9 else -.22
		var basis:=Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3(height*.65,height,height*.65))
		for loop_kind:String in preload("res://scripts/loop_layout.gd").kinds(world):
			var reserve:=preload("res://scripts/loop_layout.gd").clearance(loop_kind)
			var bounds:AABB=Transform3D(basis,Vector3(x,y,z-index*30.))*multi.mesh.get_aabb()
			if bounds.intersects(reserve):x=reserve.end.x+bounds.size.x*.5+1. if side>0 else reserve.position.x-bounds.size.x*.5-1.
		var transform:=Transform3D(basis,Vector3(x,y,z));multi.set_instance_transform(i,transform)
		var tint:=Color.WHITE
		if world==2:tint=Color("e3bc73")
		elif world==3:tint=Color("6fcad2") if i%2==0 else Color("b381cc")
		elif world==7:tint=Color("c6e9f4")
		multi.set_instance_color(i,tint);multi.set_instance_custom_data(i,Color(rng.randf(),0,0,0))
		if large:
			large_transforms.append(transform);large_colors.append(tint)
			if world!=9:solids.append(transform*multi.mesh.get_aabb())
	var node:=MultiMeshInstance3D.new();root.add_child(node);node.name="BiomePopulation";node.multimesh=multi;node.material_override=material(world)
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shadow_multi:=MultiMesh.new();shadow_multi.transform_format=MultiMesh.TRANSFORM_3D;shadow_multi.use_colors=true;shadow_multi.mesh=multi.mesh;shadow_multi.instance_count=large_transforms.size()
	for i in large_transforms.size():shadow_multi.set_instance_transform(i,large_transforms[i]);shadow_multi.set_instance_color(i,large_colors[i])
	var shadows:=MultiMeshInstance3D.new();root.add_child(shadows);shadows.name="LargeBiomeShadows";shadows.multimesh=shadow_multi;shadows.material_override=material(world);shadows.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	root.set_meta("solid_nature_boxes",solids)
	if not quality:multi.visible_instance_count=int(count*.65)
	return root
