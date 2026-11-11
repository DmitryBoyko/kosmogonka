shader_type sky;
uniform int sun_count=1;
uniform float cloud_cover=.45;
uniform float flow_time=0.;
uniform bool fast_clouds=false;
uniform sampler2D cloud_map : filter_linear_mipmap, repeat_enable;
uniform vec3 sun_a=vec3(-.22,.38,-1.);
uniform vec3 sun_b=vec3(.23,.58,-1.);
uniform vec3 sun_c=vec3(.06,.27,-1.);
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
float fbm(vec2 p){float v=0.,a=.5;for(int i=0;i<5;i++){v+=noise(p)*a;p=p*2.03+vec2(13.1,7.4);a*=.5;}return v;}
vec3 sunlight(vec3 ray,vec3 direction,vec3 color,float size,vec3 background){
 float angle=acos(clamp(dot(ray,normalize(direction)),-1.,1.));
 float disk=1.-smoothstep(size*.84,size,angle);
 float halo=exp(-angle*22.)*.15;
 return mix(background,color,disk)+color*halo*.22;
}
void sky(){
 highp vec3 ray=normalize(EYEDIR);
 float height=max(ray.y,0.);
 vec3 blue=mix(vec3(.64,.77,.86),vec3(.13,.36,.65),pow(height,.45));
 float haze=pow(1.-clamp(height,0.,1.),8.);
 blue=mix(blue,vec3(.82,.85,.85),haze*.45);
 if(ray.y<0.) blue=mix(vec3(.721,.806,.856),vec3(.32,.41,.45),smoothstep(0.,.18,-ray.y));
 if(ray.y>.025){
  highp vec2 uv=ray.xz/(ray.y+.17)*1.2+vec2(flow_time*.003,flow_time*.001);
  float field=fast_clouds ? texture(cloud_map,uv*.0625).r : fbm(uv);
  float clouds=smoothstep(.70-cloud_cover*.42,.82-cloud_cover*.27,field);
  clouds*=smoothstep(.02,.22,ray.y);
  float shade=fast_clouds ? field : fbm(uv+vec2(.15));
  vec3 cloud_color=mix(vec3(.66,.73,.78),vec3(.98,.98,.95),smoothstep(.25,.65,shade));
  blue=mix(blue,cloud_color,clouds*.88);
 }
 blue=sunlight(ray,sun_a,vec3(1.,.94,.78),.0105,blue);
 if(sun_count>1) blue=sunlight(ray,sun_b,vec3(.68,.83,1.),.0075,blue);
 if(sun_count>2) blue=sunlight(ray,sun_c,vec3(1.,.68,.42),.006,blue);
 COLOR=blue;
}
