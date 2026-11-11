extends RefCounted

const Course = preload("res://scripts/course.gd")
const Loops = preload("res://scripts/loop_layout.gd")
# Start and end are course metres. Amplitude is a signed cross-track offset.
var turns: Array[Vector4] = []
var grades: Array[Vector3] = []
const RELIEF := [8.,7.,9.,5.5,4.5,7.,8.5,10.,10.5,9.,10.]
const MAX_GRADE := .20
const LANDSCAPE_WIDTH := 255.
const RELIEF_HEIGHTS := [26.,32.,36.,24.,0.,32.,34.,47.,42.,30.,36.]
var world := 0
var course_length := 0.
var seed_value := 0
var distance_value := 0.
var view_basis := Basis.IDENTITY
var view_origin := Vector3.ZERO

func build(planet: int, seed_value_in: int, events: Array[Dictionary]) -> void:
	turns.clear()
	grades.clear()
	seed_value=seed_value_in
	var length_value:=Course.length_for(planet)
	world=planet
	course_length=length_value
	var occupied:Array[Vector2]=[
		Vector2(0,186.),Vector2(Course.FRONT_START-30.,Course.FRONT_END+Course.TRANSITION+32.),
		Vector2(1031.,1514.),Vector2(length_value*.5-30.,length_value*.5+30.),
		Vector2(length_value-152.,length_value+80.)
	]
	for kind:String in Loops.kinds(planet):
		var bounds:=Loops.clearance(kind)
		occupied.append(Vector2(-bounds.end.z-44.,-bounds.position.z+45.))
	for event:Dictionary in events:
		if event.kind in ["stairs","stairs_down","skycarrier","tunnel","basement","passage","carrier","ramp","mirror_portal"]:
			occupied.append(Vector2(event.s-event.length*.5-17.,event.s+event.length*.5+17.))
	occupied.sort_custom(func(a:Vector2,b:Vector2)->bool:return a.x<b.x)
	var rng:=RandomNumberGenerator.new()
	rng.seed=seed_value ^ ((planet+1)*31627)
	var start:=0.
	var direction:=-1. if rng.randf()<.5 else 1.
	var elevation_sign:=1.
	for span in occupied:
		var length_free:=span.x-start
		if length_free>=57.:
			var count:=maxi(1,ceili(length_free/160.))
			var segment:=length_free/count
			for i in count:
				var a:=start+float(i)*segment+rng.randf_range(1.,minf(11.,segment*.12))
				var b:=start+float(i+1)*segment-rng.randf_range(1.,minf(11.,segment*.12))
				var width:=b-a
				if width<49.:
					continue
				var amplitude:=minf(width*lerpf(.13,.20,planet/10.),20.)*rng.randf_range(.83,1.07)
				turns.append(Vector4(a,b,direction*amplitude,rng.randf_range(.81,1.19)))
				var peak:=minf(RELIEF[planet]*rng.randf_range(.81,1.10),width*MAX_GRADE/PI)
				grades.append(Vector3(a,b,peak*elevation_sign))
				if planet!=4: elevation_sign*=-1.
				direction*=-1.
		start=maxf(start,span.y)
	set_distance(0.)

func sample(s: float) -> Vector2:
	for turn in turns:
		if s<turn.x:
			break
		if s<turn.y:
			var width:=turn.y-turn.x
			var u:=(s-turn.x)/width
			var bias:=turn.w-1.
			var phase:=TAU*(u+bias*u*(1.-u))
			var slope:=TAU*(1.+bias*(1.-2.*u))/width
			return Vector2(turn.z*.5*(1.-cos(phase)),turn.z*.5*sin(phase)*slope)
	return Vector2.ZERO

func set_distance(next:float) -> void:
	distance_value=next
	var at:=sample(next)
	view_basis=Basis(Vector3.UP,atan(at.y))
	view_origin=view_basis*Vector3(-at.x,-elevation(next),0.)

func elevation(s: float) -> float:
	return grade(s).x

