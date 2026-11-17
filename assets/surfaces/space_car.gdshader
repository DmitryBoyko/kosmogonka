shader_type spatial;
render_mode depth_prepass_alpha;
uniform sampler2D colormap : source_color,filter_linear_mipmap,repeat_disable;
uniform sampler2D panel_map : source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform float window_floor=.4;
varying vec3 point;
void vertex(){point=VERTEX;}
void fragment(){
 vec3 base=texture(colormap,UV).rgb;
 float grain=dot(texture(panel_map,vec2(point.x+point.z,point.y)*1.1).rgb,vec3(.3,.59,.11));
 bool window=UV.x<.125 && point.y>window_floor && base.b>base.r*1.01 && base.g>.55;
 ALBEDO=window ? vec3(.40,.75,.88) : base*(.82+.43*grain);
 ALPHA=window ? .16 : 1.;
 ROUGHNESS=window ? .28 : .76;
 METALLIC=window ? .0 : .18;
 SPECULAR=.25;
}
