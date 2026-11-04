extends MultiMeshInstance3D
const CAPACITY:=12
var pool:Array[Dictionary]=[]
var cursor:=0
var wait:=0.
var side:=-1.
func _ready() -> void:
	var quad:=QuadMesh.new(); quad.size=Vector2.ONE*.07
	multimesh=MultiMesh.new(); multimesh.transform_format=MultiMesh.TRANSFORM_3D; multimesh.use_colors=true; multimesh.mesh=quad; multimesh.instance_count=CAPACITY
	var mat:=ShaderMaterial.new(); mat.shader=preload("res://assets/surfaces/foot_spark.gdshader"); material_override=mat
	cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in CAPACITY: pool.append({"age":1.,"life":.2,"p":Vector3.ZERO,"v":Vector3.ZERO}); multimesh.set_instance_color(i,Color(1,1,1,0))
func advance(dt:float,feet:Vector3,speed:float,active:bool,reduced:bool) -> void:
	wait-=dt
	if active and not reduced and wait<=0:
		wait=.18; side=-side
		for i in 2:
			var item:Dictionary=pool[cursor]; cursor=(cursor+1)%CAPACITY
			item.age=0.; item.life=.16+randf()*.09; item.p=feet+Vector3(side*.16,.03,.05)
			item.v=Vector3(randf_range(-.5,.5),randf_range(.6,1.1),randf_range(.4,1.2))
	var any:=false
	for i in CAPACITY:
		var item:Dictionary=pool[i]; item.age+=dt
		if item.age>=item.life or reduced: multimesh.set_instance_color(i,Color(1,1,1,0)); continue
		any=true; item.v.y-=dt*5.; item.p+=item.v*dt; item.p.z+=speed*dt*.55
		var opacity:float=(1.-item.age/item.life)*.7
		multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY,item.p))
		multimesh.set_instance_color(i,Color(1.,.76 if i%2 else .90,.45 if i%2 else .75,opacity))
	visible=any
