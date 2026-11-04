extends RefCounted
const COUNTS=[1,1,2,2,2,1,3,2,3,3]
const DIRECTIONS=[Vector3(-.22,.38,-1),Vector3(.23,.58,-1),Vector3(.06,.27,-1)]
static func create() -> ShaderMaterial:
	var material:=ShaderMaterial.new(); material.shader=preload("res://assets/spaceflight/day_sky.gdshader"); return material
static func configure(material:ShaderMaterial,index:int) -> void:
	material.set_shader_parameter("sun_count",COUNTS[index%10])
	material.set_shader_parameter("cloud_cover",[.40,.65,.16,.32,.54,.12,.72,.24,.16,.38][index%10])
	material.set_shader_parameter("sun_a",DIRECTIONS[0]); material.set_shader_parameter("sun_b",DIRECTIONS[1]); material.set_shader_parameter("sun_c",DIRECTIONS[2])

static func advance(material:ShaderMaterial,index:int,time:float,reduced:bool=false) -> Array[Vector3]:
	var result:Array[Vector3]=[]
	for i in 3:
		var angle:float=0. if reduced else time*(.0012+i*.00015)
		var direction:Vector3=Basis(Vector3.UP,angle)*DIRECTIONS[i]
		result.append(direction)
	material.set_shader_parameter("sun_a",result[0]); material.set_shader_parameter("sun_b",result[1]); material.set_shader_parameter("sun_c",result[2])
	material.set_shader_parameter("flow_time",0. if reduced else time)
	return result
