extends RefCounted
const G=preload("res://scripts/geometry.gd")
const Identity=preload("res://scripts/planet_identity.gd")
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
	var profile:=Identity.get_profile(index)
	mat.set_shader_parameter("identity",posmod(index,10))
	mat.set_shader_parameter("terrain_seed",profile.seed)
	mat.set_shader_parameter("land_color",Color(profile.land))
	mat.set_shader_parameter("ocean_color",Color(profile.water))
	mat.set_shader_parameter("ridge_color",Color(profile.ridge))
	mat.set_shader_parameter("sea_level",profile.sea)
	mat.set_shader_parameter("ice_coverage",profile.ice)
	mat.set_shader_parameter("distant",distant); materials[key]=mat; return mat

static func create(index:int,diameter:float,at:Vector3=Vector3.ZERO,distant:bool=false) -> Node3D:
	var root:=Node3D.new(); root.name="NaturalPlanet"; root.position=at
	var profile:=Identity.get_profile(index)
	if shared_mesh==null:
		shared_mesh=SphereMesh.new(); shared_mesh.radius=.5; shared_mesh.height=1.; shared_mesh.radial_segments=64; shared_mesh.rings=32
	var mesh:=shared_mesh
	var body:=G.part(root,mesh,Vector3.ZERO,surface(index,distant)); body.name="Surface"; body.scale=Vector3.ONE*diameter
	var cloud:=ShaderMaterial.new(); cloud.shader=preload("res://assets/spaceflight/cloud_layer.gdshader")
	cloud.set_shader_parameter("cloud_map",preload("res://assets/spaceflight/2k_earth_clouds.jpg"))
	cloud.set_shader_parameter("coverage",profile.coverage)
	cloud.set_shader_parameter("cloud_tint",Color(profile.cloud))
	var clouds:=G.part(root,mesh,Vector3.ZERO,cloud); clouds.name="Clouds"; clouds.scale=Vector3.ONE*diameter*1.008
	clouds.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var atmosphere:=ShaderMaterial.new(); atmosphere.shader=preload("res://assets/spaceflight/atmosphere.gdshader")
	atmosphere.set_shader_parameter("tint",Color(profile.air))
	var air:=G.part(root,mesh,Vector3.ZERO,atmosphere); air.name="Atmosphere"; air.scale=Vector3.ONE*diameter*1.035
	air.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not distant:
		var signature:=Node3D.new(); signature.name="Signature"; root.add_child(signature)
		for i in int(profile.rings):
			var ring:=G.ring(signature,diameter*(.60+i*.105),diameter*(.69+i*.075),Vector3.ZERO,"d4b798" if index==2 else "bbdbe9" if index==7 else "8e78c4",.12 if index==9 else 0.)
			ring.name="Ring"+str(i); ring.rotation_degrees=Vector3(24 if index==2 else -30 if index==7 else 58,0,-19)
			ring.scale.y=.018; ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var ring_material:=ShaderMaterial.new(); ring_material.shader=preload("res://assets/spaceflight/planet_ring.gdshader")
			ring_material.set_shader_parameter("tint",Color("d4b798" if index==2 else "bbdbe9" if index==7 else "8e78c4"))
			ring_material.set_shader_parameter("inner_radius",diameter*(.60+i*.105))
			ring_material.set_shader_parameter("outer_radius",diameter*(.69+i*.075))
			ring.material_override=ring_material
		if index==3:
			for i in 4:
				var angle:float=i*TAU/4.+.35
				var station:=Node3D.new(); signature.add_child(station); station.position=Vector3(cos(angle)*diameter*.62,diameter*.08,sin(angle)*diameter*.62)
				G.box(station,Vector3.ONE*diameter*.018,Vector3.ZERO,"849aaa")
				for side in [-1,1]: G.box(station,Vector3(diameter*.045,.025,diameter*.022),Vector3(side*diameter*.029,0,0),"326788",.12)
	root.set_meta("planet_index",index); root.set_meta("identity",profile.id); return root

static func advance(root:Node3D,clock:float) -> void:
	root.get_node("Clouds").rotation.y=clock*.011
