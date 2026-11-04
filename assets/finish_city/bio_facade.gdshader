shader_type spatial;
uniform sampler2D surface_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 tint : source_color = vec3(.65,.8,.75);
uniform float tile_scale = .4;
uniform float metalness = .25;
uniform float roughness = .65;
varying vec3 p;
varying vec3 n;
void vertex(){ p=VERTEX; n=NORMAL; }
void fragment(){
 vec3 w=pow(abs(normalize(n)),vec3(6.)); w/=max(dot(w,vec3(1.)),.001);
 vec3 q=p*tile_scale;
 vec3 tex=texture(surface_map,q.yz).rgb*w.x+texture(surface_map,q.xz).rgb*w.y+texture(surface_map,q.xy).rgb*w.z;
 float grain=dot(tex,vec3(.3,.59,.11));
 float wall=1.-smoothstep(.35,.75,abs(normalize(n).y));
 vec2 facade=vec2(mix(p.x,p.z,w.x),p.y);
 float vine=1.-smoothstep(.03,.16,abs(sin(facade.x*.85+sin(facade.y*.9)*1.5)));
 vine*=wall*smoothstep(.15,.7,sin(facade.y*1.7+facade.x*.6));
 vec3 base=tint*mix(.72,1.12,grain);
 base=mix(base,vec3(.09,.35,.24),vine*.72);
 ALBEDO=base;
 EMISSION=vec3(0.);
 METALLIC=metalness; ROUGHNESS=roughness; SPECULAR=.4;
}
