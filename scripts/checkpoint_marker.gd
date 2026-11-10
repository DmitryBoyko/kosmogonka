extends Node3D
const G=preload("res://scripts/geometry.gd")
func _ready() -> void:
	for lane in 3:
		for j in 3:G.box(self,Vector3(1.5,.018,.12),Vector3((lane-1)*2.6,.085,-j*.35),"75ffe0",.25)
	for side in [-1.,1.]:
		G.box(self,Vector3(.25,1.3,.35),Vector3(side*4.6,.65,0),"344b65")
		G.ball(self,Vector3.ONE*.28,Vector3(side*4.6,1.5,0),"91ffdc",.5)
	var label:=G.label(self,"КОНТРОЛЬНАЯ ТОЧКА · ½",Vector3(0,3.8,0),20);label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	G.merge_static(self)
