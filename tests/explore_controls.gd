extends SceneTree
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures.append(message); push_error(message)
func touch(stick: Control, id: int, pressed: bool, at: Vector2) -> void:
	var e:=InputEventScreenTouch.new(); e.index=id; e.pressed=pressed; e.position=at; stick._input(e)
func run() -> void:
	root.size=Vector2i(540,1200)
	var ui=load("res://scripts/ui.gd").new(); root.add_child(ui); ui.exploring("Аврора")
	await process_frame; await process_frame
	var stick: Control=ui.walk_stick
	var center: Vector2=stick.get_global_transform_with_canvas()*Vector2(80,80)
	check(center.y>1050,"stick follows bottom on tall phones")
	touch(stick,11,true,center+Vector2(45,0))
	check(stick.value.x>.7 and stick.pointer==11,"first finger owns stick")
	touch(stick,12,true,center-Vector2(45,0))
	check(stick.value.x>.7 and stick.pointer==11,"second finger cannot steal movement")
	var drag:=InputEventScreenDrag.new(); drag.index=11; drag.position=center+Vector2(300,-300); stick._input(drag)
	check(absf(stick.value.length()-1)<.001,"diagonal speed clamped")
	touch(stick,12,false,center)
	check(stick.pointer==11,"unrelated release does not stop movement")
	touch(stick,11,false,center+Vector2(300,-300))
	check(stick.value==Vector2.ZERO and stick.pointer==-2,"release outside stick stops movement")
	touch(stick,11,true,center+Vector2(300,0))
	check(stick.pointer==-2,"camera touch outside stick stays available")
	touch(stick,11,true,center+Vector2(1,1))
	check(stick.value==Vector2.ZERO,"dead zone avoids drift")
	stick.reset(); check(stick.pointer==-2 and stick.value==Vector2.ZERO,"pause reset clears ownership")
	var walk=preload("res://scripts/finish_walk.gd").new(); root.add_child(walk)
	var e:=InputEventScreenTouch.new(); e.index=12; e.position=Vector2(400,500); e.pressed=true; walk.pointer_event(e)
	var camera_drag:=InputEventScreenDrag.new(); camera_drag.index=12; camera_drag.position=Vector2(500,600); walk.pointer_event(camera_drag)
	check(walk.yaw<-.7 and walk.pitch>.6,"independent touch rotates camera")
	walk.orbit_drag(Vector2(0,10000)); check(walk.pitch<=.95,"camera pitch stays usable")
	walk.stop(); check(walk.pointer==-2,"pause releases camera finger")
	var out:=FileAccess.open("res://build/explore-controls-report.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"checks":checks,"failures":failures},"  ")); out.close()
	print("EXPLORE CONTROLS: %d checks, %d failures"%[checks,failures.size()])
	walk.free(); ui.free(); await create_timer(.1).timeout; quit(0 if failures.is_empty() else 1)
