extends SceneTree
const City=preload("res://scripts/finish_city.gd")
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok:bool,label_value:String) -> void:
	checks+=1
	if not ok: failures.append(label_value); push_error(label_value)
func run() -> void:
	var signatures:Dictionary={}
	for planet in 4:
		var city:=City.build(planet); root.add_child(city)
		check(city.get_meta("building_count")==19,"nineteen real building modules per planet")
		check(city.get_meta("models")==City.FAMILIES[planet],"planet chooses its own architecture")
		check(not city.has_node("ReturnGate") and city.get_meta("open_approaches",false),"no gate or perimeter enclosure")
		check(city.has_node("FlowerGardens"),"landscaped open approaches")
		var residents=city.get_node("RunningResidents")
		check(residents.residents.size()==12,"twelve animated alien residents")
		var old_position:Vector3=residents.residents[0].position
		residents.advance(.5)
		check(residents.residents[0].position.distance_to(old_position)>.5,"residents run along their routes")
		check(residents.residents[0].get_node("AlienBody/Leg0").rotation.x!=0,"running animates limbs")
		var bounds:=AABB(); var vertices:=0; var texture_count:=0
		for piece:MeshInstance3D in city.find_children("*","MeshInstance3D",true,false):
			bounds=bounds.merge(piece.transform*piece.mesh.get_aabb())
			vertices+=piece.mesh.get_faces().size()
			if not piece.get_meta("architecture_solid",false): continue
			check(piece.get_meta("architecture_solid",false),"building geometry has collision metadata")
			if piece.material_override is ShaderMaterial and piece.material_override.shader.resource_path.contains("bio_facade"):
				var tex:Texture2D=piece.material_override.get_shader_parameter("surface_map")
				check(tex!=null and tex.resource_path.contains("MetalPlates006"),"downloaded metal texture used")
				texture_count+=1
		check(texture_count>=3 and vertices>10000,"multiple textured surfaces and actual imported model geometry")
		check(bounds.position.x< -55 and bounds.end.x>55 and bounds.position.z< -80 and bounds.end.z>30,"city encloses all sides of monument square")
		signatures[vertices]=true
		city.free()
	check(signatures.size()==4,"all four planet skylines have distinct geometry")
	var out:=FileAccess.open("res://build/finish-city-report.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"checks":checks,"failures":failures},"  ")); out.close()
	print("FINISH CITY: %d checks, %d failures"%[checks,failures.size()])
	await create_timer(.1).timeout; quit(0 if failures.is_empty() else 1)
