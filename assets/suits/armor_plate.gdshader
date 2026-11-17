shader_type spatial;
render_mode specular_schlick_ggx;

uniform sampler2D texture_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 base_tint : source_color;
uniform vec3 accent : source_color;
uniform float rough = .62;
uniform float metal = .45;
uniform int pattern = 0;
varying vec3 local_point;

void vertex() {
	local_point = VERTEX;
}

float band(float position, float width) {
	float antialias = min(.2,max(.006,fwidth(position)));
	float line = abs(fract(position + .5) - .5);
	return 1. - smoothstep(width,width + antialias,line);
}

void fragment() {
	vec2 p = local_point.xy + local_point.z * vec2(.18,.25);
	float albedo = dot(texture(texture_map,p * .72 + vec2(.27,.38)).rgb,vec3(.28,.58,.14));
	float detail;
	if (pattern < 3) {
		detail = band(p.x * (2. + float(pattern)) + p.y*.65,.035);
	} else if (pattern < 6) {
		detail = max(band(p.y * 3. + abs(p.x) * (1.4 + float(pattern-3)*.65),.036),
			band(p.x*2.,.026) * smoothstep(.12,.30,abs(p.y)));
	} else if (pattern < 9) {
		detail = band((p.x + p.y) * 3.,.07) * band((p.x-p.y) * (2. + float(pattern-6)*.8),.10);
	} else {
		detail = band(length(p * vec2(1.2,.8 + float(pattern-9)*.22)) * 5.,.062);
	}
	ALBEDO = mix(base_tint * mix(.64,1.11,albedo),accent,detail * .31);
	ROUGHNESS = clamp(rough + (.5-albedo)*.18,.25,.93);
	METALLIC = metal;
	EMISSION = accent * detail * (pattern >= 6 ? .13 : .025);
}
