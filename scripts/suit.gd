extends RefCounted
const G = preload("res://scripts/geometry.gd")
## Appearance API for the future builder. Slot ids are stable save-file identifiers.
const VERSION := 1
const SLOTS := ["torso","left_arm","right_arm","left_glove","right_glove","left_leg","right_leg","left_boot","right_boot","helmet","backpack"]
const CATALOG = preload("res://assets/suits/catalog.tres")
static var skins: Dictionary = {}
static var materials: Dictionary = {}

static func catalog() -> Dictionary:
	if skins.is_empty():
		for skin: Resource in CATALOG.skins: skins[str(skin.id)]=skin
		for tier in range(1,6):
			var skin=preload("res://scripts/suit_skin.gd").new()
			skin.id=StringName("equipment_t%d"%tier); skin.display_name=["Контур","Панцирь","Спектр","Керамика","Сингулярность"][tier-1]
			skin.fabric_color=Color(["cce7e9","dfd0b8","c9bfdc","e2ebed","e8ddc2"][tier-1])
			skin.shell_color=skin.fabric_color.lightened(.15)
			skin.trim_color=Color(preload("res://scripts/gear_visual.gd").COLORS[tier-1])
			skin.fabric_texture=preload("res://assets/suits/textures/aramid_fabric_v1.png")
			skins[str(skin.id)]=skin
	return skins

static func normalize(raw: Dictionary, girl: bool) -> Dictionary:
	var selections: Dictionary = raw.get("slots",{}) if raw.get("slots",{}) is Dictionary and int(raw.get("version",1))==VERSION else {}
	var result := {"version":VERSION,"slots":{}}
	var available := catalog()
	for slot: String in SLOTS:
		var id: String = str(selections.get(slot,"explorer_rose" if girl else "explorer_mint"))
		var valid := available.has(id)
		if valid and not available[id].compatible_slots.is_empty(): valid=available[id].compatible_slots.has(slot)
		result.slots[slot] = id if valid else "explorer_rose" if girl else "explorer_mint"
	return result

static func tag(part: MeshInstance3D, slot: String, channel: String) -> MeshInstance3D:
	part.set_meta("suit_slot",slot)
	part.set_meta("suit_channel",channel)
	return part

static func material_for(id: String, channel: String) -> StandardMaterial3D:
	var key := id+"/"+channel
	if materials.has(key): return materials[key]
	var skin: Resource = catalog()[id]
	var mat := StandardMaterial3D.new()
	mat.roughness=skin.shell_roughness
	match channel:
		"fabric":
			mat.albedo_color=skin.fabric_color
			mat.albedo_texture=skin.fabric_texture
			mat.roughness=skin.fabric_roughness
			mat.uv1_scale=Vector3(2,2,1)
			mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		"shell": mat.albedo_color=skin.shell_color
		"trim": mat.albedo_color=skin.trim_color; mat.roughness=0.44
		"joint": mat.albedo_color=skin.joint_color; mat.roughness=0.92
		"metal": mat.albedo_color=skin.metal_color; mat.metallic=0.65; mat.roughness=0.4
		"badge": mat.albedo_color=skin.badge_color; mat.roughness=0.6
		"light":
			mat.albedo_color=skin.trim_color.lightened(0.4)
			mat.emission_enabled=true
			mat.emission=skin.trim_color
			mat.emission_energy_multiplier=0.3
		_: mat.albedo_color=skin.shell_color
	materials[key]=mat
	return mat

static func apply(root: Node3D, raw: Dictionary, girl: bool) -> Dictionary:
	var loadout := normalize(raw,girl)
	for part: Node in root.find_children("*","MeshInstance3D",true,false):
		if not part.has_meta("suit_slot"): continue
		var slot: String=part.get_meta("suit_slot")
		if not loadout.slots.has(slot): continue
		part.material_override=material_for(loadout.slots[slot],part.get_meta("suit_channel","shell"))
	return loadout

static func socket(hero: Node3D, id: String, parent: Node3D, position: Vector3) -> void:
	var mount := Node3D.new()
	mount.name="SuitSocket_"+id
	parent.add_child(mount)
	mount.position=position
	hero.suit_sockets[id]=mount

