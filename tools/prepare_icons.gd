extends SceneTree
func _initialize() -> void:
	var image := Image.new()
	image.load_svg_from_string(FileAccess.get_file_as_string("res://icon.svg"), 2.0)
	image.resize(192, 192, Image.INTERPOLATE_LANCZOS)
	image.save_png("res://assets/launcher.png")
	quit()
