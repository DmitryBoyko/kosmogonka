extends Node3D
const G=preload("res://scripts/geometry.gd")
var elapsed:=0.
var streaks: Array[MeshInstance3D]=[]
func build(height: float,phase: float=0.) -> void:
	name="JointSparks";set_meta("motion",true);elapsed=phase
	scale=Vector3.ONE*height/3.05
	for i in 6:
		var streak:=G.box(self,Vector3(.018,.018,.10),Vector3.ZERO,"ffd27a" if i%2==0 else "91f7ff",1.5)
		streak.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;streak.hide();streaks.append(streak)
func advance(dt: float,moving: bool,reduced: bool) -> void:
	elapsed+=dt
	var cycle:=floori(elapsed/3.1)
	var phase:=fposmod(elapsed,3.1)
	for i in streaks.size():
		var spark:=streaks[i]
		var age:=phase-float(i)*.035
		spark.visible=moving and not reduced and age>=0. and age<.22
		if not spark.visible:continue
		var side: float=-1. if cycle%2==0 else 1.
		var direction:=Vector3(side*(.5+i*.12),.15+sin(i*2.4)*.5,cos(i*1.7)*.55)
		spark.position=Vector3(side*.44,1.25 if cycle%3==0 else 2.05,.04)+direction*age+Vector3.DOWN*age*age*2.
		spark.quaternion=Quaternion(Vector3.BACK,direction.normalized())
		spark.scale.z=1.-age/.26
