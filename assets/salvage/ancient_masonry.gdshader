shader_type spatial;
render_mode specular_schlick_ggx;
uniform sampler2D surface_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 stone_color : source_color = vec4(.62,.53,.4,1.0);
uniform float masonry_strength = 1.0;
varying vec3 point;
varying vec3 face;
float hash3(vec3 p) { return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453); }
float noise3(vec3 p) {
 vec3 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(mix(hash3(i),hash3(i+vec3(1,0,0)),f.x),mix(hash3(i+vec3(0,1,0)),hash3(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash3(i+vec3(0,0,1)),hash3(i+vec3(1,0,1)),f.x),mix(hash3(i+vec3(0,1,1)),hash3(i+vec3(1,1,1)),f.x),f.y),f.z);
}
void vertex(){ point=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; face=normalize(MODEL_NORMAL_MATRIX*NORMAL); }
void fragment(){
 vec3 w=pow(abs(face),vec3(8)); w/=max(dot(w,vec3(1)),.001);
 vec3 texture_color=texture(surface_map,point.yz*.17).rgb*w.x+texture(surface_map,point.xz*.17).rgb*w.y+texture(surface_map,point.xy*.17).rgb*w.z;
 vec2 uv=point.xy*w.z+point.zy*w.x+point.xz*w.y;
 float row=floor(uv.y/.72);
 vec2 masonry=vec2(uv.x+mod(row,2.0)*.63,uv.y)/vec2(1.65,.72);
 vec2 seam=abs(fract(masonry)-.5);
 float mortar=smoothstep(.475,.495,max(seam.x,seam.y));
 float age=noise3(point*.48),grain=noise3(point*19.0);
 float cracks=1.0-smoothstep(.015,.035,abs(noise3(point*2.3)-.48));
 vec3 col=stone_color.rgb*(.78+age*.32+grain*.12)*(vec3(.82)+texture_color*.6);
 col*=1.0-mortar*.26*masonry_strength; col*=1.0-cracks*.12;
 float dust=(1.0-smoothstep(.0,.8,abs(face.y)))*smoothstep(.4,0.0,point.y);
 col=mix(col,vec3(.42,.34,.25),dust*.25);
 ALBEDO=col; ROUGHNESS=.94; METALLIC=.02; SPECULAR=.22;
}
