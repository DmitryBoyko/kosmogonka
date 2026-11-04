extends SceneTree
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok: failures.append(message); push_error(message)
func run() -> void:
	var planets=load("res://scripts/planets.gd")
	var names:Dictionary={}
	for planet in 10:
		var data:Dictionary=planets.get_data(planet); names[data.name]=true
		check(data.regions.size()==3 and planets.biome(planet)<4,"valid biome and regions")
		var scenery=load("res://scripts/scenery.gd").new(); scenery.planet=planet; root.add_child(scenery)
		var chunk:Node3D=scenery.make_chunk(50)
		check(chunk.find_child("WindGrass",true,false)!=null,"animated grass exists on every planet")
		var glove:Node3D=load("res://scripts/basement.gd").glove(planet); root.add_child(glove)
		check(glove.get_meta("glove_planet")==planet,"planet-specific glove material")
		var styled:=0
		for piece:MeshInstance3D in glove.get_node("Punch").get_children():
			if piece.material_override is ShaderMaterial:
				check(piece.material_override.get_shader_parameter("planet")==planet,"glove texture style is applied")
				styled+=1
		check(styled==2,"both glove lobes use the textured material")
		glove.free(); scenery.free()
	check(names.size()==10,"ten distinct named worlds")
	var flora=load("res://scripts/natural_flora.gd"); var mat:ShaderMaterial=flora.material(0)
	flora.set_motion(true); check(mat.get_shader_parameter("wind")==0.,"reduced motion stops foliage sway")
	flora.set_motion(false); check(mat.get_shader_parameter("wind")==1.,"foliage animation can be restored")
	var file:=FileAccess.open("res://build/biomes-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures},"  ")); file.close()
	print("BIOMES: %d checks, %d failures"%[checks,failures.size()])
	await create_timer(.1).timeout; quit(0 if failures.is_empty() else 1)
