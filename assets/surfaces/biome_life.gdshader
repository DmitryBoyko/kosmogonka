shader_type spatial;
render_mode cull_disabled;
uniform int world=0;
uniform float motion=1.;
uniform bool wind_islands=false;
uniform sampler2D grain_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec4 ink;
varying vec3 local;
varying vec3 local_normal;
void vertex(){
 ink=COLOR;local=VERTEX;local_normal=NORMAL;
 if(world==9){VERTEX.y+=sin(TIME*.7*motion+INSTANCE_CUSTOM.r*6.28)*.2;}
 else if(wind_islands || world==3 || world==4 || world==5 || world==6){VERTEX.x+=sin(TIME*1.1*motion+INSTANCE_CUSTOM.r*6.28)*max(0.,VERTEX.y)*.045;}
}
void fragment(){
 vec3 n=abs(normalize(local_normal));
 vec3 weights=pow(n,vec3(4.));
 weights/=max(.001,dot(weights,vec3(1.)));
 vec3 uv=local*1.45;
 vec3 texture_tone=texture(grain_map,uv.yz).rgb*weights.x+texture(grain_map,uv.xz).rgb*weights.y+texture(grain_map,uv.xy).rgb*weights.z;
 float grain=smoothstep(.18,.55,dot(texture_tone,vec3(.22,.65,.13)));
 float band=sin(local.y*8.5+local.x*2.+local.z*2.3);
 float material_detail=.67+.45*grain+.08*band+.05*n.y;
 ALBEDO=ink.rgb*material_detail;ROUGHNESS=.86;SPECULAR=.15;
 if(world==10){ROUGHNESS=.42;METALLIC=.5;ALBEDO=mix(vec3(.12,.22,.34),ink.rgb,.6)*material_detail;EMISSION=vec3(.08,.21,.25)*.13;}
 if(world==0 || world==3 || world==7 || world==9){ROUGHNESS=.61;METALLIC=.12;EMISSION=ink.rgb*.055;}
 if(world==3){EMISSION=ink.rgb*(.05+.14*smoothstep(.65,.99,local.y));}
 if(world==6){float dots=pow(max(0.,sin(local.x*21.)*cos(local.z*23.)),14.);EMISSION=ink.rgb*dots*ink.a*.8;}
 if(world==8){EMISSION=vec3(.9,.10,.005)*ink.a*.28;}
 if(wind_islands){ALBEDO=mix(ALBEDO,vec3(.13,.65,.49),.23+.23*smoothstep(.28,1.15,local.y));ROUGHNESS=.67;}
}
