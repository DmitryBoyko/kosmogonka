shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
void fragment(){
 float d=length((UV-vec2(.5))*2.);
 ALBEDO=vec3(.045,.065,.10); ALPHA=(1.-smoothstep(.12,1.,d))*.32;
}
