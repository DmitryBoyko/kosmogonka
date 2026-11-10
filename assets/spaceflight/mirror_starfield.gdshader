shader_type spatial;
render_mode unshaded,cull_front,depth_draw_never,fog_disabled;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void fragment(){
 vec2 p=vec2(abs(UV.x-.5)*2.,UV.y);
 float dust=sin(p.x*16.+sin(p.y*11.)*2.)*.5+.5;
 float ribbon=exp(-abs(p.y-.5-sin(p.x*8.)*.13)*24.);
 vec3 color=vec3(.009,.015,.047)+mix(vec3(.02,.22,.29),vec3(.23,.04,.27),dust)*ribbon*.65;
 vec2 cell=floor(p*vec2(900.,450.));vec2 at=fract(p*vec2(900.,450.))-.5;
 float star=step(.997,hash(cell))*exp(-dot(at,at)*24.);
 ALBEDO=color+star*vec3(.7,.9,1.);
}
