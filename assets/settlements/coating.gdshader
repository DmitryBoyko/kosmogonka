shader_type spatial;

uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D cladding : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 shell : source_color = vec4(0.4, 0.6, 0.7, 1.0);
uniform vec4 trim : source_color = vec4(0.3, 0.95, 0.88, 1.0);
uniform int world = 0;
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
	vec3 point = local_point * 0.74;
	vec3 surface = texture(cladding, point.yz).rgb * n.x
		+ texture(cladding, point.xz).rgb * n.y + texture(cladding, point.xy).rgb * n.z;
	float seam = smoothstep(0.92, 0.995, fract(local_point.y * (1.35 + float(world % 4) * 0.25)));
	vec3 paint = mix(shell.rgb, trim.rgb, smoothstep(0.18, 0.53, saturation) * 0.69);
	ALBEDO = paint * (0.37 + value * 0.91) * (0.69 + surface * 0.43) * (1.0 - seam * 0.13);
	EMISSION = trim.rgb * smoothstep(0.40, 0.72, saturation) * smoothstep(0.49, 0.78, value) * 0.10;
	ROUGHNESS = world == 10 ? 0.34 : 0.74;
	METALLIC = world == 10 ? 0.48 : 0.19;
}
