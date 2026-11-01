extends SceneTree
var app: Node
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label_value: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label_value)

func press(prefix: String) -> void:
	for b: Node in app.hud.screen.get_children():
		if b is Button and b.text.begins_with(prefix):
			b.pressed.emit()
			return
	check(false, "button not found: " + prefix)

func run() -> void:
	app = load("res://scenes/main.tscn").instantiate()
	app.test_mode = true
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app.set_physics_process(false)
	press("Играть")
	await process_frame
	check(app.state == "select", "real button signal enters selection")
	check(not app.hud.screen.get_children().any(func(n): return n is Button and n.text.begins_with("Играть")), "old menu button removed")
	press("На планету")
	await process_frame
	check(app.state == "intro", "start button begins arrival")
	press("Пропустить")
	await process_frame
	check(app.state == "run", "skip button starts run")
	app.hud.action.emit("pause")
	check(app.state == "paused", "pause action freezes run")
	press("Настройки")
	await process_frame
	check(app.hud.current == "settings", "settings button opens settings")
	press("Готово")
	await process_frame
	check(app.hud.current == "pause", "done returns to pause")
	press("Продолжить")
	await process_frame
	check(app.state == "countdown", "resume button enters countdown")
	app._process(3.1)
	check(app.state == "run", "countdown finishes")
	# Native touch gesture takes the same input path as Android.
	app.distance = 350
	app.lane = 1
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.pressed = true
	down.position = Vector2(270, 700)
	app._unhandled_input(down)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(360, 700)
	app._unhandled_input(drag)
	check(app.lane == 2, "native touch drag changes lane")
	app.pause_game()
	press("В меню")
	await process_frame
	check(app.state == "menu", "menu button returns without stale overlays")
	print("INTERACTION: %d checks, %d failures" % [checks, failures])
	app.free()
	await create_timer(0.12).timeout
	quit(0 if failures == 0 else 1)
