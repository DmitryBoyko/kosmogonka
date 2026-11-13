extends SceneTree
const Star=preload("res://scripts/collectible_star.gd")
var checks:=0
var errors:=0
var app:Node
func _initialize() -> void: call_deferred("run")
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok: errors+=1; push_error(message)
func point_key(p:Vector3) -> String:
	return str(Vector3i(roundi(p.x*100000),roundi(p.y*100000),roundi(p.z*100000)))
func run() -> void:
	Star.prepare()
	var arrays:=Star.mesh.surface_get_arrays(0); var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]; var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
	var edges:Dictionary={}; var side_count:=0; var outward:=true
	for i in range(0,vertices.size(),3):
		for j in 3:
			var a:=point_key(vertices[i+j]); var b:=point_key(vertices[i+(j+1)%3]); var key:String=a+"/"+b if a<b else b+"/"+a
			edges[key]=int(edges.get(key,0))+1
		if absf(normals[i].z)<.01:
			side_count+=1; outward=outward and normals[i].dot((vertices[i]+vertices[i+1]+vertices[i+2])/3.)>0.
	var watertight:=true
	for count:int in edges.values(): watertight=watertight and count==2
	check(watertight,"every star edge joins exactly two triangles: a sealed solid")
	check(side_count==20 and outward,"twenty outward-facing side triangles close the star thickness")
	var cargo:=preload("res://scripts/cargo_containers.gd").obstacle("cargo",4)
	check(cargo.get_meta("exposed_container_roofs",false) and cargo.get_child_count()==4,"three joined containers have no covering deck"); cargo.free()
	root.size=Vector2i(540,1188)
	app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; await process_frame; app.set_process(false); app.set_physics_process(false)
	app.start_level(); app.begin_run(); app.distance=2100.; app.spawn_and_update(); app.finish_level()
	var walk:Node3D=app.finish_walk
	check(walk.force_field!=null and walk.avatar.collision_mask==3,"finish uses a visible energy barrier on a dedicated collision layer")
	walk.avatar.position=Vector3(0,.12,5.0); walk.stick=Vector2(0,1)
	for i in 90:
		await physics_frame; walk.advance(1./60,false)
	check(walk.avatar.position.z>8.5,"interior approach has no cross-field")
	check(walk.force_field.walls.size()==4,"only the four exterior walls remain")
	var rear: Node3D=app.scenery.make_chunk(72,false)
	check(not rear.get_children().any(func(part):return part.get_meta("surface_role","")=="road" or part.get_meta("road_edge_led",false)),"road and lights stop before the monument garden")
	rear.free()
	var plaza: Node3D=app.finish.get_node("MonumentGarden")
	check(plaza.get_meta("solid_nature_boxes").size()==6 and plaza.find_children("PackFlora_*","MultiMeshInstance3D",true,false).size()>=4,"six imported trees, grass and flowers fill the courtyard")
	walk.avatar.position=Vector3(59.,.12,-75.); walk.avatar.velocity=Vector3.ZERO; walk.stick=Vector2(1,0)
	for i in 60:
		await physics_frame; walk.advance(1./60,false)
	check(walk.avatar.position.x<61.,"perimeter field prevents leaving the houses")
	var alien:=preload("res://scripts/props.gd").running_alien(1); app.add_child(alien); alien.position=Vector3(0,0,-18)
	preload("res://scripts/props.gd").animate_alien(alien,2.,1.,Vector3(2.6,1.5,0))
	check(absf(alien.get_node("AlienBody/Head").rotation.y)>.5 and alien.get_node("AlienBody/Arm1").rotation.z>2.,"alien turns its head and raises the free hand towards the runner")
	var crossing:MultiMeshInstance3D=alien.get_node("Crossing"); crossing.configure(7.8)
	check(crossing.multimesh.visible_instance_count==12 and (crossing.multimesh.mesh as BoxMesh).size.z>2.,"zebra has broad longitudinal neon stripes across three lanes")
	alien.free()
	app.hud.clear_screen("explore"); walk.yaw=PI; walk.present(.016,app.runner,app.camera,false)
	if DisplayServer.get_name()!="headless":
		await process_frame; await RenderingServer.frame_post_draw; root.get_texture().get_image().save_png("res://build/finish-force-field.png")
		app.camera.position=Vector3(14.,8.,-58.)
		app.camera.look_at(Vector3(9.,1.7,-30.))
		await process_frame; await RenderingServer.frame_post_draw; root.get_texture().get_image().save_png("res://build/monument-garden.png")
	print("SOLID STARS / FIELD / CROSSWALK: %d checks, %d failures"%[checks,errors])
	if is_instance_valid(app.mobile_presentation): app.mobile_presentation.free()
	else: app.free()
	await process_frame; quit(1 if errors else 0)
