extends RefCounted

static func enabled() -> bool:
	return OS.has_feature("android") or OS.get_cmdline_user_args().has("--mobile-render")

static func configure(view: Viewport, high_quality: bool) -> void:
	# Use the window's 3D pass and keep the HUD at the output resolution.
	var native_width := maxi(1, DisplayServer.window_get_size().x)
	var target_width := 648. if high_quality else 540.
	view.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	view.scaling_3d_scale = minf(1., target_width / native_width)
	view.msaa_3d = Viewport.MSAA_DISABLED
	view.audio_listener_enable_3d = true
