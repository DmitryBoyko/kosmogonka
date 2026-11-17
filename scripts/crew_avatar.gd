extends Node3D

const Crew = preload("res://scripts/crew.gd")
const G = preload("res://scripts/geometry.gd")
const Catalog = preload("res://scripts/outfit_catalog.gd")
const Badge = preload("res://scripts/chest_badge.gd")
const RunCycle = preload("res://scripts/crew_run_cycle.gd")
const Joints = preload("res://scripts/crew_joints.gd")
const CrewFace = preload("res://scripts/crew_expression.gd")
const CrewHair = preload("res://scripts/crew_hair.gd")
const Armor = preload("res://scripts/crew_armor.gd")
const SPRINT := "crew/sprint"
const HEAD_SCALE := .81

var character_index: int
var rig: Node3D
var skeleton: Skeleton3D
var animation: AnimationPlayer
var panels: Dictionary = {}
var palette: Dictionary = {}
var chest: Node3D
var badge: Node3D
var badge_id := ""
var armor_parts: Array[Node3D] = []
var equipped_armor: Dictionary = {}
var preview_pack: Node3D
var backpack_center: Vector3
var expression: ShaderMaterial
var blink_clock := 0.0
var smile := .2
var grin_left := 0.0

func build(index: int, with_pack: bool = false) -> void:
	character_index = index
	rig = Crew.scene(index).instantiate()
	add_child(rig)
	rig.scale = Vector3.ONE * 3.85
	skeleton = rig.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	animation = rig.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	if index==Crew.ALIEN_GUY:
		build_alien()
		return
	RunCycle.attach(animation,skeleton,character_index)
	skeleton.set_bone_pose_scale(skeleton.find_bone("head"),Vector3.ONE*HEAD_SCALE)
	var paint: Array = Crew.PAINT[index]
	var primary: String = paint[0]
	var accent: String = paint[1]
	var weave := Color(primary).darkened(.42).to_html(false)
	var head_mesh: MeshInstance3D
	for mesh: MeshInstance3D in rig.find_children("*", "MeshInstance3D", true, false):
		if "head-mesh" in String(mesh.name):
			head_mesh = mesh
		if "body-mesh" in String(mesh.name):
			# The imported body uses a single rigid segment for each limb.
			mesh.hide()

	chest = mount("torso")
	Joints.build_torso(self,primary,accent,weave)
	backpack_center = Joints.BACKPACK_POSITION
	var helmet := mount("head")
	panels["helmet"] = []
	if head_mesh:
		var head_origin := skeleton.get_bone_global_rest(skeleton.find_bone("head")).origin
		expression = CrewFace.build(head_mesh,helmet,head_origin,index)
		var head_bounds := head_mesh.get_aabb()
		var glass := G.ball(helmet,head_bounds.size + Vector3(.06,.06,.085),head_bounds.get_center()-head_origin)
		var visor := ShaderMaterial.new()
		visor.shader = preload("res://assets/suits/crew_visor.gdshader")
		visor.render_priority = 2
		glass.material_override = visor
		glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if Crew.MODELS[index]=="female-a":
			CrewHair.add_braids(helmet)
	for side in [-1.,1.]:
		var radio := G.box(helmet,Vector3(.043,.082,.082),Vector3(side*.207,.12,.013),primary,.18)
		panels["helmet"].append(radio)
		G.box(helmet,Vector3(.009,.039,.042),Vector3(side*.232,.12,.009),accent,.18)
		G.link(helmet,Vector3(side*.209,.16,.031),Vector3(side*.213,.234,.035),.009,"607e9b")

	Joints.build(self,primary,accent,weave)
	if with_pack:
		preview_pack = Node3D.new()
		chest.add_child(preview_pack)
		preview_pack.position = backpack_center
		panels["pack"] = [G.box(preview_pack,Vector3(.15,.15,.08),Vector3.ZERO,primary,.18)]
		for side in [-1.,1.]:
			var thruster := G.tube(preview_pack,.031,.16,Vector3(side*.088,0,0),accent)
			thruster.material_override = G.material(accent,.18)
			panels["pack"].append(thruster)

	for group in panels:
		palette[group] = []
		for mesh: MeshInstance3D in panels[group]:
			palette[group].append(mesh.material_override)
	for mesh:GeometryInstance3D in find_children("*","GeometryInstance3D",true,false):
		mesh.set_layer_mask_value(10,true)
	apply_outfit({})
	pose("idle")

func build_alien() -> void:
	var bounds := preload("res://scripts/loop_layout.gd").bounds(rig,Transform3D.IDENTITY)
	var fit := 2.95 / maxf(.01,bounds.size.y)
	rig.scale=Vector3.ONE*fit
	rig.position=Vector3(-bounds.get_center().x,-bounds.position.y,-bounds.get_center().z)*fit
	chest=Node3D.new()
	rig.add_child(chest)
	backpack_center=Vector3(0,bounds.position.y+bounds.size.y*.48,-bounds.size.z*.29)
	for mesh: MeshInstance3D in rig.find_children("*","MeshInstance3D",true,false):
		mesh.set_layer_mask_value(10,true)
	for clip: String in animation.get_animation_list():
		if clip!="RESET": animation.get_animation(clip).loop_mode=Animation.LOOP_LINEAR
	RunCycle.attach_alien_jet(animation,skeleton)
	pose("idle")

