extends RefCounted
const G=preload("res://scripts/geometry.gd")
const SM=preload("res://scripts/salvage_mesh.gd")
const Transport=preload("res://scripts/hover_transport.gd")
const Course=preload("res://scripts/course.gd")

static func build(event:Dictionary,variant:int) -> Node3D:
	if event.kind=="skycarrier":
		var platform:=Transport.build("carrier",variant)
		platform.scale=Vector3(1,minf(1,event.top/1.48),event.length/12)
		return platform
	var root:=Node3D.new()
	if event.kind in ["stairs","stairs_down"]:
		var flow:=preload("res://scripts/stair_flow.gd").material(root)
		var count:int=ceili(event.top/.185)
		var depth:float=event.length/count
		for i in count:
			var rel:float=-event.length*.5+(i+.5)*depth
			var y:float=Course.step_height(event,rel)
			SM.block(root,Vector3(2.12,.20,depth+.015),Vector3(0,y-.10,-rel),Transport.paint(variant,"paint"),.03)
			G.box(root,Vector3(1.95,.022,depth*.87),Vector3(0,y+.012,-rel)).material_override=Transport.paint(variant,"deck")
			for side in [-1,1]: G.box(root,Vector3(.065,.018,depth*.7),Vector3(side*.95,y+.045,-rel),"95e9d5",.3).material_override=flow
		if event.kind=="stairs":
			var message:String="↑  К ПЛАТФОРМЕ" if event.lower else "↑↑  К ПЛАТФОРМЕ"
			G.label(root,message,Vector3(0,event.top+1.4,-event.length*.5),23)
			G.label(root,"ВНИЗ БЕЗ УРОНА",Vector3(0,event.top+.7,-event.length*.5),19).modulate=Color("a7ead7")
	else:
		var shell:=Transport.paint(variant,"paint"); var frame:=Transport.paint(variant,"frame")
		for side in [-1,1]:
			SM.block(root,Vector3(.18,3.25,event.length),Vector3(side*1.14,1.625,0),shell)
		SM.block(root,Vector3(2.45,.35,event.length),Vector3(0,3.425,0),shell,.15)
		var light:=ShaderMaterial.new(); light.shader=preload("res://assets/surfaces/passage_light.gdshader")
		light.set_shader_parameter("phase",event.s*.07)
		for z in range(-int(event.length*.5),int(event.length*.5)+1,4):
			for side in [-1,1]:
				SM.block(root,Vector3(.08,3.1,.12),Vector3(side*1.03,1.55,z),frame,.02)
				G.box(root,Vector3(.10,.10,3.8),Vector3(side*.94,3.05,z)).material_override=preload("res://scripts/surface_style.gd").edge(int(event.get("planet",0)))
			SM.block(root,Vector3(2.15,.1,.18),Vector3(0,3.2,z),frame,.03)
		if not event.get("elevated",false): G.label(root,"БОНУСНЫЙ ПРОХОД",Vector3(0,4.1,event.length*.5),21)
		root.set_meta("passage_light",light)
	if event.kind=="stairs_down": Transport.batch(root)
	else: batch_keep_labels(root)
	return root

static func batch_keep_labels(root:Node3D) -> void:
	var labels:Array=[]
	for child in root.get_children():
		if child is Label3D: root.remove_child(child); labels.append(child)
	Transport.batch(root)
	for child in labels: root.add_child(child)

static func animate(root:Node3D,clock:float,reduced:bool) -> void:
	var light:ShaderMaterial=root.get_meta("passage_light",null)
	if light:
		light.set_shader_parameter("flow_time",clock)
		light.set_shader_parameter("reduced_motion",reduced)
