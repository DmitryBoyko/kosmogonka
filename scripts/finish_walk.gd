extends Node3D
## A separate, untimed post-race space; the race's score is already committed.
var avatar: CharacterBody3D
var stick:=Vector2.ZERO
var yaw:=0.0
var pitch:=.20
var pointer: int=-2
var pointer_pos:=Vector2.ZERO
var jump_pending:=false
var elapsed:=0.0
var force_field:Node3D
var zoom:=1.
var touches:Dictionary={}
var pinch_distance:=0.
var pinch_zoom:=1.
var camera_shape:=SphereShape3D.new()

static func prepare_collisions(monument:Node3D) -> void:
	var shapes:Array=[]
	var boxes: Array = monument.get_meta("city_collision_boxes",[]).duplicate()
	var garden := monument.get_node_or_null("MonumentGarden")
	if garden: boxes.append_array(garden.get_meta("solid_nature_boxes",[]))
	for bounds:AABB in boxes:
		var shape:=BoxShape3D.new(); shape.size=bounds.size
		shapes.append({"shape":shape,"transform":Transform3D(Basis.IDENTITY,bounds.get_center())})
	append_mesh_collisions(monument,monument,shapes)
	monument.set_meta("cached_collision_shapes",shapes)

static func append_mesh_collisions(monument:Node3D,section:Node3D,shapes:Array) -> void:
	var inverse:=monument.global_transform.affine_inverse()
	for piece:MeshInstance3D in section.find_children("*","MeshInstance3D",true,false):
		if not piece.visible or not piece.get_meta("architecture_solid",false): continue
		shapes.append({"shape":piece.mesh.create_trimesh_shape(),"transform":inverse*piece.global_transform})

func build(monument: Node3D, _planet: int, start: Vector3, scenery: Node3D) -> void:
	for landscape:Node3D in scenery.find_children("*","Node3D",true,false):
		if not landscape.is_visible_in_tree(): continue
		for bounds:AABB in landscape.get_meta("solid_nature_boxes",[]):
			var body:=StaticBody3D.new(); add_child(body)
			body.global_transform=landscape.global_transform*Transform3D(Basis.IDENTITY,bounds.get_center())
			var collision:=CollisionShape3D.new(); var box:=BoxShape3D.new(); box.size=bounds.size; collision.shape=box; body.add_child(collision)
	# Preserve the race ground and road. The fallback plane lies at the same soil level.
	var floor_body:=StaticBody3D.new(); add_child(floor_body)
	var floor_shape:=CollisionShape3D.new(); var infinite_plane:=WorldBoundaryShape3D.new()
	infinite_plane.plane=Plane(Vector3.UP,-.225 if _planet==4 else -12.); floor_shape.shape=infinite_plane; floor_body.add_child(floor_shape)
	for piece:MeshInstance3D in scenery.find_children("*","MeshInstance3D",true,false):
		if not piece.is_visible_in_tree(): continue
		if piece.get_meta("surface_role","") not in ["road","ground","walkable_relief"]: continue
		var road_body:=StaticBody3D.new(); add_child(road_body); road_body.global_transform=piece.global_transform
		var road_shape:=CollisionShape3D.new(); road_shape.shape=piece.mesh.create_trimesh_shape(); road_body.add_child(road_shape)
	# Use the rendered architecture, including gate openings and rear colonnades.
	if monument.has_meta("cached_collision_shapes"):
		for item:Dictionary in monument.get_meta("cached_collision_shapes"):
			var body:=StaticBody3D.new(); add_child(body); body.global_transform=monument.global_transform*item.transform
			var shape:=CollisionShape3D.new(); shape.shape=item.shape; body.add_child(shape)
	else:
		for piece: MeshInstance3D in monument.find_children("*","MeshInstance3D",true,false):
			if not piece.visible or not piece.get_meta("architecture_solid",false): continue
			var body:=StaticBody3D.new(); add_child(body); body.global_transform=piece.global_transform
			var shape:=CollisionShape3D.new(); shape.shape=piece.mesh.create_trimesh_shape(); body.add_child(shape)
	avatar=CharacterBody3D.new(); add_child(avatar); avatar.name="FreeRunner"
	avatar.collision_mask=3
	avatar.floor_max_angle=deg_to_rad(57.)
	avatar.position=Vector3(start.x,maxf(.12,start.y),start.z); avatar.floor_snap_length=.4
	var capsule:=CapsuleShape3D.new(); capsule.radius=.34; capsule.height=2.8
	var collision:=CollisionShape3D.new(); collision.shape=capsule; collision.position.y=1.4; avatar.add_child(collision)
	camera_shape.radius=.28
	force_field=preload("res://scripts/finish_field.gd").new(); add_child(force_field); force_field.build(_planet)

func stop() -> void:
	stick=Vector2.ZERO; pointer=-2; jump_pending=false
	touches.clear(); pinch_distance=0.
	if is_instance_valid(avatar): avatar.velocity=Vector3.ZERO

