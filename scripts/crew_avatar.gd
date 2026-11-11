extends Node3D

const Crew = preload("res://scripts/crew.gd")
const G = preload("res://scripts/geometry.gd")
const Catalog = preload("res://scripts/outfit_catalog.gd")
const Badge = preload("res://scripts/chest_badge.gd")

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

func build(index: int, with_pack: bool = false) -> void:
	character_index = index
	rig = Crew.scene(index).instantiate()
	add_child(rig)
	rig.scale = Vector3.ONE * 3.85
	skeleton = rig.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	animation = rig.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	for clip in ["idle","walk","sprint","crouch","fall","sit"]:
		animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	var accent: String = Crew.ACCENTS[index % Crew.ACCENTS.size()]
	var head_bounds := AABB()
	for mesh: MeshInstance3D in rig.find_children("*", "MeshInstance3D", true, false):
		if "head-mesh" in String(mesh.name):
			head_bounds = mesh.get_aabb()
		if "body-mesh" in String(mesh.name):
			for surface in mesh.mesh.get_surface_count():
				var original := mesh.get_active_material(surface) as StandardMaterial3D
				if original:
					var fabric := original.duplicate() as StandardMaterial3D
					fabric.albedo_color = Color("b2c7de")
					mesh.set_surface_override_material(surface, fabric)

	chest = mount("torso")
	var shell := G.box(chest, Vector3(.23,.136,.096), Vector3(0,.076,.072), "dfedf5")
	panels["torso"] = [shell, G.box(chest, Vector3(.164,.087,.018), Vector3(0,.085,.128), accent)]
	var collar := G.ring(chest,.066,.088,Vector3(0,.151,.004),"7f9bb1")
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
		panels["arms"].append(G.box(arm,Vector3(.075,.086,.088),Vector3(direction*.04,0,0),"dcecf5"))
		panels["gloves"].append(G.box(arm,Vector3(.051,.065,.07),Vector3(direction*.213,0,0),accent))
		var leg := mount("leg-" + side)
		panels["legs"].append(G.box(leg,Vector3(.083,.084,.04),Vector3(0,-.073,.073),"c6dceb"))
		panels["boots"].append(G.box(leg,Vector3(.103,.054,.154),Vector3(0,-.146,.035),"e7f0f7"))
	if with_pack:
		preview_pack = Node3D.new()
		chest.add_child(preview_pack)
		preview_pack.position = Vector3(0,.065,-.082)
		panels["pack"] = [G.box(preview_pack,Vector3(.15,.15,.08),Vector3.ZERO,"405a77")]
		for side in [-1.,1.]:
			G.tube(preview_pack,.031,.16,Vector3(side*.088,0,0),accent)

	for group in panels:
		palette[group] = []
		for mesh: MeshInstance3D in panels[group]:
			palette[group].append(mesh.material_override)
	apply_outfit({})
	pose("idle")

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
	badge.position = Vector3(0,.085,.139)
	badge_id = next_badge

func pose(action: String, speed: float = 0.0, gesture: String = "") -> void:
	var clip := "idle"
	var rate := 1.0
	match action:
		"run", "walk":
			clip = "walk" if action == "walk" or (speed > 0 and speed < 8.) else "sprint"
			rate = clampf(speed / (6. if clip == "walk" else 17.),.65,1.6) if speed > 0 else 1.
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
	animation.speed_scale = rate