static func mounts(hero: Node3D) -> void:
	socket(hero,"torso",hero.body,Vector3(0,1.14,0))
	socket(hero,"helmet",hero.head,Vector3.ZERO)
	socket(hero,"backpack",hero.pack,Vector3(0,1.2,-0.4))
	for i in 2:
		var side := "left" if i==0 else "right"
		socket(hero,side+"_arm",hero.arms[i],Vector3.ZERO)
		socket(hero,side+"_forearm",hero.elbows[i],Vector3.ZERO)
		socket(hero,side+"_glove",hero.hands[i],Vector3(0,0,0.025))
		socket(hero,side+"_leg",hero.legs[i],Vector3(0,-0.19,0))
		socket(hero,side+"_shin",hero.knees[i],Vector3(0,-0.14,0))
		socket(hero,side+"_boot",hero.knees[i],Vector3(0,-0.32,0.1))

static func details(hero: Node3D) -> void:
	# Raised seals, stitch lines and armor edges stay legible at gameplay scale;
	# the fine textile is reserved for close-up views instead of noisy screen pixels.
	for side in [-1.0,1.0]:
		for i in 9:
			tag(G.box(hero.body,Vector3(0.009,0.024,0.012),Vector3(side*0.32,1.04+i*0.04,0.22)),"torso","metal")
		for y in [1.11,1.39]:
			tag(G.ball(hero.body,Vector3.ONE*0.035,Vector3(side*0.22,y,0.36)),"torso","metal")
		var strap := tag(G.box(hero.body,Vector3(0.075,0.45,0.025),Vector3(side*0.32,1.27,0.21)),"torso","joint")
		strap.rotation.z=side*0.12
	for i in 3:
		var seal := tag(G.ring(hero.body,0.35,0.4,Vector3(0,0.82+i*0.055,0)),"torso","joint")
		seal.scale=Vector3(1,0.3,0.76)
	tag(G.box(hero.body,Vector3(0.17,0.11,0.05),Vector3(0,0.86,0.33)),"torso","metal")
	for i in 2:
		var side := "left" if i==0 else "right"
		var elbow: Node3D=hero.elbows[i]
		var knee: Node3D=hero.knees[i]
		for j in 3:
			var seal := tag(G.ring(elbow,0.10,0.135,Vector3(0,0.02-j*0.04,0)),side+"_arm","joint")
			seal.scale.y=0.28
		var cuff := tag(G.ring(elbow,0.105,0.14,Vector3(0,-0.26,0)),side+"_arm","metal")
		cuff.scale.y=0.35
		tag(G.ball(hero.hands[i],Vector3(0.19,0.12,0.07),Vector3(0,0.02,0.145)),side+"_glove","trim")
		for j in 3:
			tag(G.box(hero.hands[i],Vector3(0.012,0.06,0.009),Vector3((j-1)*0.047,0.02,0.184)),side+"_glove","joint")
		tag(G.ball(knee,Vector3(0.25,0.18,0.09),Vector3(0,-0.02,0.15)),side+"_leg","shell")
		tag(G.box(knee,Vector3(0.17,0.08,0.025),Vector3(0,-0.02,0.20)),side+"_leg","trim")
		for j in 4:
			tag(G.box(knee,Vector3(0.33,0.025,0.035),Vector3(0,-0.473,-0.06+j*0.1)),side+"_boot","joint")
		var ankle := tag(G.ring(knee,0.11,0.15,Vector3(0,-0.22,0.02)),side+"_boot","joint")
		ankle.scale.y=0.3
	for i in 4:
		tag(G.box(hero.pack,Vector3(0.42,0.035,0.025),Vector3(0,1.06+i*0.10,-0.58)),"backpack","joint")
	for side in [-1.0,1.0]:
		tag(G.box(hero.pack,Vector3(0.05,0.56,0.04),Vector3(side*0.235,1.2,-0.59)),"backpack","trim")
		tag(G.box(hero.pack,Vector3(0.12,0.09,0.045),Vector3(side*0.235,1.44,-0.62)),"backpack","metal")
