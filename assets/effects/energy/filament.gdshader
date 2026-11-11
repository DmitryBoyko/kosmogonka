shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform sampler2D noise_map : filter_linear_mipmap, repeat_enable;
uniform vec3 tint : source_color;
uniform float energy_time;
varying float offset;
void vertex() { offset = INSTANCE_CUSTOM.x; }
void fragment() {
	float u = UV.y;
	float n = texture(noise_map,vec2(u*3.2+offset+energy_time*.39,offset*.69-energy_time*.42)).r;
	float trail = sin(u*44.+energy_time*7.+offset*14.)*.05;
	float x = abs(UV.x-.5-(n-.5)*.60-trail);
	float bolt = exp(-x*40.);
	float glow = exp(-x*9.)*.45;
	float reach = smoothstep(0.,.14,u)*(1.-smoothstep(.72,1.,u));
	float travel = .36+.64*pow(.5+.5*sin(u*13.-energy_time*5.+offset*16.),2.);
	ALBEDO = mix(tint,vec3(.92,.98,1.),bolt*.72);
	ALPHA = (bolt+glow)*reach*travel*.84;
}
