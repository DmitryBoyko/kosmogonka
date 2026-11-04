extends SceneTree
const Star=preload("res://scripts/collectible_star.gd")
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok: failures.append(message); push_error(message)
func run() -> void:
	var app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
	await process_frame; app.set_process(false); app.set_physics_process(false)
	app.camera.position=Vector3(0,5,12); app.camera.look_at(Vector3(0,1,0))
	var normal:=Star.build(app.track_root,1); var double:=Star.build(app.track_root,2)
	check(double.get_meta("radius")>normal.get_meta("radius")*1.5,"double star has a clearly larger silhouette")
	Star.animate(normal,0,0,false); var before:Vector3=normal.get_node("Spin").rotation
	Star.animate(normal,.2,0,false); check(normal.get_node("Spin").rotation.distance_to(before)>.2,"star visibly rotates")
	check(Star.mesh.get_aabb().size.z>.6,"beveled collectible is volumetric even edge-on")
	app.sound.star_pickup(1); check(app.sound.last_pickup_key=="pickup_gold","regular sound")
	app.sound.star_pickup(2); check(app.sound.last_pickup_key=="pickup_double","double sound")
	app.sound.star_pickup(2,true); check(app.sound.last_pickup_key=="pickup_mega","mega sound")
	for key in ["pickup_gold","pickup_double","pickup_mega"]:
		var clip:AudioStream=app.sound.get_clip(key); check(clip!=null and clip.get_length()>.1 and clip.get_length()<.5,"short imported bell: "+key)
	app.pickup_feedback.notify(2,Vector3(0,1,0)); app.pickup_feedback.advance(.03,Vector3.ZERO,app.camera,true)
	check(app.pickup_feedback.badge.text.contains("×2"),"double receipt is explicit")
	check(app.pickup_feedback.bursts[0].visible,"pickup contact flash starts immediately")
	var count:int=app.pickup_feedback.get_child_count()
	for i in 1000: app.pickup_feedback.notify(2)
	check(app.pickup_feedback.get_child_count()==count and app.pickup_feedback.bursts.size()==8,"dense chains reuse eight effects")
	app.pickup_feedback.reduced_motion=true; app.pickup_feedback.advance(.03,Vector3.ZERO,app.camera,true)
	check(app.pickup_feedback.aura.material_override.get_shader_parameter("reduced"),"reduced motion softens the aura")
	var file:=FileAccess.open("res://build/arcade-pickups-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures},"  ")); file.close()
	print("ARCADE PICKUPS: %d checks, %d failures"%[checks,failures.size()])
	app.free(); await create_timer(.1).timeout; quit(0 if failures.is_empty() else 1)
