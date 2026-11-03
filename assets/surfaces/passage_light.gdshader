shader_type spatial;
render_mode unshaded;
uniform float flow_time=0.;
uniform float phase=0.;
uniform bool reduced_motion=false;
void fragment(){
 float power=reduced_motion ? .85 : .66+.24*sin(flow_time*5.0+phase);
 ALBEDO=vec3(.36,.92,1.)*power;
 EMISSION=vec3(.36,.92,1.)*power*.5;
}
