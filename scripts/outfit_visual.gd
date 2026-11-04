extends RefCounted
const G=preload("res://scripts/geometry.gd")
const SM=preload("res://scripts/salvage_mesh.gd")
const Catalog=preload("res://scripts/outfit_catalog.gd")
static var paints:Dictionary={}
static var fabrics:Dictionary={}
static func paint(item:Dictionary) -> Material:
	if paints.has(item.id): return paints[item.id]
	var material:ShaderMaterial=preload("res://scripts/salvage_materials.gd").material("hull-titanium").duplicate()
	material.set_shader_parameter("tint",Color(item.color)); material.set_shader_parameter("metalness",.55); material.set_shader_parameter("roughness",.38)
	paints[item.id]=material; return material
static func apply(hero:Node3D,outfit:Dictionary,base:Dictionary) -> void:
	for pattern in ["GearUpgrade*","OutfitPart_*"]:
		for node:Node in hero.find_children(pattern,"Node3D",true,false):
			if is_instance_valid(node): node.free()
	hero.apply_suit(base)
	var default_star:Node3D=hero.body.get_node_or_null("DefaultChestStar")
	if default_star: default_star.visible=not outfit.has("badge") and not outfit.has("torso")
	for group:String in outfit:
		var item:=Catalog.get_item(str(outfit[group]))
		if item.is_empty(): continue
		var color:String=item.color; var tier:int=item.tier; var material:=paint(item)
		for slot:String in Catalog.SLOTS.get(group,[]):
			for piece:MeshInstance3D in hero.suit_parts(slot):
				var original:=piece.material_override as StandardMaterial3D
				if original==null: continue
				var key:String=str(item.id)+"/"+str(original.get_instance_id())
				if not fabrics.has(key):
					var tinted:=original.duplicate() as StandardMaterial3D
					tinted.albedo_color=original.albedo_color.lerp(Color(color),.60 if piece.get_meta("suit_channel","")=="shell" else .28)
					fabrics[key]=tinted
				piece.material_override=fabrics[key]
		var sockets:Array=[]
		if group=="badge":
			var badge:=preload("res://scripts/chest_badge.gd").build(int(item.shape),str(item.color))
			badge.name="OutfitPart_badge"; hero.body.add_child(badge); badge.position=Vector3(0,1.26,.372 if outfit.has("torso") else .357)
			continue
		match group:
			"helmet": sockets=["helmet"]
			"torso": sockets=["torso"]
			"arms": sockets=["left_arm","right_arm"]
			"gloves": sockets=["left_glove","right_glove"]
			"legs": sockets=["left_shin","right_shin"]
			"boots": sockets=["left_boot","right_boot"]
			"pack": sockets=["backpack"]
			"board": sockets=["board"]
		for socket:String in sockets:
			var root:=Node3D.new(); root.name="OutfitPart_"+group+"_"+socket
			if socket=="board": hero.board.add_child(root)
			else: hero.suit_sockets[socket].add_child(root)
			match group:
				"torso":
					SM.block(root,Vector3(.62,.44,.09),Vector3(0,.03,.32),material,.07)
					if not outfit.has("badge"):
						var star:=preload("res://scripts/chest_badge.gd").build(1); root.add_child(star); star.position=Vector3(0,.12,.38)
					for i in tier: G.box(root,Vector3(.045,.045,.025),Vector3((i-(tier-1)*.5)*.075,-.10,.38),color,.4)
				"helmet":
					for side in [-1,1]:
						SM.block(root,Vector3(.09,.30,.20),Vector3(side*.38,.04,0),material,.035)
						for i in tier: G.box(root,Vector3(.06,.035,.06),Vector3(side*.43,-.08+i*.045,.07),color,.35)
				"arms": SM.block(root,Vector3(.33,.27,.34),Vector3(0,-.08,.04),material,.07)
				"gloves":
					SM.block(root,Vector3(.23,.20,.20),Vector3(0,-.035,.03),material,.04)
					G.box(root,Vector3(.12,.035,.025),Vector3(0,.05,.145),color,.5)
				"legs": SM.block(root,Vector3(.27,.32,.15),Vector3(0,.015,.13),material,.05)
				"boots":
					SM.block(root,Vector3(.28,.10,.43),Vector3(0,-.03,0),material,.035)
					G.box(root,Vector3(.21,.035,.04),Vector3(0,.025,.21),color,.5)
				"pack":
					SM.block(root,Vector3(.52,.68,.16),Vector3(0,0,-.08),material,.07)
					for side in [-1,1]:
						G.tube(root,.11,.6+tier*.04,Vector3(side*.34,0,-.10),color)
						for i in tier: G.box(root,Vector3(.20,.035,.035),Vector3(side*.30,-.24+i*.11,-.23),color,.5)
				"board":
					for side in [-1,1]:
						SM.block(root,Vector3(.18,.14,1.35),Vector3(side*(.62+item.shape*.05),.025,0),material,.06)
						for i in tier: G.box(root,Vector3(.09,.025,.16),Vector3(side*.53,.11,-.65+i*.28),color,.5)
			G.merge_static(root)
