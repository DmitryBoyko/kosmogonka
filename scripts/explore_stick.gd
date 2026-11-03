extends Control
signal moved(value: Vector2)
var pointer: int=-2
var value:=Vector2.ZERO
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	queue_redraw()
func reset() -> void:
	pointer=-2; value=Vector2.ZERO; moved.emit(value); queue_redraw()
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	var pos:=Vector2.ZERO; var pressed:=false; var released:=false; var id: int=-3
	if event is InputEventScreenTouch:
		pos=event.position; id=event.index; pressed=event.pressed; released=not pressed
	elif event is InputEventScreenDrag:
		pos=event.position; id=event.index
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.device==InputEvent.DEVICE_ID_EMULATION: return
		pos=event.position; id=-1; pressed=event.pressed; released=not pressed
	elif event is InputEventMouseMotion and pointer==-1: pos=event.position; id=-1
	else: return
	var delta:=get_global_transform_with_canvas().affine_inverse()*pos-size*.5
	if pressed and pointer==-2 and delta.length()<size.x*.5: pointer=id
	if pointer!=id: return
	if released: reset()
	else:
		value=delta.limit_length(62)/62
		if value.length()<.12: value=Vector2.ZERO
		moved.emit(value); queue_redraw()
	get_viewport().set_input_as_handled()
func _draw() -> void:
	var center:=size*.5
	draw_circle(center,78,Color(.025,.08,.15,.68))
	draw_arc(center,76,0,TAU,64,Color(.52,.95,.86,.8),3,true)
	draw_circle(center+value*48,27,Color(.45,.91,.85,.83))
	draw_arc(center+value*48,27,0,TAU,40,Color(.85,1,1),2,true)
