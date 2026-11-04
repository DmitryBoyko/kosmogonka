extends RefCounted
const G=preload("res://scripts/geometry.gd")
const MAPS=[preload("res://assets/spaceflight/2k_earth_daymap.jpg"),preload("res://assets/spaceflight/2k_mars.jpg"),preload("res://assets/spaceflight/2k_moon.jpg"),preload("res://assets/spaceflight/2k_venus_surface.jpg")]
static var materials:Dictionary={}
static var shared_mesh:SphereMesh
static func surface(index:int,distant:bool=false) -> ShaderMaterial:
	var key:=str(index)+str(distant)
	if materials.has(key): return materials[key]
	var mat:=ShaderMaterial.new(); mat.shader=preload("res://assets/spaceflight/planet_surface.gdshader")
	var type:int=[0,0,1,0,0,1,0,2,3,2][index%10]
	mat.set_shader_parameter("surface_map",MAPS[type]); mat.set_shader_parameter("longitude",index*.113)
	mat.set_shader_parameter("tint",[Color("ecf3ff"),Color("e8f5e1"),Color("fff0dc"),Color("d5e1ee"),Color("d6f4f5"),Color("fff0c8"),Color("e0ebcf"),Color("d2e8f1"),Color("a88b76"),Color("d8d4e2")][index%10])
	mat.set_shader_parameter("distant",distant); materials[key]=mat; return mat

static func create(index:int,diameter:float,at:Vector3=Vector3.ZERO,distant:bool=false) -> Node3D:
	var root:=Node3D.new(); root.name="NaturalPlanet"; root.position=at
	if shared_mesh==null:
		shared_mesh=SphereMesh.new(); shared_mesh.radius=.5; shared_mesh.height=1.; shared_mesh.radial_segments=64; shared_mesh.rings=32
	var mesh:=shared_mesh
	var body:=G.part(root,mesh,Vector3.ZERO,surface(index,distant)); body.name="Surface"; body.scale=Vector3.ONE*diameter
	var cloud:=ShaderMaterial.new(); cloud.shader=preload("res://assets/spaceflight/cloud_layer.gdshader")
	cloud.set_shader_parameter("cloud_map",preload("res://assets/spaceflight/2k_earth_clouds.jpg"))
	cloud.set_shader_parameter("coverage",[.66,.86,.19,.48,.80,.16,.90,.13,.24,.35][index%10])
	var clouds:=G.part(root,mesh,Vector3.ZERO,cloud); clouds.name="Clouds"; clouds.scale=Vector3.ONE*diameter*1.008
	clouds.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var atmosphere:=ShaderMaterial.new(); atmosphere.shader=preload("res://assets/spaceflight/atmosphere.gdshader")
	atmosphere.set_shader_parameter("tint",[Color("68a4ff"),Color("7fbaec"),Color("dcae75"),Color("8cace2"),Color("78b9ef"),Color("e7c391"),Color("8db5d5"),Color("b1c9f1"),Color("c6a27c"),Color("9da7d6")][index%10])
	var air:=G.part(root,mesh,Vector3.ZERO,atmosphere); air.name="Atmosphere"; air.scale=Vector3.ONE*diameter*1.035
	air.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.set_meta("planet_index",index); return root

static func advance(root:Node3D,clock:float) -> void:
	root.get_node("Clouds").rotation.y=clock*.011
