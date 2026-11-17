extends Node3D

const G = preload("res://scripts/geometry.gd")
const Shops = preload("res://scripts/monument_shops.gd")
const Categories = preload("res://scripts/gear_economy.gd")
const Layout = preload("res://scripts/loop_layout.gd")
const Neon = preload("res://scripts/neon_arrows.gd")
var markers: Array[Node3D] = []
var materials: Array[ShaderMaterial] = []
var elapsed := 0.

func build(finish: Node3D) -> void:
	name = "ShopBeacons"
	var random := RandomNumberGenerator.new()
	random.randomize()
	var available := range(Neon.COLORS.size())
	var shape := QuadMesh.new()
	shape.size = Vector2.ONE*4.05
	for i in Shops.POSITIONS.size():
		var marker := Node3D.new()
		add_child(marker)
		markers.append(marker)
		marker.name = Categories.CATEGORIES[i]
		var booth: Node3D = finish.get_node("MonumentShops/"+marker.name)
		var bounds := Layout.bounds(booth,Transform3D.IDENTITY)
		marker.position = Shops.POSITIONS[i]+Vector3.UP*maxf(8.5,bounds.end.y+2.2)
		var variant: int = available.pop_at(random.randi_range(0,available.size()-1))
		marker.set_meta("arrow_variant",variant)
		var paint := Neon.material(variant,PI*.5,true,i*.18)
		materials.append(paint)
		G.part(marker,shape,Vector3.ZERO,paint).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func advance(dt: float, camera: Camera3D, reduced: bool) -> void:
	elapsed += dt
	for i in markers.size():
		var marker := markers[i]
		materials[i].set_shader_parameter("clock",elapsed)
		materials[i].set_shader_parameter("steady",reduced)
		var target := camera.global_position
		target.y = marker.global_position.y
		if marker.global_position.distance_squared_to(target)>.01:
			marker.look_at(target,Vector3.UP,true)
