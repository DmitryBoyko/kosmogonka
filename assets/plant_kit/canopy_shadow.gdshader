shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, shadows_disabled;

void fragment() {
	vec2 p = UV * 2. - 1.;
	float edge = dot(p,p);
	ALBEDO = vec3(.023,.031,.044);
	ALPHA = .29 * (1. - smoothstep(.04,.92,edge));
}
