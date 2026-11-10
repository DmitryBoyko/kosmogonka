shader_type spatial;
render_mode unshaded,cull_disabled,blend_add,depth_draw_never;
uniform vec3 tint:source_color=vec3(.2,.8,1.);
uniform float motion=1.;
void fragment(){
 vec2 p=UV-.5;float r=length(p*vec2(1.,.7));float a=atan(p.y,p.x);
 float band=pow(.5+.5*cos(r*53.-TIME*1.7*motion+a*3.),7.);
 float fade=1.-smoothstep(.27,.5,length(p));
 ALBEDO=tint;ALPHA=fade*(.045+band*.16);
}
