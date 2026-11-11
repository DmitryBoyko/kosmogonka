shader_type spatial;
render_mode specular_schlick_ggx;

uniform sampler2D atlas : source_color, filter_nearest, repeat_disable;
uniform sampler2D surface_map : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 paint : source_color;
uniform vec3 accent : source_color;
uniform vec3 hull_scale = vec3(1.);
uniform int pattern;
varying vec3 hull_point;
varying vec3 hull_normal;

void vertex() {
	hull_point = VERTEX * hull_scale;
	hull_normal = NORMAL;
}

void fragment() {
	vec3 source = texture(atlas, UV).rgb;
	float luma = dot(source, vec3(.24,.67,.09));
	float chroma = max(source.r,max(source.g,source.b))-min(source.r,min(source.g,source.b));
	float ink = smoothstep(.12,.40,chroma);
	float dark = 1. - smoothstep(.10,.34,luma + chroma*.35);
	vec3 weights = pow(abs(normalize(hull_normal)),vec3(4.));
	weights /= max(dot(weights,vec3(1.)),.001);
	vec3 p = hull_point * .8;
	vec3 tiles = texture(surface_map,p.zy).rgb*weights.x
		+ texture(surface_map,p.xz).rgb*weights.y
		+ texture(surface_map,p.xy).rgb*weights.z;
	float surface = dot(tiles,vec3(.24,.67,.09));

	float diagonal = abs(hull_point.x)*(.60 + float(pattern)*.29) + hull_point.z*.49;
	float stripe = smoothstep(.32,.36,fract(diagonal))*(1.-smoothstep(.47,.52,fract(diagonal)));
	stripe *= smoothstep(.8,1.9,abs(hull_point.x));
	vec3 enamel = mix(paint,accent,max(ink,stripe*.82));
	ALBEDO = mix(enamel*(.73 + luma*.27),vec3(.033,.047,.067),dark*.94)*mix(.65,1.22,surface);
	METALLIC = mix(.43,.74,dark);
	ROUGHNESS = clamp(.39 + dark*.16 + (1.-surface)*.24,.27,.82);
	SPECULAR = .53;
}
