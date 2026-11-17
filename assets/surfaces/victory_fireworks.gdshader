shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

varying vec4 ink;
void vertex() {
	ink=INSTANCE_CUSTOM;
}
void fragment() {
	float longitudinal=1.-UV.y;
	float distance_to_axis=abs(UV.x-.5)*2.;
	float taper=mix(.20,1.,smoothstep(0.,.94,longitudinal));
	float body=1.-smoothstep(taper*.58,taper,distance_to_axis);
	float tip=smoothstep(.66,.86,longitudinal)*(1.-smoothstep(.92,1.,longitudinal));
	float fade=smoothstep(0.,.75,longitudinal)*(1.-smoothstep(.97,1.,longitudinal));
	vec3 saturated=pow(ink.rgb,vec3(1.5));
	ALBEDO=mix(saturated*.62,mix(saturated,vec3(1.),.20*tip),clamp(tip+longitudinal*.72,0.,1.));
	ALPHA=body*fade*ink.a;
}
