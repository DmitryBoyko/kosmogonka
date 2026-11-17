shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never, shadows_disabled;

uniform vec4 beam_color : source_color = vec4(.48, .78, 1., 1.);
uniform float power = .83;
varying float along;

void vertex() {
	along = VERTEX.y + .5;
}

void fragment() {
	float edge = mix(.36,1.,smoothstep(.0, .78, abs(dot(normalize(NORMAL), normalize(VIEW)))));
	float length_fade = smoothstep(0., .035, along) * (1. - smoothstep(.67, 1., along));
	ALBEDO = beam_color.rgb;
	ALPHA = power * .28 * edge * length_fade;
}
