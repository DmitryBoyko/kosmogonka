extends RefCounted
const Planets=preload("res://scripts/planets.gd")
const G=preload("res://scripts/geometry.gd")
static var leaf_mesh:ArrayMesh
static var grass_mesh:ArrayMesh
static var mats:Dictionary={}
static var reduced_motion:=false
static var high_quality:=true
static func set_motion(reduced:bool) -> void:
	reduced_motion=reduced
	for m:ShaderMaterial in mats.values():
		m.set_shader_parameter("wind",0. if reduced else 1.)
		if m.shader.resource_path.ends_with("biome_life.gdshader"):m.set_shader_parameter("motion",0. if reduced else 1.)
static func material(planet:int,grass:bool=false) -> ShaderMaterial:
	var key:=str(planet)+str(grass)
	if mats.has(key): return mats[key]
	var m:=ShaderMaterial.new(); m.shader=preload("res://assets/surfaces/living_foliage.gdshader")
	m.set_shader_parameter("tint",Color(["628744","3e8b47","9a9851","478578"][Planets.biome(planet)]))
	m.set_shader_parameter("wind",0. if reduced_motion else 1.)
	mats[key]=m; return m

static func blade(grass:bool) -> ArrayMesh:
	if grass and grass_mesh: return grass_mesh
	if not grass and leaf_mesh: return leaf_mesh
	var st:=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var width:=.045 if grass else .19
	var pts:Array[Vector3]=[Vector3(0,0,0),Vector3(-width,.35,0),Vector3(width,.35,0),Vector3(-width*.55,.7,.08),Vector3(width*.55,.7,.08),Vector3(.025,1,.14)]
	var uv:Array[Vector2]=[Vector2(.5,0),Vector2(0,.35),Vector2(1,.35),Vector2(.12,.7),Vector2(.88,.7),Vector2(.5,1)]
	for strand in (7 if grass else 1):
		var turn:=Basis(Vector3.UP,strand*2.399)
		var shift:=Vector3(sin(strand*2.399),0,cos(strand*2.399))*.10 if grass else Vector3.ZERO
		for i in [0,2,1,1,2,4,1,4,3,3,4,5]:
			st.set_normal(turn*Vector3(0,0,1)); st.set_uv(uv[i]); st.add_vertex(turn*pts[i]+shift)
	var mesh:=st.commit()
	if grass: grass_mesh=mesh
	else: leaf_mesh=mesh
	return mesh

static func grass(root:Node3D,planet:int,seed_value:int,extent:Vector2=Vector2(46,30),center:Vector3=Vector3(0,-.22,-15)) -> void:
	var rng:=RandomNumberGenerator.new(); rng.seed=seed_value+731
	var multi:=MultiMesh.new(); multi.transform_format=MultiMesh.TRANSFORM_3D
	multi.mesh=blade(true)
	var mobile:=preload("res://scripts/mobile_render.gd").enabled()
	multi.instance_count=(220 if high_quality else 110) if mobile else (720 if high_quality else 320)
	for i in multi.instance_count:
		var x:=rng.randf_range(-extent.x*.5,extent.x*.5)
		# Keep the road and free-walk routes clear.
		if absf(x)<5: x=signf(x if x!=0 else 1)*rng.randf_range(5.2,extent.x*.5)
		var pos:=center+Vector3(x,0,rng.randf_range(-extent.y*.5,extent.y*.5))
		var scale_value:=Vector3(rng.randf_range(.7,1.5),rng.randf_range(.18,.42),1.)
		multi.set_instance_transform(i,Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(scale_value),pos))
	var node:=MultiMeshInstance3D.new(); root.add_child(node); node.multimesh=multi; node.material_override=material(planet,true)
	node.name="WindGrass"; node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if mobile: node.visibility_range_end=86.

static func tree(root:Node3D,at:Vector3,planet:int,seed_value:int=0) -> Node3D:
	var rng:=RandomNumberGenerator.new(); rng.seed=seed_value+538
	var trunk:=Node3D.new(); root.add_child(trunk); trunk.position=at
	G.link(trunk,Vector3.ZERO,Vector3(.1,3.3,0),.17,"78634a")
	var crown:=Node3D.new(); trunk.add_child(crown); crown.position=Vector3(.1,2.2,0)
	crown.set_meta("motion","plant"); crown.set_meta("phase",float(seed_value))
	for i in 5:
		var a:=i*TAU/5; G.link(trunk,Vector3(.1,2,0),Vector3(sin(a)*1.5,2.8+(i%2)*.7,cos(a)*1.5),.065,"78634a")
	var multi:=MultiMesh.new(); multi.transform_format=MultiMesh.TRANSFORM_3D; multi.mesh=blade(false); multi.instance_count=150
	for i in multi.instance_count:
		var a:=rng.randf()*TAU; var r:=sqrt(rng.randf())*1.9
		var pos:=Vector3(cos(a)*r,rng.randf_range(.2,1.9)-r*.28,sin(a)*r)
		var basis:=Basis.from_euler(Vector3(rng.randf_range(-1.2,.3),rng.randf()*TAU,rng.randf_range(-1,1)))
		multi.set_instance_transform(i,Transform3D(basis.scaled(Vector3.ONE*rng.randf_range(.6,1.1)),pos))
	var leaves:=MultiMeshInstance3D.new(); crown.add_child(leaves); leaves.multimesh=multi; leaves.material_override=material(planet)
	return crown

static func bush(planet:int,seed_value:int) -> Node3D:
	var root:=Node3D.new(); root.name="LeafyObstacle"
	var rng:=RandomNumberGenerator.new(); rng.seed=seed_value+178
	var multi:=MultiMesh.new(); multi.transform_format=MultiMesh.TRANSFORM_3D; multi.mesh=blade(false); multi.instance_count=180
	for i in multi.instance_count:
		var h:=rng.randf_range(.12,2.30); var a:=rng.randf()*TAU
		var radius:=sqrt(rng.randf())*(1.-h/4.)*.88
		var basis:=Basis.from_euler(Vector3(rng.randf_range(-1.2,.25),a,rng.randf_range(-.7,.7)))
		multi.set_instance_transform(i,Transform3D(basis.scaled(Vector3.ONE*.65),Vector3(sin(a)*radius,h,cos(a)*radius)))
	for i in 5: G.link(root,Vector3.ZERO,Vector3(sin(i)*.5,1.6+sin(i)*.4,cos(i)*.5),.06,"78634a")
	var leaves:=MultiMeshInstance3D.new(); root.add_child(leaves); leaves.multimesh=multi; leaves.material_override=material(planet)
	return root
