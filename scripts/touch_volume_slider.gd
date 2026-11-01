extends HSlider
## Native HSlider handles the mouse; explicitly handle Android's real touch events.
var finger := -1

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		finger = -1
		return
	if event is InputEventScreenTouch:
		var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		if event.pressed and Rect2(Vector2.ZERO, size).grow(10).has_point(local):
			finger = event.index
			set_from_touch(local.x)
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == finger:
			finger = -1
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == finger:
		var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		set_from_touch(local.x)
		get_viewport().set_input_as_handled()

func set_from_touch(x: float) -> void:
	var padding := 22.0
	value = min_value + clampf((x - padding) / (size.x - padding * 2), 0, 1) * (max_value - min_value)
