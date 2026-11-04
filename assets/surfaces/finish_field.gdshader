shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec3 tint : source_color=vec3(.25,.86,1.);
uniform float flow_time=0.;
uniform float proximity=0.;
uniform vec2 touch_point=vec2(.5,.25);
varying vec2 field_uv;
void vertex(){field_uv=UV;}
void fragment(){
 vec2 p=field_uv;
 float edge=pow(max(abs(p.x-.5)*2.,abs(p.y-.5)*2.),12.);
 float sweep=pow(.5+.5*sin(p.y*24.-flow_time*1.4),14.);
 float distance_to=length((p-touch_point)*vec2(2.45,1.));
 float ripple=pow(.5+.5*cos(distance_to*48.-flow_time*4.),12.)*exp(-distance_to*3.)*proximity;
 float alpha=.015+edge*.32+sweep*.018+ripple*.25;
 ALBEDO=tint; ALPHA=alpha;
}
