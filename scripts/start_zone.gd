extends Node3D
const G=preload("res://scripts/geometry.gd")
var lamps:Array[MeshInstance3D]=[]
var themes:Dictionary={}
var energy_core:MeshInstance3D
var halo:MeshInstance3D
var world:=0
const LANDING_PAD:=Vector3(12.,.13,6.5)
var clock:=0.
func build() -> void:
	name="LaunchGrid"
	var pad:=preload("res://scripts/shop_ship_kit.gd").model(self,"Platform_CenterPlate",LANDING_PAD,Vector3(11.,.25,10.))
	pad.name="LandingPad"
	G.ring(self,3.05,3.20,LANDING_PAD+Vector3.UP*.18,"72eff5",.55)
	for j in 8:
		var angle:=j*TAU/8.
		G.ball(self,Vector3.ONE*.26,LANDING_PAD+Vector3(cos(angle)*4.,.25,sin(angle)*4.),"ffe5a0",.32)
	for j in 6:
		G.box(self,Vector3(.45,.03,.15),Vector3(2.1+j*1.05,.05,4.2),"7deee8",.22)
	preload("res://scripts/shop_ship_kit.gd").model(self,"Platform_CenterPlate",Vector3(0,.055,5.7),Vector3(7.8,.12,6.4))
	for side in [-1,1]:
		for i in 6: G.box(self,Vector3(.08,.025,.75),Vector3(side*1.14,.07,-i*2.),"9ecdd7",.1)
		G.box(self,Vector3(.42,2.2,.45),Vector3(side*2.35,1.1,-.8),"263d51")
		for i in 3:
			var lamp:=G.box(self,Vector3(.31,.18,.06),Vector3(side*2.35,1.85-i*.43,-.54),"9acbd7",.1)
			lamps.append(lamp)
	for x in 6:
		for z in 2:
			if (x+z)%2==0: G.box(self,Vector3(.48,.025,.48),Vector3((x-2.5)*.48,.08,-1.8-z*.48),"dbe8e6")
	var title:=G.label(self,"S T A R T",Vector3(0,.10,-4.),44)
	title.rotation_degrees.x=-90.; title.billboard=BaseMaterial3D.BILLBOARD_DISABLED; title.pixel_size=.012
	for lane in 3:
		var index:=G.label(self,"0%d"%[lane+1],Vector3((lane-1)*2.6,.09,-.5),30);index.rotation_degrees.x=-90.;index.pixel_size=.012
		for i in 6:
			var mark:=G.box(self,Vector3(.75,.018,.09),Vector3((lane-1)*2.6,.09,-5.-i*.7),"7de6f0",.15);mark.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	energy_core=G.ball(self,Vector3.ONE*.36,Vector3(0,3.5,-2.8),"b4fff1",.6)
	halo=G.ring(self,.35,.42,Vector3(0,3.5,-2.8),"9beaff",.4);halo.rotation.x=PI*.5
	configure(0)
func configure(index:int) -> void:
	world=index
	for root:Node3D in themes.values():root.hide()
	if not themes.has(index):themes[index]=signature(index)
	themes[index].show()
	energy_core.material_override=G.material(preload("res://scripts/planets.gd").get_data(index).accent,.6)
