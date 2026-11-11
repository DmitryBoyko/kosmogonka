shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform float power = 0.;

void fragment() {
	vec2 p = UV * 2. - 1.;
	float radius = length(p);
	float glow = exp(-5.8 * radius) * (1. - smoothstep(.60,1.,radius));
	float horizontal = exp(-abs(p.y)*22.) * (1. - smoothstep(.14,.88,abs(p.x)));
	ALBEDO = vec3(.55,.83,1.) * 1.5;
	ALPHA = clamp((glow + horizontal*.45)*power,0.,1.);
}
