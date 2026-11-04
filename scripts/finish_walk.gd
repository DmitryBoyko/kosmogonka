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

static func prepare_collisions(monument:Node3D) -> void:
	var shapes:Array=[]
	for bounds:AABB in monument.get_meta("city_collision_boxes",[]):
		var shape:=BoxShape3D.new(); shape.size=bounds.size
		shapes.append({"shape":shape,"transform":Transform3D(Basis.IDENTITY,bounds.get_center())})
	for piece:MeshInstance3D in monument.find_children("*","MeshInstance3D",true,false):
		if not piece.visible or not piece.get_meta("architecture_solid",false): continue
		shapes.append({"shape":piece.mesh.create_trimesh_shape(),"transform":monument.global_transform.affine_inverse()*piece.global_transform})
	monument.set_meta("cached_collision_shapes",shapes)

func build(monument: Node3D, _planet: int, start: Vector3, scenery: Node3D) -> void:
	# Preserve the race ground and road. The fallback plane lies at the same soil level.
	var floor_body:=StaticBody3D.new(); add_child(floor_body)
	var floor_shape:=CollisionShape3D.new(); var infinite_plane:=WorldBoundaryShape3D.new()
	infinite_plane.plane=Plane(Vector3.UP,-.225); floor_shape.shape=infinite_plane; floor_body.add_child(floor_shape)
	for piece:MeshInstance3D in scenery.find_children("*","MeshInstance3D",true,false):
		if not piece.is_visible_in_tree(): continue
		if piece.get_meta("surface_role","")!="road": continue
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
	avatar.position=Vector3(start.x,maxf(.12,start.y),start.z); avatar.floor_snap_length=.4
	var capsule:=CapsuleShape3D.new(); capsule.radius=.29; capsule.height=1.7
	var collision:=CollisionShape3D.new(); collision.shape=capsule; collision.position.y=.85; avatar.add_child(collision)
	force_field=preload("res://scripts/finish_field.gd").new(); add_child(force_field); force_field.build(_planet)

func stop() -> void:
	stick=Vector2.ZERO; pointer=-2; jump_pending=false
	if is_instance_valid(avatar): avatar.velocity=Vector3.ZERO

func pointer_event(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and pointer==-2: pointer=event.index; pointer_pos=event.position
		elif not event.pressed and pointer==event.index: pointer=-2
	elif event is InputEventScreenDrag and event.index==pointer:
		orbit_drag(event.position-pointer_pos); pointer_pos=event.position
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.device!=InputEvent.DEVICE_ID_EMULATION:
		if event.pressed: pointer=-1; pointer_pos=event.position
		else: pointer=-2
	elif event is InputEventMouseMotion and pointer==-1:
		orbit_drag(event.position-pointer_pos); pointer_pos=event.position

func orbit_drag(delta: Vector2) -> void:
	yaw-=delta.x*.008; pitch=clampf(pitch+delta.y*.005,.18,.95)

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
	var velocity:=Vector2(avatar.velocity.x,avatar.velocity.z)
	if velocity.length()>.1: hero.rotation.y=lerp_angle(hero.rotation.y,atan2(velocity.x,velocity.y),minf(1,dt*12))
	hero.animate(dt,"jump" if not avatar.is_on_floor() else "run" if velocity.length()>.1 else "win" if elapsed<1.5 else "idle",velocity.length())
	var target:=hero.position+Vector3(0,1.4,0)
	var desired:=target+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*14
	var query:=PhysicsRayQueryParameters3D.create(target,desired,1,[avatar.get_rid()])
	var hit:=get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty(): desired=hit.position+(target-hit.position).normalized()*.35
	camera.position=camera.position.lerp(desired,1.0 if reduced_motion else 1-exp(-dt*9))
	camera.look_at(target); camera.fov=66
