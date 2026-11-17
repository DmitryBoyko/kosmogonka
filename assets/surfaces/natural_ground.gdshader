shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
#include "res://assets/surfaces/shallow_relief.gdshaderinc"
uniform sampler2D biome_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 tint : source_color=vec3(1.);
uniform int planet_index=0;
uniform float track_distance=0.;
uniform bool hill=false;
uniform bool distant_terrain=false;
uniform bool wind_islands=false;
uniform bool storm_rock=false;
uniform vec3 expedition_mineral : source_color=vec3(1.);
uniform float expedition_mix=0.;
uniform vec2 track_rotation=vec2(1.,0.);
uniform float track_lateral=0.;
varying vec3 p;
varying float shoulder;
void vertex(){
 vec3 world=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;
 p=vec3(dot(world.xz,vec2(track_rotation.x,-track_rotation.y))+track_lateral,
        world.y,dot(world.xz,track_rotation.yx)-track_distance);
 shoulder=1.-COLOR.a;
}
void fragment(){
 float texture_scale = storm_rock ? (distant_terrain ? .40 : 1.24) : (distant_terrain ? .18 : .37);
 vec3 tex=texture(biome_map,p.xz*texture_scale).rgb;
 float variation=.92+.08*sin(p.x*.19)*sin(p.z*.23);
 ALBEDO=tex*tint*variation; EMISSION=vec3(0.); ROUGHNESS=.97; SPECULAR=.12; METALLIC=0.;
	float grain=dot(tex,vec3(.299,.587,.114));
	if(planet_index==4){
	 float ripple=sin(p.x*.8+TIME*.7)*sin(p.z*.7-TIME*.6);
	 ALBEDO=mix(vec3(.015,.09,.17),vec3(.035,.34,.39),grain)*(.94+ripple*.06);
	 ROUGHNESS=.55+ripple*.035;SPECULAR=0.;METALLIC=0.;
	 if(hill){
	  ALBEDO=mix(vec3(.10,.13,.14),vec3(.28,.30,.27),grain);
	  ROUGHNESS=.92;
	 }
	}else if(storm_rock){
	 float grit=dot(texture(biome_map,p.xz*2.67+vec2(.36,.21)).rgb,vec3(.299,.587,.114));
	 float rock_detail=smoothstep(.17,.66,grain*.79+grit*.21);
	 float oxide=smoothstep(.32,.75,rock_detail)*smoothstep(-.30,.51,sin(p.x*.13)*cos(p.z*.095));
	 ALBEDO=mix(vec3(.34,.33,.43),vec3(.57,.52,.65),rock_detail);
	 ALBEDO=mix(ALBEDO,vec3(.54,.34,.41),oxide*.65);
	}else if(planet_index==8){
	 float f=sin(p.x*.25+sin(p.z*.19))+sin(p.z*.28-sin(p.x*.14));
	 float lava=hill?pow(1.-smoothstep(.04,.18,abs(f)),2.):1.-smoothstep(1.1,1.5,abs(f));
	 ALBEDO=mix(vec3(.17,.13,.23)*(1.+grain*.67),vec3(.48,.075,.008),lava);
	 EMISSION=vec3(1.,.17,.008)*lava*(1.15+sin(p.z*.7+TIME*.55)*.12);ROUGHNESS=mix(.96,.48,lava);
	}else if(wind_islands){
	 float moss=.5+.5*sin(p.x*.12+sin(p.z*.18))*cos(p.z*.095);
	 ALBEDO=mix(vec3(.23,.42,.60),vec3(.39,.78,.60),moss)*(.75+.45*grain);
	 ROUGHNESS=.91;
	}else if(planet_index==7){
	 float crack=1.-smoothstep(.02,.065,abs(sin(p.x*.19+sin(p.z*.22))));
	 ALBEDO=mix(vec3(.7,.83,.88)*( .8+grain*.4),vec3(.025,.19,.31),crack);ROUGHNESS=.43;SPECULAR=.45;
	}else if(planet_index==2 || planet_index==5){
	 ALBEDO=(planet_index==2?vec3(.55,.36,.16):vec3(.69,.5,.23))*(.7+grain*.55+sin(p.x*.35+sin(p.z*.09))*.035);
	}else if(planet_index==6){
	 float damp = smoothstep(-.3,.57,sin(p.x*.16)*cos(p.z*.18));
	 vec3 mulch = mix(vec3(.21,.17,.29),vec3(.30,.23,.33),damp);
	 ALBEDO = mix(mulch,tex*vec3(.66,.58,.74),.63);
	 EMISSION=vec3(.05,.09,.06)*smoothstep(.69,.88,grain)*.21;
	}else if(planet_index==3){
	 float fracture=smoothstep(.19,.57,grain);
	 float mineral_vein=smoothstep(.43,.80,grain)*smoothstep(.12,.65,sin(p.x*.19)*cos(p.z*.24));
	 vec3 shale=mix(vec3(.23,.27,.34),vec3(.38,.43,.50),fracture);
	 ALBEDO=mix(shale,vec3(.21,.47,.42),mineral_vein*.5);
	 ROUGHNESS=.91;
	}else if(planet_index==9){
	 ALBEDO=mix(vec3(.18,.14,.29),vec3(.34,.25,.45),smoothstep(.16,.56,grain));EMISSION=vec3(.12,.04,.21)*pow(grain,5.)*.2;
	}else if(planet_index==10){
	 float facet=step(.5,fract(p.x*.15+p.z*.07));
	 ALBEDO=mix(vec3(.18,.26,.36),vec3(.29,.37,.48),facet);ROUGHNESS=.84;METALLIC=0.;SPECULAR=0.;
	 EMISSION=vec3(.04,.17,.20)*(1.-smoothstep(.01,.025,abs(fract(p.x*.15+p.z*.07)-.5)));
	}else if(planet_index==0){
	 ALBEDO=mix(tex*vec3(.65,.85,.72),vec3(.22,.26,.32)*( .8+grain),.64);
	}
	float strata = sin(p.z*.071 + sin(p.x*.043)*2.2)*sin(p.x*.086-p.z*.024);
	float soil = smoothstep(-.53,.61,strata);
	vec3 earth = vec3(1.13,1.04,.89);
	if (planet_index==1 || planet_index==6) earth=vec3(.84,1.17,.76);
	if (planet_index==7 || planet_index==10) earth=vec3(.83,1.01,1.20);
	float terrain_detail=planet_index==2 || planet_index==5
		? smoothstep(.62,.79,grain) : smoothstep(.18,.56,grain);
	ALBEDO *= mix(vec3(.76,.77,.78),earth,soil) * mix(.79,1.16,terrain_detail);
	if (shoulder>.001) {
		vec3 bank=ALBEDO * vec3(1.03,1.19,1.06);
		if (planet_index==3) bank=mix(ALBEDO,vec3(.20,.39,.34),terrain_detail*.67);
		if (planet_index==6) bank=mix(ALBEDO,vec3(.27,.19,.25),terrain_detail*.73);
		if (planet_index==7) bank=mix(ALBEDO,vec3(.49,.67,.72),terrain_detail*.62);
		if (planet_index==8) bank=ALBEDO*vec3(.97,.88,.93);
		if (storm_rock) bank=mix(ALBEDO,vec3(.27,.49,.49),terrain_detail*.55);
		ALBEDO=mix(ALBEDO,bank,shoulder*mix(.34,.91,soil));
	}
	ALBEDO=mix(ALBEDO,expedition_mineral*mix(.69,1.13,terrain_detail),expedition_mix*mix(.62,1.,soil));
	if (!distant_terrain) {
		float relief_depth = storm_rock ? .019 : .042;
		NORMAL = shallow_relief(NORMAL,VERTEX,grain,relief_depth*(1.-smoothstep(14.,38.,length(VERTEX))));
	}
	if (distant_terrain) {
	 float mist=smoothstep(145.,1160.,length(VERTEX));
	 ALBEDO*=1.-mist;
	 EMISSION=mix(EMISSION,vec3(.721,.806,.856),mist);
	 SPECULAR*=1.-mist;
	 METALLIC*=1.-mist;
	}
}
