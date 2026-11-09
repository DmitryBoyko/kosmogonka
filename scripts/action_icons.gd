extends RefCounted
const MAP={"select":"play","start":"rocket","restart":"rotate-ccw","resume":"play","menu":"house","settings":"settings-2","close_settings":"check","planets":"orbit","builder":"shirt","shop_nearest":"shopping-bag","close_gear":"x","wear_item":"shirt","remove_item":"x","fit_reset":"rotate-ccw","shop_details":"layers","camera_view":"eye"}
static var textures:Dictionary={}
static func texture(name_value:String) -> Texture2D:
	if not textures.has(name_value):textures[name_value]=load("res://assets/ui/icons/"+name_value+".svg")
	return textures[name_value]
static func apply(button:Button,command:String,label_value:String) -> void:
	if not MAP.has(command):return
	button.tooltip_text=label_value.replace("→","").strip_edges();button.text=""
	var icon:=TextureRect.new();icon.name="ActionIcon";icon.texture=texture(MAP[command]);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
	button.add_child(icon)
	var arrange:=func():icon.size=Vector2.ONE*minf(38.,button.size.y-18.);icon.position=(button.size-icon.size)*.5
	button.resized.connect(arrange);arrange.call()
static func view(button:Button,first_person:bool) -> void:
	var icon:TextureRect=button.get_node_or_null("ActionIcon")
	if icon:icon.texture=texture("eye" if first_person else "person-standing")
	button.text="";button.tooltip_text="Вид от первого лица" if first_person else "Вид со стороны"
