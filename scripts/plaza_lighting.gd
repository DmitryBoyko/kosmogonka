extends Node3D

const G=preload("res://scripts/geometry.gd")
var beams: Array[Node3D]=[]
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
	var city:=get_parent().get_node_or_null("FinishCity")
	if city:
		for box: AABB in city.get_meta("collision_boxes",[]):
			if box.size.y<6.: continue
			var color: String=["39dbff","ff63c8","a280ff"][int(absf(box.position.x+box.position.z))%3]
			for x in [box.position.x-.07,box.end.x+.07]:
				for z in [box.position.z-.07,box.end.z+.07]:
					G.box(trim,Vector3(.12,box.size.y-.4,.12),Vector3(x,box.position.y+box.size.y*.5,z),color,.8)
			G.box(trim,Vector3(box.size.x+.24,.12,.12),Vector3(box.get_center().x,box.end.y-.12,box.position.z-.07),color,.8)
			G.box(trim,Vector3(box.size.x+.24,.12,.12),Vector3(box.get_center().x,box.end.y-.12,box.end.z+.07),color,.8)
	preload("res://scripts/arcade_materials.gd").apply(trim,planet)
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
	advance(0.,true)

func advance(dt: float, reduced: bool) -> void:
	age+=dt
	for i in beams.size():
		beams[i].rotation=Vector3(.68+(0. if reduced else sin(age*.18+i)*.22),(-.8 if i%2==0 else .8)+(0. if reduced else sin(age*.14+i)*.45),0.)
