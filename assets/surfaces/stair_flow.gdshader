shader_type spatial;
render_mode unshaded, shadows_disabled;
uniform vec3 light_color : source_color=vec3(.35,.95,.8);
uniform float flow_distance=0.;
uniform float activation=0.;
uniform bool reduced_motion=false;
varying float track_z;
void vertex(){track_z=VERTEX.z;}
void fragment(){
 float phase=fract((track_z+flow_distance)/5.);
 float wave=smoothstep(0.,.12,phase)*(1.-smoothstep(.22,.65,phase));
 float power=reduced_motion ? .2+activation*.5 : .15+activation*(.25+wave*1.4);
 ALBEDO=light_color*power; EMISSION=light_color*power*.6;
}
