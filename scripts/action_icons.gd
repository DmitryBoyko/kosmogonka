extends RefCounted
const FIRST_PERSON = preload("res://assets/ui/icons/camera-first-person.svg")
const THIRD_PERSON = preload("res://assets/ui/icons/camera-third-person.svg")
static func attach_camera(button: Button) -> void:
	var icon:=TextureRect.new();icon.name="ActionIcon";icon.texture=THIRD_PERSON;icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var material:=ShaderMaterial.new()
	material.shader=preload("res://assets/ui/action_icon.gdshader")
	icon.material=material
	button.add_child(icon)
	var arrange:=func():icon.size=Vector2.ONE*minf(42.,button.size.y-12.);icon.position=(button.size-icon.size-Vector2(0,4))*.5
	button.resized.connect(arrange);arrange.call()
static func view(button:Button,first_person:bool) -> void:
	var icon:TextureRect=button.get_node_or_null("ActionIcon")
	if icon:
		icon.texture=FIRST_PERSON if first_person else THIRD_PERSON
		icon.material.set_shader_parameter("bottom_color",Color("bc83ff") if first_person else Color("50b9ff"))
	button.text="";button.tooltip_text="Вид от первого лица" if first_person else "Вид со стороны"
