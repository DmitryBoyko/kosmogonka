extends RefCounted
## Skin the supplied rigid source without changing its rest shape or textures.
static var meshes: Dictionary={}
const HIPS=[Vector3(-.17,-.10,.02),Vector3(.17,-.10,.02)]
const KNEES=[Vector3(-.27,-.36,-.025),Vector3(.27,-.36,-.025)]
const ANKLES=[Vector3(-.285,-.60,.055),Vector3(.285,-.60,.055)]
var skeleton: Skeleton3D
var phase := 0.
var motion := 0.
var fit := 1.

func build(model: Node3D, scale_value: float) -> void:
	fit=scale_value
	skeleton=Skeleton3D.new()
	skeleton.name="PatrolSkeleton"
	model.add_child(skeleton)
	bone("Root",-1,Vector3.ZERO)
	for side in 2:
		var hip:=bone("Hip%d"%side,0,HIPS[side])
		var knee:=bone("Knee%d"%side,hip,KNEES[side]-HIPS[side])
		bone("Ankle%d"%side,knee,ANKLES[side]-KNEES[side])
	for side in 2:
		var sign_value: float=-1. if side==0 else 1.
		var shoulder:=bone("Shoulder%d"%side,0,Vector3(sign_value*.29,.30,.09))
		bone("Elbow%d"%side,shoulder,Vector3(sign_value*.065,-.17,-.025))
	var skin:=Skin.new()
	skin.set_bind_count(skeleton.get_bone_count())
	for index in skeleton.get_bone_count():
		var rest:=skeleton.get_bone_rest(index)
		var parent:=skeleton.get_bone_parent(index)
		while parent>=0:
			rest=skeleton.get_bone_rest(parent)*rest
			parent=skeleton.get_bone_parent(parent)
		skin.set_bind_bone(index,index)
		skin.set_bind_pose(index,rest.affine_inverse())
	for piece: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		var source:=piece.mesh
		var key:=source.get_instance_id()
		if not meshes.has(key): meshes[key]=skinned(source)
		piece.mesh=meshes[key]
		piece.skin=skin
		piece.skeleton=piece.get_path_to(skeleton)

func bone(label: String, parent: int, at: Vector3) -> int:
	var index:=skeleton.get_bone_count()
	skeleton.add_bone(label)
	if parent>=0: skeleton.set_bone_parent(index,parent)
	skeleton.set_bone_rest(index,Transform3D(Basis.IDENTITY,at))
	skeleton.set_bone_pose_position(index,at)
	return index

static func skinned(source: Mesh) -> ArrayMesh:
	var result:=ArrayMesh.new()
	for surface in source.get_surface_count():
		var arrays:=source.surface_get_arrays(surface)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var indices:=PackedInt32Array(); indices.resize(vertices.size()*4)
		var weights:=PackedFloat32Array(); weights.resize(vertices.size()*4)
		for i in vertices.size():
			var p:=vertices[i]
			var side:=0 if p.x<0. else 1
			var first:=0; var second:=0; var mix_value:=0.
			if p.y<-.105 and absf(p.x)>.07:
				var hip:=1+side*3
				if p.y>-.18:
					first=0; second=hip; mix_value=smoothstep(-.105,-.18,p.y)
				elif p.y>-.40:
					first=hip; second=hip+1; mix_value=smoothstep(-.31,-.40,p.y)
				else:
					first=hip+1; second=hip+2; mix_value=smoothstep(-.54,-.62,p.y)
			elif absf(p.x)>.235 and p.y>-.10 and p.y<.38:
				var arm:=7+side*2
				if absf(p.x)<.29 and p.y>.20:
					first=0; second=arm; mix_value=smoothstep(.235,.29,absf(p.x))
				else:
					first=arm; second=arm+1; mix_value=smoothstep(.18,.08,p.y)
			indices[i*4]=first; indices[i*4+1]=second
			weights[i*4]=1.-mix_value; weights[i*4+1]=mix_value
		arrays[Mesh.ARRAY_BONES]=indices; arrays[Mesh.ARRAY_WEIGHTS]=weights
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		result.surface_set_material(surface,source.surface_get_material(surface))
	return result

func advance(dt: float, speed: float, reduced: bool) -> void:
	phase+=speed*dt/.65
	motion=move_toward(motion,clampf(speed/.55,0.,1.),dt*4.)
	for side in 2:
		var cycle:=fposmod(phase+side*.5,1.)
		var stride:=.65*.60/fit
		var offset: float
		var lift:=0.
		if cycle<.60:
			offset=lerpf(-stride*.5,stride*.5,cycle/.60)
		else:
			var t: float=(cycle-.60)/.40
			offset=lerpf(stride*.5,-stride*.5,smoothstep(0.,1.,t))
			lift=sin(t*PI)*.065
		var goal: Vector3=ANKLES[side]+Vector3(0,lift,offset)*motion
		solve_leg(side,goal)
		var arm:=7+side*2
		skeleton.set_bone_pose_rotation(arm,Quaternion(Vector3.RIGHT,-sin((phase+side*.5)*TAU)*.15*motion))
		skeleton.set_bone_pose_rotation(arm+1,Quaternion(Vector3.RIGHT,-.06*motion))
	# Reduced motion removes secondary rocking, never the readable walking cycle.
	skeleton.set_bone_pose_rotation(0,Quaternion(Vector3.FORWARD,0. if reduced else sin(phase*TAU)*.009*motion))

func solve_leg(side: int, goal: Vector3) -> void:
	var upper: Vector3=KNEES[side]-HIPS[side]
	var lower: Vector3=ANKLES[side]-KNEES[side]
	var a:=Vector2(upper.y,upper.z).length()
	var b:=Vector2(lower.y,lower.z).length()
	var target: Vector3=goal-HIPS[side]
	var d:=clampf(Vector2(target.y,target.z).length(),absf(a-b)+.001,a+b-.0001)
	var angle:=atan2(-target.z,-target.y)
	var thigh:=angle+acos(clampf((a*a+d*d-b*b)/(2.*a*d),-1.,1.))
	var shin:=thigh-acos(clampf((d*d-a*a-b*b)/(2.*a*b),-1.,1.))
	var rest_thigh:=atan2(-upper.z,-upper.y)
	var rest_shin:=atan2(-lower.z,-lower.y)
	var hip:=1+side*3
	var q1:=thigh-rest_thigh
	var q2:=(shin-thigh)-(rest_shin-rest_thigh)
	skeleton.set_bone_pose_rotation(hip,Quaternion(Vector3.RIGHT,q1))
	skeleton.set_bone_pose_rotation(hip+1,Quaternion(Vector3.RIGHT,q2))
	skeleton.set_bone_pose_rotation(hip+2,Quaternion(Vector3.RIGHT,-q1-q2))

