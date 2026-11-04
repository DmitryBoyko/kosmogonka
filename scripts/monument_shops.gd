extends RefCounted
const G=preload("res://scripts/geometry.gd")
const Economy=preload("res://scripts/gear_economy.gd")
const POSITIONS=[Vector3(-27,0,10),Vector3(27,0,10),Vector3(0,0,-57)]
static func build() -> Node3D:
	var root:=Node3D.new(); root.name="MonumentShops"
	for i in 3:
		var booth:=preload("res://scripts/shop_ship_kit.gd").terminal(Economy.CATEGORIES[i],i); root.add_child(booth); booth.position=POSITIONS[i]; booth.name=Economy.CATEGORIES[i]
		booth.rotation.y=PI if i==2 else .6 if i==0 else -.6
	return root
static func nearest(at:Vector3) -> String:
	for i in 3:
		if Vector2(at.x-POSITIONS[i].x,at.z-POSITIONS[i].z).length()<4.2: return Economy.CATEGORIES[i]
	return ""
