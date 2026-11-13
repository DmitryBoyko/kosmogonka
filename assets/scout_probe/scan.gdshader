shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never, shadows_disabled;

uniform float scan_phase = 0.0;
uniform float strength = 1.0;
uniform vec4 tint : source_color = vec4(0.20, 0.84, 1.0, 1.0);

void fragment() {
	float band = 1.0 - smoothstep(0.0, 0.13, abs(UV.y - scan_phase));
	float fade = smoothstep(0.0, 0.16, UV.y) * (1.0 - smoothstep(0.82, 1.0, UV.y));
	ALBEDO = tint.rgb;
	ALPHA = (0.10 + band * 0.32) * fade * strength;
}
