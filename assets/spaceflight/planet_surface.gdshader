shader_type spatial;
uniform sampler2D surface_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 tint : source_color=vec3(1.);
uniform float longitude=0.;
uniform bool distant=false;
uniform int identity=0;
uniform float terrain_seed=1.7;
uniform vec3 land_color : source_color=vec3(.5,.4,.6);
uniform vec3 ocean_color : source_color=vec3(.1,.4,.5);
uniform vec3 ridge_color : source_color=vec3(.8,.8,.9);
uniform float sea_level=.48;
uniform float ice_coverage=.05;
varying vec3 sphere_direction;
float hash3(vec3 p){p=fract(p*.1031);p+=dot(p,p.yzx+33.33);return fract((p.x+p.y)*p.z);}
float noise3(vec3 p){
 vec3 cell=floor(p),f=fract(p); f=f*f*(3.-2.*f);
 return mix(mix(mix(hash3(cell),hash3(cell+vec3(1,0,0)),f.x),mix(hash3(cell+vec3(0,1,0)),hash3(cell+vec3(1,1,0)),f.x),f.y),mix(mix(hash3(cell+vec3(0,0,1)),hash3(cell+vec3(1,0,1)),f.x),mix(hash3(cell+vec3(0,1,1)),hash3(cell+vec3(1,1,1)),f.x),f.y),f.z);
}
void vertex(){sphere_direction=normalize(VERTEX);}
void fragment(){
 vec3 n=normalize(sphere_direction);
 vec3 p=n*3.4+vec3(terrain_seed,terrain_seed*.71,-terrain_seed*.43);
 float h=noise3(p)*.70+noise3(p*2.17)*.30;
 float detail=dot(texture(surface_map,vec2(UV.x+longitude,UV.y)).rgb,vec3(.299,.587,.114));
 float land=smoothstep(sea_level-.025,sea_level+.025,h);
 vec3 ground=mix(land_color*.52,land_color*1.18,detail);
 ground=mix(ground,ridge_color,smoothstep(.61,.80,h)*.55);
 vec3 water=mix(ocean_color*.30,ocean_color*1.15,smoothstep(sea_level-.22,sea_level,h));
 vec3 color=mix(water,ground,land);
 vec3 glow=vec3(0.);
 float fine=noise3(p*5.3);
 if(identity==0){
  float crystal=pow(1.-abs(fine-.5)*2.,18.)*land;
  color+=ridge_color*crystal*.17; glow=vec3(.13,.40,.38)*crystal*.08;
 }else if(identity==1){
  color=mix(color,vec3(.72,.40,.52),smoothstep(.67,.84,fine)*land*.46);
 }else if(identity==2){
  color*=.97+.04*sin(h*180.+n.y*95.+detail*20.); color=mix(color,ridge_color,smoothstep(.72,.9,fine)*.14);
 }else if(identity==3){
  vec2 grid=abs(fract(vec2(UV.x*180.,UV.y*90.))-.5);
  float streets=(1.-smoothstep(.015,.055,min(grid.x,grid.y)))*land*smoothstep(.4,.6,fine);
  glow=mix(vec3(.12,.72,.85),vec3(.72,.14,.65),smoothstep(.4,.7,h))*streets*.8;
  color=mix(color,vec3(.32,.38,.46),streets*.25);
 }else if(identity==4){
  float coast=1.-smoothstep(.015,.055,abs(h-sea_level));
  color=mix(color,vec3(.28,.72,.69),coast*.5);
 }else if(identity==5){
  color=mix(color,ridge_color,smoothstep(.48,.73,fine)*land*.4);
 }else if(identity==6){
  float veins=(1.-smoothstep(.012,.046,abs(fine-.5)))*land;
  color=mix(color,vec3(.35,.23,.42),smoothstep(.65,.8,h)*.4);
  glow=vec3(.35,.69,.40)*veins*.45;
 }else if(identity==8){
  float lava=1.-smoothstep(.012,.052,abs(fine-.5));
  color=mix(color,vec3(.36,.075,.015),lava*.7); glow=vec3(1.,.20,.015)*lava*.95;
 }else if(identity==9){
  float fault=smoothstep(.94,.995,.5+.5*sin(h*100.+n.y*33.));
  glow=vec3(.45,.17,.80)*fault*.55; color*=.72;
 }
 if(ice_coverage>0.){
  float ice=smoothstep(1.-ice_coverage-.07,1.-ice_coverage+.1,abs(n.y)+h*.14);
  vec3 snow=mix(vec3(.67,.82,.91),vec3(.94,.98,1.),detail);
  if(identity==7) snow=mix(snow,vec3(.17,.40,.57),(1.-smoothstep(.009,.028,abs(fine-.5)))*.65);
  color=mix(color,snow,ice);
 }
 ALBEDO=color; EMISSION=glow;
 ROUGHNESS=mix(.86,.30,1.-land); SPECULAR=mix(.25,.55,1.-land); METALLIC=0.;
 if(identity==7){ROUGHNESS=.44;SPECULAR=.5;}
}
