shader_type spatial;
render_mode shadows_disabled, diffuse_lambert, specular_disabled;
#include "res://assets/surfaces/road_coating.gdshaderinc"

uniform sampler2D surface_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 road_color : source_color;
uniform vec4 detail_color : source_color;
uniform vec2 texture_levels = vec2(.17, .44);
uniform vec2 image_repeat = vec2(1.);
uniform int road_style = 0;
uniform float natural_color = .55;
uniform float length_m = 260.;
void fragment() {
	vec2 uv = vec2(UV.x, UV.y * length_m / 5.);
	vec3 albedo = texture(surface_texture, uv * image_repeat).rgb;
	ALBEDO = road_coating(road_color.rgb, detail_color.rgb, albedo, uv, texture_levels, road_style, natural_color, OUTPUT_IS_SRGB);
	ROUGHNESS = .93;
	ALPHA = 1.-smoothstep(.45,1.,UV.y);
}
