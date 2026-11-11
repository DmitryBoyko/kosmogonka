extends Control
## A small 3D render target; CanvasLayer UI stays at the window's native resolution.
var app:Node3D
var world:SubViewport
static func enabled() -> bool:
	return OS.has_feature("android") or OS.get_cmdline_user_args().has("--mobile-render")
static func install(game:Node3D) -> Control:
	var rig:Control=load("res://scripts/mobile_render.gd").new()
	rig.app=game; rig.name="MobilePresentation"
	var window:=game.get_tree().root
	window.add_child(rig); rig.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rig.mouse_filter=Control.MOUSE_FILTER_IGNORE
	rig.world=SubViewport.new(); rig.world.name="World540"
	rig.world.own_world_3d=true; rig.world.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	rig.add_child(rig.world)
	var image:=TextureRect.new(); image.texture=rig.world.get_texture()
	image.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; image.stretch_mode=TextureRect.STRETCH_SCALE
	rig.add_child(image); image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	game.reparent(rig.world,false); game.set_process_unhandled_input(false)
	rig.resized.connect(rig.resize_world); rig.resize_world()
	return rig
func resize_world() -> void:
	if not is_instance_valid(world): return
	world.size=Vector2i(540,maxi(960,roundi(540.*size.y/maxf(1.,size.x))))
	if is_instance_valid(app.hud): app.hud._layout()
func _unhandled_input(event:InputEvent) -> void:
	if is_instance_valid(app): app._unhandled_input(event)

func _input(event:InputEvent) -> void:
	if is_instance_valid(app) and (app.forward_crew_drag(event) or app.forward_play_drag(event)):
		get_viewport().set_input_as_handled()
