shader_type spatial;

uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D finish_map : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 shell : source_color;
uniform vec4 accent : source_color;
uniform int container_kind = 0;
varying vec3 p;
varying vec3 n;

void vertex() {
	p = VERTEX;
	n = NORMAL;
}

void fragment() {
	vec3 decal = texture(atlas, UV).rgb;
	float value = dot(decal, vec3(.299,.587,.114));
	float saturation = max(max(decal.r,decal.g),decal.b) - min(min(decal.r,decal.g),decal.b);
	vec3 weights = pow(abs(normalize(n)),vec3(5.0));
	weights /= max(dot(weights,vec3(1.0)),.001);
	vec3 q = p * 2.9;
	vec3 skin = texture(finish_map,q.yz).rgb * weights.x
		+ texture(finish_map,q.xz).rgb * weights.y + texture(finish_map,q.xy).rgb * weights.z;
	float panel = 0.0;
	if (container_kind == 0) {
		panel = smoothstep(.72,.92,fract((p.x + p.y + p.z) * 19.0));
	} else if (container_kind == 1) {
		panel = 1.0 - smoothstep(.05,.18,abs(sin(p.y * 83.0 + p.x * 2.0)));
	} else {
		vec2 grid = abs(fract(vec2(atan(p.x,p.z) * 1.55, p.y * 26.0)) - .5);
		panel = smoothstep(.43,.49,max(grid.x,grid.y));
	}
	float logo = smoothstep(.18,.59,saturation);
	vec3 paint = mix(shell.rgb,accent.rgb,logo * .82);
	ALBEDO = paint * (0.34 + value * .96) * (.65 + .54 * skin);
	ALBEDO = mix(ALBEDO, accent.rgb*.48, panel * .28);
	EMISSION = accent.rgb * (logo * smoothstep(.25,.69,value)*.16+panel*.055);
	ROUGHNESS = container_kind == 1 ? .52 : .72;
	METALLIC = container_kind == 2 ? .46 : .23;
}
