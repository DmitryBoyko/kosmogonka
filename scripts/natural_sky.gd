extends RefCounted
const COUNTS=[1,1,2,2,2,1,3,2,3,3,2]
const DIRECTIONS=[Vector3(-.32,.75,1),Vector3(.23,.58,-1),Vector3(.06,.27,-1)]
const ZENITH := ["667aca","478fbc","ab777a","515197","318aba","5490b2","735490","527aa8","96607b","584b86","546fae"]
const HORIZON := ["c6c8ec","bce7dc","ffcfab","c19cd7","a9e8ec","fae1ac","ddaed8","d3e9f5","ffb698","bda6db","c5def1"]
static func create() -> ShaderMaterial:
	var material:=ShaderMaterial.new(); material.shader=preload("res://assets/spaceflight/day_sky.gdshader")
	material.set_shader_parameter("fast_clouds",preload("res://scripts/mobile_render.gd").enabled())
	material.set_shader_parameter("cloud_map",preload("res://assets/spaceflight/cloud_noise.png"))
	return material
static func configure(material:ShaderMaterial,index:int) -> void:
	material.set_shader_parameter("plaza_stars",preload("res://scripts/space_backdrops.gd").texture(index))
	index = preload("res://scripts/planets.gd").style_index(index)
	material.set_shader_parameter("sky_zenith",Color(ZENITH[index]))
	material.set_shader_parameter("sky_horizon",Color(HORIZON[index]))
	material.set_shader_parameter("sun_count",COUNTS[index%COUNTS.size()])
	material.set_shader_parameter("cloud_cover",[.40,.65,.16,.32,.54,.12,.72,.24,.16,.38,.20][index%COUNTS.size()])
	material.set_shader_parameter("sun_a",DIRECTIONS[0]); material.set_shader_parameter("sun_b",DIRECTIONS[1]); material.set_shader_parameter("sun_c",DIRECTIONS[2])

static func advance(material:ShaderMaterial,index:int,time:float,reduced:bool=false) -> Array[Vector3]:
	var result:Array[Vector3]=[]
	for i in 3:
		var angle:float=0. if reduced else sin(time*(.004+i*.0005)+index*.16)*.36
		var direction:Vector3=Basis(Vector3.UP,angle)*DIRECTIONS[i]
		result.append(direction)
	material.set_shader_parameter("sun_a",result[0]); material.set_shader_parameter("sun_b",result[1]); material.set_shader_parameter("sun_c",result[2])
	material.set_shader_parameter("flow_time",0. if reduced else time)
	return result
