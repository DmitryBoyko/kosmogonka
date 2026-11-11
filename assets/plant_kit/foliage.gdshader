shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;

uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_enable;
uniform bool textured = true;
uniform bool cutout = true;
uniform vec3 base_color : source_color = vec3(1.);
uniform vec3 biome_tint : source_color = vec3(1.);
uniform float recolor : hint_range(0.,1.) = .0;
uniform float bend : hint_range(0.,1.) = .55;
uniform float wind = 1.;
uniform float glow = 0.;
varying float shade;

void vertex() {
	float height = clamp(VERTEX.y,0.,1.);
	float weight = height * height;
	float phase = INSTANCE_CUSTOM.x * 6.283;
	float sway = sin(TIME*1.64 + phase + VERTEX.y*2.2);
	float gust = sin(TIME*.64 + phase*1.7);
	VERTEX.x += (sway*.025 + gust*.022)*weight*bend*wind;
	VERTEX.z += sin(TIME*1.14 + phase)*.025*weight*bend*wind;
	shade = mix(.83,1.12,height)*mix(.88,1.14,INSTANCE_CUSTOM.y);
}

void fragment() {
	vec4 texel = textured ? texture(atlas,UV) : vec4(1.);
	if (cutout && texel.a < .43) {
		discard;
	}
	vec3 original = texel.rgb * base_color;
	float green = smoothstep(.005,.19,original.g-max(original.r*.86,original.b*.83));
	float luminance = dot(original,vec3(.2126,.7152,.0722));
	vec3 colored = biome_tint * (.36 + luminance*.87);
	ALBEDO = mix(original,colored,recolor*(.24+green*.76))*shade;
	ROUGHNESS = .87;
	SPECULAR = .19;
	BACKLIGHT = ALBEDO*.22;
	EMISSION = ALBEDO*glow;
}
