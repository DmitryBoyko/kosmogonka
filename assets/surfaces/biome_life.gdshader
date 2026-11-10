shader_type spatial;
render_mode cull_disabled;
uniform int world=0;
uniform float motion=1.;
varying vec4 ink;
varying vec3 local;
void vertex(){
 ink=COLOR;local=VERTEX;
 if(world==9){VERTEX.y+=sin(TIME*.7*motion+INSTANCE_CUSTOM.r*6.28)*.2;}
 else if(world==4 || world==6){VERTEX.x+=sin(TIME*1.1*motion+INSTANCE_CUSTOM.r*6.28)*max(0.,VERTEX.y)*.03;}
}
void fragment(){
 ALBEDO=ink.rgb;ROUGHNESS=.86;SPECULAR=.18;
 if(world==10){ROUGHNESS=.2;METALLIC=.82;ALBEDO=mix(vec3(.12,.22,.34),ink.rgb,.6);EMISSION=vec3(.08,.21,.25)*.3;}
 if(world==0 || world==3 || world==7 || world==9){ROUGHNESS=.3;METALLIC=.18;EMISSION=ink.rgb*.10;}
 if(world==6){float dots=pow(max(0.,sin(local.x*21.)*cos(local.z*23.)),14.);EMISSION=ink.rgb*dots*ink.a*.8;}
 if(world==8){EMISSION=vec3(.9,.10,.005)*ink.a*.28;}
}
