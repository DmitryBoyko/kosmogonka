extends RefCounted
const G=preload("res://scripts/geometry.gd")
const SM=preload("res://scripts/salvage_mesh.gd")
const Monuments=preload("res://scripts/finish_monuments.gd")
const Mat=preload("res://scripts/salvage_materials.gd")
const Garden=preload("res://scripts/city_garden.gd")
const Planets=preload("res://scripts/planets.gd")

static func build(planet:int) -> Node3D:
	var root:=Node3D.new(); root.name="FinishArch"; root.set_meta("style",planet)
	var stone:=Monuments.finish("ancient-patina",Color("dfd7c2") if Planets.biome(planet)==0 else Color("e4b27e"))
	var alloy:=Mat.material("hull-titanium"); var dark:=Mat.material("hull-ceramic",true)
	if Planets.biome(planet)==3:
		var metal:=ShaderMaterial.new(); metal.shader=preload("res://assets/salvage/transport_surface.gdshader")
		metal.set_shader_parameter("surface_map",preload("res://assets/finish_city/MetalPlates006_1K-JPG_Color.jpg"))
		metal.set_shader_parameter("tint",Color("253b59")); metal.set_shader_parameter("metalness",.72); metal.set_shader_parameter("roughness",.3)
		dark=metal
	for side in [-1,1]:
		SM.block(root,Vector3(2.1,.4,2.5),Vector3(side*5.6,.1,0),stone if planet<3 else dark,.15)
	match Planets.biome(planet):
		0:
			for side in [-1,1]:
				for y in 9:
					var drum:=G.tube(root,.54,.58,Vector3(side*5.6,.7+y*.58,0),"ffffff",.51)
					drum.material_override=stone
				for y in [.48,5.9]: SM.block(root,Vector3(1.6,.32,1.65),Vector3(side*5.6,y,0),stone,.12)
			SM.block(root,Vector3(13,.48,1.7),Vector3(0,6.25,0),stone,.08)
			for side in [-1,1]:
				var beam:=SM.block(root,Vector3(6.9,.35,1.65),Vector3(side*3.1,7.18,0),stone,.08); beam.rotation.z=-side*.28
			for i in 15: SM.block(root,Vector3(.22,.25,1.8),Vector3((i-7)*.8,6.63,0),stone,.02)
		1:
			for side in [-1,1]:
				SM.limb(root,[Vector3(side*5.6,.3,0),Vector3(side*5.9,3,0),Vector3(side*4.3,6.3,0),Vector3(0,7.6,0)],[.43,.34,.27,.16],alloy,10)
			for i in 11:
				var a:=PI*i/10
				G.ball(root,Vector3(1.6,.7,1.7),Vector3(cos(a)*5.5,2+sin(a)*5.3,0),"65b98e").material_override=Garden.foliage(1)
				Garden.flower(root,Vector3(cos(a)*5.5,2.3+sin(a)*5.3,.8),i)
		2:
			for side in [-1,1]:
				for i in 6: SM.block(root,Vector3(1.45,.58,1.8),Vector3(side*5.6,.6+i*.58,0),stone,.10)
			for i in 15:
				var a:float=PI*(i+.5)/15
				var block:=SM.block(root,Vector3(1.32,.72,1.8),Vector3(cos(a)*5.6,3.85+sin(a)*3.2,0),stone,.07)
				block.rotation.z=a-PI*.5
		3:
			for side in [-1,1]:
				SM.block(root,Vector3(1.25,6.7,1.9),Vector3(side*5.6,3.4,0),dark,.24)
				SM.block(root,Vector3(.4,5.8,.22),Vector3(side*5.6,3.6,1.01),alloy,.04)
				for i in 5:
					var fin:=SM.block(root,Vector3(.14,.9,2.35),Vector3(side*(5.1+i*.16),4.6+i*.35,0),alloy,.03); fin.rotation.z=side*.35
				G.box(root,Vector3(.09,5.6,.09),Vector3(side*5.2,3.4,1.06),"72f9ef",.7)
			SM.block(root,Vector3(9.2,.6,2.0),Vector3(-.8,7.1,0),dark,.2)
			var wing:=SM.block(root,Vector3(4.2,.6,2),Vector3(4.2,6.65,0),alloy,.13); wing.rotation.z=-.2
			for i in 6: G.box(root,Vector3(.6,.07,.09),Vector3(-3.7+i*1.1,6.74,1.06),"ff77cf",.6)
	# A textured recessed sign belongs to the architecture; passage stays 9.8 m clear.
	SM.block(root,Vector3(8.7,.80,.35),Vector3(0,5.5,.95),dark,.12)
	G.label(root,Planets.get_data(planet).name.to_upper()+" / ФИНИШ",Vector3(0,5.5,1.17),35)
	for i in 7: G.star(root,.18,Vector3((i-3)*.7,5.,1.18))
	var labels:Array[Node]=[]
	for label:Node in root.get_children():
		if label is Label3D: root.remove_child(label); labels.append(label)
	SM.batch(root)
	for label:Node in labels: root.add_child(label)
	for piece:MeshInstance3D in root.find_children("*","MeshInstance3D",true,false): piece.set_meta("architecture_solid",true)
	return root
