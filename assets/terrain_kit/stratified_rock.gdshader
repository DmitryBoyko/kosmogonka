shader_type spatial;
render_mode specular_schlick_ggx;

uniform sampler2D grain_map : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 rock : source_color;
uniform vec3 layer : source_color;
uniform vec3 accent : source_color;
uniform float caps;
uniform float glow;
varying vec3 rock_point;
varying vec3 rock_normal;
varying float rock_height;
varying vec2 material_roles;

void vertex() {
	vec3 scale_value = vec3(length(MODEL_MATRIX[0].xyz),length(MODEL_MATRIX[1].xyz),length(MODEL_MATRIX[2].xyz));
	rock_point = VERTEX * scale_value;
	rock_normal = NORMAL;
	rock_height = VERTEX.y;
	material_roles = COLOR.rg;
}

void fragment() {
	vec3 n = normalize(rock_normal);
	vec3 w = pow(abs(n),vec3(5.));
	w /= max(dot(w,vec3(1.)),.001);
	vec3 uvw = rock_point*.22;
	vec3 mineral = texture(grain_map,uvw.yz).rgb*w.x + texture(grain_map,uvw.xz).rgb*w.y + texture(grain_map,uvw.xy).rgb*w.z;
	float grain = dot(mineral,vec3(.22,.67,.11));
	float strata = sin(rock_point.y*.80 + rock_point.x*.20 + sin(rock_point.z*.37)*.72);
	float sediment = smoothstep(-.58,.64,strata + grain*.38);
	float seams = pow(1. - abs(sin(rock_point.y*.44 + rock_point.x*.27 - rock_point.z*.12 + grain*1.6)),9.);
	float cap = max(material_roles.x*.59,smoothstep(.66,.95,rock_height)*smoothstep(.30,.86,n.y))*caps;
	vec3 color = mix(rock,layer,sediment*.60+material_roles.y*.30);
	color = mix(color,accent,cap+seams*.23*(1.-cap));
	ALBEDO = color * (.61+grain*.53+max(n.y,0.)*.11);
	EMISSION = accent * seams * glow * (.42+grain*.58);
	METALLIC = 0.;
	ROUGHNESS = mix(.92,.68,cap);
	SPECULAR = .22;
}
