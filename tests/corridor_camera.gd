extends SceneTree
const Guard=preload("res://scripts/runner_camera_guard.gd")
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for kind in ["tunnel","passage"]:
		for lane in 3:
			for rel in range(-40,41,4):
				var boxes:=Guard.shells([{"kind":kind,"lane":lane,"s":0.,"length":44.}],rel)
				for hx in [-2.6,0.,2.6]:
					for hy in [0.,7.2]:
						for front in [-1.,1.]:
							var hero:=Vector3(hx,hy,0)
							var desired:=Vector3(0,4.8+hy,7.2*front)
							var at:=Guard.resolve(desired,hero,boxes)
							checks+=1
							if not Guard.clear_view(hero+Vector3(0,1.65,0),at,boxes): failures.append(str([kind,lane,rel,hx,hy,front]))
	print("CORRIDOR CAMERA: %d checks, %d failures"%[checks,failures.size()])
	for failure in failures.slice(0,10): push_error(failure)
	quit(0 if failures.is_empty() else 1)
