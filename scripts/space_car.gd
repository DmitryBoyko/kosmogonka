extends RefCounted
const Catalog=preload("res://scripts/space_car_catalog.gd")
const G=preload("res://scripts/geometry.gd")
const Palette=preload("res://assets/space_cars/Textures/colormap.png")
const Bounds=preload("res://scripts/loop_layout.gd")
static var scenes: Dictionary={}
static var paints: Dictionary={}
static var windows: Dictionary={}
static var wheel_paint: StandardMaterial3D

static func build(event: Dictionary, world: int) -> Node3D:
	var root:=Node3D.new()
	var style: int=event.get("car_style",Catalog.variant(event.encounter,event.lane,world))
	var key: String=Catalog.NAMES[style]
	if not scenes.has(key):scenes[key]=load("res://assets/space_cars/"+key+".glb")
	var hull:=Node3D.new();hull.name="HoverCar";root.add_child(hull)
	var model: Node3D=scenes[key].instantiate();hull.add_child(model)
	var original_driver := model.find_child("character", true, false) as MeshInstance3D
	var open_seat := original_driver != null
	var seat_box := AABB()
	if open_seat:
		var driver_transform := preload("res://scripts/finish_city.gd").local_transform(original_driver, model)
		seat_box = driver_transform * original_driver.mesh.get_aabb()
		original_driver.free()
	var box:=Bounds.bounds(model,Transform3D.IDENTITY)
	var fit := minf(2.08 / box.size.x, 2.29 / box.size.y)
	model.scale=Vector3.ONE*fit
	model.position=-Vector3(box.get_center().x,box.position.y,box.get_center().z)*fit+Vector3.UP*.32
	var window_box:=AABB()
	for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if not String(mesh.name).contains("body"):
			for surface in mesh.mesh.get_surface_count():
				var original:=mesh.get_active_material(surface) as StandardMaterial3D
				if original:
					if wheel_paint==null:
						wheel_paint=StandardMaterial3D.new();wheel_paint.albedo_texture=Palette;wheel_paint.roughness=.86
					mesh.set_surface_override_material(surface,wheel_paint)
			continue
		var transform_value:=preload("res://scripts/finish_city.gd").local_transform(mesh,model)
		for surface in mesh.mesh.get_surface_count():
			var original:=mesh.get_active_material(surface) as StandardMaterial3D
			if not original:continue
			if not paints.has(key):
				var paint:=ShaderMaterial.new();paint.shader=preload("res://assets/surfaces/space_car.gdshader")
				paint.set_shader_parameter("colormap",Palette)
				paint.set_shader_parameter("panel_map",preload("res://assets/salvage/hull-ceramic-v1.png"))
				paint.set_shader_parameter("window_floor",mesh.get_aabb().size.y*.40)
				paints[key]=paint
			mesh.set_surface_override_material(surface,paints[key])
			if not windows.has(key):
				var arrays:=mesh.mesh.surface_get_arrays(surface)
				var verts: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
				var uvs: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
				var first:=true
				for i in verts.size():
					if uvs[i].x>=.125 or verts[i].y<mesh.get_aabb().size.y*.50:continue
					var at:=transform_value*verts[i]
					window_box=AABB(at,Vector3.ZERO) if first else window_box.expand(at)
					first=false
				windows[key]=window_box
	window_box=windows.get(key,AABB())
	if not window_box.has_volume():
		var seat := box.get_center() + Vector3(0., box.size.y * .23, box.size.z * .13)
		window_box = AABB(seat - Vector3(.1, .13, .1), Vector3(.2, .26, .2))
	var cabin:=model.transform*window_box.get_center()
	var pilot:=preload("res://scripts/crew_avatar.gd").new()
	pilot.name="AlienDriver";pilot.set_meta("motion",true);hull.add_child(pilot)
	pilot.build(preload("res://scripts/crew.gd").ALIEN_GUY);pilot.pose("pilot")
	var pilot_scale:=clampf(window_box.size.y*fit*.85/1.8,.20,.33)
	pilot.scale=Vector3.ONE*pilot_scale
	pilot.position=cabin+Vector3(-.18,-2.35*pilot_scale,.06)
	if open_seat:
		var seat := Vector3(seat_box.get_center().x, seat_box.position.y, seat_box.get_center().z)
		pilot.scale = Vector3.ONE * .34
		pilot.position = model.transform * seat - Vector3.UP * .45
	for mesh: GeometryInstance3D in pilot.find_children("*","GeometryInstance3D",true,false):mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for side in [-1.,1.]:
		for z in [-1.,1.]:
			G.ring(hull,.18,.28,Vector3(side*.82,.25,z*Catalog.LENGTHS[style]*.32),"60f3e7",.8)
		var engine:=G.tube(hull,.19,.52,Vector3(side*.66,.65,-Catalog.LENGTHS[style]*.46),"364a70")
		engine.rotation.x=PI*.5
		G.ball(hull,Vector3(.26,.26,.43),Vector3(side*.66,.65,-Catalog.LENGTHS[style]*.50),"5de8ff",.8)
	var signal_mount:=Node3D.new();signal_mount.set_meta("motion",true);hull.add_child(signal_mount)
	var indicator:=G.ball(signal_mount,Vector3(.14,.12,.12),Vector3(signf(float(event.lane-event.source_lane))*.85,1.1,Catalog.LENGTHS[style]*.43),"ffb447",.65)
	G.merge_static(hull)
	root.set_meta("hull",hull);root.set_meta("pilot",pilot);root.set_meta("indicator",indicator);root.set_meta("car_style",style)
	return root

static func present(root: Node3D,event: Dictionary,time: float,reduced: bool) -> void:
	var hull: Node3D=root.get_meta("hull")
	hull.position.y=0. if reduced else sin(time*2.1+event.origin)*.035
	hull.rotation.z=0. if reduced else sin(time*1.3+event.origin)*.012
	root.get_meta("indicator").visible=event.get("lane_change",false) and fposmod(time,.6)<.3
