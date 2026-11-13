shader_type spatial;

uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D cladding : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 shell : source_color = vec4(0.4, 0.6, 0.7, 1.0);
uniform vec4 trim : source_color = vec4(0.3, 0.95, 0.88, 1.0);
uniform int world = 0;
uniform int finish = 0;
varying vec3 local_point;
varying vec3 local_normal;

void vertex() {
	local_point = VERTEX;
	local_normal = NORMAL;
}

void fragment() {
	vec3 color = texture(atlas, UV).rgb;
	float value = dot(color, vec3(0.299, 0.587, 0.114));
	float saturation = max(max(color.r, color.g), color.b) - min(min(color.r, color.g), color.b);
	vec3 n = pow(abs(normalize(local_normal)), vec3(5.0));
	n /= max(dot(n, vec3(1.0)), 0.001);
	vec3 point = local_point * (finish == 1 ? 0.29 : 0.39);
	vec3 surface = texture(cladding, point.yz).rgb * n.x
		+ texture(cladding, point.xz).rgb * n.y + texture(cladding, point.xy).rgb * n.z;
	vec3 base = finish == 1 ? mix(shell.rgb, vec3(0.9, 0.87, 0.77), 0.52) :
		finish == 2 ? mix(shell.rgb, vec3(0.65, 0.37, 0.23), 0.43) : shell.rgb;
	float panel = dot(surface, vec3(0.299, 0.587, 0.114));
	vec3 textured = base * mix(0.43, 1.52, smoothstep(0.07, 0.65, panel));
	float accent = smoothstep(0.17, 0.52, saturation);
	ALBEDO = mix(textured, mix(color, trim.rgb, 0.35), accent * 0.69) * mix(0.50, 1.25, value);
	EMISSION = trim.rgb * accent * smoothstep(0.46, 0.76, value) * 0.16;
	ROUGHNESS = finish == 0 ? 0.52 : 0.78;
	METALLIC = finish == 0 ? 0.46 : 0.11;
}
