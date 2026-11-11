shader_type spatial;
render_mode unshaded, cull_back, shadows_disabled;

uniform sampler2D noise_map : filter_linear_mipmap, repeat_enable;
uniform vec3 tint : source_color;
uniform vec3 hot : source_color = vec3(.92,1.,1.);
uniform float energy_time;

void fragment() {
	float a = texture(noise_map,UV*vec2(3.,1.8)+vec2(energy_time*.17,-energy_time*.16)).r;
	float b = texture(noise_map,UV*vec2(5.,3.2)+vec2(-energy_time*.19,energy_time*.22)).r;
	float field = a*.67+b*.33;
	float tendril = pow(1.-abs(sin((field+UV.y*.19)*12.)),5.);
	float rim = pow(1.-clamp(dot(normalize(NORMAL),normalize(VIEW)),0.,1.),3.);
	vec3 plasma = mix(tint*.14,tint,field*.72+rim*.22);
	ALBEDO = mix(plasma,hot,clamp(tendril*.59+rim*.43,0.,1.))*(.92+field*.58);
}
