extends Node3D
const G=preload("res://scripts/geometry.gd")
var lamps:Array[MeshInstance3D]=[]
func build() -> void:
	name="LaunchGrid"
	preload("res://scripts/shop_ship_kit.gd").model(self,"Platform_CenterPlate",Vector3(0,.055,5.7),Vector3(7.8,.12,6.4))
	for side in [-1,1]:
		for i in 6: G.box(self,Vector3(.08,.025,.75),Vector3(side*1.14,.07,-i*2.),"9ecdd7",.1)
		G.box(self,Vector3(.42,2.2,.45),Vector3(side*2.35,1.1,-.8),"263d51")
		for i in 3:
			var lamp:=G.box(self,Vector3(.31,.18,.06),Vector3(side*2.35,1.85-i*.43,-.54),"9acbd7",.1)
			lamps.append(lamp)
	for x in 6:
		for z in 2:
			if (x+z)%2==0: G.box(self,Vector3(.48,.025,.48),Vector3((x-2.5)*.48,.08,-1.8-z*.48),"dbe8e6")
	var title:=G.label(self,"S T A R T",Vector3(0,.10,-4.),44)
	title.rotation_degrees.x=-90.; title.billboard=BaseMaterial3D.BILLBOARD_DISABLED; title.pixel_size=.012
func advance(mode:String,distance_value:float,count:float) -> void:
	visible=mode in ["intro","countdown","run"] and distance_value<35.
	position.z=distance_value
	for i in lamps.size():
		var on:bool=mode=="run" or (mode=="countdown" and i%3>=3-int(ceil(count)))
		lamps[i].material_override=G.material("8affbc" if on else "734254",.4 if on else .05)
