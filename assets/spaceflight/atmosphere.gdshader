shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_front, shadows_disabled, fog_disabled;
uniform vec3 tint : source_color=vec3(.22,.50,1.);
void fragment(){
 float facing=abs(dot(normalize(NORMAL),normalize(VIEW)));
 float rim=pow(1.-facing,4.);
 ALBEDO=tint; EMISSION=tint*.30; ALPHA=rim*.26;
}
