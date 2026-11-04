shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
varying vec4 particle_color;
void vertex(){
 MODELVIEW_MATRIX=VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0],INV_VIEW_MATRIX[1],INV_VIEW_MATRIX[2],MODEL_MATRIX[3]);
 particle_color=COLOR;
}
void fragment(){
 float d=length((UV-vec2(.5))*2.);
 ALBEDO=particle_color.rgb; ALPHA=(1.-smoothstep(.12,1.,d))*particle_color.a;
}
