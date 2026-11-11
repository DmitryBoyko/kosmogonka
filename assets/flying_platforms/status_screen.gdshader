shader_type spatial;
render_mode unshaded, shadows_disabled, fog_disabled;

uniform vec4 accent : source_color = vec4(0.12, 0.94, 0.91, 1.0);
uniform int mode = 0;
uniform float motion = 1.0;

float line_mark(float x, float thickness) {
	return 1.0 - smoothstep(thickness * 0.5, thickness, abs(x));
}

void fragment() {
	vec2 uv = UV;
	vec2 p = uv - 0.5;
	float t = TIME * motion;
	float content = 0.0;
	float grid = max(line_mark(fract(uv.x * 15.0) - 0.5, 0.035), line_mark(fract(uv.y * 8.0) - 0.5, 0.045));
	float scan = 0.22 * line_mark(fract(uv.y + t * 0.16) - 0.5, 0.11);

	if (mode == 0 || mode == 4) {
		vec2 r = vec2(p.x * 2.0, p.y) - vec2(-0.32, 0.0);
		float d = length(r);
		content = max(line_mark(d - 0.31, 0.013), line_mark(d - 0.18, 0.013));
		content = max(content, line_mark(length(r - vec2(sin(t * 0.5), cos(t * 0.5)) * 0.23), 0.05));
		content = max(content, step(0.58, uv.x) * (1.0 - step(0.89, uv.x)) * line_mark(fract(uv.y * 5.0) - 0.5, 0.115));
	} else if (mode == 1 || mode == 3) {
		float bar = floor(uv.x * 15.0);
		float signal = 0.19 + 0.30 * (0.5 + 0.5 * sin(bar * 1.43 + t * (0.7 + float(mode) * 0.17)));
		content = step(0.21, uv.y) * (1.0 - step(0.21 + signal, uv.y)) * step(0.22, fract(uv.x * 15.0));
		content += line_mark(uv.y - 0.79, 0.018) * step(0.09, uv.x) * (1.0 - step(0.91, uv.x));
	} else {
		float path = abs(p.y - sin(uv.x * 16.0 + t) * 0.15) + abs(p.y - 0.22) * 0.18;
		content = max(0.5 * line_mark(path - 0.085, 0.03), line_mark(path - 0.14, 0.028));
		content *= step(0.08, uv.x) * (1.0 - step(0.92, uv.x));
	}
	float frame = max(line_mark(abs(p.x) - 0.474, 0.012), line_mark(abs(p.y) - 0.446, 0.023));
	ALBEDO = vec3(0.013, 0.025, 0.044) + accent.rgb * (0.13 * grid + 0.46 * scan + 0.62 * content + 0.44 * frame);
	EMISSION = accent.rgb * (content * 0.32 + frame * 0.28);
}
