extends MultiMeshInstance3D
## Fixed allocation and one draw call for decorative stars and sparks.
var capacity:=48
var particles:Array[Dictionary]=[]
var cursor:=0
var rng:=RandomNumberGenerator.new()
var live_count:=0
func _ready() -> void:
	var quad:=QuadMesh.new(); quad.size=Vector2.ONE
	multimesh=MultiMesh.new(); multimesh.transform_format=MultiMesh.TRANSFORM_3D; multimesh.use_colors=true; multimesh.use_custom_data=true; multimesh.mesh=quad; multimesh.instance_count=capacity
	multimesh.custom_aabb=AABB(Vector3(-150,-100,-150),Vector3(300,250,300))
	var mat:=ShaderMaterial.new(); mat.shader=preload("res://assets/surfaces/stellar_particle.gdshader"); material_override=mat
	cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; rng.seed=7919
	for i in capacity: particles.append({"age":10.,"life":1.,"p":Vector3.ZERO,"v":Vector3.ZERO,"size":.1,"star":false,"spin":0.,"color":Color.WHITE,"gravity":2.}); multimesh.set_instance_color(i,Color(0,0,0,0))
	hide()
func emit_particle(at:Vector3,velocity:Vector3,life:float,size_value:float,color:Color,star:bool,gravity:float=2.) -> void:
	var p:Dictionary=particles[cursor]; cursor=(cursor+1)%capacity
	p.age=0.;p.life=life;p.p=at;p.v=velocity;p.size=size_value;p.star=star;p.spin=rng.randf_range(-3,3);p.color=color;p.gravity=gravity
func clear() -> void:
	for i in particles.size(): particles[i].age=10.; multimesh.set_instance_color(i,Color(0,0,0,0))
	live_count=0;hide()
func advance_particles(dt:float,scroll:float=0.) -> void:
	live_count=0
	for i in particles.size():
		var p:Dictionary=particles[i];p.age+=dt
		if p.age>=p.life: multimesh.set_instance_color(i,Color(0,0,0,0));continue
		live_count+=1;p.v*=exp(-dt*.65);p.v.y-=p.gravity*dt;p.p+=p.v*dt;p.p.z+=scroll
		var scale_value:float=p.size*(1.-.4*p.age/p.life)
		var basis_value:=Basis.from_scale(Vector3(scale_value if p.star else scale_value*.34,scale_value,scale_value))
		multimesh.set_instance_transform(i,Transform3D(basis_value,p.p))
		var color:Color=p.color;color.a=pow(1.-p.age/p.life,.8)
		multimesh.set_instance_color(i,color);multimesh.set_instance_custom_data(i,Color(1. if p.star else 0.,p.spin*p.age,0.,0.))
	visible=live_count>0
