shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never, shadows_disabled;

void fragment() {
	float edge = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 3.0);
	ALBEDO = vec3(0.61, 0.87, 0.97);
	ALPHA = 0.008 + edge * 0.21;
}
