extends Node3D

const G = preload("res://scripts/geometry.gd")
const Probe = preload("res://scripts/roadside_probe.gd")
const PLATFORMS = [
	preload("res://assets/finish_city/platforms/cyber_dHymLbsOMY.glb"),
	preload("res://assets/finish_city/platforms/cyber_s0rwPHWMpY.glb"),
]
var planet_index := 0
var platform: Node3D
var sentry: Node3D
var scanners: Array[Dictionary]=[]
var escort: Node3D
var scout: Node3D
var elapsed := 0.
var visit := -1
var target: Node3D

func build(world: int=0) -> void:
	planet_index=world
	name="PlazaAirshow"
	platform=Node3D.new()
	platform.name="CyberPlatform"
	add_child(platform)
	fit_platform(platform,0,Vector3(6.5,1.1,4.4))
	escort=Node3D.new()
	escort.name="CyberPlatformEscort"
	add_child(escort)
	fit_platform(escort,1,Vector3(5.6,.85,1.65))
	G.box(platform,Vector3(6.1,.11,4.12),Vector3(0,.36,0),"43efd1",.38)
	for side in [-1.,1.]:
		G.box(platform,Vector3(1.48,1.12,1.14),Vector3(side*1.93,.9,.54),"ef72b7")
		G.box(platform,Vector3(1.25,.76,.12),Vector3(side*1.93,1.00,1.14),"94f1ff",.85)
		G.label(platform,"◉",Vector3(side*1.93,1.0,1.22),32)
		G.tube(platform,.11,1.38,Vector3(side*2.26,1.85,-.86),"ffc14c")
		G.ball(platform,Vector3.ONE*.29,Vector3(side*2.26,2.55,-.86),"ff7edb",.7)
		for z in [-1.18,1.18]:
			G.tube(platform,.42,.48,Vector3(side*2.24,-.52,z),"424b89")
			G.ring(platform,.23,.41,Vector3(side*2.24,-.78,z),"54ffdf",.88)
	G.box(platform,Vector3(1.45,1.06,1.65),Vector3(0,.77,-.46),"ffac4d")
	G.merge_static(platform)
	sentry=Node3D.new()
	sentry.name="CyberPlatformSentry"
	add_child(sentry)
	fit_platform(sentry,0,Vector3(4.8,.8,3.3))
	add_robot(platform,Vector3(0,1.32,-.46),0)
	add_robot(escort,Vector3(0,.43,0),1)
	add_robot(sentry,Vector3(0,.41,0),2)
	scout=Probe.new()
	add_child(scout)
	scout.create_visual()
	scout.hide()

func fit_platform(holder: Node3D, index: int, size: Vector3) -> void:
	var model: Node3D = PLATFORMS[index].instantiate()
	holder.add_child(model)
	var bounds := preload("res://scripts/loop_layout.gd").bounds(model,Transform3D.IDENTITY)
	model.scale = size / bounds.size
	model.position = -bounds.get_center() * model.scale
	for piece: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		for slot in piece.mesh.get_surface_count():
			var material := piece.get_active_material(slot) as StandardMaterial3D
			if not material or material.albedo_texture: continue
			var paint := material.duplicate() as StandardMaterial3D
			var palette := {"LightGrey":"6e9cff","Grey":"4e68ca","DarkGrey":"384980","Orange":"ffad42"}
			if palette.has(material.resource_name): paint.albedo_color=Color(palette[material.resource_name])
			piece.set_surface_override_material(slot,paint)

