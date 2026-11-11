extends Node3D

const Crew = preload("res://scripts/crew.gd")
const G = preload("res://scripts/geometry.gd")
const Catalog = preload("res://scripts/outfit_catalog.gd")
const Badge = preload("res://scripts/chest_badge.gd")
const Shell = preload("res://scripts/salvage_mesh.gd")
const RunCycle = preload("res://scripts/crew_run_cycle.gd")
const SPRINT := "crew/sprint"
static var body_fits: Dictionary = {}

var character_index: int
var rig: Node3D
var skeleton: Skeleton3D
var animation: AnimationPlayer
var panels: Dictionary = {}
var palette: Dictionary = {}
var chest: Node3D
var badge: Node3D
var badge_id := ""
var preview_pack: Node3D
var backpack_center: Vector3

func build(index: int, with_pack: bool = false) -> void:
	character_index = index
	rig = Crew.scene(index).instantiate()
	add_child(rig)
	rig.scale = Vector3.ONE * 3.85
	skeleton = rig.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	animation = rig.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	RunCycle.attach(animation, character_index)
	for clip in ["idle","walk","sprint","crouch","fall","sit"]:
		animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	var accent: String = Crew.ACCENTS[index % Crew.ACCENTS.size()]
	var head_bounds := AABB()
	var body_fit: Dictionary = body_fits.get(index, {})
	for mesh: MeshInstance3D in rig.find_children("*", "MeshInstance3D", true, false):
		if "head-mesh" in String(mesh.name):
			head_bounds = mesh.get_aabb()
		if "body-mesh" in String(mesh.name):
			if body_fit.is_empty():
				body_fit = measure_body(mesh)
				body_fits[index] = body_fit
			for surface in mesh.mesh.get_surface_count():
				var original := mesh.get_active_material(surface) as StandardMaterial3D
				if original:
					var fabric := original.duplicate() as StandardMaterial3D
					fabric.albedo_color = Color("b2c7de")
					mesh.set_surface_override_material(surface, fabric)

	chest = mount("torso")
	var torso: AABB = body_fit["torso"]
	var torso_center := torso.get_center()
	var panel_position := Vector3(torso_center.x, torso_center.y, torso.end.z + .018)
	var shell := Shell.block(chest, torso.size + Vector3(.02,.014,.022), torso_center, G.material("dfedf5"), .018)
	panels["torso"] = [shell, G.box(chest, Vector3(.164,.087,.018), panel_position, accent)]
	backpack_center = Vector3(torso_center.x, torso_center.y, torso.position.z - .057)
	var collar := G.ring(chest,.066,.088,Vector3(torso_center.x,torso.end.y + .006,0),"7f9bb1")
	collar.scale.z = .84
	var helmet := mount("head")
	panels["helmet"] = []
	if head_bounds.has_volume():
		var head_origin := skeleton.get_bone_global_rest(skeleton.find_bone("head")).origin
		var glass := G.ball(helmet,head_bounds.size + Vector3(.06,.06,.085),head_bounds.get_center()-head_origin)
		var visor := ShaderMaterial.new()
		visor.shader = preload("res://assets/suits/crew_visor.gdshader")
		glass.material_override = visor
		glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for side in [-1.,1.]:
		var radio := G.box(helmet,Vector3(.043,.082,.082),Vector3(side*.207,.12,.013),"d9eaf6")
		panels["helmet"].append(radio)
		G.box(helmet,Vector3(.009,.039,.042),Vector3(side*.232,.12,.009),accent,.18)
		G.link(helmet,Vector3(side*.209,.16,.031),Vector3(side*.213,.234,.035),.009,"607e9b")

	panels["arms"] = []
	panels["gloves"] = []
	panels["legs"] = []
	panels["boots"] = []
	for side in ["left","right"]:
		var direction := 1. if side == "left" else -1.
		var arm := mount("arm-" + side)
		panels["arms"].append(Shell.block(arm,Vector3(.097,.145,.147),Vector3(direction*.039,0,0),G.material("dcecf5"),.014))
		panels["gloves"].append(Shell.block(arm,Vector3(.115,.123,.147),Vector3(direction*.229,0,.009),G.material(accent),.012))
		var leg := mount("leg-" + side)
		var bounds: AABB = body_fit["leg-" + side]
		var center := bounds.get_center()
		panels["legs"].append(Shell.block(leg,Vector3(bounds.size.x+.009,.10,.11),Vector3(center.x,-.063,.025),G.material("c6dceb"),.012))
		panels["boots"].append(Shell.block(leg,Vector3(bounds.size.x+.013,.064,bounds.size.z+.008),Vector3(center.x,bounds.position.y+.032,center.z),G.material("e7f0f7"),.01))
	if with_pack:
		preview_pack = Node3D.new()
		chest.add_child(preview_pack)
		preview_pack.position = backpack_center
		panels["pack"] = [G.box(preview_pack,Vector3(.15,.15,.08),Vector3.ZERO,"405a77")]
		for side in [-1.,1.]:
			G.tube(preview_pack,.031,.16,Vector3(side*.088,0,0),accent)

	for group in panels:
		palette[group] = []
		for mesh: MeshInstance3D in panels[group]:
			palette[group].append(mesh.material_override)
	apply_outfit({})
	pose("idle")

