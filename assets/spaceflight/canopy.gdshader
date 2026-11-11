shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, shadows_disabled;

uniform vec3 tint : source_color = vec3(.62,.85,.92);

void fragment() {
	float fresnel = 1. - clamp(dot(normalize(NORMAL),normalize(VIEW)),0.,1.);
	float rim = pow(fresnel,4.);
	ALBEDO = tint;
	ROUGHNESS = .12;
	METALLIC = .02;
	SPECULAR = .34;
	EMISSION = tint*rim*.085;
	ALPHA = .032 + rim*.33;
}
