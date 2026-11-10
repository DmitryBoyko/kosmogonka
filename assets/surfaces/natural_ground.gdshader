shader_type spatial;
uniform sampler2D grass_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 tint : source_color=vec3(1.);
uniform int planet_index=0;
uniform float track_distance=0.;
uniform bool hill=false;
varying vec3 p;
void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;p.z-=track_distance;}
void fragment(){
 vec3 tex=texture(grass_map,p.xz*.12).rgb;
 float variation=.92+.08*sin(p.x*.19)*sin(p.z*.23);
 ALBEDO=tex*tint*variation; EMISSION=vec3(0.); ROUGHNESS=.97; SPECULAR=.12; METALLIC=0.;
	float grain=dot(tex,vec3(.299,.587,.114));
	if(planet_index==4){
	 float ripple=sin(p.x*.8+TIME*.7)*sin(p.z*.7-TIME*.6);
	 ALBEDO=mix(vec3(.015,.09,.17),vec3(.035,.34,.39),grain)*(.94+ripple*.06);
	 ROUGHNESS=.55+ripple*.035;SPECULAR=0.;METALLIC=0.;
	}else if(planet_index==8){
	 float f=sin(p.x*.25+sin(p.z*.19))+sin(p.z*.28-sin(p.x*.14));
	 float lava=hill?pow(1.-smoothstep(.04,.18,abs(f)),2.):1.-smoothstep(1.1,1.5,abs(f));
	 ALBEDO=mix(vec3(.035,.025,.027)*(1.+grain),vec3(.48,.075,.008),lava);
	 EMISSION=vec3(1.,.17,.008)*lava*(1.15+sin(p.z*.7+TIME*.55)*.12);ROUGHNESS=mix(.96,.48,lava);
	}else if(planet_index==7){
	 float crack=1.-smoothstep(.02,.065,abs(sin(p.x*.19+sin(p.z*.22))));
	 ALBEDO=mix(vec3(.7,.83,.88)*( .8+grain*.4),vec3(.025,.19,.31),crack);ROUGHNESS=.43;SPECULAR=.45;
	}else if(planet_index==2 || planet_index==5){
	 ALBEDO=(planet_index==2?vec3(.55,.36,.16):vec3(.69,.5,.23))*(.7+grain*.55+sin(p.x*.35+sin(p.z*.09))*.035);
	}else if(planet_index==6){
	 float vein=pow(1.-abs(sin(p.x*.21+sin(p.z*.24))),12.);
	 ALBEDO=vec3(.11,.065,.13)*(.7+grain);EMISSION=vec3(.13,.3,.24)*vein*.18;
	}else if(planet_index==3){
	 vec2 grid=abs(fract(p.xz*.16)-.5);float line=1.-smoothstep(.008,.025,min(grid.x,grid.y));
	 ALBEDO=vec3(.045,.065,.10)*(1.+grain*.35);EMISSION=vec3(.08,.29,.32)*line*.32;ROUGHNESS=.72;
	}else if(planet_index==9){
	 ALBEDO=vec3(.105,.075,.16)*(.6+grain*.8);EMISSION=vec3(.12,.04,.21)*pow(grain,5.)*.2;
	}else if(planet_index==10){
	 float facet=step(.5,fract(p.x*.15+p.z*.07));
	 ALBEDO=mix(vec3(.10,.17,.27),vec3(.22,.27,.38),facet);ROUGHNESS=.28;METALLIC=.65;SPECULAR=.3;
	 EMISSION=vec3(.04,.17,.20)*(1.-smoothstep(.01,.025,abs(fract(p.x*.15+p.z*.07)-.5)));
	}else if(planet_index==0){
	 ALBEDO=mix(tex*vec3(.65,.85,.72),vec3(.14,.18,.23)*( .8+grain),.64);
	}
}
