shader_type spatial;

uniform sampler2D armor_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D wear_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 paint_color : source_color = vec3(.32,.39,.20);
uniform float metalness = .32;
uniform float glow = 0.;
uniform bool hazard = false;
varying vec3 point;
varying vec3 axis;
void vertex() { point=VERTEX; axis=NORMAL; }
void fragment() {
 vec3 n=abs(normalize(axis));
 vec2 uv=n.z>n.x && n.z>n.y ? point.xy : (n.x>n.y ? point.zy : point.xz);
 uv*=2.4;
 vec3 panel=texture(armor_map,uv).rgb;
 vec3 wear=texture(wear_map,uv*.73+vec2(.19,.34)).rgb;
 float grain=dot(panel,vec3(.3,.59,.11));
 float scratches=(1.-smoothstep(.025,.13,wear.r-wear.b))*.24;
 vec3 paint=paint_color;
 if(hazard) {
  float line=fract((point.x+point.y)*9.);
  float aa=max(fwidth(line),.025);
  float stripe=smoothstep(.47-aa,.47+aa,line)*(1.-smoothstep(.90-aa,.90+aa,line));
  paint=mix(paint,vec3(.055,.065,.043),stripe*.73);
 }
 ALBEDO=mix(paint*(.64+grain*1.35),vec3(.28,.30,.27),scratches);
 METALLIC=metalness;
 ROUGHNESS=.74;
 SPECULAR=.25;
 EMISSION=paint_color*glow;
}
