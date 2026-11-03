extends SceneTree
const Transport=preload("res://scripts/hover_transport.gd")
const Props=preload("res://scripts/props.gd")
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures.append(label); push_error(label)
func highest(root_node: Node3D, x: float, z: float) -> float:
	var y: float=-100
	for piece: MeshInstance3D in root_node.get_children():
		var faces:=piece.mesh.get_faces()
		for i in range(0,faces.size(),3):
			var hit=Geometry3D.ray_intersects_triangle(Vector3(x,5,z),Vector3.DOWN,faces[i],faces[i+1],faces[i+2])
			if hit!=null: y=maxf(y,hit.y)
	return y
func run() -> void:
	for kind in ["carrier","truck","broken","board"]:
		for variant in 3:
			var vehicle:=Transport.build(kind,variant)
			var copy:=Transport.build(kind,variant)
			check(vehicle.get_child_count()<=11,"material batching limits submissions: "+kind)
			check(vehicle.get_child(0).mesh==copy.get_child(0).mesh,"models share immutable meshes")
			var textured:=0
			var bounds:=AABB()
			for piece: MeshInstance3D in vehicle.get_children():
				bounds=bounds.merge(piece.mesh.get_aabb())
				if piece.material_override is ShaderMaterial:
					textured+=1
					check(piece.material_override.get_shader_parameter("surface_map") is Texture2D,"actual metal texture loaded")
			check(textured==3,"paint, frame and non-slip metal have separate finishes")
			check(bounds.size.x<2.5,"vehicle fits lane")
			check(bounds.end.y<=3.01,"truck matches declared jump clearance")
			check(bounds.size.z<=float(vehicle.get_meta("transport_length"))+.1,"visual length matches encounter")
			if kind in ["carrier","board"]:
				var level:=1.48 if kind=="carrier" else 0.0
				for x in [-.7,0,.7] if kind=="carrier" else [-.3,0,.3]:
					for z in [-1.,0.,1.] if kind=="carrier" else [-.4,0.,.4]:
						check(absf(highest(vehicle,x,z)-level)<.015,"real flat deck agrees with support height")
			vehicle.free(); copy.free()
	var traffic:=Props.obstacle("traffic",2)
	check(traffic.has_node("Warning") and traffic.get_child(0).get_meta("finish")==2,"crossing traffic keeps warning and finish")
	traffic.free()
	var ramp:=Transport.ramp()
	for z in [-2.5,0.,2.5]: check(absf(highest(ramp,0,z)-(3-z)/6*1.48)<.005,"ramp actual surface matches support slope")
	ramp.free()
	var out:=FileAccess.open("res://build/transports-report.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"checks":checks,"failures":failures},"  ")); out.close()
	print("TRANSPORTS: %d checks, %d failures"%[checks,failures.size()])
	await create_timer(.1).timeout; quit(0 if failures.is_empty() else 1)
