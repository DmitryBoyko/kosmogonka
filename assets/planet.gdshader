shader_type spatial;
render_mode specular_schlick_ggx;
varying vec3 local_position;
void vertex() {
	local_position = VERTEX;
}
float terrain(vec3 p) {
	return sin(p.x*5.0+sin(p.z*6.0))*sin(p.y*6.0+cos(p.x*3.0)) + 0.3*sin(p.z*17.0+p.x*12.0)*sin(p.y*13.0);
}
void fragment() {
	vec3 p = normalize(local_position);
	float n = terrain(p);
	vec3 ocean = mix(vec3(0.10,0.55,0.66),vec3(0.25,0.84,0.76),smoothstep(-0.7,0.1,n));
	vec3 land = mix(vec3(0.40,0.27,0.66),vec3(0.78,0.57,0.85),smoothstep(0.15,0.9,n));
	ALBEDO = mix(ocean,land,smoothstep(0.02,0.14,n));
	float cloud = smoothstep(0.82,1.15,terrain(p*1.7+vec3(TIME*0.015,0.0,0.0)));
	ALBEDO = mix(ALBEDO,vec3(0.92,0.86,1.0),cloud*0.63);
	ROUGHNESS = 0.82;
}
