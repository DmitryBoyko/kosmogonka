shader_type spatial;
uniform sampler2D surface_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D roughness_map : filter_linear_mipmap, repeat_enable;
uniform vec3 tint : source_color = vec3(.65,.8,.75);
uniform float tile_scale = .4;
uniform float metalness = .25;
uniform float roughness = .65;
uniform float normal_strength=.4;
uniform float panel_weight=.5;
varying vec3 p;
varying vec3 n;
void vertex(){ p=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz; n=normalize(MODEL_NORMAL_MATRIX*NORMAL); }
void fragment(){
 vec3 base_n=normalize(n),weight=abs(base_n),tangent;
 vec2 plane;
 if(weight.y>max(weight.x,weight.z)){plane=p.xz;tangent=vec3(1.,0.,0.);}
 else if(weight.x>weight.z){plane=p.zy;tangent=vec3(0.,0.,-sign(base_n.x));}
 else{plane=p.xy;tangent=vec3(sign(base_n.z),0.,0.);}
 vec2 uv=plane*tile_scale;
 vec3 tex=texture(surface_map,uv).rgb;
 vec2 panel=abs(fract(plane/vec2(2.8,1.4))-.5)*2.;
 float seam=smoothstep(.97,.995,max(panel.x,panel.y));
 ALBEDO=tex*tint*mix(1.,.54,seam*panel_weight);
 vec3 bump=texture(normal_map,uv).rgb*2.-1.; bump.xy*=normal_strength;
 tangent=normalize(tangent-base_n*dot(tangent,base_n));
 vec3 bitangent=normalize(cross(base_n,tangent));
 vec3 bumped=normalize(tangent*bump.x+bitangent*bump.y+base_n*bump.z);
 NORMAL=normalize((VIEW_MATRIX*vec4(bumped,0.)).xyz);
 EMISSION=vec3(0.);
 METALLIC=metalness; ROUGHNESS=clamp(texture(roughness_map,uv).r*.7+roughness*.3,.30,.97); SPECULAR=.4;
}