func measure_body(mesh: MeshInstance3D) -> Dictionary:
	var bounds := {}
	var skin := mesh.skin
	var bone_names: Array[StringName] = []
	var to_local: Array[Transform3D] = []
	for bind in skin.get_bind_count():
		var name := skin.get_bind_name(bind)
		var bone := skeleton.find_bone(name) if not name.is_empty() else skin.get_bind_bone(bind)
		bone_names.append(skeleton.get_bone_name(bone))
		to_local.append(skeleton.get_bone_global_rest(bone).affine_inverse())
	for surface in mesh.mesh.get_surface_count():
		var arrays := mesh.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var joints: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var influences: int = joints.size() / vertices.size()
		for i in vertices.size():
			var first := i * influences
			var strongest := first
			for j in range(first + 1, first + influences):
				if weights[j] > weights[strongest]:
					strongest = j
			var bind := joints[strongest]
			var name := bone_names[bind]
			if name not in [&"torso", &"leg-left", &"leg-right"]:
				continue
			var point := to_local[bind] * vertices[i]
			bounds[name] = bounds[name].expand(point) if bounds.has(name) else AABB(point, Vector3.ZERO)
	return bounds

func mount(bone: String) -> BoneAttachment3D:
	var attachment := BoneAttachment3D.new()
	attachment.bone_name = bone
	skeleton.add_child(attachment)
	return attachment

func apply_outfit(outfit: Dictionary) -> void:
	for group in panels:
		var item := Catalog.get_item(str(outfit.get(group,"")))
		for i in panels[group].size():
			var mesh: MeshInstance3D = panels[group][i]
			mesh.material_override = palette[group][i] if item.is_empty() else G.material(item.color)
	var next_badge := str(outfit.get("badge",""))
	if is_instance_valid(badge) and next_badge == badge_id:
		return
	if is_instance_valid(badge):
		badge.free()
	var item := Catalog.get_item(next_badge)
	badge = Badge.build(int(item.get("shape",1)))
	chest.add_child(badge)
	badge.scale = Vector3.ONE * .235
	var torso: AABB = body_fits[character_index]["torso"]
	badge.position = Vector3(torso.get_center().x,torso.get_center().y,torso.end.z+.029)
	badge_id = next_badge

func pose(action: String, speed: float = 0.0, gesture: String = "", dt: float = 1.0/60.0) -> void:
	var clip := "idle"
	var rate := 1.0
	match action:
		"run", "walk":
			var walking_limit := 6.5 if animation.assigned_animation == SPRINT else 8.5
			clip = "walk" if action == "walk" or (speed > 0 and speed < walking_limit) else SPRINT
			var reference := 6. if clip == "walk" else 17.
			rate = clampf(pow(speed / reference,.65),.68,1.27) if speed > 0 else 1.
		"jump", "flip": clip = "jump"
		"slide", "roll": clip = "crouch"
		"jet", "board": clip = "fall"
		"pilot": clip = "sit"
		"win": clip = "emote-yes"
	if not gesture.is_empty() and action == "run":
		clip = "interact-right"
	if animation.current_animation != clip and animation.assigned_animation != clip:
		animation.play(clip,.12)
		animation.advance(0.)
	animation.speed_scale = lerpf(animation.speed_scale, rate, 1. - exp(-10. * dt))
