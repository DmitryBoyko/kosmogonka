extends SceneTree
const Course=preload("res://scripts/course.gd")
const Basement=preload("res://scripts/basement.gd")
const Ship=preload("res://scripts/space_ship.gd")
const Crew=preload("res://scripts/crew.gd")
var app:Node
var checks:=0
var errors:=0
func _initialize() -> void: call_deferred("run")
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok: errors+=1; push_error(message)
func shot(key:String) -> void:
	await process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/arrival-"+key+".png")
func run() -> void:
	root.size=Vector2i(540,1188)
	app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; await process_frame; app.set_process(false); app.set_physics_process(false)
	var prepared:=Basement.glove(0)
	app.warm_geometry_gpu(prepared,false)
	await process_frame
	prepared.free()
	app.planet=0; app.start_level(); app.cinema_time=2.; app._process(.016)
	var forward:Vector3=-app.orbit.ship.global_basis.z
	check(forward.dot((app.camera.global_position-app.orbit.ship.global_position).normalized())>0.,"orbital pilot faces the camera")
	await shot("orbit-front")
	for entry in [[9.1,"canopy"],[10.2,"jet-exit"],[10.77,"jet-touchdown"],[13.5,"depart"]]:
		app.cinema_time=entry[0]; app._process(.016); await shot(entry[1])
		if entry[1]=="canopy": check(app.ship.canopy_hinge.rotation.x>1.,"canopy opens before takeoff")
		if entry[1]=="jet-exit":
			check(app.runner.visible and app.runner.mood=="disembark" and not app.surface_pilot.visible,"pilot exits in the new jetpack sequence")
			var skeleton: Skeleton3D = app.runner.crew_avatar.skeleton
			var left := skeleton.get_bone_pose_rotation(skeleton.find_bone("knee-left"))
			var right := skeleton.get_bone_pose_rotation(skeleton.find_bone("knee-right"))
			check(left.angle_to(right)>.5,"disembarking pilot tucks one knee")
		if entry[1]=="depart": check(app.ship.position.x>12. and app.runner.position.length()<.1,"ship leaves sideways after player lands")
	app.cinema_time=14.1; app._process(.016)
	check(app.state=="countdown" and app.countdown_time==3.,"3-second countdown follows disembarkation")
	await shot("countdown-grid")
	app._process(3.1); check(app.state=="run","countdown starts the run")
	app.begin_departure()
	app.cinema_time=1.95
	app._process(.016)
	var to_seat: Vector3 = app.surface_pilot.global_position-app.runner.global_position
	to_seat.y=0.
	check(app.runner.visible and app.runner.mood=="jump" and app.runner.global_basis.z.dot(to_seat.normalized())>.98,
		"departing hero jumps face-first towards the cockpit")
	await shot("boarding-front")
	app.start_level(); app.begin_run()
	app.distance=550.; app.events.assign([{"kind":"tunnel","s":550.,"length":44.,"lane":1}]); app.x=2.6; app.height=0.; app.tunnel_active={}
	for i in 30: app.update_camera(1./60)
	check(absf(app.camera.position.x-2.6)<.05,"bypass camera stays in the player's lane beside elevated passage")
	app.x=-2.6
	for i in 30: app.update_camera(1./60)
	check(absf(app.camera.position.x+2.6)<.05,"bypass follows the opposite adjacent lane")
	check(Basement.WIDTH>=5. and Basement.HEIGHT>=5.,"underground interior has room to see hazards")
	app.events.clear(); app.reset_course(); app.begin_run()
	var route:Dictionary={}
	for e:Dictionary in app.events:
		if e.kind=="basement": route=e; break
	app.distance=route.s-18.; app.lane=route.lane; app.x=(route.lane-1)*2.6; app.height=Basement.FLOOR; app.support=Basement.FLOOR; app.basement_active=route; app.passage_camera_blend=1.
	app.runner.position=Vector3(app.x,app.height,0)
	app.spawn_and_update(); app._process(.016); await shot("basement-sightline")
	check(app.camera.position.y<-.5 and app.camera.position.y>Basement.FLOOR+3.,"underground camera sits above the head below the ceiling")
	app.track_root.visible=false; app.hud.clear_screen("play"); app.camera.position=Vector3(3.7,2.8,7.7); app.camera.look_at(Vector3(0,1.7,0))
	var truck:=preload("res://scripts/props.gd").obstacle("truck",0); app.add_child(truck)
	check(truck.has_meta("cabin") and truck.get_node("AlienCabin").find_children("*","MeshInstance3D",true,false).any(func(mesh): return mesh.material_override is StandardMaterial3D and mesh.material_override.metallic>.80),"truck has mirrored glazing")
	truck.get_node("AlienCabin").advance(.4,-12.,true,false)
	check(truck.get_node("AlienCabin").led.get_shader_parameter("power")>.35,"approaching headlights pulse")
	await shot("truck-driver")
	truck.free()
	var arch:=preload("res://scripts/props.gd").obstacle("arch",1)
	app.add_child(arch); check(arch.get_meta("container_arch",false),"arch is built from cargo containers")
	app.camera.position=Vector3(3.7,2.8,7.7); app.camera.look_at(Vector3(0,1.5,0)); await shot("container-arch"); arch.free()
	var stairs_event:Dictionary={"kind":"stairs","top":2.96,"length":16.,"s":100.,"lower":true}
	var stairs:=preload("res://scripts/course_features.gd").build(stairs_event,0)
	preload("res://scripts/stair_flow.gd").advance(stairs,92.,stairs_event,false)
	var flow:ShaderMaterial=stairs.get_meta("stair_flow")
	check(float(flow.get_shader_parameter("activation"))>.99 and is_equal_approx(float(flow.get_shader_parameter("flow_distance")),92.*1.7),"stair wave activates and advances at 1.7 times runner travel")
	stairs.free()
	for i in 30: app.foot_sparks.advance(1./60,Vector3.ZERO,17.,true,false)
	check(app.foot_sparks.multimesh.instance_count==12 and app.foot_sparks.visible,"foot sparks reuse a bounded pool")
	app.foot_sparks.advance(.1,Vector3.ZERO,17.,true,true)
	check(not app.foot_sparks.visible,"reduced motion suppresses foot sparks")
	var fleet := {}
	var craft := Ship.create(0)
	root.add_child(craft)
	for variant in 4:
		craft.configure(variant)
		fleet[craft.get_meta("source_model")] = true
	check(fleet.size()==4,"four unique imported hulls")
	for index in Crew.MODELS.size():
		var actor: Node3D = craft.make_pilot(Crew.is_female(index),{},index)
		await process_frame
		var skeleton: Skeleton3D = actor.crew_avatar.skeleton
		var torso := craft.to_local(skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("torso")).origin))
		check(torso.distance_to(Ship.SEAT)<.04,"seated pose remains anchored after animation updates for %d"%index)
		var face: Node3D = actor.find_child("Expression",true,false)
		var face_point := craft.to_local(face.global_position)
		check(face_point.y>1.65 and ((face_point-Vector3.UP*Ship.SILL)/Ship.CANOPY_RADIUS).length()<.92,"face is behind the clear windshield for %d"%index)
		for visor: MeshInstance3D in face.get_parent().find_children("*","MeshInstance3D",false,false):
			if not visor.mesh is SphereMesh:
				continue
			var limit := 0.
			for axis in [Vector3.UP,Vector3.FORWARD,Vector3.BACK,Vector3.LEFT,Vector3.RIGHT,Vector3(0,1,1).normalized(),Vector3(0,1,-1).normalized()]:
				var tip := craft.to_local(visor.to_global(axis*.5))
				limit = maxf(limit,((tip-Vector3.UP*Ship.SILL)/Ship.CANOPY_RADIUS).length())
			check(limit<.985,"helmet clearance for %d (%.3f of the canopy radius)"%[index,limit])
		for attachment: BoneAttachment3D in skeleton.find_children("*","BoneAttachment3D",true,false):
			if not attachment.bone_name.begins_with("ankle"):
				continue
			for boot: MeshInstance3D in attachment.find_children("*","MeshInstance3D",true,false):
				var bounds: AABB = (craft.global_transform.affine_inverse()*boot.global_transform)*boot.get_aabb()
				check(bounds.position.y>.34 and bounds.end.y<Ship.SILL and absf(bounds.get_center().x)<.55,"boot stays inside the covered footwell for %d"%index)
		actor.free()
	craft.free()
	print("ARRIVAL REVIEW: %d checks, %d failures"%[checks,errors])
	if is_instance_valid(app.mobile_presentation): app.mobile_presentation.free()
	else: app.free()
	await process_frame; quit(1 if errors else 0)