func grade(s: float) -> Vector2:
	for hill in grades:
		if s<hill.x: break
		if s>=hill.y: continue
		var width := hill.y-hill.x
		var phase := TAU*(s-hill.x)/width
		return Vector2(hill.z*.5*(1.-cos(phase)),hill.z*PI/width*sin(phase))
	return Vector2.ZERO

func roadbed_height(s: float, world_x: float) -> float:
	return elevation(s)*(1.-smoothstep(27.,63.5,absf(world_x)))

func terrain_height(s: float, world_x: float) -> float:
	return terrain_profile(s,world_x,sample(s).x)

func terrain_profile(s:float, world_x:float, centre:float) -> float:
	var bed:=roadbed_height(s,world_x)
	if world==4: return bed
	var lateral:=world_x-centre
	var edge:=absf(lateral)
	if edge<=8. or absf(world_x)>=LANDSCAPE_WIDTH: return bed
	var district:=minf(s,absf(course_length-s))
	var verge:=lerpf(36.,8.,smoothstep(12.,105.,district))
	var fade:=smoothstep(verge,verge+22.,edge)*(1.-smoothstep(172.,LANDSCAPE_WIDTH,absf(world_x)))
	var offset:=float(posmod(seed_value,7919))*.22*smoothstep(180.,310.,s)+float(world)*21.
	var rolling:=.5+.5*sin((s+offset)*.065+lateral*.105+sin(s*.031-lateral*.08)*.7)
	var ridges:=.5+.5*cos((s-offset)*.021+lateral*.036+sin(s*.012+lateral*.033))
	var foothills:=rolling*rolling*4.4
	var mountains:float=smoothstep(25.,108.,edge)*pow(ridges,2.2)*RELIEF_HEIGHTS[world]
	return bed+fade*(foothills+mountains)

func view_height(z: float) -> float:
	return elevation(distance_value-z)+view_origin.y

func view_transform() -> Transform3D:
	return Transform3D(view_basis,view_origin)

func local_curve(point:Vector3,s:float) -> Vector3:
	var at:=sample(s)
	var yaw:=atan(at.y)
	return Vector3(at.x+point.x*cos(yaw),point.y+elevation(s),point.z+point.x*sin(yaw))

func map(point:Vector3) -> Vector3:
	return view_basis*local_curve(point,distance_value-point.z)+view_origin

func map_ground(point: Vector3, sea_level: bool = false) -> Vector3:
	var s := distance_value-point.z
	var at := local_curve(point,s)
	at.y = point.y+(0. if sea_level else terrain_height(s,at.x))
	return view_basis*at+view_origin

func heading(s:float) -> float:
	return view_basis.get_euler().y-atan(sample(s).y)

func bend_mesh(mesh: Mesh, placement: Transform3D, start:float, ground: bool = false) -> ArrayMesh:
	var result:=ArrayMesh.new()
	for surface in mesh.get_surface_count():
		var arrays:=mesh.surface_get_arrays(surface)
		var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
		for i in vertices.size():
			var point:=placement*vertices[i]
			var s:=start-point.z
			vertices[i]=point+Vector3.UP*roadbed_height(s,point.x) if ground else local_curve(point,s)
			if i<normals.size():
				var yaw:float=0. if ground else -atan(sample(s).y)
				var slope:=grade(s).y*(1.-smoothstep(27.,63.5,absf(point.x))) if ground else grade(s).y
				normals[i]=Basis(Vector3.UP,yaw)*Basis(Vector3.RIGHT,atan(slope))*(placement.basis*normals[i]).normalized()
		arrays[Mesh.ARRAY_VERTEX]=vertices
		arrays[Mesh.ARRAY_NORMAL]=normals
		arrays[Mesh.ARRAY_TANGENT]=null
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return result

func changes_chunk(index:int) -> bool:
	var start:=index*30.
	for turn in turns:
		if turn.x>=start+30.:
			break
		if turn.y>start:
			return true
	return false

func grades_chunk(index: int) -> bool:
	var start:=index*30.
	for hill in grades:
		if hill.x>=start+30.: break
		if hill.y>start: return true
	return false
