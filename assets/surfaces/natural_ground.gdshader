shader_type spatial;
uniform sampler2D grass_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 tint : source_color=vec3(1.);
varying vec3 p;
void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment(){
 vec3 tex=texture(grass_map,p.xz*.12).rgb;
 float variation=.92+.08*sin(p.x*.19)*sin(p.z*.23);
 ALBEDO=tex*tint*variation; ROUGHNESS=.97; SPECULAR=.12; METALLIC=0.;
}