func mount(bone: String) -> BoneAttachment3D:
	var attachment := BoneAttachment3D.new()
	attachment.bone_name = bone
	skeleton.add_child(attachment)
	return attachment

func apply_outfit(outfit: Dictionary) -> void:
	if character_index==Crew.ALIEN_GUY: return
	var selection := {}
	for group: String in Catalog.ARMOR:
		if outfit.has(group) and not Catalog.get_item(str(outfit[group])).is_empty():
			selection[group]=outfit[group]
	if selection!=equipped_armor:
		equipped_armor = selection
		for part in armor_parts: part.free()
		armor_parts.clear()
		for group: String in selection:
			Armor.decorate(group,Catalog.get_item(selection[group]),panels[group],armor_parts)
	for group in panels:
		var item := Catalog.get_item(str(outfit.get(group,"")))
		for i in panels[group].size():
			var mesh: MeshInstance3D = panels[group][i]
			if item.is_empty(): mesh.material_override = palette[group][i]
			elif Catalog.ARMOR.has(group): mesh.material_override = Armor.fabric(item,palette[group][i])
			else: mesh.material_override = G.material(item.color)
	var next_badge := str(outfit.get("badge",""))
	var badge_position := Joints.BADGE_POSITION
	if selection.has("torso") and not next_badge.is_empty():
		badge_position.z += .026
	if is_instance_valid(badge) and next_badge == badge_id:
		badge.position = badge_position
		return
	if is_instance_valid(badge):
		badge.free()
	var item := Catalog.get_item(next_badge)
	badge = Badge.build(int(item.get("shape",1)))
	chest.add_child(badge)
	badge.scale = Vector3.ONE * .235
	badge.position = badge_position
	if Catalog.meteor_capacity(item)>0:
		var emitter := G.ring(badge,.188,.207,Vector3(0,0,-.008),"91eaff",.4)
		emitter.rotation.x=PI*.5
		emitter.scale.y=.8
	badge_id = next_badge

func grin(duration: float = 1.35) -> void:
	grin_left = maxf(grin_left,duration)

func update_expression(dt: float, smile_target: float) -> void:
	if expression == null:
		return
	blink_clock += dt
	var period := 2.65 + float(character_index % 6) * .23
	var phase := fposmod(blink_clock + float(character_index % 7) * .39 + .7,period)
	var blink := smoothstep(0.,.065,phase) * (1. - smoothstep(.105,.20,phase))
	grin_left = maxf(0.,grin_left - dt)
	smile = lerpf(smile,1. if grin_left > 0. else smile_target,1. - exp(-8. * dt))
	expression.set_shader_parameter("blink",blink)
	expression.set_shader_parameter("smile",smile)

func pose(action: String, speed: float = 0.0, gesture: String = "", dt: float = 1.0/60.0, smile_target: float = .20) -> void:
	if character_index==Crew.ALIEN_GUY:
		var original_clip: String = {"run":"Running Cycle","walk":"Walking Cycle","jet":"crew/jet","shop_guard":"Standby","pilot":"Standby","win":"Idle1"}.get(action,"Idle1")
		if animation.assigned_animation != original_clip and animation.has_animation(original_clip):
			animation.play(original_clip,.16)
			animation.advance(0.)
		rotation.x=lerpf(rotation.x,-.23 if action in ["slide","roll"] else .08 if action=="jump" else 0.,minf(1.,dt*12.))
		return
	var clip := "idle"
	var rate := 1.0
	match action:
		"run":
			clip = "sprint"
			rate = clampf(pow(speed / 17.,.65),.88,1.27) if speed > 0 else 1.
		"walk":
			clip = "walk"
			rate = clampf(pow(speed / 6.,.65),.68,1.27) if speed > 0 else 1.
		"jump", "flip": clip = "jump"
		"slide", "roll": clip = "crouch"
		"jet": clip = "jet"
		"board": clip = "fall"
		"disembark": clip = "disembark"
		"pilot": clip = "sit"
		"win": clip = "emote-yes"
		"wave": clip = "wave"
		"work": clip = "interact-right"
		"shop_guard": clip = "emote-yes"
	if not gesture.is_empty() and action == "run":
		clip += "-" + gesture
	update_expression(dt,1. if action=="win" else .72 if action=="disembark" else .55 if action=="jet" else maxf(.82,smile_target) if not gesture.is_empty() else smile_target)
	clip = "crew/" + clip
	if animation.current_animation != clip and animation.assigned_animation != clip:
		var keep_stride := animation.current_animation.begins_with(SPRINT) and clip.begins_with(SPRINT)
		var stride := animation.current_animation_position if keep_stride else 0.
		animation.play(clip,.12)
		animation.advance(0.)
		if keep_stride: animation.seek(stride,true)
	animation.speed_scale = lerpf(animation.speed_scale, rate, 1. - exp(-10. * dt))
