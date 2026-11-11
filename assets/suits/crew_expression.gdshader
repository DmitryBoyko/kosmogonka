shader_type spatial;
render_mode cull_back, depth_draw_never, shadows_disabled;

uniform float blink : hint_range(0, 1) = 0.0;
uniform float smile : hint_range(0, 1) = 0.2;
uniform float makeup : hint_range(0, 1) = 0.0;
uniform vec4 iris : source_color = vec4(0.12, 0.55, 0.83, 1.0);
uniform bool third_eye = false;
uniform bool digital = false;

float ellipse(vec2 p, vec2 radius) {
	return 1.0 - smoothstep(0.88, 1.08, length(p / radius));
}

float stroke(vec2 p, vec2 a, vec2 b, float width) {
	vec2 ab = b - a;
	float along = clamp(dot(p - a, ab) / dot(ab, ab), 0.0, 1.0);
	return 1.0 - smoothstep(width * 0.62, width, length(p - a - ab * along));
}

void ink(inout vec4 paint, vec3 shade, float mask) {
	paint.rgb = mix(paint.rgb, shade, mask);
	paint.a = max(paint.a, mask);
}

void draw_eye(inout vec4 paint, vec2 p, float style) {
	vec3 liner = digital ? iris.rgb : vec3(0.065, 0.026, 0.056);
	float open = 1.0 - blink;
	vec2 eye = vec2(p.x, p.y / max(0.18, open));
	if (open > 0.13) {
		ink(paint, liner, ellipse(eye, vec2(0.025, 0.026)));
		ink(paint, vec3(1.0, 0.96, 0.93), ellipse(eye - vec2(0.0, -0.002), vec2(0.0215, 0.0215)));
		vec2 pupil = eye - vec2(-0.002, 0.0);
		ink(paint, iris.rgb, ellipse(pupil, vec2(0.013, 0.019)));
		ink(paint, liner * 0.64, ellipse(pupil, vec2(0.0078, 0.012)));
		ink(paint, vec3(1.0), ellipse(pupil - vec2(-0.004, 0.006), vec2(0.0048, 0.0056)));
		ink(paint, vec3(0.75, 0.93, 1.0), ellipse(pupil - vec2(0.004, -0.006), vec2(0.0026, 0.003)));
	}
	float rim = open * 0.022;
	float arc = stroke(p, vec2(-0.022, 0.0), vec2(0.004, rim + 0.002), 0.0037);
	arc = max(arc, stroke(p, vec2(0.004, rim + 0.002), vec2(0.024, 0.004), 0.0037));
	float flick = stroke(p, vec2(0.017, 0.008 + rim * 0.3), vec2(0.032, 0.021 + rim * 0.3), 0.0038);
	flick = max(flick, stroke(p, vec2(0.011, 0.011 + rim * 0.5), vec2(0.019, 0.025 + rim * 0.5), 0.0028));
	flick = max(flick, stroke(p, vec2(0.023, 0.003), vec2(0.037, 0.010), 0.0026));
	ink(paint, liner, max(arc, flick * style));
}

void fragment() {
	vec2 p = vec2((UV.x - 0.5) * 0.24, 0.10 - UV.y * 0.20);
	vec4 paint = vec4(0.0);
	float cheek = 1.0 - smoothstep(0.25, 1.05, length(vec2(abs(p.x) - 0.078, p.y + 0.022) / vec2(0.032, 0.018)));
	vec3 blush = digital ? iris.rgb : vec3(0.75, 0.22, 0.32);
	paint = vec4(blush, cheek * mix(0.24, 0.46, makeup));
	draw_eye(paint, vec2(abs(p.x) - 0.058, p.y - 0.021), makeup);
	if (third_eye) {
		draw_eye(paint, (p - vec2(0.0, 0.067)) * 1.35, makeup * 0.55);
	}
	float corner = pow(abs(p.x) / 0.045, 2.0) * mix(0.006, 0.015, smile);
	vec2 lip = vec2(p.x, p.y + 0.052 - corner);
	float width = mix(0.028, 0.047, smile);
	float inside = ellipse(lip, vec2(width, mix(0.0037, 0.013, smile)));
	vec3 lipstick = mix(vec3(0.34, 0.085, 0.11), vec3(0.74, 0.095, 0.27), makeup);
	ink(paint, digital ? iris.rgb : lipstick, ellipse(lip, vec2(width + 0.003, mix(0.006, 0.016, smile))));
	ink(paint, vec3(0.17, 0.039, 0.074), inside * 0.88);
	ink(paint, vec3(1.0, 0.92, 0.89), inside * smoothstep(-0.002, 0.003, lip.y) * smoothstep(0.32, 0.70, smile));
	ALBEDO = paint.rgb;
	EMISSION = paint.rgb * (digital ? 0.42 : 0.13);
	ROUGHNESS = 0.88;
	ALPHA = paint.a;
}
