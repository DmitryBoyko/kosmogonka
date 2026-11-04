shader_type spatial;
uniform sampler2D surface_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 tint : source_color=vec3(1.);
uniform float longitude=0.;
uniform bool distant=false;
void fragment(){
 vec3 color=texture(surface_map,vec2(UV.x+longitude,UV.y)).rgb*tint;
 float water=smoothstep(.03,.13,color.b-max(color.r,color.g));
 ALBEDO=distant?mix(color,vec3(.32,.51,.68),.38):color;
 ROUGHNESS=mix(.91,.32,water); SPECULAR=mix(.23,.55,water); METALLIC=0.;
}
