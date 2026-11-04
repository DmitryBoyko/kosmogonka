extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label_value: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(label_value)
func run() -> void:
	var app=load("res://scenes/main.tscn").instantiate()
	app.test_mode=true
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app.set_physics_process(false)
	app.start_level()
	app.begin_run()
	app.distance=21.5
	app.check_contacts()
	app._process(0.06)
	check(app.stars==1,"star collection still updates the score immediately")
	check(app.sparks.is_empty(),"collecting a star never emits body debris")
	check(app.pickup_feedback.badge.text.contains("+1"),"pickup receipt appears above the character")
	check(app.pickup_feedback.aura.visible,"collection activates the soft golden pickup aura")
	var before: int=app.pickup_feedback.get_child_count()
	app.pickup_feedback.notify(3)
	app._process(0.06)
	check(app.pickup_feedback.total==4,"a nearby bonus is grouped with the pickup receipt")
	for i in 100: app.pickup_feedback.notify(1)
	check(app.pickup_feedback.get_child_count()==before,"long star chains reuse one effect instead of spawning particles")
	var energy: float=app.pickup_feedback.energy
	app.pause_game()
	app._process(1)
	check(app.pickup_feedback.energy==energy,"pause freezes the feedback animation")
	check(not app.pickup_feedback.badge.is_visible_in_tree(),"pickup receipt does not cover the pause screen")
	app.state="run"
	app.hud.playing()
	for i in 60: app._process(1.0/60)
	check(not app.pickup_feedback.badge.visible and not app.pickup_feedback.aura.visible,"receipt and contact flashes fade out completely")
	for s in [400,900]:
		for h in [0.0,3.2,6.5]:
			app.distance=s
			app.height=h
			app.runner.position.y=h
			app.pickup_feedback.notify(1)
			app._process(0.06)
			var rect:=Rect2(app.pickup_feedback.badge.global_position,app.pickup_feedback.badge.size)
			check(app.get_viewport().get_visible_rect().encloses(rect) and rect.position.y>=170,"receipt stays in the safe screen area")
	app.pickup_feedback.reset()
	check(app.pickup_feedback.total==0 and app.hud.score_label.scale==Vector2.ONE,"new run clears the visual pickup chain")
	app.free()
	await process_frame
	print("PICKUP FEEDBACK: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
