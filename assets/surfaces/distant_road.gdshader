shader_type spatial;
render_mode shadows_disabled;
uniform sampler2D road_map : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 road_color : source_color;
uniform float length_m = 260.;
void fragment() {
	vec3 marks = texture(road_map,vec2(UV.x*3.,UV.y*length_m*.18)).rgb;
	float h = dot(marks,vec3(.299,.587,.114));
	ALBEDO = road_color.rgb * mix(.75,1.45,smoothstep(.025,.30,h));
	ROUGHNESS = .93;
	ALPHA = 1.-smoothstep(.45,1.,UV.y);
}
