shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform float energy : hint_range(0.0,1.0) = 0.0;
void fragment() {
	float edge=pow(max(0.0,1.0-abs(UV.y-0.5)*2.0),1.7);
	float ends=pow(max(0.0,sin(UV.x*3.14159265)),0.55);
	vec3 gold=mix(vec3(1.0,0.55,0.12),vec3(1.0,0.92,0.60),edge);
	ALBEDO=gold*1.35;
	EMISSION=gold*0.6;
	ALPHA=edge*ends*energy*0.65;
}
