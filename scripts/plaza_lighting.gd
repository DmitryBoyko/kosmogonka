extends Node3D

const G=preload("res://scripts/geometry.gd")
const Neon = preload("res://assets/surfaces/plaza_neon.gdshader")
const Searchlight = preload("res://assets/surfaces/plaza_searchlight.gdshader")
var beams: Array[Node3D]=[]
var sky_beams: Array[MeshInstance3D] = []
var trim_materials: Array[ShaderMaterial] = []
var age := 0.

static func install(finish: Node3D, planet: int) -> void:
	if finish.has_node("PlazaLighting"): return
	var lighting=load("res://scripts/plaza_lighting.gd").new()
	lighting.name="PlazaLighting"
	finish.add_child(lighting)
	lighting.build(planet)

func build(planet: int) -> void:
	# Emissive architecture batches separately from collision geometry.
	var trim:=Node3D.new()
	trim.name="NeonArchitecture"
	add_child(trim)
	for i in 3:
		var material := ShaderMaterial.new()
		material.shader = Neon
		material.set_shader_parameter("base_color", [Color("38d8ff"), Color("fb5ac9"), Color("9870ff")][i])
		material.set_shader_parameter("streak_color", [Color("ff4cbb"), Color("876aff"), Color("54f7ec")][i])
		trim_materials.append(material)
	var city:=get_parent().get_node_or_null("FinishCity")
	if city:
		for box: AABB in city.get_meta("collision_boxes",[]):
			if box.size.y<6.: continue
			var material := trim_materials[int(absf(box.position.x + box.position.z)) % trim_materials.size()]
			for x in [box.position.x-.07,box.end.x+.07]:
				for z in [box.position.z-.07,box.end.z+.07]:
					G.box(trim, Vector3(.12, box.size.y-.4, .12), Vector3(x, box.position.y+box.size.y*.5, z)).material_override = material
			for z in [box.position.z-.07,box.end.z+.07]:
				G.box(trim, Vector3(box.size.x+.24,.12,.12), Vector3(box.get_center().x,box.end.y-.12,z)).material_override = material
			for x in [box.position.x-.07,box.end.x+.07]:
				G.box(trim, Vector3(.12,.12,box.size.z+.24), Vector3(x,box.end.y-.12,box.get_center().z)).material_override = material
	G.merge_static(trim)
	for i in 4:
		var base:=Node3D.new()
		add_child(base)
		base.position=[Vector3(-34,0,-9),Vector3(34,0,-9),Vector3(-30,0,-60),Vector3(30,0,-60)][i]
		var color: String=["46cfff","fa64c7","ac83ff","55f4ce"][i]
		G.tube(base,.42,.32,Vector3(0,.16,0),"38497c")
		G.tube(base,.11,3.6,Vector3(0,1.9,0),"617eb4")
		var pivot:=Node3D.new()
		base.add_child(pivot)
		pivot.position.y=3.8
		G.box(pivot,Vector3(.60,.40,.50),Vector3.ZERO,"344875")
		G.box(pivot,Vector3(.48,.25,.04),Vector3(0,0,-.27),color,.8)
		var lamp:=SpotLight3D.new()
		pivot.add_child(lamp)
		lamp.light_color=Color(color)
		lamp.light_energy=3.2
		lamp.spot_range=32.
		lamp.spot_angle=32.
		lamp.shadow_enabled=false
		var cone:=CylinderMesh.new()
		cone.top_radius=.03; cone.bottom_radius=3.; cone.height=15.
		cone.radial_segments=16; cone.cap_top=false; cone.cap_bottom=false
		var material:=StandardMaterial3D.new()
		material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode=BaseMaterial3D.CULL_DISABLED
		material.albedo_color=Color(color); material.albedo_color.a=.035
		var beam:=G.part(pivot,cone,Vector3(0,0,-7.5),material)
		beam.rotation.x=PI*.5
		beam.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		beams.append(pivot)
		preload("res://scripts/arcade_materials.gd").apply(base,planet)
	var searchlight_mounts := [Vector3(-22,9.6,-12),Vector3(23,11.,-22),Vector3(9.,14.2,-41)]
	for i in searchlight_mounts.size():
		var at: Vector3 = searchlight_mounts[i]
		var distance := INF
		if city:
			for roof: AABB in city.get_meta("collision_boxes",[]):
				if roof.size.y<7. or minf(roof.size.x,roof.size.z)<4.: continue
				var middle := roof.get_center()
				var difference := Vector2(searchlight_mounts[i].x-middle.x,searchlight_mounts[i].z-middle.z).length_squared()
				if difference>=distance: continue
				distance=difference
				at=Vector3(middle.x,roof.end.y+.29,middle.z)
		add_searchlight(at,["5fdaff","ff64b7","ac86ff"][i],planet)
	advance(0.,true)

func add_searchlight(at: Vector3, color: String, planet: int) -> void:
	var holder := Node3D.new()
	holder.name = "SkySearchlight"
	add_child(holder)
	holder.position = at
	var lens := G.ring(holder,.29,.38,Vector3.ZERO,color,.52)
	lens.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	G.tube(holder,.40,.45,Vector3(0,-.23,0),"263653")
	preload("res://scripts/arcade_materials.gd").apply(holder,planet)
	var cone := CylinderMesh.new()
	cone.bottom_radius=.20
	cone.top_radius=4.2
	cone.height=1.
	cone.radial_segments=16
	cone.cap_top=false
	cone.cap_bottom=false
	var mist := ShaderMaterial.new()
	mist.shader = Searchlight
	mist.set_shader_parameter("beam_color",Color(color))
	var beam := G.part(holder,cone,Vector3.ZERO,mist)
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sky_beams.append(beam)

func advance(dt: float, reduced: bool) -> void:
	age+=dt
	for material in trim_materials:
		material.set_shader_parameter("steady", reduced)
		if not reduced: material.set_shader_parameter("clock", age)
	for i in beams.size():
		beams[i].rotation=Vector3(.68+(0. if reduced else sin(age*.18+i)*.22),(-.8 if i%2==0 else .8)+(0. if reduced else sin(age*.14+i)*.45),0.)
		var lamp := beams[i].get_child(2) as SpotLight3D
		lamp.light_energy = 3.2 if reduced else 2.65 + .65 * sin(age * 1.45 + i * 1.3)
	for i in sky_beams.size():
		var beam := sky_beams[i]
		var drift := 0. if reduced else age*.16
		var ray := Vector3(sin(i*2.2+drift)*.32,1.,cos(i*1.9+drift*.75)*.44).normalized()
		beam.position = ray*32.
		beam.quaternion = Quaternion(Vector3.UP,ray)
		beam.scale = Vector3(1.,64.,1.)
		beam.visible = age>0.
		beam.material_override.set_shader_parameter("power",.82 if reduced else .77+.12*sin(drift*1.6+i))
