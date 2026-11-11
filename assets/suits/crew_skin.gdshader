shader_type spatial;
render_mode specular_schlick_ggx;

uniform sampler2D source_atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform vec3 complexion : source_color = vec3(1.);
uniform ivec2 extra_skin_cell = ivec2(-1);
uniform bool metal_mask = false;
uniform bool steel_mask = false;

void fragment() {
	vec3 base = texture(source_atlas, UV).rgb;
	ivec2 cell = ivec2(floor(UV * vec2(16.,4.)));
	bool normal_skin = cell.y == 2 && (cell.x == 1 || cell.x == 3 || cell.x == 5);
	bool skin = normal_skin || all(equal(cell,extra_skin_cell));
	float texture_shade = dot(base,vec3(.26,.63,.11));
	if (skin) {
		ALBEDO = complexion * mix(.86,1.08,texture_shade);
		EMISSION = complexion*.115;
	} else if (metal_mask && all(equal(cell,ivec2(5,3)))) {
		ALBEDO = (steel_mask ? vec3(.49,.56,.62) : vec3(.24,.245,.25)) * (.72+texture_shade*.5);
		METALLIC = steel_mask ? .36 : .02;
		EMISSION = steel_mask ? vec3(.063,.075,.087) : vec3(0.);
	} else {
		ALBEDO = base;
	}
	ROUGHNESS = skin ? .81 : steel_mask ? .40 : .67;
	SPECULAR = .24;
}
