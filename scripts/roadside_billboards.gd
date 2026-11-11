extends Node3D

const Avatar = preload("res://scripts/crew_avatar.gd")
const G = preload("res://scripts/geometry.gd")
const SM = preload("res://scripts/salvage_mesh.gd")
const Finishes = preload("res://scripts/salvage_materials.gd")
const Planets = preload("res://scripts/planets.gd")
const Loops = preload("res://scripts/loop_layout.gd")
const Short = preload("res://assets/road_ads/billboard-short.glb")
const Tall = preload("res://assets/road_ads/billboard-tall.glb")
const Backdrop = preload("res://assets/spaceflight/2k_stars_milky_way.jpg")
const DISPLAY_HEIGHT := 7.6
const POST_OFFSET := 4.8

var signs: Array[Node3D] = []
var marks := PackedFloat32Array()
var portrait: SubViewport
var actor: Node3D
var character := -1
var outfit: Dictionary = {}
var world := -1
var elapsed := 0.
var refresh := 0.

func setup_portrait() -> void:
	portrait = SubViewport.new()
	portrait.name = "SharedBillboardPortrait"
	portrait.size = Vector2i(420,180)
	portrait.own_world_3d = true
	portrait.transparent_bg = true
	portrait.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(portrait)
	var backdrop := WorldEnvironment.new()
	backdrop.environment = Environment.new()
	backdrop.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	backdrop.environment.ambient_light_color = Color("e0edff")
	backdrop.environment.ambient_light_energy = .64
	portrait.add_child(backdrop)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-31,-146,0)
	sun.light_energy = 1.08
	portrait.add_child(sun)
	var camera := Camera3D.new()
	portrait.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.24
	camera.position = Vector3(-.06,2.55,5.2)
	camera.look_at(Vector3(-.06,2.55,0))
	camera.current = true

func configure(planet: int, index: int, loadout: Dictionary, track_length: float) -> void:
	if not is_instance_valid(portrait):
		setup_portrait()
	if index != character or outfit != loadout:
		if is_instance_valid(actor): actor.free()
		actor = Avatar.new()
		portrait.add_child(actor)
		actor.build(index)
		actor.apply_outfit(loadout)
		actor.rotation.y = -.14
		character = index
		outfit = loadout.duplicate()
		elapsed = .31
		draw_portrait(.15)
	if world == planet:
		update_marks(planet,track_length)
		return
	world = planet
	for sign in signs:
		sign.free()
	signs.clear()
	var fractions := [.21,.68] if planet == 0 else [.16,.44,.78]
	for i in fractions.size():
		var sign := make_sign((i+planet)%2==1,planet,i)
		sign.hide()
		add_child(sign)
		signs.append(sign)
	update_marks(planet,track_length)

func update_marks(planet:int,track_length:float) -> void:
	marks.clear()
	var fractions := [.21,.68] if planet == 0 else [.16,.44,.78]
	for fraction:float in fractions:
		marks.append(clear_marker(fraction*track_length,planet))

static func clear_marker(value: float, planet: int) -> float:
	var spans := [Vector2(800,1000),Vector2(1025,1515)]
	for kind: String in Loops.kinds(planet):
		var bounds := Loops.clearance(kind)
		spans.append(Vector2(-bounds.end.z-15.,-bounds.position.z+20.))
	spans.sort_custom(func(a:Vector2,b:Vector2) -> bool: return a.x < b.x)
	for span: Vector2 in spans:
		if value >= span.x and value < span.y:
			value = span.y
	return value

func make_sign(tall: bool, planet: int, index: int) -> Node3D:
	var sign := Node3D.new()
	sign.name = "RoadsideBillboard"
	var model := (Tall if tall else Short).instantiate() as Node3D
	var scale_value := .013 if tall else .035
	var housing := Finishes.material("hull-titanium",true)
	var frame_tint: String = Planets.get_data(planet).accent
	var source := model as MeshInstance3D
	if not source:
		source = model.find_child("b" if tall else "Billboard_A",true,false) as MeshInstance3D
	if not source:
		source = model.find_children("*","MeshInstance3D",true,false)[0] as MeshInstance3D
	var shell := ArrayMesh.new()
	for surface: int in ([0] if tall else [0,2]):
		shell.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,source.mesh.surface_get_arrays(surface))
	model.free()
	var size := Vector2(8.84,3.02) if tall else Vector2(8.56,2.93)
	var model_y := (530. if tall else 185.7)*scale_value
	var model_z := (55.8 if tall else 10.)*scale_value
	var shell_part := G.part(sign,shell,Vector3(90.*scale_value if tall else 0.,DISPLAY_HEIGHT-model_y,-model_z),housing)
	shell_part.rotation.y = PI*.5 if tall else 0.
	shell_part.scale = Vector3(scale_value,scale_value,scale_value)
	if tall: shell_part.scale.z *= 1.16
	else: shell_part.scale.x *= 1.24
	shell_part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var at := Vector3(0,DISPLAY_HEIGHT,0)
	for side in [-1.,1.]:
		var post := SM.block(sign,Vector3(.48,DISPLAY_HEIGHT+2.5,.68),Vector3(side*POST_OFFSET,(DISPLAY_HEIGHT-.7)*.5-1.25,-.27),housing,.09)
		post.name = "ShoulderPostLeft" if side<0. else "ShoulderPostRight"
		post.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var crossbeam := SM.block(sign,Vector3(POST_OFFSET*2.+.32,.32,.65),at+Vector3(0,-size.y*.35,-.27),housing,.065)
	crossbeam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var surround := SM.block(sign,Vector3(size.x+.12,size.y+.12,.09),at - Vector3(0,0,.048),housing,.07)
	surround.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var frame := G.box(sign,Vector3(size.x+.10,.054,.069),at + Vector3(0,size.y*.5+.065,.026),frame_tint,.5)
	frame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var quad := QuadMesh.new()
	quad.size = size
	var media := ShaderMaterial.new()
	media.shader = preload("res://assets/road_ads/portrait.gdshader")
	media.set_shader_parameter("portrait",portrait.get_texture())
	media.set_shader_parameter("stars",Backdrop)
	media.set_shader_parameter("accent",Color(frame_tint))
	media.set_shader_parameter("layout",float(index%2))
	var display := G.part(sign,quad,at,media)
	display.name = "HeroDisplay"
	display.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return sign

func draw_portrait(dt: float) -> void:
	if not is_instance_valid(actor) or DisplayServer.get_name() == "headless":
		return
	var player: AnimationPlayer = actor.animation
	const WAVE := "crew/wave"
	if player.assigned_animation != WAVE:
		player.play(WAVE)
		player.advance(0.)
		player.pause()
	var length := player.get_animation(WAVE).length
	player.seek(fposmod(elapsed,length),true)
	actor.update_expression(dt,.96)
	portrait.render_target_update_mode = SubViewport.UPDATE_ONCE

func advance(dt: float, running: bool, distance_value: float, reduced_motion: bool, track:RefCounted=null) -> void:
	var near := false
	for i in signs.size():
		var rel := distance_value - marks[i]
		signs[i].visible = running and rel > -145. and rel < 23.
		var local:=Vector3(0,0,rel)
		signs[i].position=track.map(local) if track else local
		signs[i].rotation.y=track.heading(marks[i]) if track else 0.
		near = near or (signs[i].visible and rel > -82. and rel < 10.)
	if near and not reduced_motion:
		elapsed += dt
		refresh += dt
		if refresh >= .10:
			draw_portrait(refresh)
			refresh = 0.
