shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
#include "res://assets/surfaces/road_coating.gdshaderinc"
#include "res://assets/surfaces/shallow_relief.gdshaderinc"

uniform sampler2D surface_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec2 repeats = vec2(1.0, 6.0);
uniform vec2 image_repeat = vec2(1.);
uniform int road_style = 0;
uniform vec2 texture_levels = vec2(.17, .44);
uniform vec4 road_color : source_color = vec4(.31, .34, .40, 1.);
uniform vec4 detail_color : source_color = vec4(.33, .43, .42, 1.);
uniform float relief_depth = .012;
uniform float natural_color = .55;

void fragment() {
	vec2 uv = UV * repeats;
	vec3 albedo = texture(surface_texture, uv * image_repeat).rgb;
	ALBEDO = road_coating(road_color.rgb, detail_color.rgb, albedo, uv, texture_levels, road_style, natural_color, OUTPUT_IS_SRGB);
	float relief = smoothstep(texture_levels.x, texture_levels.y, dot(albedo,vec3(.299,.587,.114)));
	NORMAL = shallow_relief(NORMAL,VERTEX,relief,relief_depth*(1.-smoothstep(8.,28.,length(VERTEX))));
	ROUGHNESS = .93;
}
