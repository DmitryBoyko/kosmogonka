shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled, depth_test_disabled;
uniform float age=1.;
uniform float strength=1.;
uniform float special=0.;
uniform float suit_fx=0.;
uniform bool reduced=false;
uniform bool aura=false;
void fragment(){
 vec2 q=(UV-.5)*2.; float r=length(q);
 float t=clamp(age,0.,1.);
 float fade=pow(1.-t,1.5);
 float flash=exp(-r*r*38.)*exp(-t*24.);
 float halo=exp(-r*r*5.)*fade*.18;
 float radius=reduced?.42:mix(.12,.86,1.-pow(1.-t,3.));
 float ring=exp(-pow((r-radius)*36.,2.))*fade*.22;
 float sparks=0.;
 for(int i=0;i<8;i++){
  if (i>=4 && float(i-3)>suit_fx*4.0+.1) break;
  float a=float(i)*6.283185/(4.0+floor(suit_fx*4.0+.1))+.2;
  vec2 center=vec2(cos(a),sin(a))*(reduced?.35:mix(.15,.8,t));
  vec2 d=q-center;
  float cross_ray=max(exp(-abs(d.x)*140.-abs(d.y)*26.),exp(-abs(d.y)*140.-abs(d.x)*26.));
  sparks+=cross_ray*smoothstep(0.,.08,t)*(1.-smoothstep(.18,.8,t));
 }
 float value=aura?halo+ring*.45:flash*.85+halo+ring+sparks*(.55+special*.3);
 vec3 color=mix(vec3(1.,.62,.13),vec3(1.,.93,.64),clamp(flash+sparks,0.,1.));
 vec3 spectrum=.65+.35*cos(atan(q.y,q.x)+vec3(0.,2.09,4.18)+t*3.0);
 color=mix(color,spectrum,suit_fx*.88);
 ALBEDO=color; EMISSION=color*(.35+suit_fx*.55);
 ALPHA=clamp(value*strength,0.,.8);
}
