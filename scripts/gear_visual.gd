extends RefCounted
const G=preload("res://scripts/geometry.gd")
const COLORS=["75c5d6","e7b777","b69beb","cce9ef","ffe3a0"]
static func apply(hero:Node3D,levels:Dictionary) -> void:
	for node in hero.find_children("GearUpgrade*","Node3D",true,false):
		if is_instance_valid(node): node.free()
	for category in ["suit","pack","board"]:
		var tier:int=clampi(int(levels.get(category,0)),0,5)
		if tier==0: continue
		var root:=Node3D.new(); root.name="GearUpgrade_"+category
		var color:String=COLORS[tier-1]
		if category=="board":
			hero.board.add_child(root)
			for side in [-1,1]:
				G.box(root,Vector3(.07,.13,1.45),Vector3(side*.65,.02,0),color,.14)
				for i in tier: G.box(root,Vector3(.12,.035,.16),Vector3(side*.5,.08,-.72+i*.30),color,.25)
		elif category=="pack":
			hero.suit_sockets.backpack.add_child(root)
			for side in [-1,1]:
				G.tube(root,.09,.55+float(tier)*.05,Vector3(side*.34,0,-.08),color)
				for i in tier: G.box(root,Vector3(.18,.025,.04),Vector3(side*.34,-.22+i*.10,-.20),color,.25)
		else:
			hero.suit_sockets.torso.add_child(root)
			for side in [-1,1]:
				G.box(root,Vector3(.13,.56,.07),Vector3(side*.31,.02,.31),color)
				for i in tier: G.box(root,Vector3(.20,.025,.035),Vector3(side*.18,-.12+i*.075,.36),color,.12)
			var crown:=Node3D.new(); hero.suit_sockets.helmet.add_child(crown); crown.name="GearUpgrade_Helmet"
			for side in [-1,1]:
				G.box(crown,Vector3(.055,.15+tier*.035,.10),Vector3(side*.40,.23,-.07),color,.08)
			if tier>=3:
				for slot in ["left_arm","right_arm","left_shin","right_shin"]:
					var pad:=Node3D.new(); pad.name="GearUpgrade_"+slot; hero.suit_sockets[slot].add_child(pad)
					G.ball(pad,Vector3(.28,.20,.18),Vector3(0,0,.09),color)
