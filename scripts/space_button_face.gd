extends ColorRect
var button:BaseButton
var press_animation:=0.
static var blank:Texture2D
static func attach(target:BaseButton,primary:bool=false,is_toggle:bool=false) -> void:
	var face:ColorRect=load("res://scripts/space_button_face.gd").new()
	face.button=target; face.mouse_filter=Control.MOUSE_FILTER_IGNORE; face.show_behind_parent=true
	var shader:=ShaderMaterial.new(); shader.shader=preload("res://assets/spaceflight/space_button.gdshader")
	shader.set_shader_parameter("painted_plate",preload("res://assets/ui/cyberpunk-button.png"))
	shader.set_shader_parameter("primary",primary); shader.set_shader_parameter("toggle",is_toggle)
	shader.set_shader_parameter("pause_icon",target.get_meta("command","")=="pause")
	var command:String=target.get_meta("command","")
	shader.set_shader_parameter("show_led",not command.begins_with("planet_"))
	shader.set_shader_parameter("icon_kind",1 if command=="leave_finish" else 2 if command in ["walk_jump","run_jump"] else 0)
	shader.set_shader_parameter("opacity",.55 if command in ["leave_finish","walk_jump","run_jump","use_charge_jet","use_charge_board"] else 1.)
	face.material=shader; target.add_child(face); face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for state in ["normal","hover","pressed","disabled","focus"]:
		var style:=StyleBoxEmpty.new()
		style.content_margin_left=8 if target.size.x<130 else 20; style.content_margin_right=64 if is_toggle else 8 if target.size.x<130 else 20
		style.content_margin_top=11 if state=="pressed" else 8; style.content_margin_bottom=5 if state=="pressed" else 8
		target.add_theme_stylebox_override(state,style)
	if is_toggle:
		if blank==null:
			var image:=Image.create(1,1,false,Image.FORMAT_RGBA8); image.fill(Color.TRANSPARENT); blank=ImageTexture.create_from_image(image)
		for key in ["checked","unchecked","checked_disabled","unchecked_disabled"]: target.add_theme_icon_override(key,blank)

func _process(dt:float) -> void:
	if not is_visible_in_tree() or not is_instance_valid(button): return
	material.set_shader_parameter("dimensions",size)
	press_animation=move_toward(press_animation,1. if button.is_pressed() else 0.,dt*(19. if button.is_pressed() else 11.))
	material.set_shader_parameter("pressed",press_animation)
	material.set_shader_parameter("hovered",1. if button.is_hovered() else 0.)
	material.set_shader_parameter("focused",1. if button.has_focus() else 0.)
	material.set_shader_parameter("disabled",1. if button.disabled else 0.)
	material.set_shader_parameter("checked",button.button_pressed)
