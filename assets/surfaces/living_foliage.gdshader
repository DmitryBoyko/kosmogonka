shader_type spatial;
render_mode cull_disabled;
uniform vec3 tint : source_color=vec3(.22,.43,.12);
uniform float wind=1.;
uniform bool grass=false;
varying float height_factor;
void vertex(){
 vec3 world=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;
 float h=clamp(VERTEX.y,0.,1.);
 VERTEX.x+=sin(TIME*1.7+world.x*.8+world.z*.24)*h*h*.10*wind;
 VERTEX.z+=sin(TIME*1.1+world.z*.6)*h*h*.04*wind;
 height_factor=h;
}
void fragment(){
 float vein=exp(-abs(UV.x-.5)*80.);
 float ribs=pow(abs(sin(UV.y*48.+abs(UV.x-.5)*30.)),20.);
 ALBEDO=tint*mix(.65,1.3,UV.y)+vec3(.08,.11,.015)*(vein+ribs*.25);
 ROUGHNESS=.93; METALLIC=0.; SPECULAR=.16;
 BACKLIGHT=tint*.12;
}
