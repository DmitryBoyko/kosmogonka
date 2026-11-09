shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
uniform vec3 tint : source_color=vec3(.8,.7,.5);
uniform float inner_radius=10.;
uniform float outer_radius=12.;
void fragment(){
 float r=.5-.5*cos(UV.y*6.2831853);
 float grains=.5+.5*sin(r*311.+sin(r*71.)*2.);
 float bands=.58+.42*sin(r*93.);
 float edge=smoothstep(0.,.055,r)*(1.-smoothstep(.92,1.,r));
 float gap=1.-smoothstep(.018,.045,abs(r-.61));
 if(edge*(1.-gap*.85)<.10){discard;}
 ALBEDO=tint*(.45+.45*grains)*(.66+.34*bands); EMISSION=tint*.035;
}
