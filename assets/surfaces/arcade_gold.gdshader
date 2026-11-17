shader_type spatial;
uniform vec4 star_color : source_color = vec4(1., .765, .336, 1.);
varying vec3 p;
void vertex(){p=VERTEX;}
void fragment(){
 float band=pow(.5+.5*sin(dot(normalize(NORMAL),normalize(vec3(-.4,.8,.6)))*7.+p.y*.7),6.);
 vec3 ink=star_color.rgb;
 ALBEDO=mix(ink,vec3(1.),band*.39);
 METALLIC=.70; ROUGHNESS=.18; SPECULAR=.65;
 EMISSION=ink*(.64+band*.36);
}
