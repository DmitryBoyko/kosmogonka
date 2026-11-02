shader_type spatial;
render_mode unshaded;
uniform vec4 tint : source_color = vec4(.3,.8,.7,1.0);
uniform float activation : hint_range(0.0,1.0) = 0.0;
uniform float energy_time = 0.0;
uniform bool reduced_motion = false;
varying vec3 local_point;
void vertex() { local_point=VERTEX; }
void fragment() {
 float reveal=reduced_motion ? activation : smoothstep(local_point.y-.65,local_point.y+.65,activation*16.0-1.0);
 float band=pow(max(0.0,cos(local_point.y*1.65-energy_time*3.0+local_point.x*.22)),14.0);
 float flow=reduced_motion ? 0.0 : band*.52*activation;
 vec3 lit=tint.rgb*(.62+flow);
 ALBEDO=mix(vec3(.065,.085,.09),lit,reveal);
 EMISSION=tint.rgb*reveal*(.35+flow*.65);
}
