shader_type canvas_item;
uniform vec2 dimensions=vec2(444.,64.);
uniform float pressed=0.;
uniform float hovered=0.;
uniform float focused=0.;
uniform float disabled=0.;
uniform bool primary=false;
uniform bool toggle=false;
uniform bool checked=false;
uniform bool pause_icon=false;
uniform int icon_kind=0;
uniform float opacity=1.;
float line(vec2 p,vec2 a,vec2 b,float width){vec2 d=b-a;return 1.-smoothstep(width,width+.014,length(p-a-d*clamp(dot(p-a,d)/dot(d,d),0.,1.)));}
float cross2(vec2 a,vec2 b){return a.x*b.y-a.y*b.x;}
float triangle(vec2 p,vec2 a,vec2 b,vec2 c){float x=cross2(p-a,b-a),y=cross2(p-b,c-b),z=cross2(p-c,a-c);return step(0.,x*y)*step(0.,y*z);}
float shape(vec2 p,vec2 size,float cut){
 float d=max(max(-p.x,p.x-size.x),max(-p.y,p.y-size.y));
 d=max(d,(cut-p.x-p.y)*.707);
 d=max(d,(cut-(size.x-p.x)-p.y)*.707);
 d=max(d,(cut-p.x-(size.y-p.y))*.707);
 return max(d,(cut-(size.x-p.x)-(size.y-p.y))*.707);
}
void fragment(){
 vec2 p=UV*dimensions; float depth=5.; float drop=pressed*2.5;
 vec2 face_p=p-vec2(0.,drop); vec2 face_size=dimensions-vec2(0.,depth);
 float outer=shape(p-vec2(0.,depth),face_size,9.);
 float sdf=shape(face_p,face_size,9.);
 float body=1.-smoothstep(-.5,.5,outer);
 float face=1.-smoothstep(-.5,.5,sdf);
 vec3 accent=primary?vec3(.29,.78,.88):vec3(.31,.47,.65);
 vec3 metal=mix(vec3(.16,.23,.34),vec3(.055,.085,.15),UV.y);
 metal+=hovered*vec3(.025,.045,.065);
 float rim=1.-smoothstep(-2.,-1.,sdf);
 float inset=smoothstep(-5.,-3.5,sdf)*(1.-smoothstep(-3.,-2.,sdf));
 vec3 color=mix(vec3(.018,.028,.052),metal,face);
 color=mix(color,accent*.65,rim*face);
 color+=vec3(.16,.23,.29)*(1.-smoothstep(1.,3.,abs(face_p.y-1.5)))*face;
 color+=accent*inset*.18;
 float led=step(12.,p.x)*step(p.x,16.)*step(dimensions.y*.35,p.y)*step(p.y,dimensions.y*.62);
 if(!toggle && !pause_icon && icon_kind==0) color+=accent*led*(primary?.85:.4);
 if(focused>.5) color+=accent*(1.-smoothstep(0.,1.,abs(sdf+3.)))*.75;
 if(toggle){
  vec2 q=p-vec2(dimensions.x-44.,dimensions.y*.5);
  float rail=1.-smoothstep(8.,9.,length(vec2(max(abs(q.x)-10.,0.),q.y)));
  color=mix(color,vec3(.025,.045,.07),rail);
  float knob=1.-smoothstep(6.,7.,length(q-vec2(checked?9.:-9.,0.)));
  color=mix(color,checked?vec3(.33,.82,.84):vec3(.40,.47,.55),knob);
 }
 if(pause_icon){
  vec2 q=abs(p-dimensions*.5);
  float bars=step(4.,q.x)*step(q.x,8.)*step(q.y,10.);
  color=mix(color,vec3(.82,.94,1.),bars);
 }
 if(icon_kind>0){
  vec2 q=(p-dimensions*.5)/min(dimensions.x,dimensions.y);
  float ink=0.;
  if(icon_kind==1){
   ink=1.-smoothstep(.94,1.04,length((q-vec2(0.,-.035))/vec2(.115,.28)));
   ink=max(ink,triangle(q,vec2(-.06,.04),vec2(-.23,.23),vec2(-.08,.19)));
   ink=max(ink,triangle(q,vec2(.06,.04),vec2(.23,.23),vec2(.08,.19)));
   float window=1.-smoothstep(.045,.06,length(q-vec2(0.,-.11)));
   color=mix(color,vec3(.83,.97,1.),ink); color=mix(color,vec3(.12,.46,.62),window);
   float fire=triangle(q,vec2(-.055,.20),vec2(.055,.20),vec2(0.,.36)); color=mix(color,vec3(1.,.72,.32),fire);
  }else{
   ink=1.-smoothstep(.05,.065,length(q-vec2(-.04,-.24)));
   ink=max(ink,line(q,vec2(-.06,-.13),vec2(.03,.07),.035));
   ink=max(ink,line(q,vec2(-.055,-.09),vec2(-.23,-.25),.03));
   ink=max(ink,line(q,vec2(-.055,-.09),vec2(.18,-.27),.03));
   ink=max(ink,line(q,vec2(.03,.07),vec2(-.18,.27),.035));
   ink=max(ink,line(q,vec2(.03,.07),vec2(.24,.19),.035));
   color=mix(color,vec3(.83,.97,1.),ink);
  }
 }
 color=mix(color,vec3(dot(color,vec3(.3,.59,.11)))*.58,disabled);
 COLOR=vec4(color,max(body,face)*opacity);
}
