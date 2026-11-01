shader_type spatial;
render_mode specular_schlick_ggx;
varying vec3 local_position;
uniform vec4 ocean_color : source_color = vec4(0.1,0.55,0.66,1.0);
uniform vec4 land_color : source_color = vec4(0.55,0.3,0.78,1.0);
uniform sampler2D surface_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
void vertex() {
	local_position = VERTEX;
}
float terrain(vec3 p) {
	return sin(p.x*5.0+sin(p.z*6.0))*sin(p.y*6.0+cos(p.x*3.0)) + 0.3*sin(p.z*17.0+p.x*12.0)*sin(p.y*13.0);
}
vec3 surface_at(vec2 uv) {
	return texture(surface_texture,abs(fract(uv*0.5)*2.0-1.0)).rgb;
}
void fragment() {
	vec3 p = normalize(local_position);
	float n = terrain(p);
	vec3 ocean = ocean_color.rgb * mix(0.8,1.25,smoothstep(-0.7,0.1,n));
	vec3 land = land_color.rgb * mix(0.8,1.25,smoothstep(0.15,0.9,n));
	vec3 weights=pow(abs(p),vec3(4.0));
	weights/=max(0.001,weights.x+weights.y+weights.z);
	vec3 detail=surface_at(p.yz*3.0)*weights.x+surface_at(p.xz*3.0)*weights.y+surface_at(p.xy*3.0)*weights.z;
	land=mix(land,detail,0.48);
	ALBEDO = mix(ocean,land,smoothstep(0.02,0.14,n));
	float cloud = smoothstep(0.82,1.15,terrain(p*1.7+vec3(TIME*0.015,0.0,0.0)));
	ALBEDO = mix(ALBEDO,vec3(0.92,0.86,1.0),cloud*0.63);
	ROUGHNESS = 0.82;
}
