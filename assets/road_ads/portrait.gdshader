shader_type spatial;
render_mode unshaded, shadows_disabled;

uniform sampler2D portrait : source_color, filter_linear, repeat_disable;
uniform sampler2D stars : source_color, filter_linear, repeat_disable;
uniform vec4 accent : source_color = vec4(0.18, 0.82, 1.0, 1.0);
uniform float layout = 0.0;

float band(float x, float radius) {
	return 1.0 - smoothstep(radius * 0.45, radius, abs(x));
}

void fragment() {
	vec2 uv = UV;
	vec2 astro = vec2(uv.x * 0.57 + 0.20 + layout * 0.075, uv.y * 0.44 + 0.26);
	vec3 space = vec3(0.017, 0.030, 0.087) + texture(stars, astro).rgb * vec3(0.52, 0.49, 0.89);
	vec2 p = (uv - vec2(0.23 + 0.51 * layout, 0.47)) * vec2(2.23, 1.0);
	float r = length(p);
	float planet = 1.0 - smoothstep(0.265, 0.277, r);
	vec3 surface = mix(vec3(0.036, 0.053, 0.165), accent.rgb * 0.49, smoothstep(-0.29, 0.24, p.x - p.y * 0.7));
	surface += accent.rgb * (0.05 + 0.075 * sin((p.y + p.x * 0.22) * 105.0));
	space = mix(space, surface, planet * 0.9);
	space += accent.rgb * band(r - 0.273, 0.025) * 0.39;
	vec2 ring = vec2(p.x, (p.y + p.x * 0.24) * 3.4);
	space += accent.rgb * band(length(ring) - 0.38, 0.010) * (1.0 - planet * 0.72);
	vec4 hero = texture(portrait, uv);
	space = mix(space, hero.rgb, hero.a);
	float frame = max(band(abs(uv.x - 0.5) - 0.487, 0.006), band(abs(uv.y - 0.5) - 0.476, 0.012));
	ALBEDO = mix(space, accent.rgb * 0.92, frame * 0.81);
	EMISSION = accent.rgb * frame * 0.27;
}