func signature(index:int) -> Node3D:
	var root:=Node3D.new();root.name="LaunchIdentity%d"%index;add_child(root);root.position.z=-13.
	var accent:String=preload("res://scripts/planets.gd").get_data(index).accent
	for side in [-1.,1.]:
		var x:float=side*5.1
		G.tube(root,1.05,.35,Vector3(x,.18,-2.5),"34455d")
		G.ring(root,.92,1.02,Vector3(x,.39,-2.5),accent,.25)
		match index:
			0,2,7:
				for j in 3:
					var column:=G.tube(root,.35,2.1+j*.65,Vector3(x+(j-1)*.55,1.4+j*.32,-2.5+j*.3),"9adce6" if index==0 else "e3b45f" if index==2 else "d3eaff",.035)
					column.mesh=column.mesh.duplicate();column.mesh.radial_segments=6;column.mesh.top_radius=.025
			1:
				G.link(root,Vector3(x,.4,-2.5),Vector3(x,2.7,-2.5),.13,"6d9e83")
				for j in 6:
					var a:float=j*TAU/6.;G.ball(root,Vector3(.65,.5,.4),Vector3(x+sin(a)*.5,2.7+cos(a)*.5,-2.5),"ec9fd3")
				G.ball(root,Vector3.ONE*.5,Vector3(x,2.7,-2.2),"ffe6a0",.15)
			3:
				for j in 3:
					var plate:=G.box(root,Vector3(.14,2.4+j*.4,.6),Vector3(x+(j-1)*.5,1.6,-2.5),accent,.2);plate.rotation.z=side*.18
				G.label(root,"NEON\nREADY",Vector3(x,3.4,-2.5),25)
			4:
				for j in 5:
					var a:float=j*TAU/5.;var end:=Vector3(x+sin(a)*.6,1.4+j*.25,-2.5+cos(a)*.5)
					G.link(root,Vector3(x,.4,-2.5),end,.13,"a59ac8");G.ball(root,Vector3.ONE*.4,end,"8ae0d7",.1)
			5:
				G.tube(root,.2,2.4,Vector3(x,1.5,-2.5),"d7bd86")
				var panel:=G.box(root,Vector3(2.3,.12,1.8),Vector3(x,2.7,-2.5),"376b99");panel.rotation.z=side*.4
				for j in 4:G.box(root,Vector3(.035,.035,1.8),Vector3(x+(j-1.5)*.5,2.81,-2.5),"b9e9fa",.05)
			6:
				G.tube(root,.24,2.4,Vector3(x,1.6,-2.5),"aaa7ad")
				G.ball(root,Vector3(2.3,.65,1.8),Vector3(x,2.9,-2.5),"b38aca",.08)
				G.ring(root,.3,.72,Vector3(x,2.68,-2.5),"c8ff9b",.25)
			8:
				G.tube(root,.6,2.8,Vector3(x,1.6,-2.5),"3d3943",.48)
				for j in 3:G.ring(root,.46,.61,Vector3(x,1.+j*.6,-2.5),"ffa04b",.4)
			9:
				for j in 3:
					var ring:=G.ring(root,.65+j*.18,.72+j*.18,Vector3(x,2.,-2.5),accent,.25);ring.rotation=Vector3(j*.7,.4+j*.8,.5)
			10:
				for j in 3:
					var pane:=G.box(root,Vector3(.55,2.4+j*.3,.12),Vector3(x+(j-1)*.65,1.7,-2.5),"bed8ec");pane.rotation.y=side*(.3+j*.2);pane.rotation.z=side*.14
					var mat:=G.material("bed8ec").duplicate() as StandardMaterial3D;mat.metallic=.85;mat.roughness=.22;pane.material_override=mat
	G.merge_static(root)
	var outpost:=preload("res://scripts/space_kit_locations.gd").build(index,false)
	root.add_child(outpost)
	outpost.position.z=13.
	return root
func advance(mode:String,distance_value:float,count:float) -> void:
	visible=mode in ["intro","countdown","run"] and distance_value<35.
	position.z=distance_value
	clock+=get_process_delta_time()
	var reduced:bool=get_node("/root/Profile").reduced_motion
	energy_core.scale=Vector3.ONE*.36*(1.+(0. if reduced else sin(clock*3.)*.08))
	halo.rotation.z=0. if reduced else clock*.3
	for i in lamps.size():
		var on:bool=mode=="run" or (mode=="countdown" and i%3>=3-int(ceil(count)))
		lamps[i].material_override=G.material("8affbc" if on else "734254",.4 if on else .05)
