shader_type spatial;
render_mode unshaded, shadows_disabled, fog_disabled;

uniform vec4 base_color : source_color = vec4(0.02, 0.65, 1.0, 1.0);
uniform vec4 streak_color : source_color = vec4(1.0, 0.06, 0.56, 1.0);
uniform float clock = 0.0;
uniform bool steady = false;
varying vec3 contour_point;

void vertex() {
	contour_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float along = dot(contour_point, vec3(0.23, -0.43, 0.17));
	float packet = smoothstep(0.65, 0.96, sin(along - clock * 3.8) * 0.5 + 0.5);
	float twin = smoothstep(0.79, 0.97, sin(along * 1.8 + clock * 2.3) * 0.5 + 0.5);
	float pulse = 0.73 + 0.27 * sin(clock * 2.0 + along * 0.34);
	vec3 tone = mix(base_color.rgb, streak_color.rgb, packet * 0.85);
	tone = mix(tone, vec3(0.67, 0.92, 1.0), twin * 0.58);
	ALBEDO = steady ? base_color.rgb : tone * (pulse + packet * 0.65 + twin * 0.32);
}
