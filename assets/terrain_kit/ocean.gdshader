shader_type spatial;
render_mode specular_schlick_ggx;

uniform sampler2D waves : filter_linear_mipmap, repeat_enable;
uniform int planet_index = 4;
uniform float track_distance;
uniform float track_lateral;
uniform vec2 track_rotation = vec2(1.,0.);
uniform float wave_time;
uniform float wave_detail = 1.;

varying vec2 sea_point;

void vertex() {
	vec3 at = (MODEL_MATRIX * vec4(VERTEX,1.)).xyz;
	sea_point = vec2(dot(at.xz,vec2(track_rotation.x,-track_rotation.y))+track_lateral,
		dot(at.xz,track_rotation.yx)-track_distance);
}

void fragment() {
	vec2 uv = sea_point*.047;
	float swell = texture(waves,uv+vec2(.024,-.013)*wave_time).r;
	float ripple = texture(waves,uv*1.53+vec2(-.021,.029)*wave_time).r;
	float combined = swell*.65+ripple*.35;
	float fresnel = pow(1.-clamp(dot(normalize(NORMAL),normalize(VIEW)),0.,1.),3.8);
	float crest = smoothstep(.61,.83,combined);
	float horizon = smoothstep(85.,620.,length(VERTEX));
	vec3 deep = vec3(.009,.071,.131);
	vec3 teal = vec3(.026,.258,.291);
	vec3 sky = vec3(.34,.57,.69);
	vec3 water = mix(deep,teal,smoothstep(.18,.79,combined));
	ALBEDO = mix(water,sky,fresnel*.58);
	ALBEDO = mix(ALBEDO,vec3(.57,.79,.78),crest*(1.-horizon)*.32);
	EMISSION = mix(vec3(.004,.020,.031),sky*.23,horizon);
	if (wave_detail>.0) {
		vec3 view_x = dFdx(VERTEX);
		vec3 view_y = dFdy(VERTEX);
		vec3 rx = cross(view_y,NORMAL), ry = cross(NORMAL,view_x);
		float det = dot(view_x,rx);
		vec3 bump = sign(det)*(dFdx(combined)*rx+dFdy(combined)*ry);
		NORMAL = normalize(abs(det)*NORMAL-bump*.24*wave_detail*(1.-horizon));
	}
	ROUGHNESS = mix(.21,.53,horizon);
	SPECULAR = mix(.37,.12,horizon);
}
