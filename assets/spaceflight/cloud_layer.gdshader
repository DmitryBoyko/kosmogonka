shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, shadows_disabled;
uniform sampler2D cloud_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float coverage=.7;
uniform float drift=0.;
uniform vec3 cloud_tint : source_color=vec3(.96,.975,1.);
void fragment(){
 float cloud=texture(cloud_map,vec2(UV.x+drift,UV.y)).r;
 ALBEDO=cloud_tint; ROUGHNESS=1.; SPECULAR=0.;
 ALPHA=smoothstep(.14,.82,cloud)*coverage;
}
