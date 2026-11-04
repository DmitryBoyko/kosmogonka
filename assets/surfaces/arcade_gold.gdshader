shader_type spatial;
varying vec3 p;
void vertex(){p=VERTEX;}
void fragment(){
 float band=pow(.5+.5*sin(dot(normalize(NORMAL),normalize(vec3(-.4,.8,.6)))*7.+p.y*.7),6.);
 vec3 deep=vec3(.63,.32,.06); vec3 gold=vec3(1.,.765,.336);
 ALBEDO=mix(gold,vec3(1.,.94,.64),band*.48);
 METALLIC=.70; ROUGHNESS=.18; SPECULAR=.65;
 EMISSION=gold*.48+vec3(1.,.95,.69)*band*.34;
}
