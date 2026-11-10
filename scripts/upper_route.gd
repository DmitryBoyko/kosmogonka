extends RefCounted
const C=preload("res://scripts/course.gd")
const G=preload("res://scripts/geometry.gd")
const SM=preload("res://scripts/salvage_mesh.gd")
const H=preload("res://scripts/hover_support.gd")
const START:=1060.
const END:=1484.
const DECK_VARIANTS=[[7.2,9.6,7.2,9.6,4.8,9.6],[9.6,7.2,9.6,7.2,7.2,9.6],[7.2,7.2,9.6,9.6,7.2,9.6],[9.6,9.6,7.2,7.2,4.8,9.6]]
const ROWS=[
	[1060.,1104.,0.,7.2],[1104.,1140.,7.2,7.2],[1140.,1156.,7.2,9.6],
	[1156.,1194.,9.6,9.6],[1194.,1210.,9.6,7.2],[1210.,1260.,7.2,7.2],
	[1260.,1276.,7.2,9.6],[1276.,1328.,9.6,9.6],[1328.,1344.,9.6,4.8],
	[1344.,1370.,4.8,4.8],[1370.,1400.,4.8,9.6],[1400.,1444.,9.6,9.6],[1444.,1484.,9.6,0.]]
static func install(events:Array[Dictionary],pickups:Array[Dictionary],world:int) -> void:
	# Keep the entry ramp free; all other ground encounters remain playable below.
	for i in range(events.size()-1,-1,-1):
		if events[i].lane==0 and ((events[i].s>START-15. and events[i].s<1104.+12.) or (events[i].s>END-18. and events[i].s<END+35.)):events.remove_at(i)
	var rows:Array=ROWS.duplicate(true);var heights:Array=DECK_VARIANTS[C.variant()]
	for index in rows.size():
		if index%2==1:rows[index][2]=heights[index/2];rows[index][3]=heights[index/2]
		else:rows[index][2]=0. if index==0 else heights[index/2-1];rows[index][3]=0. if index==12 else heights[index/2]
	for row in rows:
		var e:=C.make_event((row[0]+row[1])*.5,0,"upper_deck" if row[2]==row[3] else "upper_stairs",-20,"bonus")
		e.length=row[1]-row[0];e.from_height=row[2];e.to_height=row[3];e.top=maxf(row[2],row[3]);e.sway_group=START;e.planet=world
		events.append(e)
		for at in range(int(row[0])+6,int(row[1])-2,10):
			if not has_floor(e,float(at)-e.s):continue
			C.add_star(pickups,float(at),0,base_height(e,float(at)-e.s)+1.,2,e,"upper")
			pickups[-1].motion_base_y=pickups[-1].y
		if row[2]==row[3]:
			var box:=C.make_event(e.s,0,"upper_crate",-20,"bonus");box.length=1.3;box.top=e.top+1.05;box.from_height=e.top;box.to_height=e.top;box.sway_group=START;box.anchor=e;box.planet=world;events.append(box)
static func gap(e:Dictionary) -> Vector2:
	if e.kind!="upper_stairs":return Vector2.ZERO
	var steps:=maxi(1,ceili(absf(e.to_height-e.from_height)/.16))
	var depth:float=e.length/steps
	var skipped:=maxi(1,ceili((2.2+float(e.get("planet",0))*.06)/depth))
	var first:=clampi(int(steps*.58),2,maxi(2,steps-skipped-2))
	return Vector2(first*depth-e.length*.5,(first+skipped)*depth-e.length*.5)
static func has_floor(e:Dictionary,rel:float) -> bool:
	var opening:=gap(e)
	return opening==Vector2.ZERO or rel<opening.x or rel>=opening.y
static func base_height(e:Dictionary,rel:float) -> float:
	if e.kind=="upper_crate":return e.top
	var u:=clampf(rel/e.length+.5,0.,1.)
	if e.kind=="upper_stairs":
		var steps:=maxi(1,ceili(absf(e.to_height-e.from_height)/.16));u=minf(1.,(floor(u*steps)+1.)/steps)
	return lerpf(e.from_height,e.to_height,u)
static func floor_at(e:Dictionary,rel:float,clock:float,local_x:float) -> float:return base_height(e,rel)+H.floor_delta(e,clock,local_x)
static func build(e:Dictionary,world:int) -> Node3D:
	var root:=Node3D.new();root.name="SkyGarden";root.set_meta("upper_route",true)
	var paints:Array[Material]=[]
	for tint in ["56bcb8","c18bbd","d4b567","809ed0"]:
		var mat:=preload("res://scripts/hover_transport.gd").paint(world,"paint").duplicate() as ShaderMaterial;mat.set_shader_parameter("tint",Color(tint));paints.append(mat)
	var flow:=preload("res://scripts/stair_flow.gd").material(root,world)
	if e.kind=="upper_crate":
		SM.block(root,Vector3(1.75,1.05,1.3),Vector3(0,e.from_height+.525,0),preload("res://scripts/cargo_containers.gd").coating(4+world),.08)
		G.merge_static(root);return root
	if e.kind=="upper_stairs":
		var count:=ceili(absf(e.to_height-e.from_height)/.16);var depth:float=e.length/count
		for i in count:
			var rel:float=-e.length*.5+(i+.5)*depth;var y:=base_height(e,rel)
			if not has_floor(e,rel):continue
			SM.block(root,Vector3(2.35,.20,depth+.015),Vector3(0,y-.10,-rel),paints[int(i/4)%4],.03)
			G.box(root,Vector3(2.20,.018,.065),Vector3(0,y+.015,-rel+depth*.38)).material_override=flow
		var opening:=gap(e)
		for edge:float in [opening.x-.12,opening.y+.12]:
			G.box(root,Vector3(2.25,.035,.16),Vector3(0,base_height(e,edge)+.025,-edge),"ffd071",.45).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	else:
		SM.block(root,Vector3(2.35,.24,e.length),Vector3(0,e.top-.12,0),paints[posmod(int(e.top/2.4),4)],.06)
		for side in [-1.,1.]:G.box(root,Vector3(.065,.04,e.length),Vector3(side*1.13,e.top+.025,0)).material_override=flow
		preload("res://scripts/roadside_biology.gd").prepare_meshes()
		var multi:=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D;multi.use_custom_data=true;multi.mesh=preload("res://scripts/roadside_biology.gd").flower_mesh;multi.instance_count=8
		for i in 8:
			multi.set_instance_transform(i,Transform3D(Basis.from_scale(Vector3.ONE*.8),Vector3(-1.32 if i%2==0 else 1.32,e.top,e.length*(float(i/2)/4.-.38))))
			multi.set_instance_custom_data(i,Color(i*.12,.5,0,0))
		var flowers:=MultiMeshInstance3D.new();root.add_child(flowers);flowers.multimesh=multi;flowers.material_override=preload("res://scripts/roadside_biology.gd").material(world,false);flowers.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	G.merge_static(root)
	H.mount(root,2.35,e.length,e.from_height,e.to_height)
	if e.from_height==0.:G.label(root,"НЕБЕСНЫЙ САД · 3–4 ЭТАЖА",Vector3(0,1.7,e.length*.5+2.),19)
	return root
