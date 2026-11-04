shader_type spatial;
uniform int planet=0;
varying vec3 p;
void vertex(){p=VERTEX;}
void fragment(){
 float grain=sin(p.x*170.)*sin(p.y*160.+p.z*90.)*.025;
 vec3 color=vec3(.40,.32,.72); float pattern=0.;
 if(planet==0){pattern=pow(abs(sin((p.x+p.y)*19.)),16.);color=mix(vec3(.31,.40,.77),vec3(.65,.92,1.),pattern*.6);}
 if(planet==1){pattern=pow(abs(sin(p.y*22.+sin(p.x*12.)*2.)),14.);color=mix(vec3(.18,.55,.34),vec3(.72,.96,.51),pattern*.6);}
 if(planet==2){pattern=step(.72,fract((p.x+p.y)*7.));color=mix(vec3(.88,.38,.11),vec3(.20,.16,.12),pattern*.65);}
 if(planet==3){pattern=max(step(.94,fract(p.x*12.)),step(.94,fract(p.y*12.)));color=mix(vec3(.10,.14,.23),vec3(1.,.2,.65),pattern);}
 if(planet==4){pattern=pow(abs(sin(p.y*31.+p.x*7.)),12.);color=mix(vec3(.04,.38,.55),vec3(.30,.90,.92),pattern);}
 if(planet==5){pattern=step(.88,fract(p.x*15.+p.y*4.));color=mix(vec3(.86,.58,.16),vec3(1.,.93,.51),pattern);}
 if(planet==6){pattern=smoothstep(.68,.95,sin(p.x*33.)*sin(p.y*31.));color=mix(vec3(.35,.35,.17),vec3(.79,.87,.47),pattern);}
 if(planet==7){pattern=pow(abs(sin((p.x-p.y)*37.)),32.);color=mix(vec3(.45,.72,.80),vec3(.94,.98,1.),pattern);}
 if(planet==8){pattern=pow(abs(sin(p.x*18.+sin(p.y*23.)*2.)),12.);color=mix(vec3(.14,.09,.08),vec3(1.,.29,.04),pattern);}
 if(planet==9){pattern=step(.90,fract((p.x+p.y)*17.))*step(.25,fract((p.x-p.y)*11.));color=mix(vec3(.12,.08,.23),vec3(.86,.34,1.),pattern);}
 ALBEDO=color+grain; ROUGHNESS=planet==3?.30:.47;
 METALLIC=planet==2?.4:.1; EMISSION=color*pattern*(planet>=8?.65:planet==3?.55:.04);
}
