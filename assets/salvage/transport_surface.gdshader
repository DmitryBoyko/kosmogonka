shader_type spatial;
uniform sampler2D surface_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 tint : source_color = vec3(1.0);
uniform float tile_scale = .9;
uniform float metalness = .6;
uniform float roughness = .55;
uniform int surface_role = 0;
varying vec3 p;
varying vec3 n;
void vertex() { p=VERTEX; n=NORMAL; }
void fragment() {
 vec3 weights=pow(abs(normalize(n)),vec3(6.)); weights/=max(dot(weights,vec3(1.)),.001);
 vec3 q=p*tile_scale;
 vec3 tex=texture(surface_map,q.yz).rgb*weights.x+texture(surface_map,q.xz).rgb*weights.y+texture(surface_map,q.xy).rgb*weights.z;
 float value=dot(tex,vec3(.3,.59,.11));
 float finish=mix(.72,1.05,value);
 vec3 base=tint*finish;
 if(surface_role==1) {
  float grip=step(.81,fract((p.x+p.z)*15.))*step(.3,fract((p.x-p.z)*15.));
  base*=mix(.7,1.03,grip);
 }
 ALBEDO=base;
 METALLIC=metalness;
 ROUGHNESS=clamp(roughness+(1.-value)*.16,.25,.92);
 SPECULAR=.45;
}
