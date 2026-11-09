shader_type spatial;
render_mode unshaded,blend_add,cull_disabled,depth_draw_never,shadows_disabled;
uniform float motion=1.;
varying float phase;
void vertex(){phase=MODEL_MATRIX[3].x*.7+MODEL_MATRIX[3].z*.13;}
void fragment(){
 float t=TIME*motion;float x=abs(UV.x-.5);
 float width=(.24*(1.-UV.y)+.015)*(1.+sin(t*12.+phase+UV.y*9.)*.08);
 float alpha=(1.-smoothstep(width*.65,width,x))*pow(1.-UV.y,1.2);
 ALBEDO=mix(vec3(.12,.6,1.),vec3(1.,.87,.3),exp(-x*x*180.)*(1.-UV.y));
 ALPHA=alpha*.65;
}
