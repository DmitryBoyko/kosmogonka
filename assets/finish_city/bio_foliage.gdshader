shader_type spatial;
uniform vec3 leaf_color : source_color = vec3(.12,.55,.34);
uniform vec3 flower_color : source_color = vec3(1.,.35,.6);
varying vec3 p;
void vertex(){
 p=VERTEX;
 VERTEX.x+=sin(TIME*1.6+MODEL_MATRIX[3].x*.3+VERTEX.y*2.)*.035*max(VERTEX.y,0.);
}
void fragment(){
 float veins=pow(abs(sin(p.x*24.+sin(p.z*17.))),14.);
 float mottles=sin(p.x*39.+p.y*21.)*sin(p.z*31.-p.y*15.);
 float blossoms=smoothstep(.63,.88,sin(p.x*19.+p.z*13.)*sin(p.y*23.-p.z*11.));
 ALBEDO=mix(leaf_color*(.85+mottles*.14)+vec3(.12,.21,.05)*veins,flower_color,blossoms*.85);
 ROUGHNESS=.86; EMISSION=flower_color*blossoms*.065;
}
