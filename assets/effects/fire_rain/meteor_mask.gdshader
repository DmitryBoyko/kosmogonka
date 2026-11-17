shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform sampler2D effect_mask : filter_linear_mipmap, repeat_disable;
uniform vec4 tint : source_color = vec4(1.0, 0.32, 0.1, 1.0);
uniform float opacity = 0.0;
uniform bool tail = false;

void fragment() {
	float mask = texture(effect_mask, UV).r;
	if (tail) {
		float width = mix(0.06, 0.40, UV.y);
		mask *= (1.0 - smoothstep(width * 0.28, width, abs(UV.x - 0.5)));
		mask *= smoothstep(0.01, 0.88, UV.y) * (1.0 - smoothstep(0.91, 1.0, UV.y));
	}
	ALBEDO = mix(tint.rgb, vec3(1.0, 0.96, 0.9), mask * 0.38) * 1.7;
	ALPHA = mask * opacity;
}
