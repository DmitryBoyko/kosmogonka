extends SceneTree
const Style=preload("res://scripts/surface_style.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label_value: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(label_value)
func run() -> void:
	var unique: Dictionary={}
	for planet in 4:
		var texture: Texture2D=Style.GROUND[planet]
		unique[texture.get_instance_id()]=true
		check(texture.get_image().has_mipmaps(),"terrain texture has mipmaps")
		check(Style.ground(planet)==Style.ground(planet),"chunks reuse a cached terrain material")
		check(Style.globe(planet).get_shader_parameter("surface_texture")==texture,"orbit and ground share a biome's texture")
		for lanes in [1,2,3]:
			var mat:=Style.road(planet,lanes)
			var repeat: Vector2=mat.get_shader_parameter("repeats")
			check(is_equal_approx(repeat.y,roundf(repeat.y)),"road pattern joins at 30 m chunk boundaries")
	check(unique.size()==4,"four distinct biome images")
	check(Style.ROAD.get_image().has_mipmaps(),"road detail is filtered at distance")
	Style.set_quality(false)
	check(Style.ground(0).get_shader_parameter("relief")==0.0,"low quality disables terrain micro relief")
	Style.set_quality(true)
	check(Style.ground(0).get_shader_parameter("relief")>0.0,"quality setting restores micro relief")
	print("SURFACES: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
