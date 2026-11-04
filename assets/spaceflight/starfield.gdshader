shader_type spatial;
render_mode unshaded, cull_front, depth_draw_never, shadows_disabled, fog_disabled;
uniform sampler2D stars_map : source_color, filter_linear_mipmap, repeat_enable;
void fragment(){
 vec3 sky=texture(stars_map,UV).rgb;
 ALBEDO=sky*.62+vec3(.004,.008,.018);
}
