shader_type spatial;
render_mode unshaded, shadows_disabled;
uniform float power=.3;
void fragment(){ALBEDO=vec3(.65,.86,1.)*(.5+power); EMISSION=vec3(.58,.82,1.)*power*1.5;}
