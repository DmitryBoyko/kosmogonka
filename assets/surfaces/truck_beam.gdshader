shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform float power=0.;
void fragment(){ALBEDO=vec3(.6,.81,1.); ALPHA=(1.-UV.y)*(1.-UV.y)*power*.035;}
