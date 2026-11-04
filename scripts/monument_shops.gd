extends RefCounted
const G=preload("res://scripts/geometry.gd")
const Economy=preload("res://scripts/gear_economy.gd")
const POSITIONS=[Vector3(-27,0,10),Vector3(27,0,10),Vector3(0,0,-57)]
static func build() -> Node3D:
	var root:=Node3D.new(); root.name="MonumentShops"
	for i in 3:
		var booth:=Node3D.new(); root.add_child(booth); booth.position=POSITIONS[i]; booth.name=Economy.CATEGORIES[i]
		booth.rotation.y=PI if i==2 else .6 if i==0 else -.6
		var metal:=preload("res://scripts/hover_transport.gd").paint(i,"paint")
		G.box(booth,Vector3(4.8,.35,3.8),Vector3(0,-.05,0)).material_override=metal
		G.box(booth,Vector3(3.7,.9,.65),Vector3(0,.45,1.2)).material_override=metal
		for side in [-1,1]: G.box(booth,Vector3(.22,3.1,.25),Vector3(side*2,1.5,-.9)).material_override=metal
		G.box(booth,Vector3(4.7,.30,3.6),Vector3(0,3.2,0)).material_override=metal
		G.box(booth,Vector3(1.25,1.05,1.1),Vector3(0,1.4,-.2),"25394e")
		var question:=G.label(booth,"?",Vector3(0,1.55,.39),72); question.modulate=Color("ffe3a0")
		G.label(booth,Economy.TITLES[Economy.CATEGORIES[i]].to_upper(),Vector3(0,2.80,1.43),29)
		G.label(booth,"от %d ★"%Economy.PRICES[Economy.CATEGORIES[i]][0],Vector3(0,.60,1.56),24)
	return root
static func nearest(at:Vector3) -> String:
	for i in 3:
		if Vector2(at.x-POSITIONS[i].x,at.z-POSITIONS[i].z).length()<4.2: return Economy.CATEGORIES[i]
	return ""
