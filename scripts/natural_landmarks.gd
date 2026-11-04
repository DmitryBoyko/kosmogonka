extends RefCounted
const G=preload("res://scripts/geometry.gd")
const KINDS=["crystal_gardens","flower_forest","amber_spires","luminous_crystals","coral_groves","sandstone_mesа","giant_fungi","ice_spires","volcanic_rocks","floating_minerals"]
static func populate(root:Node3D,world:int,index:int) -> void:
	root.set_meta("natural_landmark_kind",KINDS[world])
	if index%2!=0: return
	var rng:=RandomNumberGenerator.new(); rng.seed=world*9157+index*137+19
	var side:float=-1. if posmod(index,4)==0 else 1.
	var group:=Node3D.new(); root.add_child(group); group.name="GiantNaturalLandmark"
	group.position=Vector3(side*rng.randf_range(17,24),-.2,rng.randf_range(-23,-8))
	if world in [0,2,3,7,9]:
		var tint:String={0:"82d6c9",2:"c6a469",3:"86acdf",7:"b7dfea",9:"acb5d9"}[world]
		for i in 3:
			var height:float=rng.randf_range(6,13)*(1. if i==0 else .6)
			var crystal:=Node3D.new(); group.add_child(crystal); crystal.position.x=(i-1)*2.2; crystal.rotation.z=(i-1)*.16
			var radius:float=1.3 if i==0 else .8
			var shaft:=G.tube(crystal,radius,height*.70,Vector3(0,height*.35,0),tint)
			var tip:=G.tube(crystal,radius,height*.30,Vector3(0,height*.85,0),tint,.04)
			for part:MeshInstance3D in [shaft,tip]:
				part.mesh=part.mesh.duplicate(); (part.mesh as CylinderMesh).radial_segments=6
			if world==9: crystal.position.y+=3.
	elif world==1:
		var crown:=preload("res://scripts/natural_flora.gd").tree(group,Vector3.ZERO,world,index+299)
		crown.get_parent().scale=Vector3.ONE*2.3
		for i in 8:
			var a:float=i*TAU/8.; var petal:=G.ball(group,Vector3(1.2,.5,2.4),Vector3(sin(a)*2.2,7.7,cos(a)*2.2),"d7a5ca")
			petal.rotation.y=a
	elif world==4:
		for i in 7:
			var end:=Vector3(sin(i*2.4)*2.7,4.+i*.8,cos(i*2.4)*2.7)
			G.link(group,Vector3.ZERO,end,.32,"ba8d97")
			G.ball(group,Vector3(2.3,1.2,2.3),end,"80b4aa")
	elif world==6:
		for i in 3:
			var height:float=5.+i*1.4; var at:=Vector3((i-1)*3.,height*.5,i*.7)
			G.tube(group,.45,height,at,"b1ac8d")
			G.ball(group,Vector3(5.,1.7,5.),Vector3(at.x,height,at.z),"b58bb2")
	else:
		for i in 4:
			var stone:=G.ball(group,Vector3(3.4,6.+i*1.3,3.8),Vector3((i-1.5)*1.4,2.4+i*.3,0),"8a7766")
			stone.material_override=preload("res://scripts/surface_style.gd").ground(world,true)
			stone.rotation=Vector3(i*.18,0.,i*.31)
	var boxes:Array=root.get_meta("solid_nature_boxes",[])
	var bounds:=AABB(); var first:=true
	for mesh:MeshInstance3D in group.find_children("*","MeshInstance3D",true,false):
		var transform:=mesh.transform; var parent:=mesh.get_parent()
		while parent!=root: transform=(parent as Node3D).transform*transform; parent=parent.get_parent()
		var box:AABB=transform*mesh.mesh.get_aabb(); bounds=box if first else bounds.merge(box); first=false
	if not first: boxes.append(bounds)
	root.set_meta("solid_nature_boxes",boxes)
