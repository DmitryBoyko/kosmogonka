extends ScrollContainer

const DEAD_ZONE := 11.
var finger := -1
var origin := Vector2.ZERO
var starting_scroll := 0.
var scrolling := false
var pressed_button: Button

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventMouse and event.device==InputEvent.DEVICE_ID_EMULATION:
		if finger>=0 or contains(event.position):
			get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		if event.pressed and finger==-1 and contains(event.position):
			finger=event.index
			origin=to_local_point(event.position)
			starting_scroll=float(scroll_vertical)
			scrolling=false
			pressed_button=button_at(event.position)
		elif not event.pressed and event.index==finger:
			var at := to_local_point(event.position)
			var tapped := pressed_button
			var click: bool = not scrolling and not event.canceled and at.distance_to(origin)<DEAD_ZONE and contains(event.position)
			finger=-1
			pressed_button=null
			get_viewport().set_input_as_handled()
			if click and is_instance_valid(tapped) and not tapped.disabled and button_at(event.position)==tapped:
				tapped.pressed.emit()
			return
		else:
			return
	elif event is InputEventScreenDrag and event.index==finger:
		var delta := to_local_point(event.position)-origin
		if absf(delta.y)>=DEAD_ZONE:
			scrolling=true
		if scrolling:
			scroll_vertical=roundi(starting_scroll-delta.y)
	else:
		return
	get_viewport().set_input_as_handled()

func contains(point: Vector2) -> bool:
	return Rect2(Vector2.ZERO,size).has_point(to_local_point(point))

func to_local_point(point: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse()*point

func button_at(point: Vector2) -> Button:
	for button: Button in find_children("*","Button",true,false):
		var local := button.get_global_transform_with_canvas().affine_inverse()*point
		if Rect2(Vector2.ZERO,button.size).has_point(local):
			return button
	return null
