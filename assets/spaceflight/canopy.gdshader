shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, shadows_disabled;
void fragment(){
 float rim=pow(1.-abs(dot(normalize(NORMAL),normalize(VIEW))),4.);
 ALBEDO=vec3(.40,.73,.83); ROUGHNESS=.09; METALLIC=.08; SPECULAR=.9;
 ALPHA=.085+rim*.26;
}
