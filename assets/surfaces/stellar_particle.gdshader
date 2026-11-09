shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
varying vec4 ink;
varying vec4 shape_data;
void vertex(){
 float sx=length(MODEL_MATRIX[0].xyz),sy=length(MODEL_MATRIX[1].xyz);
 MODELVIEW_MATRIX=VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0]*sx,INV_VIEW_MATRIX[1]*sy,INV_VIEW_MATRIX[2],MODEL_MATRIX[3]);
 ink=COLOR;shape_data=INSTANCE_CUSTOM;
}
float cross2(vec2 a,vec2 b){return a.x*b.y-a.y*b.x;}
void fragment(){
 vec2 q=(UV-.5)*2.; float c=cos(shape_data.y),s=sin(shape_data.y);q=mat2(vec2(c,s),vec2(-s,c))*q;
 float mask;
 if(shape_data.x>.5){
  float a=mod(atan(q.x,-q.y)+6.2831853,6.2831853),part=floor(a/.62831853);
  float a0=part*.62831853,a1=a0+.62831853;
  float r0=mod(part,2.)<.5?1.:.46,r1=mod(part,2.)<.5?.46:1.;
  vec2 v0=vec2(sin(a0),-cos(a0))*r0,v1=vec2(sin(a1),-cos(a1))*r1;
  vec2 d=vec2(sin(a),-cos(a)),edge=v1-v0;
  float r=abs(cross2(v0,edge)/max(.001,abs(cross2(d,edge))));
  mask=1.-smoothstep(r-.035,r+.035,length(q));
  mask+=exp(-dot(q,q)*3.)*.13;
 }else{mask=exp(-q.x*q.x*10.-q.y*q.y*2.2);}
 ALBEDO=ink.rgb*(1.+exp(-dot(q,q)*10.)*.35); ALPHA=clamp(mask*ink.a,0.,1.);
}
