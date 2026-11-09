shader_type spatial;
render_mode cull_disabled;
uniform vec3 flower_color : source_color=vec3(.94,.48,.69);
uniform float wind=1.;
uniform bool drifter=false;
varying float petal;
varying float shade;
void vertex(){
 petal=COLOR.r;shade=INSTANCE_CUSTOM.g;
 float phase=INSTANCE_CUSTOM.r*6.2831853;
 vec3 world=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;
 if(drifter){
  VERTEX.y+=abs(VERTEX.x)*sin(TIME*13.+phase)*.8*wind;
  VERTEX+=vec3(sin(TIME*.7+phase)*.7,sin(TIME*1.2+phase)*.25,cos(TIME*.6+phase)*.6)*wind;
 }else{
  VERTEX.x+=sin(TIME*1.6+world.z*.3+phase)*VERTEX.y*VERTEX.y*.12*wind;
 }
}
void fragment(){
 vec3 bloom=mix(flower_color,vec3(1.,.83,.42),shade*.45);
 ALBEDO=drifter?bloom:mix(vec3(.17,.38,.13),bloom,petal);
 ROUGHNESS=.94;SPECULAR=.1;
 if(drifter){EMISSION=bloom*.18;}
}
