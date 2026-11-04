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
	draw_circle(center+Vector2(0,6),78,Color(.01,.03,.07,.32))
	draw_circle(center,77,Color(.18,.32,.45,.36))
	draw_circle(center,71,Color(.025,.065,.11,.34))
	draw_arc(center,75,PI,TAU,48,Color(.66,.91,1.,.50),2,true)
	draw_arc(center,74,0,PI,48,Color(.13,.28,.42,.45),3,true)
	draw_arc(center,56,0,TAU,48,Color(.42,.78,.87,.18),1.5,true)
	for i in 4:
		var a:=i*PI*.5; draw_line(center+Vector2(cos(a),sin(a))*60,center+Vector2(cos(a),sin(a))*66,Color(.55,.9,1.,.4),2,true)
	var knob:=center+value*48
	draw_circle(knob+Vector2(0,4),31,Color(.01,.04,.07,.40))
	draw_circle(knob,31,Color(.45,.76,.84,.48))
	draw_circle(knob,27,Color(.12,.31,.43,.52))
	draw_arc(knob,28,PI,TAU,32,Color(.76,.96,1.,.65),2,true)
	draw_circle(knob+Vector2(-7,-9),9,Color(.62,.89,1.,.13))
