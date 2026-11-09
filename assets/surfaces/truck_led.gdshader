shader_type spatial;
render_mode unshaded, shadows_disabled;
uniform float power=.3;
void fragment(){ALBEDO=vec3(.65,.86,1.)*(.06+power*.85); EMISSION=vec3(.58,.82,1.)*power*1.5;}