func present(dt: float, player: Node3D, visitors: Array, reduced: bool) -> void:
	elapsed+=dt
	platform.position=Vector3(-14.,9.+(0. if reduced else sin(elapsed*1.2)*.38),-21.)
	platform.rotation.y=.28+(0. if reduced else sin(elapsed*.6)*.13)
	escort.position=Vector3(20.,8.+(0. if reduced else sin(elapsed*.9)*.35),-34.)
	escort.rotation.y=-.4
	sentry.position=Vector3(24.,7.2+(0. if reduced else sin(elapsed*.8)*.28),-5.)
	sentry.rotation.y=.5
	for item in scanners:
		var phase:=elapsed*.42+float(item.index)*2.1
		var eye: Vector3=item.at+Vector3.UP*1.7
		var aim:=Vector3(sin(phase)*5.,-7.,cos(phase)*5.)
		var old_yaw: float=item.robot.rotation.y
		item.robot.rotation.y=atan2(aim.x-item.at.x,aim.z-item.at.z)
		item.sparks.advance(dt,absf(angle_difference(old_yaw,item.robot.rotation.y))>.0001,reduced)
		var ray:=aim-eye
		item.beam.position=eye+ray*.5
		item.beam.quaternion=Quaternion(Vector3.DOWN,ray.normalized())
		item.beam.scale=Vector3(1.,ray.length(),1.)
	if elapsed<4.:
		scout.hide()
		return
	var pass_time:=elapsed-4.
	var current:=floori(pass_time/18.)
	var phase:=fposmod(pass_time,18.)
	if current!=visit:
		visit=current
		target=player
		if visit%2==1 and not visitors.is_empty():
			target=visitors[(visit/2)%visitors.size()].node
	if phase>7. or not is_instance_valid(target):
		scout.hide()
		return
	var at := to_local(target.global_position)+Vector3.UP*1.4
	var hover := at+Vector3(3.1,4.7,-3.8)
	var approach := smoothstep(0.,2.,phase)
	var depart := smoothstep(5.,7.,phase)
	var craft_at := Vector3(20.,13.,-36.).lerp(hover,approach).lerp(Vector3(-31.,16.,-47.),depart)
	scout.show()
	scout.craft.position=craft_at
	var direction: Vector3 = at-craft_at
	scout.craft.rotation.y=atan2(direction.x,direction.z)
	scout.beam.visible=phase>1.8 and phase<5.3
	scout.beam.position=craft_at+direction*.5
	scout.beam.quaternion=Quaternion(Vector3.DOWN,direction.normalized())
	scout.beam.scale=Vector3(1.,direction.length(),1.)
	scout.field.set_shader_parameter("strength",smoothstep(1.8,2.2,phase)*(1.-smoothstep(4.8,5.3,phase)))
	scout.field.set_shader_parameter("scan_phase",.5 if reduced else fposmod(phase*1.4,1.))

func add_robot(deck: Node3D, at: Vector3, index: int) -> void:
	var robot:=Node3D.new()
	robot.name="ScanningRobot"
	deck.add_child(robot)
	robot.position=at
	var model: Node3D=preload("res://assets/finish_city/bunker/deep_space_guard.glb").instantiate()
	robot.add_child(model)
	var bounds:=preload("res://scripts/loop_layout.gd").bounds(model,Transform3D.IDENTITY)
	var fit:=2.1/bounds.size.y
	model.scale=Vector3.ONE*fit
	model.rotation.y=PI
	model.position=-(Basis(Vector3.UP,PI)*Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z))*fit
	preload("res://scripts/robot_armor.gd").apply(model)
	G.merge_static(model)
	var cone:=CylinderMesh.new()
	cone.top_radius=.025; cone.bottom_radius=1.6; cone.height=1.
	cone.radial_segments=16; cone.cap_top=false; cone.cap_bottom=false
	var paint:=StandardMaterial3D.new()
	paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	paint.cull_mode=BaseMaterial3D.CULL_DISABLED
	paint.albedo_color=Color(.23,1.,.78,.10)
	var beam:=G.part(deck,cone,Vector3.ZERO,paint)
	beam.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var sparks=preload("res://scripts/robot_sparks.gd").new();robot.add_child(sparks);sparks.build(2.1,float(index)*.9)
	scanners.append({"sparks":sparks,"robot":robot,"beam":beam,"at":at,"index":index})
