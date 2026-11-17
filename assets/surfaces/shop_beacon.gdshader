shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never, shadows_disabled;

uniform sampler2D atlas : filter_linear, repeat_disable;
uniform vec2 tile;
uniform vec4 tint : source_color = vec4(.4, .86, 1., 1.);
uniform vec2 rotation = vec2(1.,0.);
uniform float clock = 0.;
uniform float phase = 0.;
uniform bool plaza = false;
uniform bool steady = false;
uniform bool track = false;

void fragment() {
	vec2 p = UV - .5;
	vec2 rotated = vec2(dot(p,rotation),dot(p,vec2(-rotation.y,rotation.x)));
	float visibility = 1.;
	if (track) {
		float travel = fract(TIME*.72 + phase);
		float offset = steady ? 0. : mix(-.225,.225,travel);
		rotated = (rotated - vec2(offset,0.)) / .75;
		if (!steady) visibility = smoothstep(0.,.19,travel)*(1.-smoothstep(.81,1.,travel));
	}
	rotated += .5;
	vec2 cell = clamp(rotated,vec2(.003),vec2(.997));
	vec3 mark = texture(atlas,(tile+cell)/vec2(5.,4.)).rgb;
	float inside = step(0.,rotated.x)*step(rotated.x,1.)*step(0.,rotated.y)*step(rotated.y,1.);
	float wave = fract(clock*.59 + phase);
	float pulse = plaza && !steady ? 1. - smoothstep(.035,.20,abs(UV.y - wave)) : 0.;
	float tube = smoothstep(.06,.78,mark.r);
	float hot_center = smoothstep(.76,1.,mark.r);
	float glow = mark.g*2.15 + mark.b*4.1;
	ALBEDO = mix(tint.rgb,vec3(1.),hot_center*(.37+.20*pulse));
	ALPHA = inside*clamp(tube*.94+glow*(.82+.32*pulse),0.,1.)*visibility;
}