func pointer_event(event: InputEvent) -> void:
	if event is InputEventMagnifyGesture:
		zoom=clampf(zoom*event.factor,1.,2.); return
	if event is InputEventScreenTouch:
		if event.pressed: touches[event.index]=event.position
		else: touches.erase(event.index)
		if touches.size()==2:
			var points:=touches.values(); pinch_distance=points[0].distance_to(points[1]); pinch_zoom=zoom; pointer=-2; return
		if touches.size()==1:
			pointer=int(touches.keys()[0]); pointer_pos=touches.values()[0]; pinch_distance=0.; return
		if event.pressed and pointer==-2: pointer=event.index; pointer_pos=event.position
		elif not event.pressed and pointer==event.index: pointer=-2
	elif event is InputEventScreenDrag:
		if touches.has(event.index): touches[event.index]=event.position
		if touches.size()==2 and pinch_distance>1.:
			var points:=touches.values(); zoom=clampf(pinch_zoom*points[0].distance_to(points[1])/pinch_distance,1.,2.)
		elif event.index==pointer: orbit_drag(event.position-pointer_pos); pointer_pos=event.position
	elif event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		zoom=clampf(zoom+(.12 if event.button_index==MOUSE_BUTTON_WHEEL_UP else -.12),1.,2.)
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.device!=InputEvent.DEVICE_ID_EMULATION:
		if event.pressed: pointer=-1; pointer_pos=event.position
		else: pointer=-2
	elif event is InputEventMouseMotion and pointer==-1:
		orbit_drag(event.position-pointer_pos); pointer_pos=event.position

func orbit_drag(delta: Vector2) -> void:
	yaw-=delta.x*.008; pitch=clampf(pitch+delta.y*.005,-.95 if zoom>=1.999 else .18,.95)

func advance(dt: float, keyboard: bool=true) -> void:
	elapsed+=dt
	force_field.advance(elapsed,avatar.position,get_tree().root.get_node("Profile").reduced_motion)
	var axes:=stick
	if keyboard:
		axes+=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	axes=axes.limit_length()
	var direction:=Vector3(cos(yaw)*axes.x+sin(yaw)*axes.y,0,-sin(yaw)*axes.x+cos(yaw)*axes.y)
	avatar.velocity.x=direction.x*6; avatar.velocity.z=direction.z*6
	avatar.velocity.y=maxf(-24,avatar.velocity.y-dt*22)
	if jump_pending and avatar.is_on_floor(): avatar.velocity.y=8.2
	jump_pending=false
	avatar.move_and_slide()

func present(dt: float, hero: Node3D, camera: Camera3D, reduced_motion: bool) -> void:
	hero.position=avatar.position
	var first_person:bool=zoom>=1.999
	hero.set_first_person(first_person)
	var velocity:=Vector2(avatar.velocity.x,avatar.velocity.z)
	if velocity.length()>.1: hero.rotation.y=lerp_angle(hero.rotation.y,atan2(velocity.x,velocity.y),minf(1,dt*12))
	hero.animate(dt,"jump" if not avatar.is_on_floor() else "run" if velocity.length()>.1 else "win" if elapsed<1.5 else "idle",velocity.length())
	if first_person:
		var eye:Vector3=avatar.position+Vector3.UP*2.55
		camera.position=safe_camera(eye,camera.position.lerp(eye,1. if reduced_motion else 1.-exp(-dt*12.)))
		var forward:=Vector3(-sin(yaw)*cos(pitch),-sin(pitch),-cos(yaw)*cos(pitch))
		camera.look_at(camera.position+forward);camera.fov=80.;camera.near=.06
		return
	var target:=hero.position+Vector3(0,1.4,0)
	var desired:=safe_camera(target,target+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*14./zoom)
	if desired.distance_to(target)<2.4:
		for offset in [.6,-.6,1.2,-1.2,PI]:
			var alternate:=safe_camera(target,target+Vector3(sin(yaw+offset)*cos(pitch),sin(pitch)+.2,cos(yaw+offset)*cos(pitch))*14./zoom)
			if alternate.distance_to(target)>2.4: desired=alternate; break
	var candidate:=camera.position.lerp(desired,1.0 if reduced_motion else 1-exp(-dt*9))
	camera.position=safe_camera(target,candidate)
	if camera.position.distance_to(target)<1.4: camera.position=desired
	if not camera.position.is_equal_approx(target): camera.look_at(target)
	camera.fov=66

func safe_camera(target:Vector3,wanted:Vector3) -> Vector3:
	var query:=PhysicsShapeQueryParameters3D.new(); query.shape=camera_shape
	query.transform=Transform3D(Basis.IDENTITY,target); query.motion=wanted-target
	query.collision_mask=5; query.exclude=[avatar.get_rid()]; query.margin=.035
	var fractions:PackedFloat32Array=get_world_3d().direct_space_state.cast_motion(query)
	return target+query.motion*maxf(0.,fractions[0]-.01) if fractions[0]<1. else wanted
